import 'package:flutter/material.dart';
import 'models/notification_config.dart';
import '../core/services/notification/status_notification_service.dart';
import 'actions/actions.dart';

/// File này chứa cấu hình navigation cho notification system
/// 
/// Cách sử dụng:
/// 1. Import các screen cần thiết
/// 2. Gọi setupNotificationNavigation() trong main() hoặc app initialization
/// 3. Implement logic navigate cho từng action code

/// Setup navigation handler cho notification system
/// Gọi hàm này trong main() hoặc khi khởi tạo app
void setupNotificationNavigation() {
  StatusNotificationService.onNavigate = _handleNavigate;
}

/// Handler chính để navigate đến các screen
Future<void> _handleNavigate(
  BuildContext context,
  NotificationActionCode actionCode,
  Map<String, dynamic> params,
) async {
  if (!context.mounted) return;

  // Initialize action handler
  final applicationReceivedHandler = ApplicationReceivedHandler();
  final applicationStatusHandler = ApplicationStatusHandler();

  // TODO: Import các screen cần thiết ở đầu file
  // import '../job/screens/job_detail_screen.dart';
  // import '../interview/screens/interview_detail_screen.dart';
  // etc...

  try {
    switch (actionCode) {
      // === JOB RELATED ===
      case NotificationActionCode.jobDetail:
      case NotificationActionCode.jobApproved:
      case NotificationActionCode.jobRejected:
      case NotificationActionCode.newJobPosted:
      case NotificationActionCode.jobExpiring:
        final jobId = params['jobId'] as String?;
        if (jobId != null) {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => JobDetailScreen(jobId: jobId),
          //   ),
          // );
          print('Navigate to JobDetailScreen with jobId: $jobId');
        }
        break;

      // === APPLICATION RELATED ===
      case NotificationActionCode.applicationReceived:
        final jobId = params['jobId'] as String?;
        final userId = params['userId'] as String?; // candidateId who applied
        
        if (jobId != null) {
          // Use action handler to navigate with auto-detection of job type
          await applicationReceivedHandler.navigateToJobApplicants(
            context: context,
            jobId: jobId,
            userId: userId, // Optional - for future scroll to specific applicant
          );
        } else {
          print('Error: Missing jobId in applicationReceived action');
        }
        break;

      case NotificationActionCode.applicationApproved:
      case NotificationActionCode.applicationRejected:
        final jobId = params['jobId'] as String?;
        final userId = params['userId'] as String?;
        final isApproved = params['isApproved'] as bool?;
        
        if (jobId != null) {
          // Use action handler to navigate to job detail
          await applicationStatusHandler.navigateToJobDetail(
            context: context,
            jobId: jobId,
            userId: userId,
            isApproved: isApproved,
          );
        } else {
          print('Error: Missing jobId in application status action');
        }
        break;

      // === INTERVIEW RELATED ===
      case NotificationActionCode.interviewScheduled:
      case NotificationActionCode.interviewUpdated:
      case NotificationActionCode.interviewCanceled:
      case NotificationActionCode.interviewReminder:
      case NotificationActionCode.interviewEvaluated:
        final interviewId = params['interviewId'] as String?;
        // final jobId = params['jobId'] as String?;
        if (interviewId != null) {
          debugPrint('Navigate to InterviewDetailScreen with interviewId: $interviewId');
        }
        break;

      // === PARTNERSHIP RELATED ===
      case NotificationActionCode.partnershipRequest:
      case NotificationActionCode.partnershipApproved:
      case NotificationActionCode.partnershipRejected:
      case NotificationActionCode.partnershipJobPosted:
        final partnershipId = params['partnershipId'] as String?;
        if (partnershipId != null) {
          debugPrint('Navigate to PartnershipDetailScreen with partnershipId: $partnershipId');
        }
        break;

      // === PROFILE RELATED ===
      case NotificationActionCode.profileViewed:
      case NotificationActionCode.profileFollowed:
        final userId = params['userId'] as String?;
        if (userId != null) {
          debugPrint('Navigate to ProfileScreen with userId: $userId');
        }
        break;

      // === MESSAGE RELATED ===
      case NotificationActionCode.newMessage:
      case NotificationActionCode.messageReply:
        final chatId = params['chatId'] as String?;
        // final senderId = params['userId'] as String?;
        if (chatId != null) {
          debugPrint('Navigate to ChatScreen with chatId: $chatId');
        }
        break;

      // === ADMIN RELATED ===
      case NotificationActionCode.adminReview:
      case NotificationActionCode.adminApproved:
      case NotificationActionCode.adminRejected:
        debugPrint('Navigate to Admin screen');
        break;

      // === SUBSCRIPTION RELATED ===
      case NotificationActionCode.subscriptionExpiring:
        debugPrint('Navigate to SubscriptionScreen');
        break;

      // === DEFAULT ===
      default:
        debugPrint('No navigation handler for: ${actionCode.code}');
    }
  } catch (e) {
    debugPrint('Error in notification navigation: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }
}
