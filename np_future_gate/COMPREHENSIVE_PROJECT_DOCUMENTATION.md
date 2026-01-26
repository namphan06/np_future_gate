# NP FutureGate - Tài Liệu Chi Tiết Dự Án

> **Ngày tạo:** 2026-01-21  
> **Phiên bản:** 1.0.0  
> **Mục đích:** Tài liệu tổng quan để tạo Use Case, Sơ đồ luồng, Sơ đồ hoạt động

---

## 📋 MỤC LỤC

1. [Tổng Quan Dự Án](#1-tổng-quan-dự-án)
2. [Các Role Trong Hệ Thống](#2-các-role-trong-hệ-thống)
3. [Chức Năng Chi Tiết Theo Role](#3-chức-năng-chi-tiết-theo-role)
4. [Mô Hình Dữ Liệu (Data Models)](#4-mô-hình-dữ-liệu)
5. [Quy Trình Nghiệp Vụ (Business Flows)](#5-quy-trình-nghiệp-vụ)
6. [Hệ Thống Thông Báo](#6-hệ-thống-thông-báo)
7. [API & Services](#7-api--services)
8. [Bảng Tổng Hợp Use Case](#8-bảng-tổng-hợp-use-case)

---

## 1. TỔNG QUAN DỰ ÁN

### 1.1 Mô tả
**NP FutureGate** là ứng dụng tuyển dụng toàn diện kết nối 4 đối tượng:
- Ứng viên (Candidate)
- Nhà tuyển dụng (Employer)  
- Nhà trường (School)
- Quản trị viên (Admin)

### 1.2 Mục tiêu chính
| STT | Mục tiêu |
|-----|----------|
| 1 | Kết nối ứng viên với cơ hội việc làm phù hợp |
| 2 | Hỗ trợ nhà tuyển dụng tìm kiếm và quản lý ứng viên |
| 3 | Tạo cầu nối giữa trường học và doanh nghiệp |
| 4 | Quản lý toàn bộ quy trình từ đăng tin đến phỏng vấn |

### 1.3 Công nghệ sử dụng
- **Frontend:** Flutter (Dart ^3.9.2)
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Authentication:** Email/Password + Google Sign-In

---

## 2. CÁC ROLE TRONG HỆ THỐNG

### 2.1 Bảng phân quyền tổng quan

| Role | Mã | Mô tả | Quyền chính |
|------|-----|-------|-------------|
| **Candidate** | `candidate` | Ứng viên tìm việc | Tìm việc, ứng tuyển, quản lý CV |
| **Employer** | `employer` | Nhà tuyển dụng | Đăng tin, quản lý ứng viên, phỏng vấn |
| **School** | `school` | Nhà trường | Tạo partnership job, liên kết doanh nghiệp |
| **Admin** | `admin` | Quản trị viên | Duyệt tin, quản lý user, thống kê |

### 2.2 Ma trận quyền truy cập

| Chức năng | Candidate | Employer | School | Admin |
|-----------|:---------:|:--------:|:------:|:-----:|
| Xem tin tuyển dụng | ✅ | ✅ | ✅ | ✅ |
| Ứng tuyển công việc | ✅ | ❌ | ❌ | ❌ |
| Đăng tin tuyển dụng | ❌ | ✅ | ❌ | ❌ |
| Tạo partnership job | ❌ | ❌ | ✅ | ❌ |
| Duyệt tin tuyển dụng | ❌ | ❌ | ❌ | ✅ |
| Quản lý ứng viên | ❌ | ✅ | ❌ | ❌ |
| Tạo lịch phỏng vấn | ❌ | ✅ | ❌ | ❌ |
| Chat | ✅ | ✅ | ✅ | ✅ |
| Quản lý CV | ✅ | ❌ | ❌ | ❌ |
| Quản lý user | ❌ | ❌ | ❌ | ✅ |

---

## 3. CHỨC NĂNG CHI TIẾT THEO ROLE

### 3.1 CANDIDATE (Ứng viên)

#### 3.1.1 Màn hình chính
| Màn hình | File | Mô tả |
|----------|------|-------|
| Trang chủ | `home_page_candidate.dart` | Dashboard, việc làm đề xuất |
| Tìm kiếm | `search_page_candidate.dart` | Tìm & lọc công việc |
| Chi tiết công việc | `job_detail_screen.dart` | Xem chi tiết, ứng tuyển |
| Việc đã ứng tuyển | `applied_jobs_screen.dart` | Danh sách đã apply |
| Việc đã lưu | `saved_jobs_screen.dart` | Việc bookmark |
| Công ty | `companies_list_screen.dart` | Danh sách công ty |
| Chi tiết công ty | `company_detail_screen.dart` | Thông tin công ty |
| Cài đặt | `settings_page_candidate.dart` | Cài đặt tài khoản |

#### 3.1.2 Chức năng chi tiết
| Mã | Chức năng | Mô tả | Đầu vào | Đầu ra |
|----|-----------|-------|---------|--------|
| C01 | Tìm kiếm việc làm | Tìm theo từ khóa, bộ lọc | Từ khóa, filters | Danh sách jobs |
| C02 | Lọc việc làm | Lọc theo vị trí/lĩnh vực/lương/kinh nghiệm | Filter params | Jobs filtered |
| C03 | Xem chi tiết việc | Xem thông tin đầy đủ về job | Job ID | Job details |
| C04 | Ứng tuyển | Gửi CV ứng tuyển | Job ID, CV ID | Application |
| C05 | Lưu việc làm | Bookmark việc yêu thích | Job ID | Saved job |
| C06 | Theo dõi công ty | Follow công ty | Company ID | Follower |
| C07 | Quản lý CV | Upload/xem/xóa CV | File PDF/DOC | CV list |
| C08 | Xem lịch phỏng vấn | Xem lịch đã được đặt | User ID | Interviews |
| C09 | Chat với NTD | Nhắn tin với employer | Message | Conversation |
| C10 | Cập nhật profile | Sửa thông tin cá nhân | Profile data | Updated profile |

### 3.2 EMPLOYER (Nhà tuyển dụng)

#### 3.2.1 Màn hình chính
| Màn hình | File | Mô tả |
|----------|------|-------|
| Trang chủ | `home_page_employer.dart` | Dashboard, thống kê |
| Quản lý tin | `employer_jobs_screen.dart` | CRUD tin tuyển dụng |
| Ứng viên | `job_applicants_screen.dart` | Xem ứng viên theo job |
| Tìm ứng viên | `search_page_employer.dart` | Tìm kiếm candidates |
| Lịch phỏng vấn | `interview_schedule_screen.dart` | Quản lý phỏng vấn |
| Chi tiết PV | `interview_detail_screen.dart` | Đánh giá ứng viên |
| Partnership | `partnership_requests_employer_screen.dart` | Yêu cầu từ trường |
| Hồ sơ công ty | `edit_company_profile_screen.dart` | Thông tin công ty |

#### 3.2.2 Chức năng chi tiết
| Mã | Chức năng | Mô tả | Đầu vào | Đầu ra |
|----|-----------|-------|---------|--------|
| E01 | Đăng tin tuyển dụng | Tạo tin mới | Job metadata | New job (pending) |
| E02 | Chỉnh sửa tin | Cập nhật tin đã đăng | Job data | Updated job |
| E03 | Xóa tin | Xóa tin tuyển dụng | Job ID | Deleted job |
| E04 | Xem ứng viên | Danh sách ứng tuyển | Job ID | Applicants list |
| E05 | Duyệt ứng viên | Accept/Reject ứng viên | User ID, Status | Updated status |
| E06 | Tìm ứng viên | Search candidates | Filters | Candidate list |
| E07 | Lưu ứng viên | Bookmark ứng viên | Candidate ID | Saved candidate |
| E08 | Tạo lịch PV | Đặt lịch phỏng vấn | Interview data | New interview |
| E09 | Đánh giá PV | Đánh giá sau phỏng vấn | Evaluation data | Updated interview |
| E10 | Xem thống kê | Thống kê tuyển dụng | Employer ID | Statistics |
| E11 | Duyệt partnership | Duyệt tin từ trường | Job ID, Status | Updated job |
| E12 | Chat với UV | Nhắn tin ứng viên | Message | Conversation |

### 3.3 SCHOOL (Nhà trường)

#### 3.3.1 Màn hình chính
| Màn hình | File | Mô tả |
|----------|------|-------|
| Trang chủ | `home_page_school.dart` | Dashboard |
| Partnership jobs | `jobs/` folder | Quản lý tin partnership |
| Tạo partnership | `create_school_job_screen.dart` | Tạo tin cho công ty |
| Email setup | `school_email_setup_screen.dart` | Cấu hình email |
| Tìm công ty | `search_page_school.dart` | Tìm đối tác |
| Cài đặt | `settings_page_school.dart` | Cài đặt |

#### 3.3.2 Chức năng chi tiết
| Mã | Chức năng | Mô tả | Đầu vào | Đầu ra |
|----|-----------|-------|---------|--------|
| S01 | Tạo partnership job | Tạo tin cho công ty | Job data, Company ID | Partnership job |
| S02 | Theo dõi trạng thái | Xem trạng thái duyệt | Job ID | Status info |
| S03 | Cấu hình email | Setup email trường | Email config | Updated config |
| S04 | Tìm công ty đối tác | Tìm công ty hợp tác | Filters | Company list |
| S05 | Xem thống kê | Thống kê partnership | School ID | Statistics |

### 3.4 ADMIN (Quản trị viên)

#### 3.4.1 Màn hình chính
| Màn hình | File | Mô tả |
|----------|------|-------|
| Dashboard | `dashboard_page_admin.dart` | Thống kê tổng quan |
| Quản lý user | `users_management_page_admin.dart` | CRUD users |
| Chi tiết user | `user_detail_screen.dart` | Xem/sửa user |
| Duyệt tin | `job_approval_page_admin.dart` | Duyệt jobs |
| Quản lý nội dung | `content_management_page_admin.dart` | Quản lý content |
| Báo cáo | `reports_page_admin.dart` | Reports |
| Test | `test_page_admin.dart` | Test notifications |

#### 3.4.2 Chức năng chi tiết
| Mã | Chức năng | Mô tả | Đầu vào | Đầu ra |
|----|-----------|-------|---------|--------|
| A01 | Xem dashboard | Thống kê tổng quan | - | Statistics |
| A02 | Quản lý user | CRUD users | User data | User list |
| A03 | Duyệt tin bình thường | Approve/reject jobs | Job ID, Status | Updated job |
| A04 | Duyệt partnership job | Approve/reject partnership | Job ID, Status | Updated job |
| A05 | Gửi thông báo | Push notification | Notification data | Sent notification |
| A06 | Xem báo cáo | Xem reports | Filter params | Report data |
| A07 | Khóa/mở user | Block/unblock | User ID | Updated status |

---

## 4. MÔ HÌNH DỮ LIỆU

### 4.1 Profile (Hồ sơ người dùng)

| Thuộc tính | Kiểu dữ liệu | Mô tả | Bắt buộc |
|------------|--------------|-------|:--------:|
| id | UUID | Primary key, liên kết auth.users | ✅ |
| email | String | Email đăng nhập | ✅ |
| full_name | String | Họ tên đầy đủ | ✅ |
| avatar_url | String | Link ảnh đại diện | ❌ |
| phone | String | Số điện thoại | ❌ |
| role | Enum | candidate/employer/school/admin | ✅ |
| metadata | JSONB | Thông tin bổ sung | ❌ |
| is_active | Boolean | Trạng thái hoạt động | ✅ |
| created_at | Timestamp | Thời gian tạo | ✅ |
| updated_at | Timestamp | Thời gian cập nhật | ✅ |

**Metadata structure cho Candidate:**
```json
{
  "date_of_birth": "1995-01-01",
  "address": "Hà Nội",
  "work_locations": ["Hà Nội", "TP HCM"],
  "education": "Đại học",
  "bio": "Giới thiệu bản thân",
  "interested_fields": ["IT Phần mềm", "Mobile App"],
  "work_types": ["Full-time", "Remote"],
  "cv_ids": ["uuid1", "uuid2"],
  "experience": [{"company": "ABC", "position": "Dev", "from": "2020-01", "to": "2022-12"}]
}
```

### 4.2 Job (Tin tuyển dụng)

| Thuộc tính | Kiểu dữ liệu | Mô tả | Bắt buộc |
|------------|--------------|-------|:--------:|
| id | UUID | Primary key | ✅ |
| creator_id | UUID | FK -> auth.users | ✅ |
| is_active | Boolean | Trạng thái hiển thị | ✅ |
| deadline | Timestamp | Hạn nộp hồ sơ | ❌ |
| metadata | JSONB | Thông tin chi tiết | ✅ |
| applicants | JSONB | Danh sách ứng viên | ❌ |
| view_count | Integer | Lượt xem | ✅ |
| status | Enum | pending/approved/rejected/closed | ✅ |
| created_at | Timestamp | Thời gian tạo | ✅ |
| updated_at | Timestamp | Thời gian cập nhật | ✅ |

**Job Metadata:**
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

**Applicants structure:**
```json
[
  {
    "user_id": "uuid...",
    "cv_id": "uuid...",
    "applied_at": "2024-01-01T10:00:00Z",
    "status": "pending|accepted|rejected"
  }
]
```

### 4.3 School Partnership Job

| Thuộc tính | Kiểu dữ liệu | Mô tả |
|------------|--------------|-------|
| id | UUID | Primary key |
| school_id | UUID | FK -> trường tạo |
| company_id | UUID | FK -> công ty được chỉ định |
| company_status | Enum | pending/accepted/rejected |
| company_reviewed_at | Timestamp | Thời điểm công ty duyệt |
| company_rejection_reason | String | Lý do từ chối |
| admin_status | Enum | pending/approved/rejected |
| admin_reviewed_at | Timestamp | Thời điểm admin duyệt |
| metadata | JSONB | Thông tin job (giống jobs) |
| applicants | JSONB | Danh sách ứng viên |

### 4.4 Interview Schedule (Lịch phỏng vấn)

| Thuộc tính | Kiểu dữ liệu | Mô tả |
|------------|--------------|-------|
| id | UUID | Primary key |
| candidate_id | UUID | FK -> ứng viên |
| job_id | UUID | FK -> công việc |
| employer_id | UUID | FK -> nhà tuyển dụng |
| cv_id | UUID | FK -> CV sử dụng |
| interview_time | Timestamp | Thời gian phỏng vấn |
| job_title | String | Tên công việc |
| evaluation | JSONB | Đánh giá |
| status | Enum | scheduled/completed/cancelled |
| is_partnership | Boolean | Có phải partnership job |

### 4.5 Conversation & Message (Chat)

**Conversation:**
| Thuộc tính | Kiểu dữ liệu | Mô tả |
|------------|--------------|-------|
| id | UUID | Primary key |
| participant1_id | UUID | Người tham gia 1 |
| participant1_type | String | Role của người 1 |
| participant2_id | UUID | Người tham gia 2 |
| participant2_type | String | Role của người 2 |
| job_id | UUID | Liên kết job (optional) |
| last_message | String | Tin nhắn cuối |
| status | Enum | active/archived |

**Message:**
| Thuộc tính | Kiểu dữ liệu | Mô tả |
|------------|--------------|-------|
| id | UUID | Primary key |
| conversation_id | UUID | FK -> conversation |
| sender_id | UUID | Người gửi |
| content | String | Nội dung |
| message_type | Enum | text/file |
| attachment_url | String | Link file đính kèm |
| is_read | Boolean | Đã đọc |

### 4.6 Các bảng phụ trợ

| Bảng | Mô tả |
|------|-------|
| cv_templates | Quản lý CV của ứng viên |
| device_tokens | FCM tokens cho push notification |
| user_job_activities | Lưu/xem/ứng tuyển công việc |
| company_followers | Theo dõi công ty |
| notifications | Thông báo hệ thống |
| career_news | Tin tức nghề nghiệp |
| courses | Khóa học |

---

## 5. QUY TRÌNH NGHIỆP VỤ

### 5.1 Quy trình đăng ký & đăng nhập

```
[Bắt đầu] 
    ↓
[Chọn phương thức: Email/Google]
    ↓
[Email] → [Nhập Email/Password/Họ tên/SĐT/Role]
    ↓                    ↓
[Google] → [Xác thực Google] → [Chọn Role nếu mới]
    ↓
[Tạo Profile trong DB]
    ↓
[Lưu Device Token cho FCM]
    ↓
[Điều hướng theo Role]
    ↓
[Kết thúc]
```

### 5.2 Quy trình đăng tin tuyển dụng (Employer)

```
[Employer tạo tin]
    ↓
[Nhập thông tin: Tiêu đề, mô tả, lương, yêu cầu...]
    ↓
[Submit] → [Status = 'pending']
    ↓
[Admin nhận thông báo]
    ↓
[Admin review]
    ↓
[Approve?] 
   ↓ Yes           ↓ No
[Status='approved']  [Status='rejected']
   ↓                    ↓
[Hiển thị cho UV]   [Thông báo NTD]
```

### 5.3 Quy trình Partnership Job (School)

```
[Trường tạo tin] → [Chọn công ty đối tác]
    ↓
[Gửi yêu cầu] → [company_status = 'pending']
    ↓
[Công ty nhận thông báo]
    ↓
[Công ty review]
    ↓
[Công ty accept?]
   ↓ Yes              ↓ No
[company_status=     [company_status=
 'accepted']          'rejected']
   ↓                     ↓
[Admin review]       [Thông báo trường]
   ↓
[Admin approve?]
   ↓ Yes              ↓ No
[admin_status=       [admin_status=
 'approved']          'rejected']
   ↓                     ↓
[Xuất bản cho UV]    [Thông báo]
```

### 5.4 Quy trình ứng tuyển (Candidate)

```
[UV xem chi tiết job]
    ↓
[Nhấn "Ứng tuyển"]
    ↓
[Chọn CV] → [Không có CV?] → [Upload CV mới]
    ↓
[Xác nhận ứng tuyển]
    ↓
[Gọi RPC apply_to_job]
    ↓
[Thêm vào applicants của job]
    ↓
[Tạo activity record]
    ↓
[Thông báo cho Employer]
    ↓
[Kết thúc]
```

### 5.5 Quy trình phỏng vấn

```
[Employer xem ứng viên]
    ↓
[Chọn UV để phỏng vấn]
    ↓
[Chọn thời gian] → [Check xung đột lịch]
    ↓
[Tạo lịch phỏng vấn]
    ↓
[Thông báo cho UV]
    ↓
[Phỏng vấn]
    ↓
[Employer đánh giá]
    ↓
[Cập nhật evaluation & status]
    ↓
[Accept/Reject UV]
    ↓
[Thông báo kết quả]
```

---

## 6. HỆ THỐNG THÔNG BÁO

### 6.1 Loại thông báo

| Type | Mô tả | Trigger |
|------|-------|---------|
| `info` | Thông tin chung | System |
| `success` | Thành công | Action complete |
| `warning` | Cảnh báo | Deadline, issues |
| `error` | Lỗi | System errors |
| `job` | Liên quan công việc | New job, status change |
| `interview` | Phỏng vấn | Schedule, reminder |
| `message` | Tin nhắn | New message |
| `system` | Hệ thống | Maintenance, updates |

### 6.2 Action Codes

| Code | Mô tả | Navigation |
|------|-------|------------|
| `view_job` | Xem chi tiết job | Job Detail Screen |
| `view_application` | Xem đơn ứng tuyển | Applied Jobs |
| `view_interview` | Xem lịch phỏng vấn | Interview Screen |
| `view_message` | Xem tin nhắn | Chat Screen |
| `view_profile` | Xem profile | Profile Screen |

---

## 7. API & SERVICES

### 7.1 AuthRepository
```
signUpWithEmail(email, password, fullName, phone, role)
signInWithEmail(email, password)
signInWithGoogle()
signOut(deviceToken?)
resetPassword(email)
getCurrentUserProfile()
updateProfile(userId, data)
uploadAvatar(file, userId)
saveDeviceToken(token, userId, role)
```

### 7.2 JobRepository
```
createJob(job) → Check post limit → Insert
updateJob(job)
deleteJob(jobId)
getActiveJobs() → Filter approved, active
getEmployerJobs(creatorId)
applyForJob(jobId, userId, cvId) → RPC call
hasApplied(userId, jobId)
toggleSaveJob(userId, jobId)
getSavedJobs(userId)
getAppliedJobs(userId)
updateApplicationStatus(jobId, userId, status)
getPendingJobs() → For admin
approveJob(jobId) / rejectJob(jobId)
```

### 7.3 InterviewRepository
```
createInterview(interview)
getEmployerInterviews(employerId)
getCandidateInterviews(candidateId)
updateInterviewStatus(id, status)
updateInterviewEvaluation(id, evaluation)
hasInterviewConflict(employerId, time)
```

### 7.4 ChatService
```
getConversations()
getOrCreateConversation(otherUserId, type, jobId?)
getMessages(conversationId)
sendMessage(conversationId, content, type)
markAsRead(conversationId)
streamMessages(conversationId) → Realtime
streamConversations() → Realtime
```

---

## 8. BẢNG TỔNG HỢP USE CASE

### 8.1 Use Cases - Candidate

| UC ID | Tên Use Case | Actor | Tiền điều kiện | Mô tả tóm tắt |
|-------|--------------|-------|----------------|---------------|
| UC-C01 | Đăng ký tài khoản | Candidate | Chưa có tài khoản | Tạo tài khoản mới |
| UC-C02 | Đăng nhập | Candidate | Có tài khoản | Xác thực vào hệ thống |
| UC-C03 | Tìm kiếm việc làm | Candidate | Đã đăng nhập | Tìm việc theo tiêu chí |
| UC-C04 | Xem chi tiết công việc | Candidate | Đã đăng nhập | Xem thông tin đầy đủ |
| UC-C05 | Ứng tuyển công việc | Candidate | Có CV | Gửi đơn ứng tuyển |
| UC-C06 | Quản lý CV | Candidate | Đã đăng nhập | CRUD CV |
| UC-C07 | Lưu công việc | Candidate | Đã đăng nhập | Bookmark job |
| UC-C08 | Theo dõi công ty | Candidate | Đã đăng nhập | Follow company |
| UC-C09 | Xem lịch phỏng vấn | Candidate | Có lịch PV | Xem các cuộc PV |
| UC-C10 | Chat với NTD | Candidate | Có conversation | Nhắn tin |
| UC-C11 | Cập nhật profile | Candidate | Đã đăng nhập | Sửa thông tin |

### 8.2 Use Cases - Employer

| UC ID | Tên Use Case | Actor | Tiền điều kiện | Mô tả tóm tắt |
|-------|--------------|-------|----------------|---------------|
| UC-E01 | Đăng tin tuyển dụng | Employer | Đã đăng nhập | Tạo job posting |
| UC-E02 | Quản lý tin đăng | Employer | Có tin đăng | CRUD jobs |
| UC-E03 | Xem ứng viên | Employer | Có applicants | Xem danh sách UV |
| UC-E04 | Duyệt ứng viên | Employer | Có applications | Accept/Reject |
| UC-E05 | Tìm ứng viên | Employer | Đã đăng nhập | Search candidates |
| UC-E06 | Tạo lịch phỏng vấn | Employer | Có UV accepted | Schedule interview |
| UC-E07 | Đánh giá phỏng vấn | Employer | Đã PV | Submit evaluation |
| UC-E08 | Xem thống kê | Employer | Có jobs | View statistics |
| UC-E09 | Duyệt partnership | Employer | Có request | Accept/Reject |
| UC-E10 | Chat với ứng viên | Employer | Có conversation | Nhắn tin |

### 8.3 Use Cases - School

| UC ID | Tên Use Case | Actor | Tiền điều kiện | Mô tả tóm tắt |
|-------|--------------|-------|----------------|---------------|
| UC-S01 | Tạo partnership job | School | Đã đăng nhập | Tạo tin cho cty |
| UC-S02 | Theo dõi trạng thái | School | Có partnership | Xem trạng thái |
| UC-S03 | Tìm đối tác | School | Đã đăng nhập | Search companies |
| UC-S04 | Cấu hình email | School | Đã đăng nhập | Setup email |

### 8.4 Use Cases - Admin

| UC ID | Tên Use Case | Actor | Tiền điều kiện | Mô tả tóm tắt |
|-------|--------------|-------|----------------|---------------|
| UC-A01 | Xem dashboard | Admin | Đã đăng nhập | View statistics |
| UC-A02 | Quản lý users | Admin | Đã đăng nhập | CRUD users |
| UC-A03 | Duyệt tin tuyển dụng | Admin | Có pending jobs | Approve/Reject |
| UC-A04 | Duyệt partnership | Admin | Có pending | Approve/Reject |
| UC-A05 | Gửi thông báo | Admin | Đã đăng nhập | Push notification |
| UC-A06 | Xem báo cáo | Admin | Đã đăng nhập | View reports |

---

## 9. ENUMS & CONSTANTS

### 9.1 Employment Types
| Enum | Display Name |
|------|--------------|
| fullTime | Toàn thời gian |
| partTime | Bán thời gian |
| internship | Thực tập |
| freelance | Freelance |
| contract | Hợp đồng |
| remote | Làm việc từ xa |
| temporary | Thời vụ |

### 9.2 Experience Levels
| Enum | Display Name |
|------|--------------|
| noExperience | Chưa có kinh nghiệm |
| underOneYear | Dưới 1 năm |
| oneYear - fiveYears | 1-5 năm |
| overFiveYears | Trên 5 năm |
| intern | Thực tập sinh |
| fresher | Mới tốt nghiệp |
| junior/middle/senior | Junior/Middle/Senior |
| lead/manager/director | Trưởng nhóm/Quản lý/Giám đốc |

### 9.3 Job Fields
| Enum | Display Name |
|------|--------------|
| itSoftware | IT - Phần mềm |
| marketing | Marketing / Truyền thông |
| sales | Kinh doanh / Bán hàng |
| accountingAudit | Kế toán / Kiểm toán |
| hrAdmin | Nhân sự / Hành chính |
| construction | Xây dựng |
| education | Giáo dục / Đào tạo |
| medicalHealth | Y tế / Sức khỏe |
| bankingFinance | Ngân hàng / Tài chính |
| ... | (22 lĩnh vực) |

### 9.4 Job Status
| Status | Mô tả |
|--------|-------|
| pending | Chờ duyệt |
| approved | Đã duyệt |
| rejected | Từ chối |
| closed | Đã đóng |

### 9.5 Application Status
| Status | Mô tả |
|--------|-------|
| pending | Chờ xử lý |
| accepted | Đã chấp nhận |
| rejected | Từ chối |

### 9.6 Interview Status
| Status | Mô tả |
|--------|-------|
| scheduled | Đã lên lịch |
| completed | Hoàn thành |
| cancelled | Đã hủy |

---

## 10. CẤU TRÚC THƯ MỤC DỰ ÁN

```
np_future_gate/
├── lib/
│   ├── core/
│   │   ├── config/          # Cấu hình Supabase
│   │   ├── enums/           # Enums (employment, experience, fields, provinces)
│   │   ├── models/          # Data models (16 files)
│   │   ├── repositories/    # Business logic (13 files)
│   │   ├── services/        # External services (8 files)
│   │   └── theme/           # App theme
│   ├── screens/
│   │   ├── admin/           # 9 screens
│   │   ├── auth/            # 3 screens
│   │   ├── candidate/       # 14 screens
│   │   ├── employer/        # 20 screens
│   │   ├── school/          # 14 screens
│   │   ├── chat/            # 2 screens
│   │   ├── cv/              # 16 screens
│   │   └── ...
│   ├── widgets/             # Reusable widgets
│   ├── notification/        # Notification system
│   └── main.dart
├── database/                # SQL scripts (38 files)
├── docs/                    # Documentation
└── assets/                  # Images, icons
```

---

**Tài liệu này cung cấp đầy đủ thông tin để:**
- ✅ Vẽ Use Case Diagram
- ✅ Tạo Activity Diagram cho từng quy trình
- ✅ Thiết kế Sequence Diagram
- ✅ Xây dựng ERD (Entity Relationship Diagram)
- ✅ Viết tài liệu SRS (Software Requirements Specification)
- ✅ Tạo test cases

---

*Cập nhật lần cuối: 2026-01-21*
