# Demo Mode - Hướng dẫn sử dụng

## Tổng quan
Demo Mode cho phép Admin xem giao diện của các role khác (Candidate, Employer, School) mà không cần đăng nhập lại. Tài khoản demo chỉ được phép **XEM** giao diện, **KHÔNG THỂ** thực hiện các thao tác thay đổi dữ liệu.

## Cách sử dụng

### 1. Từ Admin Panel
1. Mở drawer menu
2. Kéo xuống phần "Xem giao diện"
3. Chọn role muốn xem:
   - **Candidate View** (màu xanh)
   - **Employer View** (màu cam)
   - **School View** (màu xanh lá)
4. Xác nhận dialog để vào demo mode

### 2. Trong Demo Mode
- Có thể xem toàn bộ giao diện của role đó
- Khi thực hiện các thao tác CUD, sẽ hiện dialog cảnh báo
- Để thoát, cần đăng xuất và đăng nhập lại bằng admin account

## Cách tích hợp vào code

### Bước 1: Import Service
```dart
import 'package:your_app/core/services/demo_mode_service.dart';
```

### Bước 2: Check và block actions
Trước khi thực hiện bất kỳ thao tác CUD nào (Create, Update, Delete), thêm check:

```dart
// Ví dụ: Khi tạo CV mới
Future<void> createCV() async {
  // Check demo mode
  if (DemoModeService.instance.checkAndBlock(
    context,
    action: 'tạo CV mới',
  )) {
    return; // Blocked, dialog đã được hiện
  }

  // Tiếp tục logic bình thường
  await cvRepository.create(...);
}
```

### Bước 3: Các thao tác cần check
Danh sách các thao tác cần check:

#### Create (Tạo mới)
- ✅ Tạo CV
- ✅ Đăng việc làm
- ✅ Ứng tuyển việc làm
- ✅ Tạo company profile
- ✅ Gửi tin nhắn
- ✅ Tạo partnership job

#### Update (Cập nhật)
- ✅ Sửa CV
- ✅ Cập nhật profile
- ✅ Sửa job posting
- ✅ Update application status

#### Delete (Xóa)
- ✅ Xóa CV
- ✅ Xóa job posting
- ✅ Rút đơn ứng tuyển

## Ví dụ cụ thể

### 1. Trong form save/submit
```dart
onPressed: () async {
  if (DemoModeService.instance.checkAndBlock(
    context,
    action: 'lưu thông tin',
  )) return;
  
  await _saveForm();
}
```

### 2. Trong delete button
```dart
onPressed: () async {
  if (DemoModeService.instance.checkAndBlock(
    context,
    action: 'xóa CV',
  )) return;
  
  await _deleteCV();
}
```

### 3. Trong apply job button
```dart
onPressed: () async {
  if (DemoModeService.instance.checkAndBlock(
    context,
    action: 'ứng tuyển việc làm',
  )) return;
  
  await _applyJob();
}
```

## API Reference

### `DemoModeService`

#### Properties
- `isDemoMode`: `bool` - Check if currently in demo mode
- `demoRole`: `String?` - Current demo role ('candidate', 'employer', 'school')
- `originalEmail`: `String?` - Email of admin before entering demo mode

#### Methods

##### `enterDemoMode(String role, String originalEmail)`
Enter demo mode with specified role
- `role`: 'candidate' | 'employer' | 'school'
- `originalEmail`: Admin's email to return to later

##### `exitDemoMode()`
Exit demo mode and return to normal mode

##### `isTestAccount(String? email)` → `bool`
Check if an email is a test account

##### `getRoleDisplayName()` → `String`
Get Vietnamese display name of current demo role

##### `showDemoWarning(context, {required String action})`
Show warning dialog when attempting restricted action

##### `checkAndBlock(context, {required String action})` → `bool`
Check if in demo mode and block if true. Returns:
- `true`: Blocked (in demo mode)
- `false`: Not blocked (can proceed)

## Lưu ý quan trọng

### ⚠️ Security
- Test accounts KHÔNG tồn tại trong database
- Không có quyền thực tế
- Chỉ là client-side flag để UX

### 🎯 Best Practices
1. **Luôn check trước khi CUD**: Wrap mọi action với `checkAndBlock()`
2. **Action name rõ ràng**: Dùng Vietnamese, specific, VD: "tạo CV mới", "xóa việc làm"
3. **Không check cho Read**: Chỉ check cho Create, Update, Delete
4. **Early return**: Return ngay sau check để avoid nested code

### 🚫 Không nên làm
```dart
// ❌ BAD - Không rõ ràng
checkAndBlock(context, action: 'save');

// ✅ GOOD - Rõ ràng
checkAndBlock(context, action: 'lưu thông tin CV');
```

```dart
// ❌ BAD - Check cả read operation
if (checkAndBlock(context, action: 'xem danh sách')) return;

// ✅ GOOD - Chỉ check CUD
if (checkAndBlock(context, action: 'xóa CV')) return;
```

## Testing

### Manual Test
1. Login as Admin
2. Click "Candidate View"
3. Confirm dialog
4. Try to create/edit/delete something
5. Should see warning dialog
6. Logout and login again
7. Demo mode should be exited

### Checklist
- [ ] Dialog hiện đúng khi vào demo mode
- [ ] Có thể xem UI bình thường
- [ ] Warning hiện khi thực hiện CUD
- [ ] Logout removes demo mode
- [ ] All three roles work (candidate, employer, school)

## Troubleshooting

### Dialog không hiện
→ Check đã import DemoModeService chưa
→ Check đã wrap action với checkAndBlock chưa

### Vẫn thực hiện được action
→ Check return statement sau checkAndBlock
→ Đảm bảo early return nếu blocked

### Demo mode không thoát sau logout
→ Call `DemoModeService.instance.exitDemoMode()` trong logout handler
