# Hướng dẫn thêm cột is_active vào bảng profiles

## 1. Chạy Migration trên Supabase Dashboard

### Cách 1: Sử dụng SQL Editor trên Supabase Dashboard
1. Truy cập: https://supabase.com/dashboard
2. Chọn project của bạn
3. Vào **SQL Editor** ở menu bên trái
4. Tạo query mới (New query)
5. Copy nội dung file `add_is_active_to_profiles.sql` vào editor
6. Click **Run** để thực thi

### Cách 2: Sử dụng Supabase CLI (nếu có setup)
```bash
supabase db push
```

## 2. Các thay đổi đã thực hiện

### Database Schema
- ✅ Thêm cột `is_active` kiểu BOOLEAN với default value = `false`
- ✅ Thêm index cho cột `is_active` để tối ưu query
- ✅ Cập nhật các tài khoản hiện có thành `is_active = true` (có thể bỏ nếu muốn)

### Flutter Code
- ✅ Cập nhật `Profile` model với field `isActive`
- ✅ Cập nhật `AuthRepository` để set `is_active = false` khi đăng ký

## 3. Sử dụng

### Kiểm tra trạng thái active của user:
```dart
final profile = await authRepository.getCurrentUserProfile();
if (profile?.isActive == true) {
  // User đã được kích hoạt
} else {
  // User chưa được kích hoạt
}
```

### Kích hoạt tài khoản (từ admin):
```dart
await authRepository.updateProfile(
  userId: userId,
  metadata: profile.metadata,
  // Có thể cần thêm method riêng để update is_active
);
```

## 4. Lưu ý

- Tài khoản mới sẽ có `is_active = false` mặc định
- Admin cần kích hoạt tài khoản trước khi user có thể sử dụng đầy đủ chức năng
- Có thể cần thêm logic kiểm tra `is_active` trong các screen quan trọng
