# Application Status Notification Guide

## Tổng quan

Hệ thống thông báo tự động khi nhà tuyển dụng chấp nhận hoặc từ chối đơn ứng tuyển. Khi ứng viên nhấn vào thông báo, app sẽ tự động chuyển đến trang chi tiết công việc.

## Luồng hoạt động

### 1. Nhà tuyển dụng cập nhật trạng thái đơn ứng tuyển
**Màn hình:** `job_applicants_screen.dart`

```dart
// Trong _updateStatus() method
if (newStatus.toLowerCase() == 'accepted') {
  // Gửi thông báo chấp nhận
  await _notificationService.notifyApplicationApproved(
    candidateId: userId,
    jobId: widget.jobId,
    jobTitle: _jobTitle ?? 'Công việc',
    employerName: employerName,
  );
} else if (newStatus.toLowerCase() == 'rejected') {
  // Gửi thông báo từ chối
  await _notificationService.notifyApplicationRejected(
    candidateId: userId,
    jobId: widget.jobId,
    jobTitle: _jobTitle ?? 'Công việc',
    employerName: employerName,
  );
}
```

### 2. ApplicationNotificationService xử lý gửi thông báo
**File:** `application_notification_service.dart`

#### Thông báo chấp nhận
```dart
Future<void> notifyApplicationApproved({
  required String candidateId,
  required String jobId,
  required String jobTitle,
  required String employerName,
}) async {
  // 1. Tạo notification trong database
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

  // 2. Lấy device tokens
  final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
    userId: candidateId,
    role: 'candidate',
  );
  
  // 3. Gửi push notification
  await PushNotificationService.sendNotificationToMultipleDevices(
    deviceTokens: deviceIds,
    title: 'Đơn ứng tuyển được chấp nhận',
    body: 'Đơn ứng tuyển của bạn vào vị trí "$jobTitle" đã được chấp nhận',
    data: {
      'type': 'application_approved',
      'jobId': jobId,
    },
  );
}
```

#### Thông báo từ chối
```dart
Future<void> notifyApplicationRejected({
  required String candidateId,
  required String jobId,
  required String jobTitle,
  required String employerName,
}) async {
  // Tương tự như approved nhưng với:
  // - Title: 'Đơn ứng tuyển bị từ chối'
  // - Content: 'Rất tiếc, đơn ứng tuyển của bạn...'
  // - ActionCode: NotificationActionCode.applicationRejected
  // - Type: NotificationType.warning
}
```

### 3. Ứng viên nhấn vào thông báo
**Luồng:**
1. FCMService nhận sự kiện tap
2. Parse notification data
3. Gọi NotificationService.handleNotificationTap()
4. Lookup notification config trong `notification_config.dart`
5. Extract route params (jobId, userId, isApproved)
6. Gọi onNavigate callback

### 4. Navigation Setup xử lý điều hướng
**File:** `notification_navigation_setup.dart`

```dart
case NotificationActionCode.applicationApproved:
case NotificationActionCode.applicationRejected:
  final jobId = params['jobId'] as String?;
  final userId = params['userId'] as String?;
  final isApproved = params['isApproved'] as bool?;
  
  if (jobId != null) {
    await applicationStatusHandler.navigateToJobDetail(
      context: context,
      jobId: jobId,
      userId: userId,
      isApproved: isApproved,
    );
  }
  break;
```

### 5. ApplicationStatusHandler xử lý navigation
**File:** `notification/actions/application_status_handler.dart`

```dart
Future<void> navigateToJobDetail({
  required BuildContext context,
  required String jobId,
  String? userId,
  bool? isApproved,
}) async {
  // 1. Show loading dialog
  showDialog(...);
  
  // 2. Try loading regular job first
  JobModel? job = await _jobRepository.getJobById(jobId);
  
  // 3. Fallback to partnership job
  if (job == null) {
    job = await _jobRepository.getPartnershipJobById(jobId);
  }
  
  // 4. Navigate to JobDetailScreen
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => JobDetailScreen(job: job!),
    ),
  );
}
```

## Các file đã thay đổi

### 1. application_notification_service.dart
- ✅ Thêm method `notifyApplicationApproved()`
- ✅ Thêm method `notifyApplicationRejected()`

### 2. notification/actions/application_status_handler.dart (MỚI)
- ✅ Handler mới để xử lý navigation khi nhấn thông báo
- ✅ Tự động detect loại job (regular vs partnership)
- ✅ Navigate đến JobDetailScreen

### 3. notification/actions/actions.dart
- ✅ Export application_status_handler.dart

### 4. notification_navigation_setup.dart
- ✅ Import ApplicationStatusHandler
- ✅ Thêm case cho applicationApproved và applicationRejected
- ✅ Gọi handler.navigateToJobDetail()

### 5. notification_config.dart
- ✅ Cập nhật extractRouteParams cho applicationApproved
- ✅ Cập nhật extractRouteParams cho applicationRejected
- ✅ Support cả camelCase và snake_case

### 6. job_applicants_screen.dart
- ✅ Import ApplicationNotificationService
- ✅ Initialize _notificationService
- ✅ Gọi notifyApplicationApproved() khi accept
- ✅ Gọi notifyApplicationRejected() khi reject

## Testing

### Kiểm tra đầy đủ:
1. ✅ Nhà tuyển dụng chấp nhận đơn → Ứng viên nhận thông báo
2. ✅ Nhà tuyển dụng từ chối đơn → Ứng viên nhận thông báo
3. ✅ Nhấn vào thông báo → Mở app và chuyển đến trang chi tiết công việc
4. ✅ Hoạt động với cả regular job và partnership job
5. ✅ Debug logs hiển thị đầy đủ luồng

### Debug logs mẫu:
```
✅ Sent application approved notification to candidate abc123
📱 FCM notification received: application_approved
🔔 Notification tap detected
🎯 Action handler: applicationApproved
📍 Navigating to job detail: job123
✅ Navigation completed successfully
```

## Lưu ý kỹ thuật

### Action Data Structure
```json
{
  "jobId": "job-uuid",
  "jobTitle": "Tên công việc",
  "employerName": "Tên nhà tuyển dụng"
}
```

### Route Params Structure
```dart
{
  'jobId': 'job-uuid',
  'userId': 'candidate-uuid',  // Optional
  'isApproved': true/false      // Optional
}
```

### Notification Types
- **applicationApproved**: NotificationType.success (màu xanh)
- **applicationRejected**: NotificationType.warning (màu cam)

### Error Handling
- Loading dialogs hiển thị trong quá trình load
- Error dialogs khi không tìm thấy job
- Try/catch bao quanh tất cả async operations
- Comprehensive debug logging

## Tích hợp với hệ thống hiện có

### RLS Status
- ⚠️ RLS đã disabled trên tất cả bảng notification (development mode)
- ⚠️ Cần enable lại RLS với proper policies khi production

### Device Token Fallback
- Nếu candidate không có device tokens → Không gửi push notification
- Database notification vẫn được tạo
- Candidate có thể xem trong notifications_screen

### Email Integration
- Email từ chối vẫn được gửi song song với notification
- Không phụ thuộc vào nhau

## Next Steps (Optional Enhancements)

### Có thể thêm sau:
1. **Interview Scheduled Notification** - Thông báo khi có lịch phỏng vấn
2. **Notification Settings** - Cho phép user tắt/bật từng loại thông báo
3. **In-app Badge Count** - Hiển thị số thông báo chưa đọc trên icon
4. **Rich Notifications** - Thêm ảnh công ty, logo vào notification
5. **Action Buttons** - Thêm buttons trực tiếp trên notification (View Job, Dismiss)

## Tài liệu tham khảo
- APPLICATION_NOTIFICATION_GUIDE.md - Hướng dẫn notification system tổng quát
- PUSH_NOTIFICATION_BEHAVIOR.md - Chi tiết về push notification behavior
