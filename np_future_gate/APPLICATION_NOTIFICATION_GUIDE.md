# Application Notification System

## Tổng quan

Hệ thống tự động gửi thông báo đến thiết bị của nhà tuyển dụng khi có ứng viên ứng tuyển vào công việc.

## Luồng hoạt động

```
Ứng viên ứng tuyển
    ↓
1. Lưu đơn ứng tuyển vào database
    ↓
2. Tạo notification record trong bảng notifications
    ↓
3. Lấy danh sách device tokens của employer
    ↓
4. Kiểm tra notification_settings cho từng device
    ↓
5. Gửi push notification đến devices được phép
    ↓
6. Employer nhận thông báo trên thiết bị
```

## Điều kiện gửi notification

### 1. Kiểm tra `notification_settings` (JSONB)

Mỗi device token có trường `notification_settings` với cấu trúc:

```json
{
  "enabled": true,                      // Bật/tắt tổng thể
  "application_notifications": true,    // Bật/tắt thông báo ứng tuyển
  "notification_types": {
    "info": true                        // Bật/tắt loại notification info
  }
}
```

### 2. Logic kiểm tra (trong `_shouldSendNotification`)

```dart
// Điều kiện 1: enabled phải = true
if (!settings['enabled']) return false;

// Điều kiện 2: application_notifications phải = true
if (!settings['application_notifications']) return false;

// Điều kiện 3: notification_types.info phải = true
if (!settings['notification_types']['info']) return false;

// ✅ Tất cả điều kiện đều OK → Gửi notification
return true;
```

### 3. Mặc định

Nếu device không có `notification_settings` hoặc giá trị NULL → **Cho phép gửi** (default = true)

## Implementation

### File: `application_notification_service.dart`

#### Method chính: `notifyNewApplication()`

```dart
await _appNotificationService.notifyNewApplication(
  employerId: 'uuid',
  jobId: 'uuid',
  jobTitle: 'Senior Developer',
  candidateId: 'uuid',
  candidateName: 'Nguyễn Văn A',
  isPartnershipJob: false,
);
```

**Các bước thực hiện:**

1. **Tạo notification trong database**
   - Bảng: `notifications`
   - Action code: `application_received`
   - Type: `info`
   - Recipient: employerId

2. **Lấy device tokens**
   - Query: `device_tokens` WHERE user_id = employerId AND role = 'employer' AND is_active = true
   - SELECT: device_id, notification_settings

3. **Kiểm tra settings cho từng device**
   - Gọi `_shouldSendNotification(settings, 'application')`
   - Skip device nếu settings không cho phép

4. **Gửi push notification**
   - Sử dụng `PushNotificationService.sendNotificationToDevice()`
   - Title: "Ứng viên mới ứng tuyển"
   - Body: "{candidateName} đã ứng tuyển vào vị trí {jobTitle}"
   - Data payload: jobId, candidateId, notificationId, type

5. **Logging**
   - Log số lượng devices tìm thấy
   - Log số lượng devices gửi thành công
   - Log errors (không throw để không ảnh hưởng flow chính)

## Integration

### 1. Job Detail Screen (Regular Job)

```dart
// lib/screens/candidate/job_detail_screen.dart

Future<void> _applyForJob(String cvId) async {
  // 1. Ứng tuyển
  await _jobRepository.applyForJob(jobId, userId, cvId);
  
  // 2. Gửi notification (background, không block UI)
  _appNotificationService.notifyNewApplication(
    employerId: job.creatorId!,
    jobId: job.id!,
    jobTitle: job.metadata.title,
    candidateId: userId!,
    candidateName: candidateName,
    isPartnershipJob: false,
  ).catchError((e) {
    print('⚠️ Failed to send notification: $e');
    // Không hiển thị lỗi cho user
  });
}
```

### 2. Partnership Job Detail Screen

```dart
// lib/screens/candidate/partnership_job_detail_screen.dart

Future<void> _applyForJob(String cvId) async {
  // 1. Ứng tuyển partnership job
  await _jobRepository.applyForPartnershipJob(jobId, userId, cvId);
  
  // 2. Gửi notification với flag isPartnershipJob = true
  _appNotificationService.notifyNewApplication(
    employerId: job.creatorId!,
    jobId: job.id!,
    jobTitle: job.metadata.title,
    candidateId: userId!,
    candidateName: candidateName,
    isPartnershipJob: true, // ⚠️ Đánh dấu partnership job
  ).catchError((e) {
    print('⚠️ Failed to send notification: $e');
  });
}
```

## Notification Data Payload

Push notification chứa data để xử lý khi user tap:

```json
{
  "type": "application_received",
  "jobId": "uuid",
  "candidateId": "uuid", 
  "notificationId": "uuid"
}
```

Khi employer tap vào notification:
1. App mở lên
2. Navigate đến NotificationsScreen (theo config trong `notification_navigation_setup.dart`)
3. Từ đó có thể xem chi tiết ứng viên

## Database Tables

### 1. `notifications`
```sql
id, title, content, action_code, action_data, recipient_ids, type, created_at
```

### 2. `device_tokens`
```sql
id, device_id, user_id, role, notification_settings, is_active
```

### 3. `notification_reads`
```sql
id, notification_id, user_id, read_at
```

## Testing

### Test Case 1: Settings enabled (nên gửi)
```json
{
  "enabled": true,
  "application_notifications": true,
  "notification_types": {"info": true}
}
```
✅ Expected: Notification được gửi

### Test Case 2: Settings disabled globally (không gửi)
```json
{
  "enabled": false,
  "application_notifications": true,
  "notification_types": {"info": true}
}
```
❌ Expected: Notification bị skip

### Test Case 3: Application notifications disabled (không gửi)
```json
{
  "enabled": true,
  "application_notifications": false,
  "notification_types": {"info": true}
}
```
❌ Expected: Notification bị skip

### Test Case 4: Info type disabled (không gửi)
```json
{
  "enabled": true,
  "application_notifications": true,
  "notification_types": {"info": false}
}
```
❌ Expected: Notification bị skip

### Test Case 5: No settings (nên gửi)
```
notification_settings = NULL
```
✅ Expected: Notification được gửi (mặc định cho phép)

## Logs

Khi gửi notification, service sẽ log:

```
📧 Preparing to send application notification...
   Employer: <employerId>
   Job: <jobTitle> (<jobId>)
   Candidate: <candidateName> (<candidateId>)
   Partnership: false
✅ Notification created in database: <notificationId>
📱 Found 2 device(s) for employer
⏭️ Skipping device <deviceId> (disabled by settings)
✅ Push notification sent to device
📊 Summary: Sent to 1/2 devices
```

## Error Handling

- Tất cả errors đều được log nhưng **KHÔNG throw**
- Lý do: Notification là tính năng phụ, không được làm fail flow ứng tuyển chính
- Sử dụng `.catchError()` khi gọi từ UI

## Future Enhancements

1. **Batch notification**: Gửi nhiều thông báo cùng lúc nếu nhiều người ứng tuyển
2. **Notification grouping**: Gộp "10 người đã ứng tuyển" thay vì 10 notifications riêng
3. **Priority levels**: Thông báo ứng tuyển có thể có priority cao hơn
4. **Rich notifications**: Thêm ảnh đại diện, action buttons
5. **Analytics**: Track notification delivery rate, open rate
