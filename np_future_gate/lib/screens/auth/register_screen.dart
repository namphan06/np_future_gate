import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/auth_models.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';
import 'package:np_future_gate/core/theme/app_gradients.dart';
import 'package:np_future_gate/core/theme/app_text_styles.dart';
import 'package:np_future_gate/screens/admin/admin_home_screen.dart';
import 'package:np_future_gate/screens/candidate/candidate_home_screen.dart';
import 'package:np_future_gate/screens/employer/employer_home_screen.dart';
import 'package:np_future_gate/screens/school/school_home_screen.dart';
import 'package:np_future_gate/widgets/buttons/gradient_button.dart';
import 'package:np_future_gate/widgets/inputs/gradient_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.candidate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.candidate:
        return 'Người dùng';
      case UserRole.employer:
        return 'Nhà tuyển dụng';
      case UserRole.school:
        return 'Nhà trường';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.candidate:
        return 'Tìm kiếm cơ hội nghề nghiệp';
      case UserRole.employer:
        return 'Tuyển dụng nhân tài';
      case UserRole.school:
        return 'Kết nối sinh viên với doanh nghiệp';
      case UserRole.admin:
        return 'Quản trị hệ thống';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.candidate:
        return Icons.person_outline;
      case UserRole.employer:
        return Icons.business_outlined;
      case UserRole.school:
        return Icons.school_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authRepository.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result.success) {
          // Điều hướng theo role đã chọn
          Widget homeScreen;
          switch (_selectedRole) {
            case UserRole.candidate:
              homeScreen = const CandidateHomeScreen();
              break;
            case UserRole.employer:
              homeScreen = const EmployerHomeScreen();
              break;
            case UserRole.school:
              homeScreen = const SchoolHomeScreen();
              break;
            case UserRole.admin:
              homeScreen = const AdminHomeScreen();
              break;
          }
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => homeScreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Đăng ký thất bại'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authRepository.signInWithGoogle();

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result.success) {
        // Lấy profile để xác định role (Google sign-in tạo profile với role mặc định)
        final profile = await _authRepository.getCurrentUserProfile();
        
        if (profile != null && mounted) {
          // Điều hướng theo role
          Widget homeScreen;
          switch (profile.role) {
            case UserRole.candidate:
              homeScreen = const CandidateHomeScreen();
              break;
            case UserRole.employer:
              homeScreen = const EmployerHomeScreen();
              break;
            case UserRole.school:
              homeScreen = const SchoolHomeScreen();
            case UserRole.admin:
              homeScreen = const AdminHomeScreen();
              break;
          }
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => homeScreen),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Đăng ký thất bại'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: AppGradients.backgroundLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.primaryBlue.createShader(bounds),
                    child: const Text(
                      'Tạo tài khoản',
                      style: AppTextStyles.h1,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Chọn vai trò và điền thông tin của bạn',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Role Selection
                  const Text(
                    'Bạn là:',
                    style: AppTextStyles.h6,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: UserRole.values.where((role) => role != UserRole.admin).map((role) {
                      final isSelected = _selectedRole == role;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _RoleCard(
                            icon: _getRoleIcon(role),
                            title: _getRoleTitle(role),
                            description: _getRoleDescription(role),
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedRole = role;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Name Field
                  GradientTextField(
                    controller: _nameController,
                    labelText: 'Họ và tên',
                    hintText: 'Nhập họ và tên',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email Field
                  GradientTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Nhập email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone Field
                  GradientTextField(
                    controller: _phoneController,
                    labelText: 'Số điện thoại',
                    hintText: 'Nhập số điện thoại',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (value.length < 10) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  GradientTextField(
                    controller: _passwordController,
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixIconTap: _togglePasswordVisibility,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password Field
                  GradientTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixIconTap: _toggleConfirmPasswordVisibility,
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Register Button
                  GradientButton(
                    text: 'Đăng ký',
                    onPressed: _handleRegister,
                    gradient: AppGradients.primaryBlue,
                    height: 56,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hoặc đăng ký với',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Register Button
                  GradientOutlinedButton(
                    text: 'Đăng ký với Google',
                    onPressed: () {
                      if (!_isLoading) _handleGoogleRegister();
                    },
                    icon: Icons.g_mobiledata,
                    gradient: AppGradients.primaryBlue,
                  ),

                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GradientTextButton(
                        text: 'Đăng nhập',
                        onPressed: () => Navigator.pop(context),
                        gradient: AppGradients.primaryBlue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Role Card Widget
class _RoleCard extends StatelessWidget {

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primaryBlue : null,
          color: isSelected ? null : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.textWhite : AppColors.primaryBlue,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.textWhite.withValues(alpha: 0.9)
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
