import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/repositories/device_token_repository.dart';
import '../../core/services/supabase_service.dart';

class TestPageAdmin extends StatefulWidget {
  const TestPageAdmin({super.key});

  @override
  State<TestPageAdmin> createState() => _TestPageAdminState();
}

class _TestPageAdminState extends State<TestPageAdmin> {
  final DeviceTokenRepository _deviceTokenRepo = DeviceTokenRepository();
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  bool _isSending = false;

  Future<void> _testPushNotification() async {
    // Show dialog to choose who to send to
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi Test Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Gửi cho chính tôi'),
              subtitle: const Text('Test notification cho user hiện tại'),
              onTap: () {
                Navigator.pop(context);
                _sendToCurrentUser();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.groups, color: Colors.orange),
              title: const Text('Gửi cho TẤT CẢ users'),
              subtitle: const Text('Test gửi đến mọi người'),
              onTap: () {
                Navigator.pop(context);
                _sendToAllUsers();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.green),
              title: const Text('Gửi theo role'),
              subtitle: const Text('Chọn role cụ thể'),
              onTap: () {
                Navigator.pop(context);
                _sendByRole();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToCurrentUser() async {
    setState(() {
      _isSending = true;
    });

    try {
      final userId = _supabaseService.currentUserId;
      
      if (userId == null) {
        _showMessage('Không tìm thấy user ID', isError: true);
        return;
      }

      final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(userId: userId);
      
      if (deviceIds.isEmpty) {
        _showMessage('Không tìm thấy device token nào.', isError: true);
        return;
      }

      print('📱 Sending to current user: ${deviceIds.length} device(s)');

      final success = await PushNotificationService.sendNotificationToDevice(
        deviceToken: deviceIds.first,
        title: '🧪 Test - Current User',
        body: 'Notification gửi cho chính bạn - ${DateTime.now().toString()}',
        data: {
          'type': 'test',
          'target': 'current_user',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        _showMessage('✅ Đã gửi cho bạn!');
      } else {
        _showMessage('❌ Gửi thất bại!', isError: true);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showMessage('Lỗi: $e', isError: true);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendToAllUsers() async {
    setState(() {
      _isSending = true;
    });

    try {
      // Lấy TẤT CẢ device tokens (không filter userId)
      final allDeviceIds = await _deviceTokenRepo.getActiveDeviceIds();
      
      if (allDeviceIds.isEmpty) {
        _showMessage('Không có device token nào trong hệ thống.', isError: true);
        return;
      }

      print('📱 Sending to ALL users: ${allDeviceIds.length} device(s)');

      final success = await PushNotificationService.sendNotificationToMultipleDevices(
        deviceTokens: allDeviceIds,
        title: '📢 Broadcast Notification',
        body: 'Thông báo gửi đến TẤT CẢ users - ${DateTime.now().toString().substring(0, 19)}',
        data: {
          'type': 'broadcast',
          'target': 'all_users',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        _showMessage('✅ Đã gửi đến ${allDeviceIds.length} thiết bị!');
      } else {
        _showMessage('❌ Có lỗi xảy ra!', isError: true);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showMessage('Lỗi: $e', isError: true);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendByRole() async {
    // Show dialog to choose role
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Candidates'),
              leading: const Icon(Icons.person, color: Colors.blue),
              onTap: () {
                Navigator.pop(context);
                _sendToRole('candidate');
              },
            ),
            ListTile(
              title: const Text('Employers'),
              leading: const Icon(Icons.business, color: Colors.green),
              onTap: () {
                Navigator.pop(context);
                _sendToRole('employer');
              },
            ),
            ListTile(
              title: const Text('Schools'),
              leading: const Icon(Icons.school, color: Colors.purple),
              onTap: () {
                Navigator.pop(context);
                _sendToRole('school');
              },
            ),
            ListTile(
              title: const Text('Admins'),
              leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
              onTap: () {
                Navigator.pop(context);
                _sendToRole('admin');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToRole(String role) async {
    setState(() {
      _isSending = true;
    });

    try {
      final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(role: role);
      
      if (deviceIds.isEmpty) {
        _showMessage('Không có device token nào cho role: $role', isError: true);
        return;
      }

      print('📱 Sending to role "$role": ${deviceIds.length} device(s)');

      final success = await PushNotificationService.sendNotificationToMultipleDevices(
        deviceTokens: deviceIds,
        title: '📢 Notification for ${role.toUpperCase()}s',
        body: 'Thông báo gửi đến $role - ${DateTime.now().toString().substring(0, 19)}',
        data: {
          'type': 'role_specific',
          'target': role,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        _showMessage('✅ Đã gửi đến ${deviceIds.length} ${role}(s)!');
      } else {
        _showMessage('❌ Có lỗi xảy ra!', isError: true);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showMessage('Lỗi: $e', isError: true);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }


  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppMainColors.primary, AppMainColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.science, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Testing & Debugging',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Test các tính năng và kiểm tra hệ thống',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Test Options Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildTestCard(
                      icon: Icons.notifications_active,
                      title: 'Push Notifications',
                      subtitle: 'Test gửi thông báo',
                      color: Colors.orange,
                      onTap: _isSending ? null : _testPushNotification,
                      isLoading: _isSending,
                    ),
                    _buildTestCard(
                      icon: Icons.email_outlined,
                      title: 'Email Service',
                      subtitle: 'Test gửi email',
                      color: Colors.blue,
                      onTap: () {
                        _showMessage('Tính năng đang phát triển');
                      },
                    ),
                    _buildTestCard(
                      icon: Icons.storage,
                      title: 'Database',
                      subtitle: 'Kiểm tra kết nối DB',
                      color: Colors.green,
                      onTap: () {
                        _showMessage('Tính năng đang phát triển');
                      },
                    ),
                    _buildTestCard(
                      icon: Icons.api,
                      title: 'API Tests',
                      subtitle: 'Test các API endpoints',
                      color: Colors.purple,
                      onTap: () {
                        _showMessage('Tính năng đang phát triển');
                      },
                    ),
                    _buildTestCard(
                      icon: Icons.security,
                      title: 'Authentication',
                      subtitle: 'Test đăng nhập/đăng ký',
                      color: Colors.red,
                      onTap: () {
                        _showMessage('Tính năng đang phát triển');
                      },
                    ),
                    _buildTestCard(
                      icon: Icons.upload_file,
                      title: 'File Upload',
                      subtitle: 'Test upload files',
                      color: Colors.teal,
                      onTap: () {
                        _showMessage('Tính năng đang phát triển');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CircularProgressIndicator(color: color)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 40),
                ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

