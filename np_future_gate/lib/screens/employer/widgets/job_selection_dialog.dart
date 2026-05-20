import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/models/job_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/theme/app_main_colors.dart';
import '../../../widgets/speech_text_field.dart';

class JobSelectionDialog extends StatefulWidget {
  final Profile candidate;

  const JobSelectionDialog({super.key, required this.candidate});

  @override
  State<JobSelectionDialog> createState() => _JobSelectionDialogState();
}

class _JobSelectionDialogState extends State<JobSelectionDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<JobModel> _jobs = [];
  Profile? _employerProfile;
  bool _isLoading = true;
  String? _errorMessage;

  // EmailJS Configuration
  final String _emailJsServiceId = dotenv.get('EMAILJS_SERVICE_ID');
  final String _emailJsTemplateId = dotenv.get('EMAILJS_TEMPLATE_ID');
  final String _emailJsPublicKey = dotenv.get('EMAILJS_PUBLIC_KEY');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bạn chưa đăng nhập';
        });
        return;
      }

      // 1. Fetch Employer Profile
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _employerProfile = Profile.fromJson(profileResponse);

      // 2. Fetch Jobs
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
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải dữ liệu: $e';
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

  String _formatSalary(dynamic salary) {
    // Assuming salary is SalaryRange or similar struct in JobModel
    // Based on previous code: job.metadata.salary.min
    if (salary.min != null) {
      return '${salary.min} - ${salary.max} triệu';
    }
    return 'Thỏa thuận';
  }

  Future<void> _onJobSelected(JobModel job) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi email mời ứng tuyển'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn gửi email mời ứng tuyển cho:'),
            const SizedBox(height: 8),
            Text('Ứng viên: ${widget.candidate.fullName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Công việc: ${job.metadata.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppMainColors.primary, foregroundColor: Colors.white),
            child: const Text('Gửi Email'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sendEmail(job);
    }
  }

  Future<void> _sendEmail(JobModel job) async {
    if (_employerProfile == null) return;

    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final body = {
        'service_id': _emailJsServiceId,
        'template_id': _emailJsTemplateId,
        'user_id': _emailJsPublicKey,
        'template_params': {
          'job_name': job.metadata.title,
          'candidate_name': widget.candidate.fullName ?? 'Ứng viên',
          'job_field': job.metadata.fields.join(', '),
          'job_salary': _formatSalary(job.metadata.salary),
          'employer_name': _employerProfile!.fullName ?? 'Nhà tuyển dụng',
          'company_name': _employerProfile!.metadata['company_name'] ?? 'Công ty',
          'employer_mail': _employerProfile!.email ?? '',
          'email_to': widget.candidate.email ?? '',
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      // Dismiss Loading
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
       
        if (mounted) {
          Navigator.pop(context); // Close Job Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email đã được gửi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gửi email thất bại: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss Loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            SpeechTextField(
              controller: _searchController,
              hint: 'Tìm theo tên, lĩnh vực...',
              prefixIcon: Icons.search,
              onChanged: (value) => setState(() => _searchQuery = value),
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
                                          'Lương: ${_formatSalary(job.metadata.salary)}',
                                          style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _onJobSelected(job),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppMainColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Chọn'),
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
