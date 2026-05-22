import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/auth_models.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/features/admin/screens/admin_home_screen.dart';
import 'package:np_future_gate/features/auth/screens/login_screen.dart';
import 'package:np_future_gate/features/candidate/screens/candidate_home_screen.dart';
import 'package:np_future_gate/features/employer/screens/employer_home_screen.dart';
import 'package:np_future_gate/features/school/screens/school_home_screen.dart';

/// Splash Screen - Kiểm tra auth state khi khởi động app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Đợi 1 giây để hiển thị splash (tùy chọn)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final supabaseService = SupabaseService.instance;
    final authRepository = AuthRepository();

    // Kiểm tra user đã đăng nhập chưa
    if (supabaseService.isAuthenticated) {
      // Đã đăng nhập → lấy profile để xác định role
      try {
        final profile = await authRepository.getCurrentUserProfile();
        
        if (!mounted) return;

        if (profile != null) {
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
        } else {
          // Profile không tồn tại → đăng xuất và quay về login
          await authRepository.signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        // Lỗi khi lấy profile → quay về login
        debugPrint('Error loading profile: $e');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      // Chưa đăng nhập → vào LoginScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc app icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/logo/Screenshot 2025-11-30 100112.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Đang tải...'),
          ],
        ),
      ),
    );
  }
}
