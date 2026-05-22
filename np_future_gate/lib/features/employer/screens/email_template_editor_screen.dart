import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:np_future_gate/core/repositories/employer_response_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class EmailTemplateEditorScreen extends StatefulWidget {

  const EmailTemplateEditorScreen({
    super.key,
    required this.templateType,
    required this.title,
    required this.color,
    this.candidateId,
    this.jobId,
    this.candidateData,
    this.jobData,
    this.employerData,
    this.interviewData,
  });
  final String templateType;
  final String title;
  final Color color;
  
  // Optional: Nếu null = Template Management Mode (chỉ chỉnh sửa template)
  // Nếu có = Send Email Mode (gửi email thật)
  final String? candidateId;
  final String? jobId;
  final Map<String, dynamic>? candidateData;
  final Map<String, dynamic>? jobData;
  final Map<String, dynamic>? employerData;
  final Map<String, dynamic>? interviewData;

  @override
  State<EmailTemplateEditorScreen> createState() =>
      _EmailTemplateEditorScreenState();
}

class _EmailTemplateEditorScreenState extends State<EmailTemplateEditorScreen> {
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  
  // Track which text field was last focused
  late FocusNode _subjectFocusNode;
  late FocusNode _bodyFocusNode;
  TextEditingController? _lastFocusedController;
  
  final _repository = EmployerResponseRepository();
  final _supabaseService = SupabaseService.instance;
  
  final List<PlatformFile> _attachments = []; // Newly picked files (not uploaded yet)
  List<Map<String, dynamic>> _savedAttachments = []; // Already uploaded files from DB
  bool _isVariablesPanelExpanded = false;
  bool _isSaving = false;
  
  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  TextEditingController? _activeListeningController;
  
  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    
    _subjectFocusNode = FocusNode();
    _bodyFocusNode = FocusNode();
    
    // Speech-to-text init
    _speech = stt.SpeechToText();
    _initSpeech();
    
    // Listen to focus changes to track which field was last focused
    _subjectFocusNode.addListener(() {
      if (_subjectFocusNode.hasFocus) {
        _lastFocusedController = _subjectController;
      }
    });
    _bodyFocusNode.addListener(() {
      if (_bodyFocusNode.hasFocus) {
        _lastFocusedController = _bodyController;
      }
    });
    
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final employerId = _supabaseService.currentUserId;
      if (employerId == null) return;

      // Load template từ email_templates
      final response = await _supabaseService.client
          .from('email_templates')
          .select()
          .eq('employer_id', employerId)
          .eq('response_type', widget.templateType)
          .maybeSingle();

      if (response != null) {
        _subjectController.text = response['subject'] as String? ?? '';
        _bodyController.text = response['body'] as String? ?? '';
        
        // Load saved attachments
        final attachmentsData = response['attachments'];
        if (attachmentsData != null && attachmentsData is List) {
          setState(() {
            _savedAttachments = List<Map<String, dynamic>>.from(
              attachmentsData.map((e) => Map<String, dynamic>.from(e)),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading template: $e');
    }
  }

  void _insertVariable(String variable) {
    // Use the last focused controller, default to body if none was focused
    final controller = _lastFocusedController ?? _bodyController;
    final currentText = controller.text;
    
    // Get cursor position; if invalid (-1), append to the end
    int currentPosition = controller.selection.base.offset;
    if (currentPosition < 0 || currentPosition > currentText.length) {
      currentPosition = currentText.length;
    }
    
    final newText = currentText.substring(0, currentPosition) +
        variable +
        currentText.substring(currentPosition);
    
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: currentPosition + variable.length,
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn file: $e')),
        );
      }
    }
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

  Future<void> _toggleListeningFor(TextEditingController controller) async {
    if (!_speechAvailable) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _activeListeningController = null;
      });
    } else {
      _activeListeningController = controller;
      setState(() => _isListening = true);
      
      final startPosition = controller.selection.baseOffset >= 0
          ? controller.selection.baseOffset
          : controller.text.length;
      
      await _speech.listen(
        onResult: (result) {
          if (!_isListening) return;
          setState(() {
            final before = controller.text.substring(0, startPosition);
            final after = controller.text.substring(startPosition);
            final newText = before + result.recognizedWords + after;
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                offset: startPosition + result.recognizedWords.length,
              ),
            );
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'vi_VN',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
        ),
      );
    }
  }

  Widget _buildMicButton(TextEditingController controller) {
    final isActive = _isListening && _activeListeningController == controller;
    return IconButton(
      onPressed: () => _toggleListeningFor(controller),
      icon: Icon(
        isActive ? Icons.mic : Icons.mic_none,
        color: isActive ? Colors.red : widget.color,
      ),
      tooltip: 'Nhập bằng giọng nói',
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _subjectFocusNode.dispose();
    _bodyFocusNode.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _saveTemplate,
                  icon: const Icon(Icons.send, size: 20),
                  label: const Text('Gửi'),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.color,
                  ),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Subject Field
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tiêu đề Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              _buildMicButton(_subjectController),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
            focusNode: _subjectFocusNode,
            decoration: InputDecoration(
              hintText: 'Nhập tiêu đề email',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.color, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Body Field
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nội dung Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              _buildMicButton(_bodyController),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            focusNode: _bodyFocusNode,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Nhập nội dung email',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.color, width: 2),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          // Attachments Section
          Row(
            children: [
              Expanded(
                child: Text(
                  'File đính kèm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Thêm file'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
          if (_savedAttachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._savedAttachments.asMap().entries.map(
              (entry) => _buildSavedAttachmentItem(entry.key, entry.value),
            ),
          ],
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._attachments.map((file) => _buildAttachmentItem(file)),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Variables Section - Expandable
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              initiallyExpanded: _isVariablesPanelExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isVariablesPanelExpanded = expanded;
                });
              },
              leading: Icon(Icons.code, color: widget.color),
              title: const Text(
                'Biến có sẵn',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Nhấn vào biến để thêm vào nội dung',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildVariableGroup(
                        'Thông tin công việc',
                        Icons.work_outline,
                        Colors.blue,
                        [
                          {'var': '{{job_title}}', 'label': 'Tên vị trí'},
                          {'var': '{{job_field}}', 'label': 'Lĩnh vực'},
                          {'var': '{{job_location}}', 'label': 'Địa điểm'},
                          {'var': '{{salary_range}}', 'label': 'Mức lương'},
                          {'var': '{{employment_type}}', 'label': 'Loại hình'},
                        ],
                      ),
                      _buildVariableGroup(
                        'Thông tin ứng viên',
                        Icons.person_outline,
                        Colors.green,
                        [
                          {'var': '{{candidate_name}}', 'label': 'Tên'},
                          {'var': '{{candidate_email}}', 'label': 'Email'},
                          {'var': '{{candidate_phone}}', 'label': 'SĐT'},
                        ],
                      ),
                      _buildVariableGroup(
                        'Thông tin công ty',
                        Icons.business_outlined,
                        Colors.purple,
                        [
                          {'var': '{{company_name}}', 'label': 'Tên công ty'},
                          {'var': '{{employer_email}}', 'label': 'Email'},
                          {'var': '{{employer_phone}}', 'label': 'SĐT'},
                          {'var': '{{company_address}}', 'label': 'Địa chỉ'},
                        ],
                      ),
                      _buildVariableGroup(
                        'Thông tin phỏng vấn',
                        Icons.event_outlined,
                        Colors.orange,
                        [
                          {'var': '{{interview_date}}', 'label': 'Ngày PV'},
                          {'var': '{{interview_time}}', 'label': 'Giờ PV'},
                          {'var': '{{interview_location}}', 'label': 'Địa điểm'},
                          {'var': '{{interview_type}}', 'label': 'Hình thức'},
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Preview Button
          OutlinedButton.icon(
            onPressed: _showPreview,
            icon: const Icon(Icons.preview_outlined),
            label: const Text('Xem trước'),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.color,
              side: BorderSide(color: widget.color),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableGroup(
    String title,
    IconData icon,
    Color color,
    List<Map<String, String>> variables,
  ) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      children: variables.map((v) => _buildVariableChip(v['var']!, v['label']!, color)).toList(),
    );
  }

  Widget _buildVariableChip(String variable, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Material(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _insertVariable(variable),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        variable,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAttachmentItem(int index, Map<String, dynamic> attachment) {
    final name = attachment['name'] as String? ?? 'File';
    final size = attachment['size'] as int? ?? 0;
    final sizeInMB = (size / 1048576).toStringAsFixed(2);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done, color: Colors.green.shade600, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$sizeInMB MB • Đã lưu',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
            onPressed: () {
              setState(() => _savedAttachments.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(PlatformFile file) {
    final sizeInMB = (file.size / 1048576).toStringAsFixed(2);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$sizeInMB MB',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() => _attachments.remove(file));
            },
          ),
        ],
      ),
    );
  }

  void _showPreview() {
    // Template mode: Hiển thị với biến {{variable}}
    final subject = _subjectController.text;
    final body = _bodyController.text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.preview, color: widget.color),
            const SizedBox(width: 8),
            const Text('Xem trước Email'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiêu đề:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    body,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                    softWrap: true,
                  ),
                ),
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'File đính kèm:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._attachments.map((file) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              file.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
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

  Future<void> _saveTemplate() async {
    if (_isSaving) return;

    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề email')),
      );
      return;
    }

    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung email')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final employerId = _supabaseService.currentUserId;
      if (employerId == null) {
        throw Exception('User not authenticated');
      }

      // Upload new attachment files to Supabase Storage
      final List<Map<String, dynamic>> allAttachments = List.from(_savedAttachments);
      
      for (var file in _attachments) {
        try {
          final url = await _repository.uploadAttachment(file, employerId);
          allAttachments.add({
            'url': url,
            'name': file.name,
            'size': file.size,
            'type': _getContentType(file.extension),
          });
        } catch (e) {
          debugPrint('Error uploading file ${file.name}: $e');
        }
      }

      // UPSERT - tự động insert hoặc update
      await _supabaseService.client.from('email_templates').upsert({
        'employer_id': employerId,
        'response_type': widget.templateType,
        'subject': _subjectController.text,
        'body': _bodyController.text,
        'attachments': allAttachments,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template đã được lưu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
