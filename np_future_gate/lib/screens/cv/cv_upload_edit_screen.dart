import 'package:flutter/material.dart';
import 'package:np_future_gate/core/enums/job_fields.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';

class CVUploadEditScreen extends StatefulWidget {

  const CVUploadEditScreen({
    super.key,
    required this.cvId,
    required this.initialData,
  });
  final String cvId;
  final Map<String, dynamic> initialData;

  @override
  State<CVUploadEditScreen> createState() => _CVUploadEditScreenState();
}

class _CVUploadEditScreenState extends State<CVUploadEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  String? _selectedField;
  bool _isLoading = false;
  final CVSupabaseService _cvService = CVSupabaseService();



  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    final info = data['personal_info'] ?? {};
    
    _titleController = TextEditingController(text: data['title'] ?? '');
    _nameController = TextEditingController(text: info['full_name'] ?? '');
    _emailController = TextEditingController(text: info['email'] ?? '');
    _phoneController = TextEditingController(text: info['phone'] ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');
    
    // Check typeField or info['field']
    _selectedField = data['typeField'] ?? info['field'];
    if (_selectedField != null && !JobField.valuesList.contains(_selectedField)) {
        _selectedField = null; // Reset if invalid
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateCV() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedData = Map<String, dynamic>.from(widget.initialData);
      final currentInfo = Map<String, dynamic>.from(updatedData['personal_info'] ?? {});

      // Update fields
      updatedData['title'] = _titleController.text;
      updatedData['description'] = _descriptionController.text;
      updatedData['typeField'] = _selectedField;
      
      currentInfo['full_name'] = _nameController.text;
      currentInfo['email'] = _emailController.text;
      currentInfo['phone'] = _phoneController.text;
      currentInfo['field'] = _selectedField;
      
      updatedData['personal_info'] = currentInfo;
      // Note: We are not updating 'file_url' here as we don't support re-upload in this simple edit screen yet.

      await _cvService.updateCVData(widget.cvId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              
              _buildInputField(
                label: 'Email',
                hint: 'email@example.com',
                controller: _emailController,
                icon: Icons.email,
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                label: 'Số điện thoại',
                hint: '09xxxxxxxx',
                controller: _phoneController,
                icon: Icons.phone,
                inputType: TextInputType.phone,
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
                label: 'Mô tả ngắn',
                hint: 'Mô tả sơ lược...',
                controller: _descriptionController,
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCV,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[600],
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(hint),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.category),
          ),
        ),
      ],
    );
  }
}
