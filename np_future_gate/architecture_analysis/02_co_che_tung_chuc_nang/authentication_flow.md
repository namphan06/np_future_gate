# Luồng Xác Thực (Authentication Flow)

## Mục đích

Tài liệu này mô tả chi tiết cơ chế xác thực người dùng trong ứng dụng NP FutureGate, bao gồm:
- Đăng nhập bằng Email/Password qua Supabase Auth
- Đăng nhập/Đăng ký bằng Google Sign-In
- Đăng ký tài khoản mới với lựa chọn vai trò (Candidate, Employer, School)
- Đổi mật khẩu và đặt lại mật khẩu
- Quản lý phiên đăng nhập và điều hướng theo vai trò

## Các thành phần tham gia

| Thành phần | Đường dẫn | Vai trò |
|------------|-----------|---------|
| `LoginScreen` | `lib/features/auth/screens/login_screen.dart` | Giao diện đăng nhập |
| `RegisterScreen` | `lib/features/auth/screens/register_screen.dart` | Giao diện đăng ký |
| `ChangePasswordScreen` | `lib/features/auth/screens/change_password_screen.dart` | Giao diện đổi mật khẩu |
| `AuthRepository` | `lib/core/repositories/auth_repository.dart` | Xử lý logic xác thực |
| `SupabaseService` | `lib/core/services/supabase_service.dart` | Quản lý Supabase client (Singleton) |
| `SupabaseConfig` | `lib/core/config/supabase_config.dart` | Cấu hình URL và API key từ `.env` |
| `FCMService` | `lib/core/services/fcm_service.dart` | Lưu FCM token sau đăng nhập |
| `DeviceTokenRepository` | `lib/core/repositories/device_token_repository.dart` | Lưu/xóa device token |
| `AuthResult` | `lib/core/models/auth_models.dart` | Model kết quả xác thực |
| `UserRole` | `lib/core/models/auth_models.dart` | Enum vai trò người dùng |
| `Profile` | `lib/core/models/profile_model.dart` | Model thông tin người dùng |

## Kiến trúc tổng quan

```mermaid
graph TB
    subgraph "Presentation Layer"
        LS[LoginScreen]
        RS[RegisterScreen]
        CPS[ChangePasswordScreen]
    end

    subgraph "Data Layer"
        AR[AuthRepository]
        DTR[DeviceTokenRepository]
    end

    subgraph "Service Layer"
        SS[SupabaseService<br/>Singleton]
        FCMS[FCMService<br/>Singleton]
    end

    subgraph "External Services"
        SA[Supabase Auth]
        SDB[Supabase Database<br/>profiles table]
        GS[Google Sign-In]
        FCM[Firebase Cloud Messaging]
    end

    LS --> AR
    RS --> AR
    CPS --> AR
    LS --> FCMS
    AR --> SS
    AR --> DTR
    AR --> GS
    SS --> SA
    SS --> SDB
    FCMS --> FCM
    DTR --> SDB
```

## Luồng xử lý chi tiết

### 1. Khởi tạo Supabase

Trước khi ứng dụng chạy, `SupabaseService.initialize()` được gọi trong `main()`:

1. Load file `.env` chứa `SUPABASE_URL` và `SUPABASE_ANON_KEY`
2. Khởi tạo Supabase client với `AuthFlowType.pkce` (Proof Key for Code Exchange)
3. Lưu client instance vào Singleton để sử dụng toàn ứng dụng

```dart
// Cấu hình PKCE flow cho bảo mật cao hơn
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
);
```

### 2. Đăng nhập bằng Email/Password

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant LS as LoginScreen
    participant AR as AuthRepository
    participant SA as Supabase Auth
    participant DB as Supabase DB
    participant FCM as FCMService

    U->>LS: Nhập email + password
    LS->>LS: Validate form (email hợp lệ, password >= 6 ký tự)
    LS->>AR: signInWithEmail(email, password)
    AR->>SA: signInWithPassword(email, password)
    
    alt Đăng nhập thành công
        SA-->>AR: AuthResponse (user != null)
        AR->>DB: SELECT FROM profiles WHERE id = user.id
        
        alt Tài khoản bị vô hiệu hóa
            DB-->>AR: profile.isActive == false
            AR->>SA: signOut()
            AR-->>LS: AuthResult.failure("Tài khoản bị ngừng hoạt động")
            LS->>U: Hiển thị SnackBar lỗi
        else Tài khoản hoạt động
            DB-->>AR: Profile (role, fullName, ...)
            AR-->>LS: AuthResult.success()
            LS->>FCM: Lấy FCM token
            LS->>AR: saveDeviceToken(fcmToken, userId, role)
            AR->>DB: INSERT/UPDATE device_tokens
            LS->>LS: Điều hướng theo role
            LS->>U: Chuyển đến HomeScreen tương ứng
        end
    else Đăng nhập thất bại
        SA-->>AR: AuthException
        AR-->>LS: AuthResult.failure(message)
        LS->>U: Hiển thị SnackBar lỗi
    end
```

**Các bước chi tiết:**

1. Người dùng nhập email và password trên `LoginScreen`
2. Form validation kiểm tra:
   - Email không rỗng và chứa ký tự `@`
   - Password không rỗng và có ít nhất 6 ký tự
3. Gọi `AuthRepository.signInWithEmail()`
4. Supabase Auth xác thực credentials
5. Nếu thành công: lấy profile từ bảng `profiles` để kiểm tra trạng thái tài khoản (`isActive`)
6. Nếu tài khoản active: lưu FCM token và điều hướng theo role
7. Nếu thất bại: hiển thị thông báo lỗi bằng tiếng Việt

### 3. Đăng nhập bằng Google Sign-In

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant LS as LoginScreen
    participant AR as AuthRepository
    participant GS as Google Sign-In
    participant SA as Supabase Auth
    participant DB as Supabase DB
    participant FCM as FCMService

    U->>LS: Nhấn "Đăng nhập với Google"
    LS->>AR: signInWithGoogle()
    AR->>GS: signOut() (reset session cũ)
    AR->>GS: signIn() (hiển thị Google picker)
    U->>GS: Chọn tài khoản Google
    
    alt User hủy chọn
        GS-->>AR: null
        AR-->>LS: AuthResult.failure("Đăng nhập bị hủy")
        LS->>U: Hiển thị SnackBar lỗi
    else User chọn tài khoản
        GS-->>AR: GoogleSignInAccount
        AR->>GS: authentication (lấy tokens)
        GS-->>AR: accessToken + idToken
        AR->>SA: signInWithIdToken(provider: google, idToken, accessToken)
        
        alt Supabase xác thực thành công
            SA-->>AR: AuthResponse (user)
            AR->>DB: SELECT FROM profiles WHERE id = user.id
            
            alt Tài khoản bị vô hiệu hóa
                DB-->>AR: profile.isActive == false
                AR->>SA: signOut()
                AR->>GS: signOut()
                AR-->>LS: AuthResult.failure("Tài khoản bị ngừng")
            else Tài khoản hoạt động
                DB-->>AR: Profile
                AR-->>LS: AuthResult.success()
                LS->>FCM: Lấy FCM token
                LS->>AR: saveDeviceToken(fcmToken, userId, role)
                LS->>U: Chuyển đến HomeScreen theo role
            end
        else Supabase xác thực thất bại
            SA-->>AR: AuthException
            AR-->>LS: AuthResult.failure(message)
            LS->>U: Hiển thị SnackBar lỗi
        end
    end
```

**Các bước chi tiết:**

1. Gọi `_googleSignIn.signOut()` trước để đảm bảo user có thể chọn tài khoản mới
2. Hiển thị Google Account Picker qua `_googleSignIn.signIn()`
3. Lấy `accessToken` và `idToken` từ Google Authentication
4. Gửi tokens đến Supabase qua `signInWithIdToken()` với provider `OAuthProvider.google`
5. Supabase tự động tạo/liên kết user trong hệ thống auth
6. Kiểm tra trạng thái tài khoản và điều hướng

**Scopes yêu cầu:** `email`, `profile`

### 4. Đăng ký tài khoản mới

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant RS as RegisterScreen
    participant AR as AuthRepository
    participant SA as Supabase Auth
    participant DB as Supabase DB

    U->>RS: Chọn vai trò (Candidate/Employer/School)
    U->>RS: Nhập thông tin (name, email, phone, password)
    RS->>RS: Validate form
    RS->>AR: signUpWithEmail(email, password, fullName, phone, role)
    AR->>SA: signUp(email, password, data: {full_name, phone, role})
    
    alt Đăng ký thành công
        SA-->>AR: AuthResponse (user)
        AR->>DB: INSERT INTO profiles (id, email, full_name, phone, role, is_active: false)
        
        alt Email chưa xác thực
            AR-->>RS: AuthResult.success("Kiểm tra email để xác thực")
            RS->>U: Thông báo kiểm tra email
        else Email đã xác thực
            AR-->>RS: AuthResult.success("Đăng ký thành công!")
            RS->>U: Chuyển đến HomeScreen theo role đã chọn
        end
    else Đăng ký thất bại
        SA-->>AR: AuthException
        AR-->>RS: AuthResult.failure(message)
        RS->>U: Hiển thị SnackBar lỗi
    end
```

**Các bước chi tiết:**

1. Người dùng chọn vai trò trên `RegisterScreen`:
   - **Người dùng (Candidate):** Tìm kiếm cơ hội nghề nghiệp
   - **Nhà tuyển dụng (Employer):** Tuyển dụng nhân tài
   - **Nhà trường (School):** Kết nối sinh viên với doanh nghiệp
   - *(Admin không hiển thị trong form đăng ký)*
2. Nhập thông tin: Họ tên, Email, Số điện thoại, Mật khẩu, Xác nhận mật khẩu
3. Form validation:
   - Họ tên không rỗng
   - Email hợp lệ (chứa `@`)
   - Số điện thoại >= 10 ký tự
   - Mật khẩu >= 6 ký tự
   - Xác nhận mật khẩu khớp
4. Gọi `AuthRepository.signUpWithEmail()`:
   - Tạo user trong `auth.users` với metadata (full_name, phone, role)
   - Tạo profile trong bảng `profiles` với `is_active: false` (mặc định chưa kích hoạt)
5. Nếu trigger database đã tạo profile → bỏ qua lỗi duplicate
6. Điều hướng theo role đã chọn

### 5. Đăng ký bằng Google

Luồng tương tự đăng nhập Google (`signInWithGoogle()`). Supabase tự động xử lý:
- Nếu user chưa tồn tại → tạo mới trong `auth.users`
- Nếu user đã tồn tại → đăng nhập bình thường
- Profile được tạo với role mặc định (candidate)

### 6. Đổi mật khẩu

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant CPS as ChangePasswordScreen
    participant AR as AuthRepository
    participant SA as Supabase Auth

    U->>CPS: Nhập mật khẩu mới + xác nhận
    CPS->>CPS: Validate (>= 6 ký tự, khớp nhau)
    CPS->>AR: updatePassword(newPassword)
    AR->>SA: updateUser(UserAttributes(password: newPassword))
    
    alt Thành công
        SA-->>AR: Success
        AR-->>CPS: void
        CPS->>U: SnackBar "Đổi mật khẩu thành công"
        CPS->>CPS: Navigator.pop()
    else Thất bại
        SA-->>AR: Exception
        AR-->>CPS: throw Exception
        CPS->>U: SnackBar hiển thị lỗi
    end
```

### 7. Đặt lại mật khẩu (Reset Password)

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant AR as AuthRepository
    participant SA as Supabase Auth
    participant E as Email Service

    U->>AR: resetPassword(email)
    AR->>SA: resetPasswordForEmail(email)
    SA->>E: Gửi email reset link
    E->>U: Email với link đặt lại mật khẩu
    AR-->>U: "Đã gửi email đặt lại mật khẩu"
```

### 8. Đăng xuất

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant AR as AuthRepository
    participant DTR as DeviceTokenRepository
    participant SA as Supabase Auth
    participant GS as Google Sign-In

    U->>AR: signOut(deviceToken)
    
    alt Có device token
        AR->>DTR: removeDeviceToken(token, userId)
        DTR-->>AR: Done
    end
    
    AR->>SA: signOut()
    AR->>GS: signOut()
    AR-->>U: AuthResult.success("Đăng xuất thành công!")
```

## Điều hướng theo vai trò (Role-based Navigation)

Sau khi xác thực thành công, hệ thống điều hướng người dùng đến màn hình chính tương ứng:

| Vai trò | Màn hình | File |
|---------|----------|------|
| `candidate` | `CandidateHomeScreen` | `lib/features/candidate/screens/candidate_home_screen.dart` |
| `employer` | `EmployerHomeScreen` | `lib/features/employer/screens/employer_home_screen.dart` |
| `school` | `SchoolHomeScreen` | `lib/features/school/screens/school_home_screen.dart` |
| `admin` | `AdminHomeScreen` | `lib/features/admin/screens/admin_home_screen.dart` |

## Xử lý lỗi

### Bảng mã lỗi và thông báo

| Mã lỗi | Điều kiện | Thông báo tiếng Việt |
|---------|-----------|---------------------|
| `400` | User already registered | "Email đã được đăng ký." |
| `400` | Invalid login credentials | "Email hoặc mật khẩu không đúng." |
| `400` | Khác | "Yêu cầu không hợp lệ." |
| `422` | Validation error | "Email hoặc mật khẩu không hợp lệ." |
| `429` | Rate limit | "Quá nhiều yêu cầu. Vui lòng thử lại sau." |
| - | Account deactivated | "Tài khoản đã bị ngừng hoạt động. Liên hệ quản trị viên." |
| - | Google cancelled | "Đăng nhập Google bị hủy." |
| - | Token null | "Không thể lấy thông tin xác thực từ Google." |

### Chiến lược xử lý lỗi

1. **AuthException**: Chuyển đổi mã lỗi Supabase sang thông báo tiếng Việt qua `_getAuthErrorMessage()`
2. **PostgrestException**: Hiển thị lỗi database (thường xảy ra khi tạo profile)
3. **General Exception**: Hiển thị thông báo chung với chi tiết lỗi
4. **Account Status Check**: Kiểm tra `isActive` sau đăng nhập, nếu bị vô hiệu hóa → sign out ngay lập tức
5. **FCM Token Error**: Không block luồng đăng nhập, chỉ log warning

## Bảo mật

- **PKCE Flow**: Sử dụng `AuthFlowType.pkce` cho bảo mật OAuth cao hơn
- **Environment Variables**: Credentials lưu trong `.env`, không hardcode
- **Account Deactivation**: Kiểm tra trạng thái tài khoản sau mỗi lần đăng nhập
- **Google Session Reset**: Gọi `signOut()` trước `signIn()` để tránh tự động chọn tài khoản cũ
- **Password Validation**: Yêu cầu tối thiểu 6 ký tự
- **Device Token Cleanup**: Xóa FCM token khi đăng xuất

## Model dữ liệu

### AuthResult

```dart
class AuthResult {
  final bool success;      // Kết quả thành công/thất bại
  final String? message;   // Thông báo cho người dùng
  final dynamic data;      // Dữ liệu bổ sung (User object)
}
```

### UserRole

```dart
enum UserRole {
  candidate,   // Ứng viên tìm việc
  employer,    // Nhà tuyển dụng
  school,      // Nhà trường
  admin;       // Quản trị viên
}
```

### Bảng `profiles` (Supabase Database)

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | UUID | Khóa chính, liên kết với `auth.users.id` |
| `email` | TEXT | Email người dùng |
| `full_name` | TEXT | Họ và tên |
| `phone` | TEXT | Số điện thoại |
| `role` | TEXT | Vai trò (candidate/employer/school/admin) |
| `avatar_url` | TEXT | URL ảnh đại diện |
| `metadata` | JSONB | Dữ liệu bổ sung |
| `is_active` | BOOLEAN | Trạng thái tài khoản (mặc định: false) |

## Services và Repositories liên quan

| Tên | Loại | Chức năng trong luồng auth |
|-----|------|---------------------------|
| `SupabaseService` | Service (Singleton) | Khởi tạo và cung cấp Supabase client |
| `FCMService` | Service (Singleton) | Quản lý FCM token, lưu token sau đăng nhập |
| `AuthRepository` | Repository | Xử lý toàn bộ logic xác thực |
| `DeviceTokenRepository` | Repository | CRUD device tokens cho push notification |

## Liên kết liên quan

- [Tổng quan kiến trúc](../01_tong_quan_kien_truc.md)
- [Luồng thông báo (Notification Flow)](./notification_flow.md)
- [Giải thích Supabase](../10_giai_thich_cong_nghe_tung_cai/supabase.md)
- [Giải thích Firebase FCM](../10_giai_thich_cong_nghe_tung_cai/firebase_fcm.md)
