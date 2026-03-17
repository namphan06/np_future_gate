import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/repositories/auth_repository.dart';
import '../../widgets/animated_avatar.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/chat_service.dart';
import '../chat/chat_detail_screen.dart';
import 'school_email_setup_screen.dart';
import '../settings/notification_settings_screen.dart';

class SettingsPageSchool extends StatefulWidget {
  const SettingsPageSchool({super.key});

  @override
  State<SettingsPageSchool> createState() => _SettingsPageSchoolState();
}

class _SettingsPageSchoolState extends State<SettingsPageSchool> {
  final supabaseService = SupabaseService.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = supabaseService.currentUser;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppMainColors.backgroundLightStart,
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // School Profile Header
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // School Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: currentUser?.userMetadata?['avatar_url'] == null
                                ? LinearGradient(
                                    colors: [
                                      AppMainColors.primary.withOpacity(0.8),
                                      AppMainColors.primaryDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppMainColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedAvatar(
                              avatarUrl: currentUser?.userMetadata?['avatar_url'],
                              width: 80,
                              height: 80,
                              borderRadius: 16,
                              placeholderIcon: Icons.school_rounded,
                              placeholderColor: Colors.transparent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // School Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.userMetadata?['full_name'] ?? 'Trường học',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      currentUser?.email ?? 'No email',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Settings icon
                        Container(
                          decoration: BoxDecoration(
                            color: AppMainColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.settings,
                              color: AppMainColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Account Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Tài khoản',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        _buildSettingCard(
                          icon: Icons.person_outline,
                          title: 'Thông tin cá nhân',
                          subtitle: 'Cập nhật thông tin trường học',
                          color: Colors.blue,
                          onTap: () => _showComingSoon(context, 'Thông tin cá nhân'),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.email_outlined,
                          title: 'Email trường học',
                          subtitle: 'Đăng ký email cho tin liên kết',
                          color: Colors.purple,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SchoolEmailSetupScreen(),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.lock_outline,
                          title: 'Đổi mật khẩu',
                          subtitle: 'Thay đổi mật khẩu đăng nhập',
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          ),
                        ),
                        // const SizedBox(height: 12),
                        // _buildSettingCard(
                        //   icon: Icons.security,
                        //   title: 'Bảo mật & Quyền riêng tư',
                        //   subtitle: 'Cài đặt bảo mật tài khoản',
                        //   color: Colors.red,
                        //   onTap: () => _showComingSoon(context, 'Bảo mật'),
                        // ),
                      ],
                    ),
                  ),
                ),

                // Partnership Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Hợp tác doanh nghiệp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        _buildSettingCard(
                          icon: Icons.verified,
                          title: 'Xác minh trường học',
                          subtitle: 'Xác thực thông tin trường',
                          color: Colors.green,
                          onTap: () => _showComingSoon(context, 'Xác minh'),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.handshake_outlined,
                          title: 'Quản lý liên kết',
                          subtitle: 'Danh sách công ty đối tác',
                          color: Colors.deepPurple,
                          onTap: () => _showComingSoon(context, 'Quản lý liên kết'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Notifications Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Thông báo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        _buildSettingCard(
                          icon: Icons.notifications_outlined,
                          title: 'Cài đặt thông báo',
                          subtitle: 'Quản lý thông báo push, email',
                          color: Colors.indigo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationSettingsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.email_outlined,
                          title: 'Thông báo Email',
                          subtitle: 'Nhận thông báo qua email',
                          color: Colors.teal,
                          onTap: () => _showComingSoon(context, 'Thông báo Email'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Support Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Hỗ trợ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        _buildSettingCard(
                          icon: Icons.help_outline,
                          title: 'Hướng dẫn sử dụng',
                          subtitle: 'Cách sử dụng dành cho trường học',
                          color: Colors.cyan,
                          onTap: () => _showComingSoon(context, 'Hướng dẫn'),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.support_agent,
                          title: 'Hỗ trợ khách hàng',
                          subtitle: 'Chat với đội ngũ Admin',
                          color: Colors.lightGreen,
                          onTap: () => _openChatWithAdmin(context),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.article_outlined,
                          title: 'Điều khoản & Chính sách',
                          subtitle: 'Điều khoản sử dụng, chính sách',
                          color: Colors.blueGrey,
                          onTap: () => _showComingSoon(context, 'Điều khoản'),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.info_outline,
                          title: 'Về chúng tôi',
                          subtitle: 'Phiên bản 1.0.0',
                          color: Colors.grey,
                          onTap: () => _showAboutDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // Logout Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showLogoutDialog(context),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, color: Colors.red.shade600, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Gradient overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.85),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.2, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppMainColors.primary),
            const SizedBox(width: 10),
            const Text('Về NP Future Gate'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nền tảng tuyển dụng và phát triển sự nghiệp',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Text(
              'Phiên bản: 1.0.0\nCopyright © 2025',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog
              Navigator.pop(dialogContext);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );
              
              // Sign out
              try {
                await AuthRepository().signOut();
              } catch (e) {
                print('Logout error: $e');
              }

              // Navigate to LoginScreen
              if (context.mounted) {
                Navigator.pop(context); // Pop loading
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithAdmin(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Find admin user from profiles
      final adminResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();

      if (adminResponse == null) {
        if (context.mounted) Navigator.pop(context); // Close loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy Admin. Vui lòng thử lại sau.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final adminId = adminResponse['id'] as String;
      final adminName = adminResponse['full_name'] as String? ?? 'Admin';
      final adminAvatar = adminResponse['avatar_url'] as String? ?? '';

      // Create or get existing conversation with admin
      final chatService = ChatService();
      final conversation = await chatService.getOrCreateConversation(
        otherUserId: adminId,
        otherUserType: 'admin',
      );

      if (context.mounted) Navigator.pop(context); // Close loading

      if (conversation != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversation: conversation,
              otherUserName: adminName,
              otherUserAvatar: adminAvatar,
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo cuộc trò chuyện. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
