# Setup Test Accounts - Hướng dẫn

## Mục đích
Tạo các tài khoản test/demo trong database để Admin có thể đăng nhập vào và xem giao diện của từng role (Candidate, Employer, School) như một user thật, nhưng không thể thực hiện các thao tác thay đổi dữ liệu.

## Bước 1: Tạo Users trong Supabase Auth

1. Đăng nhập vào **Supabase Dashboard**
2. Chọn project của bạn
3. Vào **Authentication** > **Users**
4. Click **Add user** và tạo 3 tài khoản sau:

### Tài khoản 1: Test Candidate
- **Email**: `test-candidate@demo.com`
- **Password**: `Demo123456!`
- **Auto Confirm User**: ✅ (check)
- Click **Create user**
- **Lưu lại User ID** (UUID) sau khi tạo

### Tài khoản 2: Test Employer
- **Email**: `test-employer@demo.com`
- **Password**: `Demo123456!`
- **Auto Confirm User**: ✅ (check)
- Click **Create user**
- **Lưu lại User ID** (UUID) sau khi tạo

### Tài khoản 3: Test School
- **Email**: `test-school@demo.com`
- **Password**: `Demo123456!`
- **Auto Confirm User**: ✅ (check)
- Click **Create user**
- **Lưu lại User ID** (UUID) sau khi tạo

## Bước 2: Chạy SQL Script

1. Mở file `database/create_test_accounts.sql`
2. **Thay thế** các placeholder bằng User IDs thực tế từ Bước 1:
   - `REPLACE_WITH_CANDIDATE_USER_ID` → UUID của test-candidate@demo.com
   - `REPLACE_WITH_EMPLOYER_USER_ID` → UUID của test-employer@demo.com
   - `REPLACE_WITH_SCHOOL_USER_ID` → UUID của test-school@demo.com

3. Vào **Supabase Dashboard** > **SQL Editor**
4. Copy toàn bộ SQL script (đã thay thế UUIDs)
5. Paste vào SQL Editor
6. Click **Run** để thực thi

## Bước 3: Verify

Chạy query sau để kiểm tra:

```sql
SELECT 
  id,
  email,
  full_name,
  role,
  metadata->>'is_test_account' as is_test,
  created_at
FROM public.profiles
WHERE email LIKE '%demo.com'
ORDER BY role;
```

Kết quả mong đợi: 3 rows với `is_test` = `true`

## Bước 4: Test

1. Login vào app bằng tài khoản Admin
2. Mở drawer menu
3. Kéo xuống phần "Xem giao diện"
4. Click **"Candidate View"**
5. Xác nhận dialog
6. App sẽ:
   - Sign out admin
   - Sign in test-candidate@demo.com
   - Navigate to Candidate home screen
7. Bạn giờ có thể xem UI như một candidate thật!
8. Thử thực hiện action (create CV, apply job, etc.) → Sẽ thấy warning dialog

## Quay lại Admin

1. Click nút Logout trong app
2. Đăng nhập lại bằng tài khoản admin của bạn

## Cấu trúc dữ liệu Test Accounts

### Test Candidate Profile
```json
{
  "email": "test-candidate@demo.com",
  "full_name": "Demo Candidate",
  "role": "candidate",
  "metadata": {
    "is_test_account": true,
    "address": "Địa chỉ demo",
    "date_of_birth": "1995-01-01",
    "description": "..."
  }
}
```

### Test Employer Profile
```json
{
  "email": "test-employer@demo.com",
  "full_name": "Demo Company",
  "role": "employer",
  "metadata": {
    "is_test_account": true,
    "company_name": "Công ty Demo",
    "address": "Địa chỉ công ty demo",
    "website": "https://demo.com",
    ...
  }
}
```

### Test School Profile
```json
{
  "email": "test-school@demo.com",
  "full_name": "Trường Demo",
  "role": "school",
  "metadata": {
    "is_test_account": true,
    "school_type": "Đại học",
    "address": "Địa chỉ trường demo",
    ...
  }
}
```

## Tích hợp vào code

Trong bất kỳ màn hình nào cần block CUD operations:

```dart
import 'package:your_app/core/services/demo_mode_service.dart';
import 'package:your_app/core/services/supabase_service.dart';

// Ví dụ: Trong nút "Lưu CV"
onPressed: () async {
  final currentUser = SupabaseService.instance.currentUser;
  
  if (DemoModeService.instance.checkAndBlock(
    context,
    action: 'lưu CV',
    userEmail: currentUser?.email,
    userMetadata: currentUser?.userMetadata,
  )) {
    return; // Blocked
  }
  
  // Continue normal flow
  await _saveCV();
}
```

## Security Notes

⚠️ **QUAN TRỌNG**:
- Test account passwords được hardcode trong app → **KHÔNG dùng cho production**
- Chỉ dùng cho development/demo
- Nếu deploy production, nên:
  - Disable test accounts
  - Hoặc change passwords thường xuyên
  - Hoặc xóa test accounts khỏi database

## Troubleshooting

### Lỗi: "Invalid login credentials"
→ Check email và password trong Supabase Auth
→ Verify user đã được auto-confirm

### Lỗi: "User not found"
→ Check đã chạy SQL script chưa
→ Verify UUIDs đã thay thế đúng

### Warning dialog không hiện
→ Check metadata có `is_test_account: true` không
→ Check đã implement `checkAndBlock()` đúng chưa

### Không thể quay lại admin
→ Logout và login lại bằng admin credentials
→ Admin email đã được store trong DemoModeService

## Next Steps

Sau khi setup xong test accounts:

1. ✅ Implement CUD blocking trong Candidate screens
2. ✅ Implement CUD blocking trong Employer screens (khi ready)
3. ✅ Implement CUD blocking trong School screens (khi ready)
4. ✅ Test toàn bộ flow: Admin → Test account → Try CUD → Logout → Back to Admin

Tham khảo `DEMO_MODE_GUIDE.md` để biết cách tích hợp checkAndBlock() vào code.
