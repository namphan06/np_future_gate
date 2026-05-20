import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../core/models/job_model.dart';
import '../../core/models/profile_model.dart';
import '../../core/theme/app_main_colors.dart';

class JobSelectionDialogWithEmail extends StatefulWidget {
  final Profile candidate;

  const JobSelectionDialogWithEmail({super.key, required this.candidate});

  @override
  State<JobSelectionDialogWithEmail> createState() => _JobSelectionDialogWithEmailState();
}

class _JobSelectionDialogWithEmailState extends State<JobSelectionDialogWithEmail> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadJobs();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _searchQuery = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: 'vi_VN',
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bạn chưa đăng nhập';
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('jobs')
          .select('*')
          .eq('creator_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      setState(() {
        _jobs = data.map((e) => JobModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải công việc: $e';
      });
    }
  }

  List<JobModel> get _filteredJobs {
    if (_searchQuery.isEmpty) return _jobs;
    final query = _searchQuery.toLowerCase();
    return _jobs.where((job) {
      final title = job.metadata.title.toLowerCase();
      final fields = job.metadata.fields.map((e) => e.toLowerCase()).toList();
      final tags = job.metadata.requirementsTags.map((e) => e.toLowerCase()).toList();
      
      return title.contains(query) || 
             fields.any((f) => f.contains(query)) || 
             tags.any((t) => t.contains(query));
    }).toList();
  }

  Future<void> _sendEmail(JobModel job) async {
    // Validate email before sending
    if (widget.candidate.email == null || widget.candidate.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ứng viên này chưa cập nhật email, không thể gửi lời mời.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show progress dialog with details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Đang gửi email...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Từ:', 'FutureGate <onboarding@resend.dev>'),
                const SizedBox(height: 8),
                _buildDetailRow('Đến:', widget.candidate.email!),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                const Center(child: Text('Đang xử lý yêu cầu...')),
              ],
            ),
          );
        },
      ),
    );

    try {
      // Construct payload exactly like the working curl command
      // User requested to ignore dynamic sender email ("không cần phải người gửi đâu")
      final body = {
        'candidate_email': widget.candidate.email!.trim(),
        'candidate_name': widget.candidate.fullName ?? 'Candidate',
        'job_title': job.metadata.title,
        'employer_email': 'example@gmail.com', // Hardcoded to match curl
      };
      
      debugPrint('Sending email payload: $body');

      // Call the Edge Function 'send-invitation-email'
      final response = await Supabase.instance.client.functions.invoke(
        'send-invitation-email',
        body: body,
      );

      debugPrint('Response status: ${response.status}');
      debugPrint('Response data: ${response.data}');

      // Check status code manually to be safe
      if (response.status != 200) {
        throw Exception('Status ${response.status}: ${response.data}');
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        Navigator.pop(context); // Close job selection dialog
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đã gửi yêu cầu', style: TextStyle(color: Colors.green)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 16),
                Text('Đã gửi giống hệt Terminal đến:'),
                Text(widget.candidate.email!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                const Text('ID từ Server:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${response.data['id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('Lưu ý: Nếu email này KHÁC email đăng ký Resend, bạn sẽ KHÔNG nhận được mail (do dùng gói Free).', 
                  style: TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gửi thất bại', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text('Lỗi: $e'),
                const SizedBox(height: 8),
                const Text('Vui lòng kiểm tra lại kết nối hoặc thử lại sau.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn công việc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, lĩnh vực...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _toggleListening,
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  tooltip: 'Tìm bằng giọng nói',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _filteredJobs.isEmpty
                          ? Center(
                              child: Text(
                                _jobs.isEmpty 
                                    ? 'Bạn chưa đăng công việc nào' 
                                    : 'Không tìm thấy công việc phù hợp',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredJobs.length,
                              itemBuilder: (context, index) {
                                final job = _filteredJobs[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    title: Text(
                                      job.metadata.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          job.metadata.fields.join(', '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lương: ${job.metadata.salary.min != null ? '${job.metadata.salary.min} - ${job.metadata.salary.max} triệu' : 'Thỏa thuận'}',
                                          style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _sendEmail(job),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppMainColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Mời'),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
