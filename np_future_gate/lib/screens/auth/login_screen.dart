import 'package:flutter/material.dart';
import 'package:np_future_gate/screens/admin/admin_home_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/inputs/gradient_text_field.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/models/auth_models.dart';
import '../../core/services/fcm_service.dart';
import '../candidate/candidate_home_screen.dart';
import '../employer/employer_home_screen.dart';
import '../school/school_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result.success) {
          // Lấy profile để xác định role
          final profile = await _authRepository.getCurrentUserProfile();
          
          if (profile != null && mounted) {
            // Lưu FCM token thật (không phải dummy)
            try {
              final fcmToken = FCMService().fcmToken;
              if (fcmToken != null) {
                await _authRepository.saveDeviceToken(
                  deviceToken: fcmToken,
                  userId: profile.id,
                  role: profile.role.value,
                );
                print('✅ Real FCM token saved: ${fcmToken.substring(0, 20)}...');
              } else {
                print('⚠️ FCM token not available yet');
              }
            } catch (e) {
              print('⚠️ Failed to save FCM token: $e');
            }

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
              content: Text(result.message ?? 'Đăng nhập thất bại'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authRepository.signInWithGoogle();

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result.success) {
        // Lấy profile để xác định role
        final profile = await _authRepository.getCurrentUserProfile();
        
        if (profile != null && mounted) {
          // Lưu FCM token thật
          try {
            final fcmToken = FCMService().fcmToken;
            if (fcmToken != null) {
              await _authRepository.saveDeviceToken(
                deviceToken: fcmToken,
                userId: profile.id,
                role: profile.role.value,
              );
              print('✅ Real FCM token saved (Google login): ${fcmToken.substring(0, 20)}...');
            } else {
              print('⚠️ FCM token not available yet');
            }
          } catch (e) {
            print('⚠️ Failed to save FCM token: $e');
          }

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
              break;
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
            content: Text(result.message ?? 'Đăng nhập thất bại'),
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
                  const SizedBox(height: 40),

                  // Logo
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryBlue,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/logo/Screenshot 2025-11-30 100112.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Welcome Text
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.primaryBlue.createShader(bounds),
                    child: const Text(
                      'Chào mừng trở lại!',
                      style: AppTextStyles.h1,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Đăng nhập để tiếp tục khám phá tương lai',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Email Field
                  GradientTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Nhập email của bạn',
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

                  const SizedBox(height: 20),

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

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GradientTextButton(
                      text: 'Quên mật khẩu?',
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      gradient: AppGradients.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  GradientButton(
                    text: 'Đăng nhập',
                    onPressed: _handleLogin,
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
                          'Hoặc đăng nhập với',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Login Button
                  GradientOutlinedButton(
                    text: 'Đăng nhập với Google',
                    onPressed: () {
                      if (!_isLoading) _handleGoogleLogin();
                    },
                    icon: Icons.g_mobiledata,
                    gradient: AppGradients.primaryBlue,
                  ),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GradientTextButton(
                        text: 'Đăng ký ngay',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
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