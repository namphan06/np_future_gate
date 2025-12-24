# Test Account Guard - Implementation Guide

## Cách hoạt động

### 1. Auto-detect sau login
```
Login với email → AuthRepository.signInWithEmail()
    ↓
Check email in test list? → Yes → Set flag = true
    ↓
Fetch profile metadata → has is_test_account? → Yes → Set flag = true
    ↓
Flag được lưu trong TestAccountGuard.instance
```

### 2. Block tại repositories
```
User gọi cvRepository.create()
    ↓
Repository check: TestAccountGuard.instance.checkAndThrow()
    ↓
Is test account? → Yes → Throw TestAccountException
                → No → Continue normal flow
```

## Implementation trong Repositories

### Bước 1: Import Guard

```dart
import '../services/test_account_guard.dart';
```

### Bước 2: Add check vào CUD methods

#### Example: CVRepository

```dart
class CVRepository {
  
  /// CREATE
  Future<void> create(CVModel cv) async {
    // Check test account - throw if blocked
    TestAccountGuard.instance.checkAndThrow('tạo CV');
    
    // Normal logic
    await _supabase.from('cvs').insert(cv.toJson());
  }
  
  /// UPDATE
  Future<void> update(String cvId, Map<String, dynamic> data) async {
    TestAccountGuard.instance.checkAndThrow('cập nhật CV');
    
    await _supabase.from('cvs').update(data).eq('id', cvId);
  }
  
  /// DELETE
  Future<void> delete(String cvId) async {
    TestAccountGuard.instance.checkAndThrow('xóa CV');
    
    await _supabase.from('cvs').delete().eq('id', cvId);
  }
  
  /// READ - NO CHECK NEEDED
  Future<List<CVModel>> getAll() async {
    // Test accounts CAN read
    final response = await _supabase.from('cvs').select();
    return ...;
  }
}
```

#### Example: JobRepository

```dart
class JobRepository {
  
  Future<void> createJob(JobModel job) async {
    TestAccountGuard.instance.checkAndThrow('đăng việc làm');
    
    await _supabase.from('jobs').insert(job.toJson());
  }
  
  Future<void> updateJob(String jobId, JobModel job) async {
    TestAccountGuard.instance.checkAndThrow('cập nhật việc làm');
    
    await _supabase.from('jobs').update(job.toJson()).eq('id', jobId);
  }
  
  Future<void> deleteJob(String jobId) async {
    TestAccountGuard.instance.checkAndThrow('xóa việc làm');
    
    await _supabase.from('jobs').delete().eq('id', jobId);
  }
  
  Future<void> applyForJob(String jobId, String cvId) async {
    TestAccountGuard.instance.checkAndThrow('ứng tuyển việc làm');
    
    // Apply logic...
  }
}
```

#### Example: ProfileRepository

```dart
class ProfileRepository {
  
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    TestAccountGuard.instance.checkAndThrow('cập nhật thông tin');
    
    await _supabase.from('profiles').update(data).eq('id', userId);
  }
  
  Future<void> uploadAvatar(File file) async {
    TestAccountGuard.instance.checkAndThrow('thay đổi avatar');
    
    // Upload logic...
  }
}
```

## Error Handling trong UI

```dart
try {
  await cvRepository.create(newCV);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Tạo CV thành công!')),
  );
} on TestAccountException catch (e) {
  // Test account blocked
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.message),
      backgroundColor: Colors.orange,
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
    ),
  );
} catch (e) {
  // Other errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Lỗi: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Checklist - Repositories cần update

### ✅ Auth Repository
- [x] Initialize guard on login
- [x] Clear guard on logout

### ⏳ CV Repository
- [ ] `create()` - Tạo CV
- [ ] `update()` - Cập nhật CV
- [ ] `delete()` - Xóa CV
- [ ] `uploadImage()` - Upload ảnh

### ⏳ Job Repository
- [ ] `createJob()` - Tạo việc làm
- [ ] `updateJob()` - Sửa việc làm
- [ ] `deleteJob()` - Xóa việc làm
- [ ] `applyForJob()` - Ứng tuyển
- [ ]  `withdrawApplication()` - Rút đơn

### ⏳ Profile Repository
- [ ] `updateProfile()` - Cập nhật profile
- [ ] `uploadAvatar()` - Thay avatar
- [ ] `updatePassword()` - Đổi mật khẩu

### ⏳ Message Repository
- [ ] `sendMessage()` - Gửi tin nhắn
- [ ] `deleteMessage()` - Xóa tin nhắn

### ⏳ Partnership Job Repository
- [ ] `createPartnershipJob()` - Tạo việc liên kết
- [ ] `updatePartnershipJob()` - Sửa việc liên kết
- [ ] `deletePartnershipJob()` - Xóa việc liên kết

## Testing

### 1. Test Detection
```dart
// After login with test-candidate@demo.com
print(TestAccountGuard.instance.isTestAccount); // true
print(TestAccountGuard.instance.currentUserEmail); // test-candidate@demo.com
```

### 2. Test Blocking
```dart
// Try to create CV
try {
  await cvRepository.create(newCV);
  print('Created!');
} on TestAccountException catch (e) {
  print('Blocked: ${e.message}'); // Should print this
}
```

### 3. Test Normal Account
```dart
// Login with normal account
// ...
print(TestAccountGuard.instance.isTestAccount); // false

await cvRepository.create(newCV); // Should work
print('Success!');
```

## Summary

### ✅ Ưu điểm approach này:
1. **Không động database** - Chỉ code
2. **Centralized** - Tất cả logic ở một chỗ (TestAccountGuard)
3. **Auto-detect** - Không cần config gì thêm
4. **Type-safe** - Throw exception rõ ràng
5. **Easy debug** - Console logs clear

### 📝 TODO:
1. Add `TestAccountGuard.instance.checkAndThrow('action')` vào đầu mỗi CUD method trong repositories
2. UI catch `TestAccountException` và show friendly message
3. Test với tài khoản test
4. Done! ✅

Không cần sửa database, không cần sửa UI widgets, chỉ cần thêm 1 dòng vào mỗi repository method! 🎉
