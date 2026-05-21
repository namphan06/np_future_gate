import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/notification_settings_model.dart';
import 'package:np_future_gate/core/repositories/device_token_repository.dart';
import 'package:np_future_gate/core/services/fcm_service.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _deviceTokenRepo = DeviceTokenRepository();
  final _supabaseService = SupabaseService.instance;
  final _fcmService = FCMService();
  
  NotificationSettingsModel? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _supabaseService.currentUserId;
      final deviceToken = _fcmService.fcmToken;
      
      if (userId == null || deviceToken == null) {
        debugPrint('⚠️ User ID or Device Token not available');
        setState(() {
          _settings = NotificationSettingsModel();
          _isLoading = false;
        });
        return;
      }

      final settingsJson = await _deviceTokenRepo.getNotificationSettings(
        userId: userId,
        deviceToken: deviceToken,
      );

      setState(() {
        _settings = settingsJson != null
            ? NotificationSettingsModel.fromJson(settingsJson)
            : NotificationSettingsModel();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      setState(() {
        _settings = NotificationSettingsModel();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = _supabaseService.currentUserId;
      final deviceToken = _fcmService.fcmToken;

      if (userId == null || deviceToken == null) {
        throw Exception('User ID or Device Token not available');
      }

      final success = await _deviceTokenRepo.updateNotificationSettingsForAllDevices(
        userId: userId,
        settings: _settings!.toJson(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? '✅ Đã lưu cài đặt thành công'
                : '❌ Không thể lưu cài đặt'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Cài đặt thông báo',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (!_isLoading && _settings != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: TextButton.styleFrom(
                    foregroundColor: AppMainColors.primary,
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Không thể tải cài đặt'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Master Switch
                    _buildMasterSwitch(),
                    const SizedBox(height: 24),

                    // General Settings
                    _buildSectionTitle('Cài đặt chung'),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.volume_up,
                      title: 'Âm thanh',
                      subtitle: 'Phát âm thanh khi có thông báo',
                      value: _settings!.soundEnabled,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(soundEnabled: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.vibration,
                      title: 'Rung',
                      subtitle: 'Rung khi có thông báo mới',
                      value: _settings!.vibrationEnabled,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(vibrationEnabled: value);
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Notification Categories
                    _buildSectionTitle('Loại thông báo'),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.work_outline,
                      title: 'Việc làm',
                      subtitle: 'Thông báo về công việc mới',
                      value: _settings!.jobNotifications,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(jobNotifications: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.description_outlined,
                      title: 'Đơn ứng tuyển',
                      subtitle: 'Thông báo về đơn ứng tuyển',
                      value: _settings!.applicationNotifications,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(applicationNotifications: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.event_outlined,
                      title: 'Phỏng vấn',
                      subtitle: 'Thông báo về lịch phỏng vấn',
                      value: _settings!.interviewNotifications,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(interviewNotifications: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.message_outlined,
                      title: 'Tin nhắn',
                      subtitle: 'Thông báo tin nhắn mới',
                      value: _settings!.messageNotifications,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(messageNotifications: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.handshake_outlined,
                      title: 'Liên kết',
                      subtitle: 'Thông báo về liên kết trường - doanh nghiệp',
                      value: _settings!.partnershipNotifications,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(partnershipNotifications: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.system_update_outlined,
                      title: 'Hệ thống',
                      subtitle: 'Thông báo hệ thống và cập nhật',
                      value: _settings!.systemNotifications,
                      enabled: _settings!.enabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(systemNotifications: value);
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Notification Types - Simple Grid
                    _buildSectionTitle('Loại thông báo khác'),
                    const SizedBox(height: 12),
                    _buildSimpleTypesList(),

                    const SizedBox(height: 100),
                  ],
                ),
    );
  }

  Widget _buildMasterSwitch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _settings!.enabled 
              ? AppMainColors.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_settings!.enabled 
                  ? AppMainColors.primary 
                  : Colors.grey.shade400).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: _settings!.enabled 
                  ? AppMainColors.primary 
                  : Colors.grey.shade400,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo Push',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _settings!.enabled ? 'Đang bật' : 'Đang tắt',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings!.enabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings!.copyWith(enabled: value);
              });
            },
            activeThumbColor: AppMainColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
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
          onTap: enabled ? () => onChanged(!value) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppMainColors.primary.withValues(alpha: enabled ? 0.1 : 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? AppMainColors.primary : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: enabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeThumbColor: AppMainColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTypesList() {
    final types = [
      {'key': 'info', 'label': 'Thông tin', 'value': _settings!.notificationTypes.info},
      {'key': 'success', 'label': 'Thành công', 'value': _settings!.notificationTypes.success},
      {'key': 'warning', 'label': 'Cảnh báo', 'value': _settings!.notificationTypes.warning},
      {'key': 'error', 'label': 'Lỗi', 'value': _settings!.notificationTypes.error},
      {'key': 'reminder', 'label': 'Nhắc nhở', 'value': _settings!.notificationTypes.reminder},
      {'key': 'requirement', 'label': 'Yêu cầu', 'value': _settings!.notificationTypes.requirement},
      {'key': 'announcement', 'label': 'Thông báo', 'value': _settings!.notificationTypes.announcement},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: types.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final type = types[index];
          final isFirst = index == 0;
          final isLast = index == types.length - 1;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              onTap: _settings!.enabled 
                  ? () => _toggleType(type['key'] as String)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        type['label'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _settings!.enabled 
                              ? Colors.black87 
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Switch(
                      value: type['value'] as bool,
                      onChanged: _settings!.enabled 
                          ? (value) => _toggleType(type['key'] as String)
                          : null,
                      activeThumbColor: AppMainColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleType(String key) {
    setState(() {
      switch (key) {
        case 'info':
          _settings = _settings!.copyWith(
            notificationTypes: _settings!.notificationTypes.copyWith(
              info: !_settings!.notificationTypes.info,
            ),
          );
          break;
        case 'success':
          _settings = _settings!.copyWith(
            notificationTypes: _settings!.notificationTypes.copyWith(
              success: !_settings!.notificationTypes.success,
            ),
          );
          break;
        case 'warning':
          _settings = _settings!.copyWith(
            notificationTypes: _settings!.notificationTypes.copyWith(
              warning: !_settings!.notificationTypes.warning,
            ),
          );
          break;
        case 'error':
          _settings = _settings!.copyWith(
            notificationTypes: _settings!.notificationTypes.copyWith(
              error: !_settings!.notificationTypes.error,
            ),
          );
          break;
        case 'reminder':
          _settings = _settings!.copyWith(
            notificationTypes: _settings!.notificationTypes.copyWith(
              reminder: !_settings!.notificationTypes.reminder,
            ),
          );
          break;
        case 'requirement':
          _settings = _settings!.copyWith(
            notificationTypes: _settings!.notificationTypes.copyWith(
              requirement: !_settings!.notificationTypes.requirement,
            ),
          );
          break;
        case 'announcement':
          _settings = _settings!.copyWith(
            notificationTypes: _settings!.notificationTypes.copyWith(
              announcement: !_settings!.notificationTypes.announcement,
            ),
          );
          break;
      }
    });
  }
}
