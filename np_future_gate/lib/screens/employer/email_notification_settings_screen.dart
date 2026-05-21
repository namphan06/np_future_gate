import 'package:flutter/material.dart';
import 'package:np_future_gate/screens/employer/email_template_editor_screen.dart';

class EmailNotificationSettingsScreen extends StatelessWidget {
  const EmailNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt Email phản hồi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tùy chỉnh nội dung email gửi đến ứng viên cho từng trường hợp',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Response Templates Section
          _buildSectionTitle('Phản hồi ứng viên'),
          _buildTemplateCard(
            context,
            title: 'Email chấp nhận ứng viên',
            subtitle: 'Gửi khi chấp nhận ứng viên vào vị trí',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            templateType: 'accepted',
          ),
          const SizedBox(height: 12),
          _buildTemplateCard(
            context,
            title: 'Email từ chối ứng viên',
            subtitle: 'Gửi khi từ chối hồ sơ ứng viên',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            templateType: 'rejected',
          ),
          const SizedBox(height: 12),
          _buildTemplateCard(
            context,
            title: 'Email mời phỏng vấn',
            subtitle: 'Gửi lời mời phỏng vấn đến ứng viên',
            icon: Icons.event_outlined,
            color: Colors.blue,
            templateType: 'interview',
          ),

          const SizedBox(height: 32),

          // Additional Templates Section (for future expansion)
          _buildSectionTitle('Thông báo khác'),
          _buildTemplateCard(
            context,
            title: 'Email nhắc nhở',
            subtitle: 'Nhắc ứng viên hoàn tất hồ sơ',
            icon: Icons.notifications_outlined,
            color: Colors.orange,
            templateType: 'reminder',
            isComingSoon: true,
          ),
          const SizedBox(height: 12),
          _buildTemplateCard(
            context,
            title: 'Email cảm ơn',
            subtitle: 'Cảm ơn ứng viên đã ứng tuyển',
            icon: Icons.favorite_outline,
            color: Colors.pink,
            templateType: 'thank_you',
            isComingSoon: true,
          ),
          const SizedBox(height: 12),
          _buildTemplateCard(
            context,
            title: 'Email mời làm việc',
            subtitle: 'Thư chào mừng và thông tin onboarding',
            icon: Icons.business_center_outlined,
            color: Colors.purple,
            templateType: 'offer',
            isComingSoon: true,
          ),

          const SizedBox(height: 32),

          // Settings Section
          _buildSectionTitle('Cài đặt chung'),
          _buildSettingCard(
            title: 'Email người gửi',
            subtitle: 'noreply@npfuturegate.com',
            icon: Icons.email_outlined,
            color: Colors.teal,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng đang phát triển'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            title: 'Chữ ký email',
            subtitle: 'Thêm chữ ký tự động vào email',
            icon: Icons.draw_outlined,
            color: Colors.indigo,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng đang phát triển'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String templateType,
    bool isComingSoon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isComingSoon
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng đang phát triển'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailTemplateEditorScreen(
                        templateType: templateType,
                        title: title,
                        color: color,
                        // Template Management Mode - không cần data
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isComingSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Sớm ra mắt',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                        ],
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
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                    color: color.withValues(alpha: 0.1),
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
}
