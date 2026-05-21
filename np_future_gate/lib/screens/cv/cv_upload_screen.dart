import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:np_future_gate/core/enums/job_fields.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/core/services/mistral_service.dart';
import 'package:np_future_gate/core/services/ocr_service.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CVUploadScreen extends StatefulWidget {
  const CVUploadScreen({super.key});

  @override
  State<CVUploadScreen> createState() => _CVUploadScreenState();
}

class _CVUploadScreenState extends State<CVUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // New Personal Info Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedField;

  final CVSupabaseService _cvService = CVSupabaseService();

  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  
  final MistralService _mistralService = MistralService();
  
  // Tag management
  // ignore: unused_field
  final List<String> _availableTags = [
    'IT', 'Marketing', 'Business', 'Design', 'Engineer', 'Manager', 'Fresher', 'Junior', 'Senior'
  ];
  


  final TextEditingController _currentTagController = TextEditingController();
  final List<String> _addedTags = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        // Auto-fill email from auth
        if (_emailController.text.isEmpty && user.email != null) {
          _emailController.text = user.email!;
        }
        
        // Try to get phone from user metadata
        final userMetadata = user.userMetadata;
        if (userMetadata != null) {
          if (_phoneController.text.isEmpty && userMetadata['phone'] != null) {
            _phoneController.text = userMetadata['phone'].toString();
          }
          if (_nameController.text.isEmpty && userMetadata['full_name'] != null) {
            _nameController.text = userMetadata['full_name'].toString();
          }
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          
          // Auto-fill title and name from filename if empty
          if (_fileName != null) {
            final nameWithoutExt = _fileName!.split('.').first;
            if (_titleController.text.isEmpty) {
              _titleController.text = nameWithoutExt;
            }
            if (_nameController.text.isEmpty) {
              _nameController.text = nameWithoutExt;
            }
          }
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn file: $e')),
      );
    }
  }

  Future<void> _analyzeCV() async {
    if (_selectedFile == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // 1. OCR Extraction
      final result = await OcrService.extractText(
        file: _selectedFile!,
        language: 'vie', // Default to Vietnamese for local context
      );

      if (result['success'] == false) {
        throw Exception(result['error'] ?? 'Lỗi trích xuất OCR');
      }

      final String extractedText = result['text'] ?? '';
      if (extractedText.isEmpty) {
        throw Exception('Không tìm thấy văn bản trong file');
      }

      // 2. LLM Parsing
      final prompt = '''
      Hãy trích xuất thông tin cá nhân từ văn bản CV sau đây và trả về dưới dạng JSON. 
      Các trường cần trích xuất:
      - full_name (Họ tên)
      - email (Email)
      - phone (Số điện thoại)
      - job_title (Vị trí công việc/Tiêu đề CV)
      - field (Chọn một trong các lĩnh vực sau: ${JobField.valuesList.join(', ')})
      - summary (Mô tả ngắn gọn)
      - tags (Danh sách các từ khóa kỹ năng chính, tối đa 5)

      Văn bản CV:
      $extractedText

      Quy tắc:
      1. Chỉ trả về JSON, không giải thích thêm.
      2. Nếu không tìm thấy thông tin, hãy để giá trị null.
      3. Trường field phải trùng khớp chính xác với danh sách cung cấp.
      ''';

      final aiResponse = await _mistralService.sendMessage(prompt);
      
      // Extract JSON from AI response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(aiResponse);
      if (jsonMatch != null) {
        final data = json.decode(jsonMatch);
        
        setState(() {
          if (data['full_name'] != null && _nameController.text.isEmpty) {
            _nameController.text = data['full_name'];
          }
          if (data['email'] != null && _emailController.text.isEmpty) {
            _emailController.text = data['email'];
          }
          if (data['phone'] != null && _phoneController.text.isEmpty) {
            _phoneController.text = data['phone'];
          }
          if (data['job_title'] != null && _titleController.text.isEmpty) {
            _titleController.text = data['job_title'];
          }
          if (data['summary'] != null && _descriptionController.text.isEmpty) {
            _descriptionController.text = data['summary'];
          }
          if (data['field'] != null && JobField.valuesList.contains(data['field'])) {
            _selectedField = data['field'];
          }
          if (data['tags'] != null && data['tags'] is List) {
            for (var tag in data['tags']) {
              if (tag != null && !_addedTags.contains(tag.toString())) {
                _addedTags.add(tag.toString());
              }
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã trích xuất thông tin tự động!'), backgroundColor: Colors.blue),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phân tích AI: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _addTag() {
    final tag = _currentTagController.text.trim();
    if (tag.isNotEmpty && !_addedTags.contains(tag)) {
      setState(() {
        _addedTags.add(tag);
        _currentTagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _addedTags.remove(tag);
    });
  }

  List<String> _parseTags() {
    return _addedTags;
  }

  Future<void> _uploadCV() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn file CV')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Bạn chưa đăng nhập');

      // 1. Upload file
      final fileUrl = await _cvService.uploadCVFile(_selectedFile!, userId);

      // 2. Create DB Record
      final cvData = {
        'mcv': 'UPLOAD',
        'type': 'upload',
        'typeField': _selectedField, // Support field filtering
        'title': _titleController.text,
        'description': _descriptionController.text,
        'tags': _parseTags(),
        'file_url': fileUrl,
        'file_name': _fileName,
        'uploaded_at': DateTime.now().toIso8601String(),
        'personal_info': {
           'full_name': _nameController.text,
           'email': _emailController.text,
           'phone': _phoneController.text,
           'field': _selectedField,
        },
      };

      await _cvService.createCV(cvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload CV thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lỗi Upload', style: TextStyle(color: Colors.red)),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
           gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilePickerSection(),
                        const SizedBox(height: 24),
                        
                        if (_selectedFile != null) ...[
                          const Text(
                            'Thông tin cơ bản',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          // ... remainder of the form will follow naturally if I don't cut it off
                          // But I need to wrap the REST of the children.
                          // easier to just return the list of widgets in a structural way.

                        
                          _buildInputField(
                            label: 'Tên gợi nhớ (Tiêu đề)',
                            hint: 'Vd: CV Lập trình viên Flutter 2024',
                            controller: _titleController,
                            icon: Icons.title,
                            validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputField(
                            label: 'Họ và tên',
                            hint: 'Nhập họ và tên đầy đủ',
                            controller: _nameController,
                            icon: Icons.person,
                            validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(child: _buildInputField(
                                label: 'Email',
                                hint: 'email@example.com',
                                controller: _emailController,
                                icon: Icons.email,
                                inputType: TextInputType.emailAddress,
                              )),
                              const SizedBox(width: 16),
                              Expanded(child: _buildInputField(
                                label: 'Số điện thoại',
                                hint: '09xxxxxxxx',
                                controller: _phoneController,
                                icon: Icons.phone,
                                inputType: TextInputType.phone,
                              )),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildDropdownField(
                            label: 'Lĩnh vực / Ngành nghề',
                            hint: 'Chọn lĩnh vực',
                            value: _selectedField,
                            items: JobField.valuesList,
                            onChanged: (v) => setState(() => _selectedField = v),
                          ),

                          const SizedBox(height: 16),
                          _buildInputField(
                            label: 'Mô tả ngắn (Optional)',
                            hint: 'Mô tả sơ lược về hồ sơ này...',
                            controller: _descriptionController,
                            icon: Icons.description,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tags (Thẻ phân loại)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SpeechTextField(
                                  controller: _currentTagController,
                                  hint: 'Nhập tag và nhấn nút +',
                                  prefixIcon: Icons.tag,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.blue[700],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: _addTag,
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  tooltip: 'Thêm tag',
                                ),
                              ),
                            ],
                          ),
                          if (_addedTags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _addedTags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeTag(tag),
                                  backgroundColor: Colors.blue[50],
                                  labelStyle: TextStyle(
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  deleteIconColor: Colors.blue[700],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Upload CV',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedFile == null ? Icons.cloud_upload_outlined : Icons.file_present_rounded,
              size: 48,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFile == null ? 'Chọn file CV từ điện thoại' : 'Đã chọn file:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 8),
            Text(
              _fileName!,
              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Hỗ trợ PDF, DOC, DOCX',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedFile == null ? 'Chọn File' : 'Chọn File Khác'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeCV,
                icon: _isAnalyzing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(_isAnalyzing ? 'Đang phân tích...' : 'Tự động điền thông tin bằng AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? inputType,
    String? Function(String?)? validator,
  }) {
    return SpeechTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: icon,
      maxLines: maxLines,
      keyboardType: inputType,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: valHasHint(hint),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget valHasHint(String hint) {
    return Row(
      children: [
        Icon(Icons.category, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(hint, style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_selectedFile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -5),
            blurRadius: 20,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _uploadCV,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Lưu hồ sơ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
