# Supabase Authentication Integration

## Tổng quan
Project đã được tích hợp hoàn chỉnh với Supabase để xử lý authentication (đăng ký, đăng nhập, Google Sign-in).

## Cấu trúc code

### 1. Configuration Layer (`lib/core/config/`)
- **supabase_config.dart**: Đọc credentials từ file `.env` một cách an toàn

### 2. Service Layer (`lib/core/services/`)
- **supabase_service.dart**: 
  - Singleton service quản lý Supabase client
  - Initialize Supabase trong `main()`
  - Cung cấp helper methods (isAuthenticated, currentUser, currentUserId)

### 3. Model Layer (`lib/core/models/`)
- **auth_models.dart**:
  - `AuthResult`: Wrapper class cho kết quả auth operations
  - `UserRole`: Enum cho 3 vai trò (candidate, employer, school)
- **profile_model.dart**:
  - `Profile`: Model class cho bảng profiles (type-safe)
  - Methods: `fromJson()`, `toJson()`, `copyWith()`

### 4. Repository Layer (`lib/core/repositories/`)
- **auth_repository.dart**: 
  - Tất cả logic auth được tách biệt ở đây
  - Methods:
    - `signUpWithEmail()`: Đăng ký với email/password
    - `signInWithEmail()`: Đăng nhập với email/password
    - `signInWithGoogle()`: Đăng nhập với Google
    - `signOut()`: Đăng xuất
    - `resetPassword()`: Reset password
    - `getCurrentUserProfile()`: Lấy profile từ bảng `profiles` (trả về `Profile` model)
    - `updateProfile()`: Cập nhật profile
  - Error handling với messages tiếng Việt

### 5. UI Layer (`lib/screens/auth/`)
- **login_screen.dart**: 
  - Tích hợp `AuthRepository`
  - Xử lý login với email/password
  - Xử lý Google Sign-in
  - Hiển thị error/success messages
  
- **register_screen.dart**:
  - Tích hợp `AuthRepository`
  - Form đăng ký với 3 role options
  - Xử lý register và Google Sign-in
  - Gửi metadata (full_name, phone, role) lên Supabase

## File .env
File `.env` chứa credentials Supabase:
```
SUPABASE_URL=https://hrhoohbvmdmwkbqiymsb.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

⚠️ **Quan trọng**: File `.env` đã được thêm vào `.gitignore` để bảo mật.

## Dependencies đã thêm
```yaml
supabase_flutter: ^2.9.1    # Supabase client
flutter_dotenv: ^5.2.1      # Đọc .env file
google_sign_in: ^6.2.2      # Google authentication
```

## Cách sử dụng

### 1. Đăng ký user mới
```dart
final result = await authRepository.signUpWithEmail(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'Nguyen Van A',
  phone: '0901234567',
  role: UserRole.candidate,
);

if (result.success) {
  // Đăng ký thành công
  print(result.message);
} else {
  // Có lỗi
  print(result.message);
}
```

### 2. Đăng nhập
```dart
final result = await authRepository.signInWithEmail(
  email: 'user@example.com',
  password: 'password123',
);
```

### 3. Google Sign-in
```dart
final result = await authRepository.signInWithGoogle();
```

### 4. Lấy thông tin user hiện tại
```dart
final profile = await authRepository.getCurrentUserProfile();
if (profile != null) {
  print('Name: ${profile.fullName}');
  print('Role: ${profile.role.value}');
  print('Email: ${profile.email}');
}
```

### 5. Listen auth state changes
```dart
authRepository.authStateChanges.listen((event) {
  if (event.session != null) {
    // User đã đăng nhập
  } else {
    // User đã đăng xuất
  }
});
```

## Supabase Database Schema

### Bảng `profiles` (đã tạo trong Supabase)
```sql
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text,
  avatar_url text,
  phone text,
  role user_role DEFAULT 'candidate',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

### Trigger tự động tạo profile
Khi user đăng ký qua Supabase Auth, trigger sẽ tự động tạo record trong bảng `profiles` với thông tin từ `user_metadata`.

## Google Sign-in Setup (Cần làm thêm)

### Android
1. Thêm SHA-1 certificate fingerprint vào Firebase Console
2. Download `google-services.json` mới và đặt vào `android/app/`

### iOS
1. Thêm URL scheme vào `ios/Runner/Info.plist`
2. Download `GoogleService-Info.plist` và đặt vào `ios/Runner/`

### Web
Cấu hình đã có sẵn trong `google_sign_in` package.

## Testing

### 1. Test đăng ký
- Mở app → Tap "Đăng ký ngay"
- Chọn role (candidate/employer/school)
- Điền thông tin và submit
- Kiểm tra email để xác thực (nếu bật email confirmation trong Supabase)

### 2. Test đăng nhập
- Nhập email/password đã đăng ký
- Hoặc tap "Đăng nhập với Google"

### 3. Kiểm tra Supabase Dashboard
- Vào "Authentication" → "Users" để xem users
- Vào "Table Editor" → "profiles" để xem profile data

## Troubleshooting

### Lỗi: "SUPABASE_URL not found"
- Kiểm tra file `.env` có tồn tại trong root project
- Đảm bảo `.env` đã được thêm vào `pubspec.yaml` assets

### Lỗi Google Sign-in
- Kiểm tra SHA-1 đã thêm vào Firebase
- Đảm bảo package name khớp với Firebase project

### Lỗi: "Invalid login credentials"
- Kiểm tra email/password đúng
- Kiểm tra user đã xác thực email (nếu bắt buộc)

## Next Steps (TODO)

1. **Home Screen**: Tạo màn hình sau khi đăng nhập thành công
2. **Profile Screen**: Màn hình xem/chỉnh sửa profile
3. **Forgot Password**: Implement flow reset password
4. **Role-based routing**: Điều hướng khác nhau cho từng role
5. **Protected routes**: Middleware kiểm tra authentication
6. **Refresh token**: Xử lý token expiration
7. **Google Sign-in setup**: Hoàn thành cấu hình Android/iOS

## Security Notes

- ✅ Credentials lưu trong `.env` và không commit lên Git
- ✅ Sử dụng `anon key` (public key) ở client
- ✅ Row Level Security (RLS) policies trong Supabase bảo vệ data
- ⚠️ Không bao giờ lộ `service_role` key ra client
- ⚠️ Validate input ở cả client và server (Supabase functions)

## Architecture Benefits

### 1. Separation of Concerns
- UI chỉ gọi repository methods
- Repository xử lý tất cả logic auth
- Service quản lý Supabase client lifecycle

### 2. Testability
- Dễ dàng mock `AuthRepository` cho unit tests
- UI tests không cần Supabase thực

### 3. Maintainability
- Thay đổi auth logic chỉ ở repository
- Thêm auth methods mới dễ dàng
- Error handling tập trung

### 4. Reusability
- `AuthRepository` có thể dùng ở nhiều screens
- `AuthResult` model nhất quán cho mọi auth operations
