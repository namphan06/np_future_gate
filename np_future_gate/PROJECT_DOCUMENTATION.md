# NP FutureGate - Tài Liệu Tổng Hợp Dự Án

## 📋 Mục Lục

1. [Tổng Quan Dự Án](#tổng-quan-dự-án)
2. [Kiến Trúc Hệ Thống](#kiến-trúc-hệ-thống)
3. [Công Nghệ Sử Dụng](#công-nghệ-sử-dụng)
4. [Cơ Sở Dữ Liệu](#cơ-sở-dữ-liệu)
5. [Tính Năng Chính](#tính-năng-chính)
6. [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
7. [API và Services](#api-và-services)
8. [User Roles](#user-roles)
9. [Hướng Dẫn Phát Triển Web](#hướng-dẫn-phát-triển-web)

---

## 🎯 Tổng Quan Dự Án

**NP FutureGate** là một ứng dụng tuyển dụng toàn diện kết nối ứng viên, nhà tuyển dụng và trường học.

### Mục tiêu
- Kết nối ứng viên với cơ hội việc làm phù hợp
- Hỗ trợ nhà tuyển dụng tìm kiếm và quản lý ứng viên
- Tạo cầu nối giữa trường học và doanh nghiệp
- Quản lý toàn bộ quy trình tuyển dụng từ đăng tin đến phỏng vấn

### Thông tin cơ bản
- **Version**: 1.0.0+1
- **SDK**: Dart ^3.9.2
- **Framework**: Flutter
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Authentication**: Email/Password + Google Sign-In

---

## 🏗️ Kiến Trúc Hệ Thống

### Clean Architecture Pattern

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│    (Screens, Widgets, UI Components)    │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│          Repository Layer               │
│  (Business Logic, Data Management)      │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           Service Layer                 │
│   (Supabase, Firebase, External APIs)   │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│            Data Layer                   │
│        (Models, Enums, Config)          │
└─────────────────────────────────────────┘
```

### Phân tách trách nhiệm

1. **Models** (`lib/core/models/`)
   - Data classes cho entities
   - JSON serialization/deserialization
   - Business models

2. **Repositories** (`lib/core/repositories/`)
   - Business logic
   - Data transformations
   - Error handling
   - API calls

3. **Services** (`lib/core/services/`)
   - External API integrations
   - Firebase services
   - Supabase client management
   - Notification services

4. **Screens** (`lib/screens/`)
   - UI components
   - User interactions
   - State management
   - Navigation

---

## 🛠️ Công Nghệ Sử Dụng

### Core Dependencies

```yaml
# Backend & Database
supabase_flutter: ^2.9.1         # Supabase client
flutter_dotenv: ^5.2.1           # Environment variables

# Authentication
google_sign_in: ^6.2.2           # Google OAuth

# Firebase
firebase_core: ^3.10.0           # Firebase core
firebase_messaging: ^15.2.0      # Push notifications
googleapis_auth: ^1.6.0          # FCM V1 API OAuth2

# File & Media
file_picker: ^8.1.6              # File selection
image_picker: ^1.2.1             # Image selection
syncfusion_flutter_pdfviewer: ^32.1.1  # PDF viewer

# UI Components
flutter_svg: ^2.2.3              # SVG support
cupertino_icons: ^1.0.8          # iOS icons

# Utilities
intl: ^0.20.2                    # Internationalization & date formatting
url_launcher: ^6.3.2             # URL launching
share_plus: ^12.0.1              # Sharing functionality
http: ^1.6.0                     # HTTP requests

# Voice Input
speech_to_text: ^7.3.0           # Speech recognition
permission_handler: ^12.0.1      # Permission management

# Device Info
device_info_plus: ^12.3.0        # Device information
package_info_plus: ^9.0.0        # App information

# Notifications
flutter_local_notifications: ^18.0.1  # Local notifications
```

### Assets
- Logo và images: `assets/logo/`
- Environment variables: `.env` file

---

## 💾 Cơ Sở Dữ Liệu

### Supabase Schema

#### 1. **profiles** - Hồ sơ người dùng

```sql
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text,
  avatar_url text,
  phone text,
  role user_role NOT NULL DEFAULT 'candidate',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Enum for user roles
CREATE TYPE public.user_role AS ENUM ('candidate', 'employer', 'school', 'admin');
```

**Metadata structure** (JSONB):
```json
{
  "date_of_birth": "1995-01-01",
  "address": "Hà Nội",
  "work_locations": ["Hà Nội", "TP HCM"],
  "education": "Đại học",
  "bio": "Lý do thuê tôi...",
  "interested_fields": ["IT Phần mềm", "Mobile App"],
  "work_types": ["Full-time", "Remote"],
  "cv_ids": ["uuid1", "uuid2"],
  "experience": [{
    "company": "ABC",
    "position": "Developer",
    "from": "2020-01",
    "to": "2022-12"
  }],
  "security": false
}
```

#### 2. **jobs** - Tin tuyển dụng

```sql
CREATE TABLE public.jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  creator_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_active boolean DEFAULT true,
  deadline timestamptz,
  metadata jsonb DEFAULT '{}'::jsonb,
  applicants jsonb DEFAULT '[]'::jsonb,
  view_count integer DEFAULT 0,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'closed'))
);
```

**Job Metadata Structure**:
```json
{
  "title": "Senior Flutter Developer",
  "working_regions": ["Hà Nội", "Remote"],
  "experience_required": "2-3 năm",
  "fields": ["IT Phần mềm", "Mobile App"],
  "requirements_tags": ["Flutter", "Dart", "Firebase"],
  "salary": {
    "min": 1000,
    "max": 2000,
    "currency": "USD",
    "is_negotiable": false,
    "type": "monthly"
  },
  "employment_types": ["Full-time", "Remote"],
  "work_locations": ["Tòa nhà A, Cầu Giấy"],
  "job_description": ["Phát triển ứng dụng mobile", "Code review"],
  "candidate_requirements": ["2+ năm Flutter", "Tiếng Anh tốt"],
  "benefits": ["Bảo hiểm", "Laptop", "Du lịch hàng năm"]
}
```

**Applicants Structure**:
```json
[
  {
    "user_id": "uuid...",
    "cv_id": "uuid...",
    "applied_at": "2024-01-01T10:00:00Z",
    "status": "pending"
  }
]
```

#### 3. **school_partnership_jobs** - Việc làm hợp tác từ trường học

```sql
CREATE TABLE public.school_partnership_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  school_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_status text DEFAULT 'pending' CHECK (company_status IN ('pending', 'accepted', 'rejected')),
  company_reviewed_at timestamptz,
  company_rejection_reason text,
  admin_status text DEFAULT 'pending' CHECK (admin_status IN ('pending', 'approved', 'rejected')),
  admin_reviewed_at timestamptz,
  admin_rejection_reason text,
  is_active boolean DEFAULT true,
  deadline timestamptz,
  metadata jsonb DEFAULT '{}'::jsonb,
  applicants jsonb DEFAULT '[]'::jsonb,
  view_count integer DEFAULT 0
);
```

**Workflow**: Trường tạo → Công ty duyệt → Admin duyệt → Xuất bản

#### 4. **cv_templates** - Quản lý CV

```sql
CREATE TABLE public.cv_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  data jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

#### 5. **interview_schedules** - Lịch phỏng vấn

```sql
CREATE TABLE public.interview_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid,  -- Có thể reference jobs hoặc school_partnership_jobs
  employer_id uuid NOT NULL REFERENCES auth.users(id),
  cv_id uuid,
  interview_time timestamptz NOT NULL,
  job_title text NOT NULL,
  evaluation jsonb DEFAULT '{}'::jsonb,
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now()
);
```

#### 6. **device_tokens** - Push notification tokens

```sql
CREATE TABLE public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id text NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL,
  device_type text,
  device_name text,
  app_version text,
  is_active boolean DEFAULT true,
  last_login_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

#### 7. **conversations** & **messages** - Chat system

```sql
CREATE TABLE public.conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant1_id uuid NOT NULL,
  participant1_type text NOT NULL,
  participant2_id uuid NOT NULL,
  participant2_type text NOT NULL,
  job_id uuid,
  application_id text,
  last_message text,
  last_message_at timestamptz,
  last_message_sender_id uuid,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL,
  content text NOT NULL,
  message_type text DEFAULT 'text',
  attachment_url text,
  attachment_name text,
  attachment_size integer,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
```

#### 8. **user_job_activities** - Lưu & theo dõi công việc

```sql
CREATE TABLE public.user_job_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  activity_type text CHECK (activity_type IN ('saved', 'applied', 'viewed')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, job_id, activity_type)
);
```

#### 9. **company_followers** - Theo dõi công ty

```sql
CREATE TABLE public.company_followers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES auth.users(id),
  follower_id uuid NOT NULL REFERENCES auth.users(id),
  followed_at timestamptz DEFAULT now(),
  UNIQUE(company_id, follower_id)
);
```

### Supabase RPC Functions

#### apply_to_job
```sql
CREATE FUNCTION public.apply_to_job(
  p_job_id uuid,
  p_user_id uuid,
  p_cv_id uuid
) RETURNS void
```
Xử lý logic ứng tuyển vào công việc.

#### apply_to_partnership_job
```sql
CREATE FUNCTION public.apply_to_partnership_job(
  p_job_id uuid,
  p_user_id uuid,
  p_cv_id uuid
) RETURNS void
```
Xử lý logic ứng tuyển vào công việc hợp tác từ trường.

#### upsert_device_token
```sql
CREATE FUNCTION public.upsert_device_token(
  p_device_id text,
  p_user_id uuid,
  p_role text,
  p_device_type text,
  p_device_name text,
  p_app_version text
) RETURNS uuid
```
Lưu/cập nhật FCM token cho push notifications.

---

## ✨ Tính Năng Chính

### 1. Authentication & Authorization

**Các phương thức đăng nhập**:
- Email/Password
- Google Sign-In

**User Roles**:
- `candidate` (Ứng viên)
- `employer` (Nhà tuyển dụng)
- `school` (Nhà trường)
- `admin` (Quản trị viên)

**Tính năng auth**:
- Sign up với thông tin đầy đủ (họ tên, SĐT, role)
- Sign in
- Sign out
- Password reset
- Profile management
- Avatar upload to Supabase Storage

### 2. Job Management (Quản lý công việc)

#### Cho Employer:
- ✅ Đăng tin tuyển dụng
- ✅ Chỉnh sửa/xóa tin đã đăng
- ✅ Xem danh sách ứng viên
- ✅ Quản lý trạng thái ứng viên (pending/accepted/rejected)
- ✅ Thống kê (tổng tin đăng, ứng viên mới, lượt xem)
- ✅ Lọc và tìm kiếm ứng viên

#### Cho Candidate:
- ✅ Tìm kiếm công việc
- ✅ Lọc theo: vị trí, lĩnh vực, mức lương, kinh nghiệm
- ✅ Xem chi tiết công việc
- ✅ Ứng tuyển với CV
- ✅ Lưu công việc yêu thích
- ✅ Theo dõi công ty
- ✅ Xem lịch sử ứng tuyển
- ✅ Xem công việc đã lưu

#### Cho School:
- ✅ Tạo tin tuyển dụng partnership cho công ty
- ✅ Quản lý email trường (phục vụ gửi application)
- ✅ Xem danh sách partnership requests
- ✅ Theo dõi trạng thái duyệt (công ty + admin)

### 3. CV Management

- ✅ Tải lên CV (PDF, DOC, DOCX)
- ✅ Quản lý nhiều CV
- ✅ Xem trước CV (PDF viewer tích hợp)
- ✅ Chọn CV khi ứng tuyển
- ✅ Upload/download CV từ Supabase Storage
- ✅ Tự động parse CV data (metadata)

### 4. Interview Scheduling

- ✅ Employer tạo lịch phỏng vấn
- ✅ Chọn thời gian phỏng vấn
- ✅ Phát hiện xung đột lịch
- ✅ Xem danh sách lịch phỏng vấn
- ✅ Sắp xếp theo thời gian
- ✅ Đánh giá sau phỏng vấn
- ✅ Hỗ trợ cả jobs và partnership jobs

### 5. Chat System

**Realtime Chat**:
- ✅ Chat giữa candidate và employer
- ✅ Nhóm chat theo job application
- ✅ Realtime updates (Supabase Realtime)
- ✅ Unread message count
- ✅ Message history
- ✅ File attachments support

**Chat Features**:
- Text messages
- File sharing
- Mark as read
- Conversation list
- Delete messages/conversations

### 6. Push Notifications (FCM)

- ✅ Firebase Cloud Messaging integration
- ✅ Device token management
- ✅ Foreground notifications
- ✅ Background notifications
- ✅ Notification click handling
- ✅ Send notifications by role
- ✅ Multi-device support

**Notification triggers**:
- Tin tuyển dụng mới
- Ứng viên mới ứng tuyển
- Lịch phỏng vấn
- Tin nhắn mới
- Trạng thái đơn ứng tuyển thay đổi

### 7. Voice Input

- ✅ Speech-to-text cho các trường nhập liệu
- ✅ Vietnamese language support
- ✅ Permission handling
- ✅ Custom speech text field widget

### 8. Search & Filter

**Job Search**:
- Tìm kiếm theo từ khóa
- Lọc theo vị trí
- Lọc theo lĩnh vực
- Lọc theo mức lương
- Lọc theo kinh nghiệm
- Lọc theo loại công việc

**Candidate Search** (Employer):
- Tìm kiếm theo tên
- Lọc theo kỹ năng
- Lọc theo kinh nghiệm
- Lọc theo vị trí
- Lọc theo lĩnh vực

### 9. Company Management

- ✅ Company profile
- ✅ Follower count
- ✅ Job postings
- ✅ Company details
- ✅ Follow/Unfollow

### 10. Admin Features

- ✅ User management
- ✅ Content moderation (duyệt tin)
- ✅ Dashboard thống kê
- ✅ Test notification system
- ✅ Quản lý partnership jobs

---

## 📁 Cấu Trúc Dự Án

```
np_future_gate/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   └── supabase_config.dart
│   │   ├── enums/
│   │   │   ├── employment_types.dart
│   │   │   ├── experience_levels.dart
│   │   │   ├── job_fields.dart
│   │   │   └── vietnam_provinces.dart
│   │   ├── models/
│   │   │   ├── auth_models.dart           # AuthResult, UserRole
│   │   │   ├── profile_model.dart         # Profile
│   │   │   ├── job_model.dart             # JobModel, JobMetadata, JobSalary
│   │   │   ├── cv_model.dart              # CVModel
│   │   │   ├── interview_model.dart       # InterviewModel
│   │   │   ├── conversation_model.dart    # ConversationModel
│   │   │   ├── message_model.dart         # MessageModel
│   │   │   ├── device_token_model.dart    # DeviceTokenModel
│   │   │   └── user_job_activity_model.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── job_repository.dart
│   │   │   ├── candidate_repository.dart
│   │   │   ├── company_repository.dart
│   │   │   ├── interview_repository.dart
│   │   │   └── device_token_repository.dart
│   │   ├── services/
│   │   │   ├── supabase_service.dart
│   │   │   ├── fcm_service.dart
│   │   │   ├── push_notification_service.dart
│   │   │   ├── chat_service.dart
│   │   │   └── cv_supabase_service.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   ├── candidate/
│   │   │   ├── candidate_home_screen.dart
│   │   │   ├── home_page_candidate.dart
│   │   │   ├── search_page_candidate.dart
│   │   │   ├── job_detail_screen.dart
│   │   │   ├── applied_jobs_screen.dart
│   │   │   ├── saved_jobs_screen.dart
│   │   │   ├── companies_list_screen.dart
│   │   │   ├── company_detail_screen.dart
│   │   │   ├── school_jobs_screen.dart
│   │   │   ├── settings_page_candidate.dart
│   │   │   └── tools_page_candidate.dart
│   │   ├── employer/
│   │   │   ├── employer_home_screen.dart
│   │   │   ├── home_page_employer.dart
│   │   │   ├── search_page_employer.dart
│   │   │   ├── profile_page_employer.dart
│   │   │   ├── edit_company_profile_screen.dart
│   │   │   ├── interview_schedule_screen.dart
│   │   │   ├── interview_detail_screen.dart
│   │   │   ├── saved_candidates_screen.dart
│   │   │   ├── partnership_requests_employer_screen.dart
│   │   │   ├── tools_page_employer.dart
│   │   │   └── jobs/
│   │   │       ├── employer_jobs_screen.dart
│   │   │       ├── edit_job_screen.dart
│   │   │       ├── job_applicants_screen.dart
│   │   │       └── recent_applicants_screen.dart
│   │   ├── school/
│   │   │   ├── school_home_screen.dart
│   │   │   ├── home_page_school.dart
│   │   │   ├── search_page_school.dart
│   │   │   ├── settings_page_school.dart
│   │   │   ├── tools_page_school.dart
│   │   │   ├── school_email_setup_screen.dart
│   │   │   ├── jobs/
│   │   │   └── partnership/
│   │   ├── admin/
│   │   │   ├── admin_home_screen.dart
│   │   │   ├── dashboard_page_admin.dart
│   │   │   ├── users_management_page_admin.dart
│   │   │   ├── content_management_page_admin.dart
│   │   │   ├── reports_page_admin.dart
│   │   │   ├── settings_page_admin.dart
│   │   │   └── test_page_admin.dart
│   │   ├── cv/
│   │   │   ├── cv_management_screen.dart
│   │   │   ├── cv_upload_edit_screen.dart
│   │   │   └── cv_selection_screen.dart
│   │   ├── chat/
│   │   │   ├── chat_list_screen.dart
│   │   │   └── chat_screen.dart
│   │   ├── profile/
│   │   │   └── edit_profile_screen.dart
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   └── demo/
│   │       └── speech_text_field_demo_screen.dart
│   ├── widgets/
│   │   ├── animated_avatar.dart
│   │   ├── chat_floating_overlay.dart
│   │   ├── draggable_floating_button.dart
│   │   ├── global_floating_chat_button.dart
│   │   ├── speech_text_field.dart
│   │   ├── buttons/
│   │   ├── cards/
│   │   ├── inputs/
│   │   └── navigation/
│   ├── firebase_options.dart
│   └── main.dart
├── database/
│   ├── table/
│   │   ├── profile
│   │   ├── jobs
│   │   ├── school_partnership_jobs
│   │   ├── cv_templates
│   │   └── create_device_tokens_table.sql
│   ├── policy/
│   ├── chat/
│   ├── migrations/
│   ├── apply_to_job
│   ├── apply_to_partnership_job
│   ├── company_followers
│   ├── interviews_schedule
│   └── user_job_activities
├── assets/
│   └── logo/
├── android/
├── ios/
├── web/
├── .env
├── pubspec.yaml
├── README.md
├── SUPABASE_AUTH_GUIDE.md
└── PUSH_NOTIFICATION_SETUP.md
```

---

## 🔌 API và Services

### 1. AuthRepository

**Methods**:
```dart
// Authentication
Future<AuthResult> signUpWithEmail({email, password, fullName, phone, role})
Future<AuthResult> signInWithEmail({email, password})
Future<AuthResult> signInWithGoogle()
Future<AuthResult> signOut({deviceToken})
Future<AuthResult> resetPassword({email})

// Profile Management
Future<Profile?> getCurrentUserProfile()
Future<AuthResult> updateProfile({userId, fullName, phone, avatarUrl, metadata})
Future<String> uploadAvatar(File file, String userId)
Future<AuthResult> updatePassword(String newPassword)
Future<List<Profile>> getProfilesByIds(List<String> userIds)

// Device Token
Future<void> saveDeviceToken({deviceToken, userId, role})
```

### 2. JobRepository

**Methods**:
```dart
// Job CRUD
Future<void> createJob(JobModel job)
Future<void> updateJob(JobModel job)
Future<void> deleteJob(String jobId)
Future<JobModel?> getJobById(String jobId)

// Job Listing
Future<List<JobModel>> getEmployerJobs(String creatorId)
Future<List<JobModel>> getRecentEmployerJobs(String creatorId, {int limit})
Future<List<JobModel>> getActiveJobs()

// Application Management
Future<void> applyForJob(String jobId, String userId, String cvId)
Future<bool> hasApplied(String userId, String jobId)
Future<void> updateApplicationStatus(String jobId, String userId, String newStatus)
Future<void> deleteApplication(String jobId, String userId)

// Saved Jobs
Future<void> toggleSaveJob(String userId, String jobId)
Future<List<String>> getSavedJobIds(String userId)
Future<List<JobModel>> getSavedJobs(String userId)

// Statistics
Future<Map<String, dynamic>> getEmployerStats(String employerId)
Future<List<dynamic>> getRecentApplications(String employerId, {int limit})

// Partnership Jobs
Future<List<JobModel>> getEmployerPartnershipJobs(String companyId)
Future<void> applyForPartnershipJob(String jobId, String userId, String cvId)
Future<bool> hasAppliedToPartnershipJob(String userId, String jobId)
Future<JobModel?> getPartnershipJobById(String jobId)

// Streams
Stream<List<JobModel>> getEmployerJobsStream(String creatorId)
Stream<List<JobModel>> getSavedJobsStream(String userId)
Stream<List<JobModel>> getAppliedJobsStream(String userId)
```

### 3. InterviewRepository

**Methods**:
```dart
Future<void> createInterview(InterviewModel interview)
Future<List<InterviewModel>> getEmployerInterviews(String employerId)
Future<List<InterviewModel>> getCandidateInterviews(String candidateId)
Future<void> updateInterviewStatus(String id, String status)
Future<void> updateInterviewEvaluation(String id, Map<String, dynamic> evaluation)
Future<bool> hasInterviewConflict(String employerId, DateTime interviewTime)
```

### 4. ChatService

**Methods**:
```dart
Future<List<ConversationModel>> getConversations()
Future<ConversationModel> getOrCreateConversation({otherUserId, otherUserType, jobId})
Future<List<MessageModel>> getMessages(String conversationId)
Future<void> sendMessage({conversationId, content, messageType, attachmentUrl, ...})
Future<void> markAsRead(String conversationId)
Future<int> getUnreadCount(String conversationId)
Future<void> deleteConversation(String conversationId)
Future<void> deleteMessage(String messageId)

// Streams
Stream<List<MessageModel>> streamMessages(String conversationId)
Stream<List<ConversationModel>> streamConversations()
```

### 5. FCMService

**Methods**:
```dart
Future<void> initialize()
String? get fcmToken
void handleForegroundMessage(RemoteMessage message)
void handleBackgroundMessage(RemoteMessage message)
void handleNotificationClick(RemoteMessage message)
```

### 6. PushNotificationService

**Methods**:
```dart
Future<void> sendNotificationToUser({userId, title, body, data})
Future<void> sendNotificationToRole({role, title, body, data})
Future<void> sendNotificationToDevices({deviceTokens, title, body, data})
```

### 7. CVSupabaseService

**Methods**:
```dart
Future<List<CVModel>> getUserCVs(String userId)
Future<String> uploadCV(File file, String userId, String fileName)
Future<void> deleteCV(String cvId, String userId)
Future<String?> getCVDownloadUrl(String userId, String fileName)
```

---

## 👥 User Roles

### 1. Candidate (Ứng viên)

**Home Screen**:
- Danh sách công việc đề xuất
- Công việc đã lưu
- Công ty đang theo dõi
- Thống kê (số việc đã ứng tuyển, đã lưu)

**Features**:
- Tìm kiếm & lọc công việc
- Xem chi tiết công việc
- Ứng tuyển với CV
- Lưu công việc yêu thích
- Theo dõi công ty
- Quản lý CV
- Xem lịch phỏng vấn
- Chat với nhà tuyển dụng
- Cập nhật profile

**Screens**:
- Home Page
- Search Page
- Job Detail
- Applied Jobs
- Saved Jobs
- Companies List
- Company Detail
- CV Management
- Settings

### 2. Employer (Nhà tuyển dụng)

**Home Screen**:
- Thống kê (tổng tin đăng, ứng viên mới, lượt xem)
- Tin tuyển dụng gần đây
- Ứng viên mới ứng tuyển
- Partnership requests

**Features**:
- Đăng tin tuyển dụng
- Quản lý tin đã đăng
- Xem & quản lý ứng viên
- Tìm kiếm ứng viên
- Lưu ứng viên tiềm năng
- Tạo lịch phỏng vấn
- Đánh giá sau phỏng vấn
- Chat với ứng viên
- Xem partnership requests
- Cập nhật company profile

**Screens**:
- Home Page
- Jobs Management
- Job Applicants
- Search Candidates
- Saved Candidates
- Interview Schedule
- Interview Detail
- Partnership Requests
- Company Profile
- Tools Page

### 3. School (Nhà trường)

**Home Screen**:
- Thống kê partnership jobs
- Danh sách công ty hợp tác
- Partnership requests

**Features**:
- Tạo tin tuyển dụng partnership
- Gửi partnership request cho công ty
- Theo dõi trạng thái duyệt
- Quản lý email trường
- Tìm kiếm công ty
- Xem chi tiết công ty

**Screens**:
- Home Page
- Partnership Jobs
- Create Partnership Job
- Partnership Requests
- Email Setup
- Search Companies
- Settings

### 4. Admin (Quản trị viên)

**Dashboard**:
- Thống kê tổng quan
- Số lượng users theo role
- Số lượng jobs
- Hoạt động gần đây

**Features**:
- Quản lý users
- Duyệt tin tuyển dụng
- Duyệt partnership jobs
- Xem báo cáo
- Test push notifications
- Quản lý nội dung
- Cài đặt hệ thống

**Screens**:
- Dashboard
- Users Management
- Content Management
- Reports
- Test Page
- Settings

---

## 🌐 Hướng Dẫn Phát Triển Web

### Tech Stack Đề Xuất

**Frontend Framework**:
- **Next.js 14+** (React framework with App Router)
- **TypeScript** cho type safety
- **Tailwind CSS** cho styling
- **Shadcn/ui** cho UI components

**State Management**:
- **Zustand** hoặc **React Context** cho global state
- **React Query** (TanStack Query) cho server state

**Backend Integration**:
- **Supabase JavaScript Client** (`@supabase/supabase-js`)
- **Supabase Auth Helpers** cho Next.js

**Additional Libraries**:
- **React Hook Form** cho form handling
- **Zod** cho validation
- **date-fns** hoặc **dayjs** cho date manipulation
- **React PDF** cho PDF viewing
- **Socket.io** hoặc Supabase Realtime cho chat

### Project Structure (Next.js)

```
web-app/
├── app/
│   ├── (auth)/
│   │   ├── login/
│   │   ├── register/
│   │   └── reset-password/
│   ├── (candidate)/
│   │   ├── dashboard/
│   │   ├── jobs/
│   │   ├── applied/
│   │   ├── saved/
│   │   └── profile/
│   ├── (employer)/
│   │   ├── dashboard/
│   │   ├── jobs/
│   │   ├── applicants/
│   │   ├── interviews/
│   │   └── profile/
│   ├── (school)/
│   │   ├── dashboard/
│   │   ├── partnerships/
│   │   └── profile/
│   ├── (admin)/
│   │   ├── dashboard/
│   │   ├── users/
│   │   ├── jobs/
│   │   └── settings/
│   ├── api/
│   │   ├── auth/
│   │   ├── jobs/
│   │   ├── notifications/
│   │   └── chat/
│   └── layout.tsx
├── components/
│   ├── ui/                    # Shadcn components
│   ├── auth/
│   ├── jobs/
│   ├── chat/
│   └── shared/
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   └── middleware.ts
│   ├── hooks/
│   ├── utils/
│   └── types/
├── public/
└── styles/
```

### Models Migration (TypeScript)

```typescript
// types/profile.ts
export enum UserRole {
  CANDIDATE = 'candidate',
  EMPLOYER = 'employer',
  SCHOOL = 'school',
  ADMIN = 'admin'
}

export interface Profile {
  id: string;
  email?: string;
  full_name?: string;
  avatar_url?: string;
  phone?: string;
  role: UserRole;
  metadata: Record<string, any>;
  created_at: string;
  updated_at: string;
}

// types/job.ts
export interface JobSalary {
  min?: number;
  max?: number;
  currency: string;
  is_negotiable: boolean;
  type: 'monthly' | 'hourly' | 'yearly';
}

export interface JobMetadata {
  title: string;
  working_regions: string[];
  experience_required: string;
  fields: string[];
  requirements_tags: string[];
  salary: JobSalary;
  employment_types: string[];
  work_locations: string[];
  job_description: string[];
  candidate_requirements: string[];
  benefits: string[];
}

export interface JobApplication {
  user_id: string;
  cv_id: string;
  applied_at: string;
  status: 'pending' | 'accepted' | 'rejected';
}

export interface Job {
  id: string;
  creator_id: string;
  created_at: string;
  updated_at: string;
  is_active: boolean;
  deadline?: string;
  metadata: JobMetadata;
  applicants: JobApplication[];
  view_count: number;
  status: 'pending' | 'approved' | 'rejected' | 'closed';
  creator_name?: string;
  creator_avatar_url?: string;
}

// types/interview.ts
export interface Interview {
  id: string;
  candidate_id: string;
  job_id: string;
  employer_id: string;
  cv_id?: string;
  interview_time: string;
  job_title: string;
  evaluation: Record<string, any>;
  status: 'scheduled' | 'completed' | 'cancelled';
  created_at: string;
}

// types/chat.ts
export interface Conversation {
  id: string;
  participant1_id: string;
  participant1_type: string;
  participant2_id: string;
  participant2_type: string;
  job_id?: string;
  application_id?: string;
  last_message?: string;
  last_message_at?: string;
  last_message_sender_id?: string;
  status: string;
  created_at: string;
  updated_at: string;
  unread_count?: number;
}

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  message_type: 'text' | 'file';
  attachment_url?: string;
  attachment_name?: string;
  attachment_size?: number;
  is_read: boolean;
  created_at: string;
}
```

### Supabase Setup (Web)

```typescript
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

// lib/supabase/server.ts
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'

export function createServerSupabaseClient() {
  const cookieStore = cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          cookieStore.set({ name, value, ...options })
        },
        remove(name: string, options: CookieOptions) {
          cookieStore.set({ name, value: '', ...options })
        },
      },
    }
  )
}
```

### API Routes Example

```typescript
// app/api/jobs/route.ts
import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createServerSupabaseClient()
  
  const { data: jobs, error } = await supabase
    .from('jobs')
    .select(`
      *,
      profiles:creator_id (
        full_name,
        avatar_url
      )
    `)
    .eq('is_active', true)
    .eq('status', 'approved')
    .order('created_at', { ascending: false })

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ jobs })
}

export async function POST(request: Request) {
  const supabase = createServerSupabaseClient()
  const body = await request.json()

  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data, error } = await supabase
    .from('jobs')
    .insert([
      {
        creator_id: user.id,
        metadata: body.metadata,
        deadline: body.deadline,
      }
    ])
    .select()

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ job: data[0] })
}
```

### React Query Hooks

```typescript
// lib/hooks/useJobs.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { createClient } from '@/lib/supabase/client'
import { Job } from '@/types/job'

export function useJobs() {
  return useQuery({
    queryKey: ['jobs'],
    queryFn: async () => {
      const supabase = createClient()
      const { data, error } = await supabase
        .from('jobs')
        .select('*')
        .eq('is_active', true)
        .eq('status', 'approved')
      
      if (error) throw error
      return data as Job[]
    }
  })
}

export function useApplyJob() {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: async ({ jobId, cvId }: { jobId: string; cvId: string }) => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      
      if (!user) throw new Error('Not authenticated')

      const { error } = await supabase.rpc('apply_to_job', {
        p_job_id: jobId,
        p_user_id: user.id,
        p_cv_id: cvId
      })

      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['jobs'] })
      queryClient.invalidateQueries({ queryKey: ['applied-jobs'] })
    }
  })
}
```

### Realtime Chat Implementation

```typescript
// lib/hooks/useChat.ts
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Message } from '@/types/chat'

export function useMessages(conversationId: string) {
  const [messages, setMessages] = useState<Message[]>([])
  const supabase = createClient()

  useEffect(() => {
    // Fetch initial messages
    fetchMessages()

    // Subscribe to new messages
    const channel = supabase
      .channel(`messages:${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${conversationId}`
        },
        (payload) => {
          setMessages(prev => [...prev, payload.new as Message])
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [conversationId])

  async function fetchMessages() {
    const { data } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
    
    if (data) setMessages(data)
  }

  return messages
}
```

### Environment Variables (.env.local)

```env
NEXT_PUBLIC_SUPABASE_URL=https://hrhoohbvmdmwkbqiymsb.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here

# Optional: For server-side only
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Firebase (if using FCM on web)
NEXT_PUBLIC_FIREBASE_API_KEY=your_firebase_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
```

### Key Differences: Mobile vs Web

| Feature | Flutter (Mobile) | Next.js (Web) |
|---------|------------------|---------------|
| **Navigation** | Navigator 2.0 | App Router / Pages Router |
| **State** | setState, Provider | React hooks, Zustand |
| **Auth** | `supabase_flutter` | `@supabase/ssr` |
| **Realtime** | `StreamBuilder` | `useEffect` + subscriptions |
| **File Upload** | `file_picker` | `<input type="file">` |
| **Push Notifications** | FCM native | FCM web (Service Worker) |
| **PDF Viewer** | `syncfusion_flutter_pdfviewer` | `react-pdf` |
| **Styling** | Material/Cupertino | Tailwind CSS |

### Migration Priority

**Phase 1 - Core Features**:
1. ✅ Authentication (Login, Register, Google Sign-In)
2. ✅ Job listing & search
3. ✅ Job details
4. ✅ User profiles

**Phase 2 - Application Flow**:
1. ✅ CV upload & management
2. ✅ Job application
3. ✅ Saved jobs
4. ✅ Applied jobs history

**Phase 3 - Employer Features**:
1. ✅ Post job
2. ✅ Manage jobs
3. ✅ View applicants
4. ✅ Interview scheduling

**Phase 4 - Advanced Features**:
1. ✅ Real-time chat
2. ✅ Push notifications (Web Push API)
3. ✅ Admin dashboard
4. ✅ Analytics & reports

**Phase 5 - Optimizations**:
1. ✅ SEO optimization
2. ✅ Performance tuning
3. ✅ PWA support
4. ✅ Mobile responsiveness

---

## 📝 Notes & Best Practices

### Security

1. **Row Level Security (RLS)**: Tất cả các bảng đều có RLS policies
2. **Server-side validation**: Validate ở cả client và server
3. **Environment variables**: Không commit `.env` file
4. **API keys**: Chỉ sử dụng `anon_key` ở client, `service_role` ở server

### Performance

1. **Indexing**: Các bảng có indexes trên columns thường query
2. **Pagination**: Implement pagination cho lists dài
3. **Image optimization**: Resize images trước khi upload
4. **Caching**: Cache user profiles và static data

### Data Consistency

1. **Triggers**: Auto-update `updated_at` timestamps
2. **Cascading deletes**: Xóa related data khi user bị xóa
3. **Transaction**: Sử dụng RPC functions cho complex operations

### Code Quality

1. **Type safety**: Sử dụng models với type checking
2. **Error handling**: Proper error messages (tiếng Việt)
3. **Code organization**: Separation of concerns
4. **Documentation**: Comment cho complex logic

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.9.2
- Dart SDK
- Android Studio / Xcode
- Supabase account
- Firebase account (for FCM)

### Installation

1. Clone repository
2. Copy `.env.example` to `.env` và điền credentials
3. Run `flutter pub get`
4. Setup Firebase:
   - Add `google-services.json` (Android)
   - Add `GoogleService-Info.plist` (iOS)
5. Run database migrations in Supabase
6. Run `flutter run`

### Supabase Setup

1. Tạo project mới trên Supabase
2. Chạy các SQL scripts trong folder `database/`
3. Enable Realtime cho tables: `messages`, `conversations`
4. Setup Storage buckets: `avatars`, `cvs`
5. Configure Auth providers (Google)

---

## 📞 Contact & Support

**Tài liệu này được tạo vào**: 2024-12-24

**Mục đích**: Cung cấp overview đầy đủ về dự án NP FutureGate để phát triển phiên bản web tương ứng.

**Lưu ý**: Khi phát triển web app, cần đảm bảo API compatibility với mobile app, đặc biệt là về:
- Database schema
- API endpoints
- Business logic
- User roles & permissions

---

## 📚 Tài Liệu Bổ Sung

Xem thêm:
- `SUPABASE_AUTH_GUIDE.md` - Hướng dẫn authentication chi tiết
- `PUSH_NOTIFICATION_SETUP.md` - Setup push notifications
- Database SQL files trong folder `database/`
