import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/notification_model.dart';
import '../models/notification_config.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/services/notification/notification_service.dart';
import '../widgets/notification_item_widget.dart';

/// Màn hình hiển thị danh sách thông báo
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationRepository _repository = NotificationRepository();
  final NotificationService _service = NotificationService();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  
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
      print('Error loading more notifications: $e');
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
      print('Error loading unread count: $e');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc thông báo'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loại thông báo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedType == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedType = null;
                        });
                      },
                    ),
                    ...NotificationType.values.map((type) {
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _notifications.clear();
                _currentPage = 0;
                _hasMore = true;
              });
              _loadNotifications();
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tất cả (${_notifications.length})'),
            Tab(text: 'Chưa đọc ($_unreadCount)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc',
          ),
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadNotifications();
          await _loadUnreadCount();
        },
        child: _buildNotificationList(),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có thông báo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
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
