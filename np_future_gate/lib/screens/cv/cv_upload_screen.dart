import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cv_supabase_service.dart';

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
  
  // Tag management
  final List<String> _availableTags = [
    'IT', 'Marketing', 'Business', 'Design', 'Engineer', 'Manager', 'Fresher', 'Junior', 'Senior'
  ];
  
  final List<String> _jobFields = [
    'Công nghệ thông tin',
    'Kinh doanh / Bán hàng', 
    'Marketing / Truyền thông',
    'Thiết kế / Sáng tạo',
    'Kỹ thuật / Cơ khí',
    'Tài chính / Kế toán',
    'Hành chính / Nhân sự',
    'Y tế / Sức khỏe',
    'Giáo dục / Đào tạo',
    'Khác'
  ];

  final Set<String> _selectedTags = {};

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn file: $e')),
      );
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
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
        'tags': _selectedTags.toList(),
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
                            items: _jobFields,
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
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableTags.map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (_) => _toggleTag(tag),
                                selectedColor: Colors.blue[100],
                                checkmarkColor: Colors.blue[700],
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.blue[900] : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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
                    color: Colors.black.withOpacity(0.05),
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
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: inputType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: val_has_hint(hint),
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

  Widget val_has_hint(String hint) {
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
            color: Colors.black.withOpacity(0.05),
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
