# Application Notification Testing Guide

## Vấn đề và Giải pháp

### ❌ Vấn đề ban đầu
```
📱 All devices for user: []
ℹ️ No active devices found for employer
```

**Nguyên nhân:** Employer chưa đăng nhập trên thiết bị nào → không có device token trong database.

### ✅ Giải pháp đã áp dụng

Code đã được cập nhật học từ `test_page_admin.dart` với các cải tiến:

1. **Sử dụng `DeviceTokenRepository.getActiveDeviceIds()`** thay vì query trực tiếp
2. **Fallback đến current user** nếu employer không có device
3. **Gửi đến multiple devices cùng lúc** với `sendNotificationToMultipleDevices()`
4. **Đơn giản hóa logic** bỏ notification_settings validation (sẽ thêm sau)

---

## 📚 Cách hoạt động (học từ test_page_admin.dart)

### 1. Lấy Device Tokens

**❌ Cách cũ (phức tạp):**
```dart
final response = await _supabase
    .from('device_tokens')
    .select('device_id, notification_settings, user_id, role, is_active')
    .eq('user_id', employerId)
    .eq('role', 'employer')
    .eq('is_active', true);
```

**✅ Cách mới (đơn giản):**
```dart
final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
  userId: employerId,
  role: 'employer',
);
```

### 2. Fallback Logic

```dart
if (deviceIds.isEmpty) {
  print('⚠️ No devices found for employer');
  final currentUserId = _supabaseService.currentUserId;
  
  if (currentUserId != null) {
    print('🔄 Fallback: Sending to current user instead');
    deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
      userId: currentUserId,
    );
  }
}
```

**Lợi ích:**
- ✅ Test được ngay khi employer chưa có device
- ✅ Notification vẫn được gửi (đến admin/current user)
- ✅ Dễ debug và kiểm tra flow

### 3. Gửi đến Multiple Devices

**❌ Cách cũ (loop từng device):**
```dart
for (var device in devices) {
  final deviceId = device['device_id'];
  await PushNotificationService.sendNotificationToDevice(
    deviceToken: deviceId,
    // ...
  );
}
```

**✅ Cách mới (batch send):**
```dart
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
```

**Lợi ích:**
- ⚡ Nhanh hơn (1 request thay vì N requests)
- 🔥 FCM Multicast tối ưu
- 📊 Dễ track success/failure

---

## 🧪 Cách Test

### Step 1: Chạy Migration SQL
```sql
-- Mở Supabase Dashboard → SQL Editor
-- Chạy file: database/migrations/FIX_notifications_expires_at_default.sql
```

### Step 2: Hot Restart App
```bash
# Terminal hoặc trong VS Code
r  # hot restart
```

### Step 3: Test Application Flow

**Scenario A: Test với Employer có Device**
1. Đăng nhập bằng employer account `td2` trên 1 thiết bị
2. Đăng nhập bằng candidate `ts1` trên thiết bị khác
3. Apply vào job của employer `td2`
4. ✅ Notification sẽ đến thiết bị của employer `td2`

**Scenario B: Test với Employer KHÔNG có Device (Fallback)**
1. Đăng nhập bằng admin account trên thiết bị
2. Đăng nhập bằng candidate `ts1` trên thiết bị khác (hoặc cùng thiết bị)
3. Apply vào job của employer `td2` (chưa đăng nhập trên thiết bị nào)
4. ✅ Notification sẽ đến thiết bị của admin (fallback)

### Step 4: Xem Logs

```
I/flutter: 📧 Preparing to send application notification...
I/flutter:    Employer: 2e2c41e6-d4c8-4a73-8209-725925187fce
I/flutter: ✅ Notification created in database: xxx
I/flutter: ⚠️ No devices found for employer
I/flutter: 🔄 Fallback: Sending to current user instead
I/flutter: 📱 Found 1 device(s) for current user
I/flutter: ✅ Push notifications sent to 1 device(s)
```

---

## 📱 Test với test_page_admin.dart

### Cách sử dụng Test Page

1. **Mở Admin Home** → Navigate đến **Test Page Admin**

2. **Chọn Push Notifications Card**

3. **Chọn loại test:**
   - **Gửi cho chính tôi** - Test device của bạn
   - **Gửi cho TẤT CẢ users** - Broadcast đến mọi người
   - **Gửi theo role** - Test từng role cụ thể

### Các Method quan trọng

```dart
// 1. Gửi cho current user
final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
  userId: userId
);

// 2. Gửi cho TẤT CẢ (không filter userId)
final allDeviceIds = await _deviceTokenRepo.getActiveDeviceIds();

// 3. Gửi theo role
final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
  role: 'employer'
);

// 4. Gửi notification
await PushNotificationService.sendNotificationToMultipleDevices(
  deviceTokens: deviceIds,
  title: 'Test Title',
  body: 'Test Body',
  data: {'type': 'test'},
);
```

---

## 🔧 Code Changes Summary

### application_notification_service.dart

**Thay đổi chính:**
1. ✅ Import `SupabaseService` để lấy `currentUserId`
2. ✅ Dùng `DeviceTokenRepository.getActiveDeviceIds()` thay vì query trực tiếp
3. ✅ Thêm fallback logic đến current user
4. ✅ Dùng `sendNotificationToMultipleDevices()` thay vì loop
5. ✅ Xóa method `_getEmployerDeviceTokens()` và `_getCandidateDeviceTokens()`
6. ✅ Đơn giản hóa `notifyApplicationApproved()`

**Trước đây:**
- Query phức tạp với notification_settings
- Loop từng device
- Không có fallback
- Debug logs dài dòng

**Bây giờ:**
- Repository method đơn giản
- Batch send multiple devices
- Fallback đến current user
- Clean và dễ maintain

---

## ⚠️ Lưu ý

### 1. Notification Settings (tạm thời disabled)
Code hiện tại **KHÔNG check** `notification_settings` JSONB để đơn giản hóa testing.

Sẽ thêm lại sau khi test thành công:
```dart
// TODO: Add back notification settings validation
if (!_shouldSendNotification(settings, 'application')) {
  continue;
}
```

### 2. Expires At
Phải chạy migration SQL để fix `expires_at` default value:
```sql
ALTER TABLE notifications 
ALTER COLUMN expires_at SET DEFAULT (now() + interval '30 days');
```

### 3. Device Token Expiry
Device tokens có thể expire sau 30 ngày. Kiểm tra:
```sql
SELECT * FROM device_tokens 
WHERE user_id = 'xxx' 
AND (expires_at IS NULL OR expires_at > now());
```

---

## 📊 Expected Behavior

### ✅ Success Case
```
📧 Preparing to send application notification...
✅ Notification created in database: xxx
📱 Found 2 device(s) for employer
✅ Push notifications sent to 2 device(s)
```

### ⚠️ Fallback Case
```
📧 Preparing to send application notification...
✅ Notification created in database: xxx
⚠️ No devices found for employer
🔄 Fallback: Sending to current user instead
📱 Found 1 device(s) for current user
✅ Push notifications sent to 1 device(s)
```

### ❌ No Devices Case
```
📧 Preparing to send application notification...
✅ Notification created in database: xxx
⚠️ No devices found for employer
ℹ️ Current user also has no active devices
```

---

## 🎯 Next Steps

1. ✅ **Hot restart** và test lại application flow
2. ✅ Verify notification đến thiết bị (employer hoặc current user)
3. ✅ Check notification trong database có `expires_at` đúng
4. 🔜 Thêm lại notification_settings validation (optional)
5. 🔜 Test với nhiều devices cùng lúc
6. 🔜 Test với different roles (candidate, school, admin)

---

## 🐛 Troubleshooting

### Không nhận được notification?
1. Check device token có trong database không
2. Check `is_active = true`
3. Check `expires_at > now()`
4. Check FCM token còn valid không
5. Xem logs có error không

### Device token bị NULL?
```dart
// FCMService phải save token khi login
await FCMService.saveDeviceToken(role: 'employer');
```

### Muốn test mà không có device?
→ Dùng **test_page_admin.dart** để gửi test notification!

---

## 📖 References

- **test_page_admin.dart** - Example của batch sending và device management
- **DeviceTokenRepository** - Centralized device token queries
- **PushNotificationService** - FCM integration với multicast support
- **APPLICATION_NOTIFICATION_GUIDE.md** - Architecture overview
