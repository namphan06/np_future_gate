# Hệ thống Quản lý Người dùng - Admin

## Tổng quan

Hệ thống quản lý người dùng cho phép Admin xem, chỉnh sửa, và quản lý tất cả người dùng trong hệ thống (Candidates, Employers, Schools).

## Các chức năng chính

### 1. Quản lý Candidate
- ✅ Xem danh sách candidates
- ✅ Xem thông tin chi tiết (profile)
- ✅ Xem các việc đã apply
- ✅ Ngừng hoạt động tài khoản (toggle is_active)
- ✅ Xóa tài khoản
- ⏳ Xem đánh giá (sẽ phát triển sau)

### 2. Quản lý Employer
- ✅ Xem danh sách employers
- ✅ Xem thông tin chi tiết (profile)
- ✅ Xem các tin đã đăng
- ✅ Ngừng hoạt động tài khoản
- ✅ Giới hạn số tin đăng (metadata.limit_post)
- ✅ Xóa tài khoản

### 3. Quản lý School
- ✅ Xem danh sách schools
- ✅ Xem thông tin chi tiết (profile)
- ✅ Xem các việc từ trường đã đăng
- ✅ Ngừng hoạt động tài khoản
- ✅ Giới hạn số tin liên kết (metadata.limit_post)
- ✅ Xóa tài khoản

## Files đã tạo/cập nhật

### 1. Repository
- **`lib/core/repositories/admin_user_repository.dart`**
  - Quản lý tất cả operation liên quan đến user
  - Methods: getUsersByRole, toggleUserActiveStatus, setPostLimit, deleteUserAccount, getUserStatistics, etc.

### 2. Screens
- **`lib/screens/admin/user_detail_screen.dart`**
  - Màn hình chi tiết user
  - Hiển thị profile, statistics, activities
  - Các action: toggle active, set limit, delete

- **`lib/screens/admin/users_management_page_admin.dart`**
  - Màn hình quản lý danh sách users
  - Tab view: Candidates, Employers, Schools
  - Search functionality
  - Quick actions từ popup menu

### 3. Database Migrations
- **`supabase/migrations/add_is_active_to_profiles.sql`**
  - Thêm cột is_active vào bảng profiles
  - Default: false

- **`supabase/migrations/delete_user_function.sql`**
  - SQL function để xóa user hoàn toàn
  - Xóa cả auth.users và profiles

## Cài đặt

### 1. Chạy Database Migrations

```sql
-- 1. Thêm cột is_active
-- Copy nội dung từ supabase/migrations/add_is_active_to_profiles.sql
-- Paste vào Supabase SQL Editor và Run

-- 2. Tạo delete_user function
-- Copy nội dung từ supabase/migrations/delete_user_function.sql
-- Paste vào Supabase SQL Editor và Run
```

### 2. Flutter Dependencies
Đảm bảo có các dependencies sau trong `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^latest
  intl: ^latest
```

## Sử dụng

### Admin Home Screen
Từ Admin Panel, click vào "Quản lý người dùng" để mở trang quản lý.

### User Management Page
1. Chọn tab: Candidates, Employers, hoặc Schools
2. Sử dụng search bar để tìm kiếm theo email hoặc tên
3. Click vào user để xem chi tiết
4. Sử dụng menu ⋮ để quick actions:
   - Xem chi tiết
   - Ngừng hoạt động / Kích hoạt
   - Giới hạn tin đăng (Employer/School)
   - Xóa tài khoản

### User Detail Screen
1. Xem profile header với avatar và status
2. Xem statistics (số đơn apply, số tin đăng, etc.)
3. Xem thông tin chi tiết (email, phone, ngày tạo, giới hạn)
4. Xem activities (đơn apply / tin đăng / việc liên kết)
5. Sử dụng menu ⋮ ở trên để thực hiện actions

## Cấu trúc dữ liệu

### Profile Model
```dart
class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final UserRole role;
  final Map<String, dynamic> metadata;
  final bool isActive; // ⬅️ Mới thêm
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Metadata Structure
```dart
{
  'limit_post': 10, // Giới hạn số tin đăng (Employer/School)
  // ... other metadata fields
}
```

## Lưu ý

1. **is_active Field**
   - `true`: Tài khoản hoạt động bình thường
   - `false`: Tài khoản bị ngừng hoạt động (không thể login/sử dụng)

2. **limit_post Metadata**
   - Chỉ áp dụng cho Employer và School
   - `null` hoặc không có = không giới hạn
   - Number = số tin tối đa có thể đăng

3. **Delete User**
   - Xóa hoàn toàn user khỏi hệ thống
   - KHÔNG THỂ HOÀN TÁC
   - Cascade delete các dữ liệu liên quan

4. **Permissions**
   - Chỉ Admin mới có thể truy cập các chức năng này
   - Cần đảm bảo RLS (Row Level Security) được cấu hình đúng

## TODO / Tính năng tương lai

- [ ] Xem đánh giá của Candidate
- [ ] Export danh sách users
- [ ] Bulk actions (xóa nhiều, toggle nhiều)
- [ ] Filter nâng cao (theo ngày tạo, status, etc.)
- [ ] User activity logs
- [ ] Send notification to specific user
- [ ] Ban user temporarily

## Troubleshooting

### Lỗi: "Function delete_user does not exist"
→ Chạy migration `delete_user_function.sql` trên Supabase

### Lỗi: "Column is_active does not exist"
→ Chạy migration `add_is_active_to_profiles.sql` trên Supabase

### Lỗi: "Permission denied"
→ Kiểm tra RLS policies và ensure admin role có quyền truy cập
