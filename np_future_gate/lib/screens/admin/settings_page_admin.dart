import 'package:flutter/material.dart';

class SettingsPageAdmin extends StatelessWidget {
  const SettingsPageAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt hệ thống',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'System Settings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // General Settings
          const Text(
            'Cài đặt chung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.language,
            title: 'Ngôn ngữ',
            subtitle: 'Tiếng Việt',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.palette,
            title: 'Giao diện',
            subtitle: 'Light mode',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.notifications,
            title: 'Thông báo',
            subtitle: 'Email, Push notifications',
            color: Colors.orange,
          ),
          const SizedBox(height: 24),

          // Security Settings
          const Text(
            'Bảo mật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.security,
            title: 'Bảo mật tài khoản',
            subtitle: '2FA, Password policy',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.lock,
            title: 'Quyền truy cập',
            subtitle: 'Roles & Permissions',
            color: Colors.indigo,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.history,
            title: 'Nhật ký hoạt động',
            subtitle: 'Activity logs',
            color: Colors.teal,
          ),
          const SizedBox(height: 24),

          // System Settings
          const Text(
            'Hệ thống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.storage,
            title: 'Cơ sở dữ liệu',
            subtitle: 'Backup, Restore',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.email,
            title: 'Email Server',
            subtitle: 'SMTP configuration',
            color: Colors.cyan,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.bug_report,
            title: 'Debug Mode',
            subtitle: 'Development tools',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
          onTap: () {},
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
                  child: Icon(icon, color: color, size: 24),
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
}
