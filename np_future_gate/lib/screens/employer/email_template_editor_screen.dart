import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/models/employer_response_model.dart';
import '../../core/repositories/employer_response_repository.dart';
import '../../core/services/supabase_service.dart';

class EmailTemplateEditorScreen extends StatefulWidget {
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

  @override
  State<EmailTemplateEditorScreen> createState() =>
      _EmailTemplateEditorScreenState();
}

class _EmailTemplateEditorScreenState extends State<EmailTemplateEditorScreen> {
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  
  final _repository = EmployerResponseRepository();
  final _supabaseService = SupabaseService.instance;
  
  List<PlatformFile> _attachments = [];
  bool _isVariablesPanelExpanded = false;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
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
      }
    } catch (e) {
      print('Error loading template: $e');
    }
  }

  void _insertVariable(String variable) {
    final controller = _bodyController;
    final currentPosition = controller.selection.base.offset;
    final currentText = controller.text;
    
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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

  @override
  void dispose() {
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
          Text(
            'Tiêu đề Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
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
          Text(
            'Nội dung Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
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
                  color: Colors.black.withOpacity(0.05),
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
        color: color.withOpacity(0.05),
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

      // UPSERT - tự động insert hoặc update
      await _supabaseService.client.from('email_templates').upsert({
        'employer_id': employerId,
        'response_type': widget.templateType,
        'subject': _subjectController.text,
        'body': _bodyController.text,
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
}
