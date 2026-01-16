# Notification Feature Documentation

## Tổng quan
Hệ thống thông báo hoàn chỉnh cho ứng dụng với khả năng:
- Gửi thông báo đến tất cả user, một user, hoặc nhiều user
- Phân loại thông báo theo type (info, success, warning, error, announcement, requirement, reminder)
- Hành động điều hướng dựa trên action code
- Lọc và phân trang
- Real-time updates
- Tự động xóa thông báo hết hạn

## Cấu trúc thư mục

```
lib/features/notification/
├── models/
│   ├── notification_config.dart      # Cấu hình action codes và navigation
│   └── notification_model.dart       # Model dữ liệu notification
├── repositories/
│   └── notification_repository.dart  # Xử lý database operations
├── services/
│   └── notification_service.dart     # Business logic và navigation
├── screens/
│   └── notifications_screen.dart     # Màn hình danh sách thông báo
├── widgets/
│   └── notification_item_widget.dart # UI components
├── actions/
│   ├── notification_action_handler.dart # Xử lý các action phức tạp
│   ├── actions.dart                  # Export file
│   └── README.md                     # Documentation
├── notification_navigation_setup.dart # Cấu hình navigation
└── notification_feature.dart         # Export file
```

## Các thành phần chính

### 1. NotificationActionCode (notification_config.dart)

Enum định nghĩa tất cả các mã hành động của hệ thống:

#### Job Related
- `job_detail` - Chi tiết công việc
- `job_approved` - Công việc được duyệt
- `job_rejected` - Công việc bị từ chối
- `new_job_posted` - Công việc mới
- `job_expiring` - Công việc sắp hết hạn

#### Application Related
- `application_received` - Nhận đơn ứng tuyển
- `application_approved` - Đơn được chấp nhận
- `application_rejected` - Đơn bị từ chối
- `application_viewed` - Đơn được xem

#### Interview Related
- `interview_schedule` - Lịch phỏng vấn
- `interview_updated` - Cập nhật lịch phỏng vấn
- `interview_canceled` - Hủy phỏng vấn
- `interview_reminder` - Nhắc phỏng vấn
- `interview_evaluated` - Đánh giá phỏng vấn

#### Partnership Related
- `partnership_request` - Yêu cầu liên kết
- `partnership_approved` - Liên kết được duyệt
- `partnership_rejected` - Liên kết bị từ chối
- `partnership_job_posted` - Công việc liên kết mới

#### System Related
- `system_update` - Cập nhật hệ thống
- `system_maintenance` - Bảo trì hệ thống
- `announcement` - Thông báo chung

### 2. NotificationType (notification_config.dart)

Enum định nghĩa loại thông báo:
- `info` - Thông tin (màu xanh dương)
- `success` - Thành công (màu xanh lá)
- `warning` - Cảnh báo (màu cam)
- `error` - Lỗi (màu đỏ)
- `announcement` - Thông báo (màu tím)
- `requirement` - Yêu cầu (màu vàng)
- `reminder` - Nhắc nhở (màu xanh ngọc)

Mỗi type có color, icon và displayName riêng.

### 3. NotificationConfigs (notification_config.dart)

Cấu hình navigation cho từng action code:

```dart
NotificationActionConfig(
  actionCode: NotificationActionCode.jobDetail,
  routeName: '/job-detail',
  extractRouteParams: (actionData) => {
    'jobId': actionData?['job_id'],
  },
)
```

- `routeName`: Tên route để navigate
- `extractRouteParams`: Function extract parameters từ action_data
- `showDialog`: True nếu chỉ hiển thị dialog, không navigate
- `dialogTitle`: Tiêu đề dialog (nếu có)

## Cách sử dụng

### 1. Tạo thông báo mới

#### Gửi đến tất cả users:
```dart
final service = NotificationService();
await service.notifySystemUpdate(
  title: 'Cập nhật hệ thống',
  content: 'Hệ thống sẽ bảo trì từ 2h-4h sáng ngày mai',
);
```

#### Gửi đến một user:
```dart
await service.notifyNewApplication(
  employerId: 'employer-uuid',
  jobId: 'job-uuid',
  jobTitle: 'Senior Developer',
  candidateName: 'Nguyễn Văn A',
);
```

#### Gửi đến nhiều users:
```dart
final repository = NotificationRepository();
await repository.createNotificationToUsers(
  userIds: ['uuid1', 'uuid2', 'uuid3'],
  title: 'Thông báo quan trọng',
  content: 'Nội dung thông báo...',
  actionCode: NotificationActionCode.announcement,
  type: NotificationType.announcement,
);
```

### 2. Tạo thông báo với action code tùy chỉnh

```dart
await repository.createNotificationToUser(
  userId: 'user-uuid',
  title: 'Lịch phỏng vấn mới',
  content: 'Bạn có lịch phỏng vấn...',
  actionCode: NotificationActionCode.interviewScheduled,
  actionData: {
    'interview_id': 'interview-uuid',
    'job_id': 'job-uuid',
  },
  type: NotificationType.requirement,
);
```

### 3. Hiển thị màn hình thông báo

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationsScreen(),
  ),
);
```

### 4. Hiển thị badge số thông báo chưa đọc

```dart
final repository = NotificationRepository();
final count = await repository.countUnreadNotifications(
  userId: currentUserId,
);

// Trong UI
NotificationBadge(
  count: count,
  child: IconButton(
    icon: const Icon(Icons.notifications),
    onPressed: () => Navigator.push(...),
  ),
)
```

### 5. Xử lý khi user tap vào notification

```dart
final service = NotificationService();
await service.handleNotificationTap(context, notification);
// Tự động:
// - Đánh dấu đã đọc
// - Navigate đến màn hình tương ứng (nếu có)
// - Hoặc hiển thị dialog (nếu không có navigation)
```

## Thêm Action Code mới

### Bước 1: Thêm vào enum NotificationActionCode

```dart
// Trong notification_config.dart
newActionCode('new_action_code', 'Mô tả', requiresNavigation: true),
```

### Bước 2: Thêm config vào NotificationConfigs

```dart
// Trong NotificationConfigs.configs
NotificationActionCode.newActionCode: NotificationActionConfig(
  actionCode: NotificationActionCode.newActionCode,
  routeName: '/new-route',
  extractRouteParams: (actionData) => {
    'param1': actionData?['param1'],
    'param2': actionData?['param2'],
  },
),
```

### Bước 3: Implement navigation trong NotificationService

```dart
// Trong _navigateToRoute method
case '/new-route':
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => NewScreen(
      param1: params['param1'],
      param2: params['param2'],
    ),
  ));
  break;
```

### Bước 4: Tạo helper method trong NotificationService (optional)

```dart
Future<void> notifyNewAction({
  required String userId,
  required String param1,
  required String param2,
}) async {
  await _repository.createNotificationToUser(
    userId: userId,
    title: 'Tiêu đề thông báo',
    content: 'Nội dung thông báo',
    actionCode: NotificationActionCode.newActionCode,
    actionData: {
      'param1': param1,
      'param2': param2,
    },
    type: NotificationType.info,
  );
}
```

## Action Handlers

### NotificationActionHandler

Xử lý các action phức tạp yêu cầu nhiều bước (data loading, type detection, navigation).

#### Ví dụ: Navigate đến Job Applicants

```dart
final actionHandler = NotificationActionHandler();

// Tự động detect job type (regular hoặc partnership)
// và navigate với đầy đủ applicants data
await actionHandler.navigateToJobApplicants(
  context: context,
  jobId: 'job-uuid',
  userId: 'candidate-uuid', // Optional - cho future scroll
);
```

Flow hoạt động:
1. Detect job type (check `school_partnership_jobs` table)
2. Load job model phù hợp (regular hoặc partnership)
3. Extract applicants từ `job.applicants`
4. Navigate đến `JobApplicantsScreen` với đầy đủ data
5. Show loading/error/empty state khi cần

Chi tiết: Xem `lib/features/notification/actions/README.md`

## Database Schema

Xem file `database/table/notifications` cho schema đầy đủ:
- Table: `notifications`
- Table: `notification_reads`
- Functions: `get_unread_notifications()`, `count_unread_notifications()`, `delete_expired_notifications()`
- Trigger: `auto_cleanup_expired_notifications` (tự động xóa khi insert)

## API Reference

### NotificationRepository

#### Methods:
- `getNotifications()` - Lấy danh sách thông báo (có phân trang)
- `getUnreadNotifications()` - Lấy thông báo chưa đọc
- `countUnreadNotifications()` - Đếm số thông báo chưa đọc
- `markAsRead()` - Đánh dấu đã đọc
- `markAllAsRead()` - Đánh dấu tất cả đã đọc
- `createNotificationToAll()` - Gửi đến tất cả
- `createNotificationToUser()` - Gửi đến 1 user
- `createNotificationToUsers()` - Gửi đến nhiều users
- `watchNotifications()` - Stream realtime updates

### NotificationService

#### Methods:
- `handleNotificationTap()` - Xử lý khi tap vào notification
- `notifyNewApplication()` - Thông báo đơn ứng tuyển mới
- `notifyInterviewScheduled()` - Thông báo lịch phỏng vấn
- `notifyJobApproved()` - Thông báo công việc được duyệt
- `notifyJobRejected()` - Thông báo công việc bị từ chối
- `notifyPartnershipRequest()` - Thông báo yêu cầu liên kết
- `notifySystemUpdate()` - Thông báo cập nhật hệ thống
- `notifyInterviewReminder()` - Nhắc nhở phỏng vấn

## Notes

1. **recipient_ids format:**
   - `'all'` - Gửi đến tất cả
   - `'uuid'` - Gửi đến 1 user
   - `'["uuid1","uuid2"]'` - Gửi đến nhiều users

2. **Expires At:**
   - Mặc định 30 ngày từ khi tạo
   - Tự động xóa khi có notification mới được insert (trigger)
   - Có thể gọi manual: `deleteExpiredNotifications()`

3. **Navigation:**
   - Cần implement routes trong `_navigateToRoute` method của NotificationService
   - Action code có `requiresNavigation: false` sẽ chỉ hiển thị dialog

4. **Real-time:**
   - Sử dụng `watchNotifications()` để nhận updates realtime
   - Supabase Realtime phải được enable cho table `notifications`

5. **Permissions:**
   - RLS policies đã được setup
   - Admin/System cần role riêng để create notifications (hiện đang comment)
