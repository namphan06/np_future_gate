# Implementation Guide - Block Test Accounts

Hướng dẫn cách implement blocking cho test accounts ở cả 2 layers: Database và Application.

## 🎯 Mục tiêu

Test accounts (`test-candidate@demo.com`, `test-employer@demo.com`, `test-school@demo.com`) có thể:
- ✅ **Xem** toàn bộ giao diện và dữ liệu
- ❌ **Không thể** tạo, sửa, xóa dữ liệu

## 🛡️ 2-Layer Protection

### Layer 1: Database Level (RLS Policies) - Bắt buộc
### Layer 2: UI Level (Protected Widgets) - Tùy chọn nhưng khuyến nghị

---

## 📝 Bước 1: Setup Database Protection

### 1.1. Chạy SQL Script

1. Mở Supabase Dashboard > SQL Editor
2. Copy toàn bộ file `database/block_test_accounts.sql`
3. Paste và Run

### 1.2. Verify

Chạy query để check policies:

```sql
SELECT 
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE policyname LIKE '%Test accounts%'
ORDER BY tablename, cmd;
```

Kết quả mong đợi: ~15+ policies cho INSERT, UPDATE, DELETE

### 1.3. Test Database Level

```sql
-- Set session to test account
SELECT set_config('request.jwt.claims', '{"sub": "test-candidate-uuid"}', true);

-- Try to insert - should FAIL
INSERT INTO cvs (...) VALUES (...);
-- Error: new row violates row-level security policy
```

---

## 📱 Bước 2: UI Level Protection

Có **3 cách** để implement UI blocking:

### Cách 1: Sử dụng Protected Widgets (Khuyến nghị ⭐)

Thay thế buttons thường bằng protected versions:

```dart
import 'package:your_app/core/widgets/test_protected_widgets.dart';

// BEFORE:
ElevatedButton(
  onPressed: () => _saveCV(),
  child: Text('Lưu CV'),
)

// AFTER:
TestProtectedButton(
  onPressed: () => _saveCV(),
  actionName: 'lưu CV',
  child: Text('Lưu CV'),
)
```

### Cách 2: Manual Check trong onPressed

```dart
import 'package:your_app/core/widgets/test_protected_widgets.dart';

ElevatedButton(
  onPressed: () async {
    // Check test account
    if (await checkTestAccount(context, 'lưu CV')) {
      return; // Blocked
    }
    
    // Normal flow
    await _saveCV();
  },
  child: Text('Lưu CV'),
)
```

### Cách 3: Check trong function

```dart
Future<void> _saveCV() async {
  // Check at function start
  if (await checkTestAccount(context, 'lưu CV')) {
    return;
  }
  
  // Actual save logic
  try {
    await cvRepository.create(...);
    // ...
  } catch (e) {
    // ...
  }
}
```

---

## 🎨 Widget Reference

### 1. TestProtectedButton

```dart
TestProtectedButton(
  onPressed: () => _doAction(),
  actionName: 'tạo việc làm',  // Vietnamese action name
  style: ElevatedButton.styleFrom(...),  // Optional
  isElevatedButton: true,  // true = ElevatedButton, false = TextButton
  child: Text('Tạo việc làm'),
)
```

### 2. TestProtectedIconButton

```dart
TestProtectedIconButton(
  onPressed: () => _deleteCV(),
  actionName: 'xóa CV',
  icon: Icon(Icons.delete),
  tooltip: 'Xóa CV',  // Optional
)
```

### 3. TestProtectedFAB

```dart
TestProtectedFAB(
  onPressed: () => _createNew(),
  actionName: 'tạo CV mới',
  tooltip: 'Tạo CV',
  child: Icon(Icons.add),
)
```

### 4. checkTestAccount (Manual)

```dart
Future<void> _handleSubmit() async {
  if (await checkTestAccount(context, 'gửi đơn ứng tuyển')) {
    return; // Blocked - dialog shown
  }
  
  // Continue with submit logic
  await _submitApplication();
}
```

---

## 📋 Danh sách Actions cần protect

### Candidate Screens

#### CV Management
- [x] `'tạo CV mới'` - Create CV button
- [x] `'lưu CV'` - Save CV button
- [x] `'sửa CV'` - Edit CV button
- [x] `'xóa CV'` - Delete CV button
- [x] `'upload ảnh CV'` - Upload avatar
- [x] `'thay đổi template'` - Change template

#### Job Application
- [x] `'ứng tuyển việc làm'` - Apply for job
- [x] `'rút đơn ứng tuyển'` - Withdraw application
- [x] `'lưu việc làm'` - Save/bookmark job

#### Profile & Settings
- [x] `'cập nhật thông tin'` - Update profile
- [x] `'thay đổi avatar'` - Change avatar
- [x] `'cập nhật kỹ năng'` - Update skills
- [x] `'thay đổi mật khẩu'` - Change password

#### Messages
- [x] `'gửi tin nhắn'` - Send message
- [x] `'xóa tin nhắn'` - Delete message

### Employer Screens

#### Job Posting
- [x] `'đăng việc làm'` - Post job
- [x] `'sửa việc làm'` - Edit job
- [x] `'xóa việc làm'` - Delete job
- [x] `'đóng tuyển dụng'` - Close job

#### Candidate Management
- [x] `'duyệt ứng viên'` - Approve candidate
- [x] `'từ chối ứng viên'` - Reject candidate
- [x] `'mời phỏng vấn'` - Invite to interview

#### Company Profile
- [x] `'cập nhật công ty'` - Update company info
- [x] `'thay đổi logo'` - Change logo

### School Screens

#### Partnership Jobs
- [x] `'tạo việc làm liên kết'` - Create partnership job
- [x] `'sửa việc làm'` - Edit partnership job
- [x] `'xóa việc làm'` - Delete partnership job

#### School Profile
- [x] `'cập nhật thông tin trường'` - Update school info

---

## 🔍 Example Implementations

### Example 1: CV Create Screen

```dart
// lib/screens/candidate/cv/create_cv_screen.dart

import '../../../core/widgets/test_protected_widgets.dart';

class CreateCVScreen extends StatefulWidget {
  // ...
}

class _CreateCVScreenState extends State<CreateCVScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tạo CV mới')),
      floatingActionButton: TestProtectedFAB(
        onPressed: _saveCV,
        actionName: 'lưu CV',
        tooltip: 'Lưu CV',
        child: Icon(Icons.save),
      ),
      body: Column(
        children: [
          // Form fields...
          
          Row(
            children: [
              TestProtectedButton(
                onPressed: _uploadPhoto,
                actionName: 'upload ảnh CV',
                child: Text('Chọn ảnh'),
              ),
              
              TestProtectedIconButton(
                onPressed: _changeTemplate,
                actionName: 'thay đổi template',
                icon: Icon(Icons.palette),
                tooltip: 'Đổi template',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveCV() async {
    // No need to check here - TestProtectedFAB already checked
    
    try {
      await cvRepository.create(...);
      // Success handling
    } on PostgrestException catch (e) {
      // Database blocked (RLS policy)
      if (e.message.contains('row-level security')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tài khoản demo không thể lưu dữ liệu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Other errors
    }
  }
}
```

### Example 2: Job Apply Button

```dart
// In job detail screen

TestProtectedButton(
  onPressed: () async {
    await _applyForJob(job.id);
  },
  actionName: 'ứng tuyển việc làm',
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    minimumSize: Size(double.infinity, 50),
  ),
  child: Text('Ứng tuyển ngay'),
)
```

### Example 3: Delete with Confirmation

```dart
TestProtectedIconButton(
  onPressed: () {
    // Show confirmation first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa CV này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCV();
            },
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  },
  actionName: 'xóa CV',
  icon: Icon(Icons.delete, color: Colors.red),
  tooltip: 'Xóa CV',
)
```

---

## 🧪 Testing Checklist

### Manual Testing

1. **Login as test account**
   - Email: `test-candidate@demo.com`
   - Password: `Demo123456!`

2. **Test UI Blocking**
   - [ ] Click "Tạo CV" → Warning dialog hiện
   - [ ] Click "Lưu CV" → Warning dialog hiện
   - [ ] Click "Xóa CV" → Warning dialog hiện
   - [ ] Click "Ứng tuyển" → Warning dialog hiện
   - [ ] Try to edit profile → Warning dialog hiện

3. **Test Database Blocking**
   - Even if you bypass UI, database should reject:
   - [ ] Try curl/Postman to INSERT → RLS error
   - [ ] Try curl/Postman to UPDATE → RLS error
   - [ ] Try curl/Postman to DELETE → RLS error

4. **Test Normal Account**
   - Login with normal account
   - [ ] All CUD operations should work normally

### Automated Testing (Optional)

```dart
testWidgets('Test account blocked from creating CV', (tester) async {
  // Setup test account
  await mockAuth(email: 'test-candidate@demo.com', isTest: true);
  
  // Navigate to create CV
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Tạo CV'));
  await tester.pumpAndSettle();
  
  // Try to save
  await tester.tap(find.byType(TestProtectedFAB));
  await tester.pumpAndSettle();
  
  // Verify warning dialog shown
  expect(find.text('Tài khoản Demo'), findsOneWidget);
  expect(find.text('Không thể thực hiện'), findsOneWidget);
});
```

---

## ⚠️ Important Notes

1. **Database protection là bắt buộc** - UI có thể bypass nhưng database không
2. **Action names phải rõ ràng** - Dùng tiếng Việt, cụ thể: "lưu CV" không phải "save"
3. **Test thoroughly** - Đảm bảo mọi CUD action đều được protect
4. **Don't over-protect** - Chỉ block CUD, không block Read/View
5. **Error handling** - Catch PostgrestException khi RLS blocks operation

## 📚 Summary

### What you need to do:

1. ✅ **Chạy SQL** `block_test_accounts.sql` trong Supabase
2. ✅ **Replace buttons** trong candidate/employer/school screens với `TestProtectedButton`
3. ✅ **Test** với test account
4. ✅ **Verify** database blocks operations

### Files created:

- `database/block_test_accounts.sql` - RLS policies
- `lib/core/widgets/test_protected_widgets.dart` - Protected widgets
- This guide - Implementation instructions

Enjoy your secure demo mode! 🎉
