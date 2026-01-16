# Push Notification Behavior

## Hành vi khi nhận notification

### 1. App đang mở (Foreground)
- Hiển thị local notification trên thanh notification
- User có thể tap vào để xem
- App vẫn ở màn hình hiện tại

### 2. App đang chạy nền (Background)
- Notification hiển thị trên thanh notification
- **Tap vào notification → App mở lên trang đầu (home page)**
- Flow: Splash Screen → Home Page theo role

### 3. App đã đóng hoàn toàn (Terminated)
- Notification hiển thị trên thanh notification  
- **Tap vào notification → App khởi động và mở trang đầu**
- Flow: Splash Screen → Home Page theo role

## Cấu hình

### FCM Service (`lib/core/services/fcm_service.dart`)

```dart
// Handler khi app đang chạy nền và user tap notification
FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

// Handler khi app foreground
FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

// Handler khi app terminated
await FCMService().checkInitialMessage(); // Gọi trong main.dart
```

### Main.dart

```dart
// Initialize FCM
await FCMService().initialize();

// Check nếu app được mở từ notification (terminated state)
await FCMService().checkInitialMessage();
```

## Lưu ý

- Không cần navigate thêm, app sẽ tự động mở về trang đầu theo role user
- Splash screen sẽ tự động điều hướng đến:
  - Admin Home nếu role = admin
  - School Home nếu role = school  
  - Employer Home nếu role = employer
  - Candidate Home nếu role = candidate
  - Login nếu chưa đăng nhập

## Testing

1. **Test Foreground**: App đang mở, gửi notification → Xem local notification hiển thị
2. **Test Background**: Minimize app, gửi notification → Tap → App mở lên
3. **Test Terminated**: Force close app, gửi notification → Tap → App khởi động
