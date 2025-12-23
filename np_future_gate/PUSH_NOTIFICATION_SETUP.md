# Hướng dẫn Setup Push Notifications với Firebase Cloud Messaging

## 📋 Tổng quan
Tài liệu này hướng dẫn setup push notifications cho NP Future Gate app.

## ✅ Đã hoàn thành:
- ✅ Thêm Firebase packages vào pubspec.yaml
- ✅ Cấu hình Firebase options (firebase_options.dart)
- ✅ Tạo FCM Service (fcm_service.dart)
- ✅ Tạo Push Notification Service (push_notification_service.dart)
- ✅ Tạo bảng device_tokens trong Supabase
- ✅ Cập nhật Test Page để test gửi notification

## 🔧 Cần làm tiếp:

### 1. Initialize Firebase trong Main.dart

Cập nhật file `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  // Initialize FCM Service
  await FCMService().initialize();
  
  runApp(const MyApp());
}
```

###2. Cập nhật Login Screen để lưu FCM Token thật

Thay đổi trong `lib/screens/auth/login_screen.dart`:

**TỪ:**
```dart
final dummyDeviceToken = 'device_${profile.id}_${DateTime.now().millisecondsSinceEpoch}';
await _authRepository.saveDeviceToken(
  deviceToken: dummyDeviceToken,
  ...
);
```

**THÀNH:**
```dart
// Lưu FCM token thực
final fcmToken = FCMService().fcmToken;
if (fcmToken != null) {
  await _authRepository.saveDeviceToken(
    deviceToken: fcmToken,
    userId: profile.id,
    role: profile.role.value,
  );
}
```

### 3. Cấu hình Android cho FCM

#### 3.1. Cập nhật `android/app/build.gradle`:

Thêm vào cuối file:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### 3.2. Cập nhật `android/build.gradle`:

Thêm vào dependencies:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

#### 3.3. Kiểm tra `android/app/google-services.json` đã tồn tại chưa
- Nếu chưa có, tải từ Firebase Console
- Đặt vào `android/app/`

### 4. Test Push Notification

1. **Chạy app:**
   ```bash
   flutter run
   ```

2. **Đăng nhập vào app** (với role Admin để vào Test Page)

3. **Kiểm tra console log** để thấy FCM token:
   ```
   ✅ FCM Token: eXaMpLe...
   ✅ Device token saved for user: xxx
   ```

4. **Vào Test Page** (menu Admin > Test)

5. **Click vào "Push Notifications"** để gửi test notification

6. **Kiểm tra:**
   - Console log sẽ hiển thị device tokens tìm thấy
   - HTTP response từ FCM server
   - Notification sẽ hiển thị trên thiết bị

## 🐛 Troubleshooting

### Lỗi: "Device token chưa được lưu vào database"

**Nguyên nhân:** RLS policies hoặc function lỗi

**Giải pháp:**
1. Kiểm tra bảng `device_tokens` đã được tạo trong Supabase chưa
2. Kiểm tra RLS policies có đúng không
3. Kiểm tra function `upsert_device_token` có tồn tại không

**SQL để test:**
```sql
-- Test function
SELECT public.upsert_device_token(
  'test_token_123',
  'your-user-id-here',
  'admin',
  'android',
  'Test Device',
  '1.0.0'
);

-- Kiểm tra dữ liệu
SELECT * FROM public.device_tokens;
```

### Lỗi: "FCM token = null"

**Nguyên nhân:** Firebase chưa được initialize hoặc permission bị từ chối

**Giải pháp:**
1. Kiểm tra `Firebase.initializeApp()` được gọi trong `main()`
2. Kiểm tra permission notification được granted
3. Kiểm tra console log khi FCM initialize

### Lỗi: "Gửi notification thất bại (401/403)"

**Nguyên nhân:** FCM Server Key không đúng

**Giải pháp:**
1. Kiểm tra lại FCM Server Key trong Firebase Console:
   - Vào Project Settings > Cloud Messaging
   - Copy "Server key" (Legacy)
2. Cập nhật trong `push_notification_service.dart`

## 📱 FCM Server Key hiện tại:
```
BBr_3SuEHWfH3c5Df0JWOKtK3QDbj9Pejj8bnbOCA_JKShdgi2EZ9HfxCcTWLY4r-KGqAKuVjvBAJ1xO4VHFR7M
```

**Lưu ý:** Key này có thể là VAPID key cho Web Push. Đối với Android/iOS, cần dùng **Server Key** (Legacy) từ Firebase Console.

## 🎯 Các bước tiếp theo (sau khi test thành công):

1. Tích hợp notification vào các chức năng:
   - Thông báo khi có job mới
   - Thông báo khi có applicant mới
   - Thông báo interview schedule
   
2. Tạo notification screen để xem lịch sử thông báo

3. Implement notification actions (click vào notification để mở screen cụ thể)

4. Setup notification channels cho Android (High priority, Low priority, etc.)

---

Created: 2025-12-23
Author: AI Assistant
