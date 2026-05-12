import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/auth_models.dart';
import '../../core/repositories/admin_user_repository.dart';
import '../../core/theme/app_main_colors.dart';

class CreateUserScreenAdmin extends StatefulWidget {
  const CreateUserScreenAdmin({super.key});

  @override
  State<CreateUserScreenAdmin> createState() => _CreateUserScreenAdminState();
}

class _CreateUserScreenAdminState extends State<CreateUserScreenAdmin> {
  final _formKey = GlobalKey<FormState>();
  final AdminUserRepository _adminRepo = AdminUserRepository();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _limitPostController = TextEditingController();
  final TextEditingController _limitPartnershipController = TextEditingController();

  UserRole _selectedRole = UserRole.candidate;
  bool _isActive = false;
  bool _isSubmitting = false;
  DateTime? _selectedDob;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _educationController.dispose();
    _dobController.dispose();
    _limitPostController.dispose();
    _limitPartnershipController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 12, now.month, now.day),
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!value.contains('@')) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 8) {
      return 'Mật khẩu cần ít nhất 8 ký tự';
    }
    return null;
  }

  Map<String, dynamic> _buildMetadata() {
    final metadata = <String, dynamic>{};

    if (_addressController.text.trim().isNotEmpty) {
      metadata['address'] = _addressController.text.trim();
    }
    if (_websiteController.text.trim().isNotEmpty) {
      metadata['website'] = _websiteController.text.trim();
    }
    if (_descriptionController.text.trim().isNotEmpty) {
      metadata['description'] = _descriptionController.text.trim();
    }
    if (_educationController.text.trim().isNotEmpty) {
      metadata['education'] = _educationController.text.trim();
    }
    if (_selectedDob != null) {
      metadata['date_of_birth'] = _selectedDob!.toIso8601String();
    }

    final limitPost = int.tryParse(_limitPostController.text.trim());
    if (limitPost != null) {
      metadata['limit_post'] = limitPost;
    }

    final limitPartnership = int.tryParse(_limitPartnershipController.text.trim());
    if (limitPartnership != null) {
      metadata['limit_partnership'] = limitPartnership;
    }

    return metadata;
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _adminRepo.createUserAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
        metadata: _buildMetadata(),
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Tạo tài khoản thành công')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Tạo tài khoản thất bại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo tài khoản: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tạo tài khoản mới'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Thông tin tài khoản'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
                validator: (value) => _validateRequired(value, 'họ và tên'),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (value) => _validateRequired(value, 'số điện thoại'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu',
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRoleSelector(),
              const SizedBox(height: 12),
              _buildActiveSwitch(),
              const SizedBox(height: 24),

              _buildSectionTitle('Thông tin bổ sung'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả',
                maxLines: 3,
              ),
              if (_selectedRole == UserRole.candidate) ...[
                const SizedBox(height: 12),
                _buildDateOfBirthField(),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _educationController,
                  label: 'Học vấn',
                ),
              ],
              if (_selectedRole == UserRole.employer || _selectedRole == UserRole.school) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _limitPostController,
                        label: 'Giới hạn tin đăng',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    if (_selectedRole == UserRole.school) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _limitPartnershipController,
                          label: 'Giới hạn tin liên kết',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppMainColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tạo tài khoản',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRoleSelector() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Vai trò',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserRole>(
          value: _selectedRole,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: UserRole.candidate, child: Text('Ứng viên')),
            DropdownMenuItem(value: UserRole.employer, child: Text('Nhà tuyển dụng')),
            DropdownMenuItem(value: UserRole.school, child: Text('Nhà trường')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedRole = value;
              _limitPostController.clear();
              _limitPartnershipController.clear();
            });
          },
        ),
      ),
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kích hoạt tài khoản',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Switch(
            value: _isActive,
            activeColor: AppMainColors.primary,
            onChanged: (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: _pickDateOfBirth,
      decoration: InputDecoration(
        labelText: 'Ngày sinh',
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
