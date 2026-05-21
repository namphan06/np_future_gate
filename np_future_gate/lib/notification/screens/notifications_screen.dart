import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:np_future_gate/core/models/notification_model.dart';
import 'package:np_future_gate/core/repositories/notification_repository.dart';
import 'package:np_future_gate/core/services/notification/status_notification_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/notification/models/notification_config.dart';
import 'package:np_future_gate/notification/widgets/notification_item_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Màn hình hiển thị danh sách thông báo
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationRepository _repository = NotificationRepository();
  final StatusNotificationService _service = StatusNotificationService();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  int _selectedTab = 0;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  // Filters
  NotificationType? _selectedType;
  bool? _selectedReadStatus; // null = all, true = read, false = unread

  String? _currentUserId;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _initUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      await _loadNotifications();
      await _loadUnreadCount();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTab = _tabController.index;
        // Tab 0: Tất cả, Tab 1: Chưa đọc
        _selectedReadStatus = _tabController.index == 1 ? false : null;
        _notifications.clear();
        _currentPage = 0;
        _hasMore = true;
      });
      _loadNotifications();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _repository.getNotifications(
        userId: _currentUserId!,
        limit: _pageSize,
        offset: 0,
        type: _selectedType,
        isRead: _selectedReadStatus,
      );

      setState(() {
        _notifications = notifications;
        _currentPage = 0;
        _hasMore = notifications.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông báo: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_currentUserId == null || _isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final notifications = await _repository.getNotifications(
        userId: _currentUserId!,
        limit: _pageSize,
        offset: nextPage * _pageSize,
        type: _selectedType,
        isRead: _selectedReadStatus,
      );

      setState(() {
        _notifications.addAll(notifications);
        _currentPage = nextPage;
        _hasMore = notifications.length >= _pageSize;
      });
    } catch (e) {
      debugPrint('Error loading more notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    if (_currentUserId == null) return;

    try {
      final count = await _repository.countUnreadNotifications(
        userId: _currentUserId!,
      );
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await _repository.markAllAsRead(userId: _currentUserId!);
      await _loadNotifications();
      await _loadUnreadCount();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppMainColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: AppMainColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Lọc thông báo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Filter options
                const Text(
                  'Loại thông báo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // All option
                _buildFilterChip(
                  label: 'Tất cả',
                  icon: Icons.all_inbox_rounded,
                  isSelected: _selectedType == null,
                  onTap: () {
                    setBottomSheetState(() {
                      _selectedType = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                
                // Type options
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NotificationType.values.map((type) {
                    return _buildFilterChip(
                      label: type.displayName,
                      icon: _getTypeIcon(type),
                      color: _getTypeColor(type),
                      isSelected: _selectedType == type,
                      onTap: () {
                        setBottomSheetState(() {
                          _selectedType = _selectedType == type ? null : type;
                        });
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setBottomSheetState(() {
                            _selectedType = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _notifications.clear();
                            _currentPage = 0;
                            _hasMore = true;
                          });
                          _loadNotifications();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppMainColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppMainColors.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? chipColor : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? chipColor : Colors.grey[700],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: chipColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline_rounded;
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.reminder:
        return Icons.notifications_active_rounded;
      case NotificationType.requirement:
        return Icons.assignment_outlined;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.reminder:
        return Colors.purple;
      case NotificationType.requirement:
        return Colors.teal;
      case NotificationType.announcement:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              _buildCustomHeader(),
              
              // Custom Tab Bar
              _buildCustomTabBar(),
              
              // Notification List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadNotifications();
                    await _loadUnreadCount();
                  },
                  color: AppMainColors.primary,
                  child: _buildNotificationList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
              iconSize: 22,
              color: Colors.black87,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                if (_unreadCount > 0)
                  Text(
                    '$_unreadCount thông báo chưa đọc',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          
          // Filter button
          Container(
            decoration: BoxDecoration(
              color: _selectedType != null 
                  ? AppMainColors.primary.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: _selectedType != null
                  ? Border.all(color: AppMainColors.primary, width: 1.5)
                  : null,
            ),
            child: IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: _selectedType != null 
                        ? AppMainColors.primary
                        : Colors.grey[700],
                  ),
                  if (_selectedType != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppMainColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterDialog,
              iconSize: 22,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              tooltip: 'Lọc thông báo',
            ),
          ),
          
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            // Mark all as read button
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!, width: 1.5),
              ),
              child: IconButton(
                icon: const Icon(Icons.done_all_rounded),
                onPressed: _markAllAsRead,
                iconSize: 20,
                color: Colors.green[700],
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                tooltip: 'Đánh dấu tất cả đã đọc',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab(
            index: 0,
            label: 'Tất cả',
            count: _notifications.length,
            icon: Icons.inbox_rounded,
          ),
          const SizedBox(width: 4),
          _buildTab(
            index: 1,
            label: 'Chưa đọc',
            count: _unreadCount,
            icon: Icons.mark_email_unread_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      AppMainColors.primary,
                      AppMainColors.primaryDark,
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppMainColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppMainColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppMainColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_isLoading && _notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppMainColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải thông báo...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedTab == 1
                    ? Icons.mark_email_read_rounded
                    : Icons.notifications_none_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedTab == 1
                  ? 'Không có thông báo chưa đọc'
                  : 'Chưa có thông báo nào',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTab == 1
                  ? 'Tất cả thông báo đã được đọc'
                  : 'Thông báo sẽ hiển thị ở đây',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: AppMainColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final notification = _notifications[index];
        return NotificationItemWidget(
          notification: notification,
          onTap: () async {
            await _service.handleNotificationTap(context, notification);
            
            // Refresh list để update trạng thái đã đọc
            await _loadNotifications();
            await _loadUnreadCount();
          },
        );
      },
    );
  }
}
