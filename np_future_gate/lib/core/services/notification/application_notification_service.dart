import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/repositories/device_token_repository.dart';
import 'package:np_future_gate/core/repositories/notification_repository.dart';
import 'package:np_future_gate/core/services/push_notification_service.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/notification/models/notification_config.dart';

/// Service xử lý gửi notification khi có ứng viên ứng tuyển
class ApplicationNotificationService {
  final NotificationRepository _notificationRepo = NotificationRepository();
  final DeviceTokenRepository _deviceTokenRepo = DeviceTokenRepository();
  final SupabaseService _supabaseService = SupabaseService.instance;

  /// Gửi thông báo đến nhà tuyển dụng khi có ứng viên ứng tuyển
  /// 
  /// [employerId] - ID của nhà tuyển dụng
  /// [jobId] - ID của công việc
  /// [jobTitle] - Tiêu đề công việc
  /// [candidateId] - ID của ứng viên
  /// [candidateName] - Tên ứng viên
  /// [isPartnershipJob] - Có phải partnership job không
  Future<void> notifyNewApplication({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String candidateId,
    required String candidateName,
    bool isPartnershipJob = false,
  }) async {
    try {
      debugPrint('📧 Preparing to send application notification...');
      debugPrint('   Employer: $employerId');
      debugPrint('   Job: $jobTitle ($jobId)');
      debugPrint('   Candidate: $candidateName ($candidateId)');
      debugPrint('   Partnership: $isPartnershipJob');

      // 1. Tạo notification trong database
      final notification = await _notificationRepo.createNotificationToUser(
        userId: employerId,
        title: 'Ứng viên mới ứng tuyển',
        content: '$candidateName đã ứng tuyển vào vị trí "$jobTitle"',
        actionCode: NotificationActionCode.applicationReceived,
        actionData: {
          'jobId': jobId,
          'userId': candidateId,
          'candidateName': candidateName,
          'jobTitle': jobTitle,
          'isPartnershipJob': isPartnershipJob,
        },
        type: NotificationType.info,
      );

      if (notification == null) {
        debugPrint('⚠️ Failed to create notification in database');
        return;
      }

      debugPrint('✅ Notification created in database: ${notification.id}');

      // 2. Lấy danh sách device tokens của employer
      debugPrint('🔍 DEBUG: Querying with userId: $employerId, role: employer');
      
      // Query thử TẤT CẢ employer devices (không filter userId)
      final allEmployerDevices = await _deviceTokenRepo.getActiveDeviceIds(
        role: 'employer',
      );
      debugPrint('📱 DEBUG: All employer devices in DB: ${allEmployerDevices.length}');
      
      // Query theo userId cụ thể
      List<String> deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
        userId: employerId,
        role: 'employer',
      );
      debugPrint('📱 DEBUG: Devices for this employer: ${deviceIds.length}');

      // FALLBACK: Nếu employer không có device, gửi đến current user (để test)
      if (deviceIds.isEmpty) {
        debugPrint('⚠️ No devices found for employer $employerId');
        final currentUserId = _supabaseService.currentUserId;
        
        if (currentUserId != null) {
          debugPrint('🔄 Fallback: Sending to current user instead');
          deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
            userId: currentUserId,
          );
          
          if (deviceIds.isEmpty) {
            debugPrint('ℹ️ Current user also has no active devices');
            return;
          }
          debugPrint('📱 Found ${deviceIds.length} device(s) for current user');
        } else {
          debugPrint('ℹ️ No active devices found and no current user');
          return;
        }
      } else {
        debugPrint('📱 Found ${deviceIds.length} device(s) for employer');
      }

      // 3. Gửi push notification đến nhiều devices cùng lúc (học từ test_page_admin)
      final success = await PushNotificationService.sendNotificationToMultipleDevices(
        deviceTokens: deviceIds,
        title: 'Ứng viên mới ứng tuyển',
        body: '$candidateName đã ứng tuyển vào vị trí "$jobTitle"',
        data: {
          'type': 'application_received',
          'jobId': jobId,
          'candidateId': candidateId,
          'notificationId': notification.id,
        },
      );

      if (success) {
        debugPrint('✅ Push notifications sent to ${deviceIds.length} device(s)');
      } else {
        debugPrint('❌ Failed to send push notifications');
      }
    } catch (e) {
      debugPrint('❌ Error in notifyNewApplication: $e');
      // Không throw để không ảnh hưởng đến flow ứng tuyển chính
    }
  }

  /// Kiểm tra xem có nên gửi notification không dựa trên settings
  /// 
  /// Gửi thông báo khi đơn ứng tuyển được duyệt
  Future<void> notifyApplicationApproved({
    required String candidateId,
    required String jobId,
    required String jobTitle,
    required String employerName,
  }) async {
    try {
      // Tạo notification trong database
      await _notificationRepo.createNotificationToUser(
        userId: candidateId,
        title: 'Đơn ứng tuyển được chấp nhận',
        content: 'Đơn ứng tuyển của bạn vào vị trí "$jobTitle" đã được chấp nhận',
        actionCode: NotificationActionCode.applicationApproved,
        actionData: {
          'jobId': jobId,
          'jobTitle': jobTitle,
          'employerName': employerName,
        },
        type: NotificationType.success,
      );

      // Lấy device tokens và gửi push notification (đơn giản hơn)
      final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
        userId: candidateId,
        role: 'candidate',
      );
      
      if (deviceIds.isEmpty) {
        debugPrint('ℹ️ No active devices found for candidate');
        return;
      }

      await PushNotificationService.sendNotificationToMultipleDevices(
        deviceTokens: deviceIds,
        title: 'Đơn ứng tuyển được chấp nhận',
        body: 'Đơn ứng tuyển của bạn vào vị trí "$jobTitle" đã được chấp nhận',
        data: {
          'type': 'application_approved',
          'jobId': jobId,
        },
      );
      
      debugPrint('✅ Push notifications sent to ${deviceIds.length} candidate device(s)');
    } catch (e) {
      debugPrint('❌ Error in notifyApplicationApproved: $e');
    }
  }

  /// Gửi thông báo khi đơn ứng tuyển bị từ chối
  Future<void> notifyApplicationRejected({
    required String candidateId,
    required String jobId,
    required String jobTitle,
    required String employerName,
  }) async {
    try {
      // Tạo notification trong database
      await _notificationRepo.createNotificationToUser(
        userId: candidateId,
        title: 'Đơn ứng tuyển bị từ chối',
        content: 'Rất tiếc, đơn ứng tuyển của bạn vào vị trí "$jobTitle" đã không được chấp nhận',
        actionCode: NotificationActionCode.applicationRejected,
        actionData: {
          'jobId': jobId,
          'jobTitle': jobTitle,
          'employerName': employerName,
        },
        type: NotificationType.warning,
      );

      // Lấy device tokens và gửi push notification
      final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
        userId: candidateId,
        role: 'candidate',
      );
      
      if (deviceIds.isEmpty) {
        debugPrint('ℹ️ No active devices found for candidate');
        return;
      }

      await PushNotificationService.sendNotificationToMultipleDevices(
        deviceTokens: deviceIds,
        title: 'Đơn ứng tuyển bị từ chối',
        body: 'Rất tiếc, đơn ứng tuyển của bạn vào vị trí "$jobTitle" đã không được chấp nhận',
        data: {
          'type': 'application_rejected',
          'jobId': jobId,
        },
      );
      
      debugPrint('✅ Push notifications sent to ${deviceIds.length} candidate device(s)');
    } catch (e) {
      debugPrint('❌ Error in notifyApplicationRejected: $e');
    }
  }
}
