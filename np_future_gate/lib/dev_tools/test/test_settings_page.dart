import 'package:flutter/material.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/auth/screens/login_screen.dart';

class TestSettingsPage extends StatelessWidget {
  const TestSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService.instance;
    final authRepository = AuthRepository();
    final currentUser = supabaseService.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppMainColors.lightGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.settings_rounded,
                      size: 80,
                      color: AppMainColors.primaryLight,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cài Đặt',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Settings Page',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Thông tin user
              if (currentUser != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentUser.email ?? 'N/A',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.fingerprint, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ID: ${currentUser.id}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Logout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Hiển thị dialog xác nhận
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true && context.mounted) {
                      await authRepository.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
