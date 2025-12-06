import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../auth/change_password_screen.dart';
import '../../core/services/supabase_service.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/models/profile_model.dart';
import '../profile/edit_profile_screen.dart';

class SettingsPageCandidate extends StatefulWidget {
  const SettingsPageCandidate({super.key});

  @override
  State<SettingsPageCandidate> createState() => _SettingsPageCandidateState();
}

class _SettingsPageCandidateState extends State<SettingsPageCandidate> {
  final supabaseService = SupabaseService.instance;
  final _authRepo = AuthRepository();
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authRepo.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    // Use existing profile if available, otherwise fetch
    final profile = _profile ?? await _authRepo.getCurrentUserProfile();
    
    if (profile != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
      );
      if (result == true) {
        _loadProfile(); // Reload profile from DB to get latest avatar
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thông tin hồ sơ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabaseService.currentUser;
    // Prioritize profile avatar, fallback to user metadata
    final avatarUrl = _profile?.avatarUrl ?? currentUser?.userMetadata?['avatar_url'];
    final fullName = _profile?.fullName ?? currentUser?.userMetadata?['full_name'] ?? 'Người dùng';
    final phone = _profile?.phone ?? currentUser?.userMetadata?['phone'];

    return Stack(
      children: [
            Container(
              decoration: const BoxDecoration(
                 color: AppMainColors.backgroundLightStart,
              ),
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // Profile Header
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
                            // Avatar - Rectangle with rounded corners
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: avatarUrl == null
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
                                child: avatarUrl != null
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppMainColors.primary.withOpacity(0.8),
                                                  AppMainColors.primaryDark,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                        const SizedBox(width: 16),

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Name
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),

                              // Email
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

                              // Phone if available
                              if (phone != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Edit button
                        Container(
                          decoration: BoxDecoration(
                            color: AppMainColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _navigateToEditProfile,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: AppMainColors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tài khoản Section
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
                          title: 'Chỉnh sửa hồ sơ',
                          subtitle: 'Cập nhật thông tin cá nhân',
                          color: Colors.blue,
                          onTap: _navigateToEditProfile,
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
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.security,
                          title: 'Bảo mật & Quyền riêng tư',
                          subtitle: 'Cài đặt bảo mật tài khoản',
                          color: Colors.red,
                          onTap: () => _showComingSoon(context, 'Bảo mật'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Thông báo Section
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
                          color: Colors.purple,
                          onTap: () => _showComingSoon(context, 'Cài đặt thông báo'),
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

                // Hỗ trợ Section
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
                          subtitle: 'Cách sử dụng ứng dụng',
                          color: Colors.indigo,
                          onTap: () => _showComingSoon(context, 'Hướng dẫn sử dụng'),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          icon: Icons.article_outlined,
                          title: 'Điều khoản & Chính sách',
                          subtitle: 'Điều khoản sử dụng, chính sách bảo mật',
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
              'Ứng dụng tìm kiếm việc làm và phát triển sự nghiệp',
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await supabaseService.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
}
