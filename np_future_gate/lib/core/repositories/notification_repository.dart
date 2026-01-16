import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../../notification/models/notification_config.dart';

/// Repository xử lý các thao tác với database cho notifications
class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Lấy danh sách thông báo của user (có phân trang)
  /// 
  /// [userId] - ID của user
  /// [limit] - Số lượng thông báo trả về (mặc định 20)
  /// [offset] - Vị trí bắt đầu (để phân trang)
  /// [type] - Lọc theo loại thông báo
  /// [isRead] - Lọc theo trạng thái đã đọc/chưa đọc
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
    NotificationType? type,
    bool? isRead,
  }) async {
    try {
      // Query notifications
      var query = _supabase
          .from('notifications')
          .select('''
            *,
            notification_reads!left(read_at)
          ''')
          .or('recipient_ids.eq.all,recipient_ids.eq.$userId,recipient_ids.like.%$userId%')
          .eq('is_active', true);

      // Lọc theo type nếu có
      if (type != null) {
        query = query.eq('type', type.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final notifications = (response as List)
          .map((json) {
            // Kiểm tra xem user đã đọc chưa
            final reads = json['notification_reads'] as List?;
            final isReadByUser = reads?.isNotEmpty ?? false;
            final readAt = isReadByUser && reads!.isNotEmpty
                ? reads.first['read_at']
                : null;

            return NotificationModel.fromJson({
              ...json,
              'is_read': isReadByUser,
              'read_at': readAt,
            });
          })
          .where((n) => !n.isExpired) // Lọc bỏ thông báo hết hạn
          .toList();

      // Lọc theo isRead nếu có
      if (isRead != null) {
        return notifications.where((n) => n.isRead == isRead).toList();
      }

      return notifications;
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  /// Lấy danh sách thông báo chưa đọc (dùng RPC function)
  Future<List<NotificationModel>> getUnreadNotifications({
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_unread_notifications',
        params: {'user_uuid': userId},
      );

      return (response as List)
          .map((json) => NotificationModel.fromJson({
                ...json,
                'is_read': false,
              }))
          .toList();
    } catch (e) {
      print('Error getting unread notifications: $e');
      rethrow;
    }
  }

  /// Đếm số thông báo chưa đọc
  Future<int> countUnreadNotifications({
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'count_unread_notifications',
        params: {'user_uuid': userId},
      );
      return response as int;
    } catch (e) {
      print('Error counting unread notifications: $e');
      return 0;
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _supabase.from('notification_reads').insert({
        'notification_id': notificationId,
        'user_id': userId,
      });
    } catch (e) {
      // Ignore nếu đã đọc rồi (unique constraint)
      if (!e.toString().contains('duplicate')) {
        print('Error marking notification as read: $e');
      }
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead({
    required String userId,
  }) async {
    try {
      // Lấy tất cả notification IDs chưa đọc
      final unreadNotifications = await getUnreadNotifications(userId: userId);
      
      if (unreadNotifications.isEmpty) return;

      // Insert bulk vào notification_reads
      final reads = unreadNotifications
          .map((n) => {
                'notification_id': n.id,
                'user_id': userId,
              })
          .toList();

      await _supabase.from('notification_reads').insert(reads);
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết 1 thông báo
  Future<NotificationModel?> getNotificationById({
    required String notificationId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            notification_reads!left(read_at)
          ''')
          .eq('id', notificationId)
          .single();

      final reads = response['notification_reads'] as List?;
      final isReadByUser = reads?.any((r) => r['user_id'] == userId) ?? false;
      final readAt = isReadByUser
          ? reads?.firstWhere((r) => r['user_id'] == userId)['read_at']
          : null;

      return NotificationModel.fromJson({
        ...response,
        'is_read': isReadByUser,
        'read_at': readAt,
      });
    } catch (e) {
      print('Error getting notification by id: $e');
      return null;
    }
  }

  /// Tạo thông báo mới (chỉ dành cho admin/system)
  Future<NotificationModel?> createNotification({
    required CreateNotificationRequest request,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert(request.toJson())
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  /// Tạo thông báo gửi đến tất cả
  Future<NotificationModel?> createNotificationToAll({
    required String title,
    required String content,
    NotificationActionCode? actionCode,
    Map<String, dynamic>? actionData,
    NotificationType type = NotificationType.announcement,
  }) async {
    return createNotification(
      request: CreateNotificationRequest(
        recipientIds: 'all',
        title: title,
        content: content,
        actionCode: actionCode,
        actionData: actionData,
        type: type,
      ),
    );
  }

  /// Tạo thông báo gửi đến 1 user
  Future<NotificationModel?> createNotificationToUser({
    required String userId,
    required String title,
    required String content,
    NotificationActionCode? actionCode,
    Map<String, dynamic>? actionData,
    NotificationType type = NotificationType.info,
  }) async {
    return createNotification(
      request: CreateNotificationRequest(
        recipientIds: userId,
        title: title,
        content: content,
        actionCode: actionCode,
        actionData: actionData,
        type: type,
      ),
    );
  }

  /// Tạo thông báo gửi đến nhiều users
  Future<NotificationModel?> createNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String content,
    NotificationActionCode? actionCode,
    Map<String, dynamic>? actionData,
    NotificationType type = NotificationType.info,
  }) async {
    // Convert list to JSON array string
    final recipientIds = '["${userIds.join('","')}"]';
    
    return createNotification(
      request: CreateNotificationRequest(
        recipientIds: recipientIds,
        title: title,
        content: content,
        actionCode: actionCode,
        actionData: actionData,
        type: type,
      ),
    );
  }

  /// Xóa thông báo hết hạn (gọi function từ database)
  Future<void> deleteExpiredNotifications() async {
    try {
      await _supabase.rpc('delete_expired_notifications');
    } catch (e) {
      print('Error deleting expired notifications: $e');
    }
  }

  /// Stream để realtime updates
  Stream<List<NotificationModel>> watchNotifications({
    required String userId,
  }) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => (data as List)
            .map((json) => NotificationModel.fromJson(json))
            .where((n) => !n.isExpired)
            .where((n) =>
                n.recipientIds == 'all' ||
                n.recipientIds == userId ||
                n.recipientIds.contains(userId))
            .toList());
  }
}
