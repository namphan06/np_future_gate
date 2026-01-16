# Notification Actions

Folder này chứa các action handler để xử lý navigation từ notification.

## Files

### notification_action_handler.dart

Class chính xử lý các action từ notification, đặc biệt là navigation đến job applicants screen.

#### Chức năng chính:

1. **navigateToJobApplicants()** - Navigate đến danh sách ứng viên
   - Tự động phát hiện job type (regular hoặc partnership)
   - Load danh sách applicants phù hợp
   - Navigate đến JobApplicantsScreen với đầy đủ thông tin
   - Hỗ trợ optional userId để scroll đến ứng viên cụ thể (future feature)

2. **navigateToEmployerJobs()** - Navigate đến danh sách tất cả jobs của employer

#### Cơ chế hoạt động:

```
Notification Click
    ↓
NotificationService.handleNotificationTap()
    ↓
notification_navigation_setup._handleNavigate()
    ↓
NotificationActionHandler.navigateToJobApplicants()
    ↓
1. Detect job type (_isPartnershipJob)
    ├─ Check school_partnership_jobs table
    └─ Return true/false
    ↓
2. Load job model (_loadJob)
    ├─ If partnership: getPartnershipJobById()
    └─ If regular: getJobById()
    ↓
3. Extract applicants from job.applicants
    ↓
4. Navigate to JobApplicantsScreen
    └─ Pass: jobId, applicants, isPartnershipJob
```

#### Usage trong notification_navigation_setup.dart:

```dart
case NotificationActionCode.applicationReceived:
  final jobId = params['jobId'] as String?;
  final userId = params['userId'] as String?;
  
  if (jobId != null) {
    await actionHandler.navigateToJobApplicants(
      context: context,
      jobId: jobId,
      userId: userId, // Optional
    );
  }
  break;
```

#### Lưu ý:

- **Job Type Detection**: Tự động kiểm tra table `school_partnership_jobs` để xác định job type
- **Error Handling**: Có dialog thông báo lỗi nếu không load được applicants
- **Empty State**: Có dialog thông báo nếu job chưa có applicants
- **Loading State**: Hiển thị loading indicator trong quá trình load data
- **Future Enhancement**: userId có thể dùng để scroll đến applicant cụ thể sau khi navigate

## Mở rộng

Để thêm action mới:

1. Thêm method vào `NotificationActionHandler`
2. Update `notification_navigation_setup.dart` để gọi method mới
3. Update documentation này

## Dependencies

- `job_repository.dart` - Load applicants data
- `employer_jobs_screen.dart` - Employer jobs list screen
- `job_applicants_screen.dart` - Job applicants detail screen
- `supabase_flutter` - Database queries
