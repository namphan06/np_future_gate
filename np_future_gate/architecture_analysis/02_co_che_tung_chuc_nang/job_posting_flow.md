# Luồng Đăng Tin Tuyển Dụng và Matching

## Mục đích

Tài liệu này mô tả chi tiết luồng đăng tin tuyển dụng của nhà tuyển dụng (Employer), quy trình ứng tuyển của ứng viên (Candidate), và cơ chế AI Matching để đánh giá độ phù hợp giữa CV và công việc. Hệ thống hỗ trợ hai loại tin tuyển dụng: tin thường (regular jobs) và tin đối tác (partnership jobs) thông qua liên kết với trường học.

## Các thành phần tham gia

### Controllers

| Controller | File | Vai trò |
|-----------|------|---------|
| `HomeEmployerController` | `lib/features/employer/controllers/home_employer_controller.dart` | Quản lý trang chủ employer: load jobs, applications, stats, subscription |
| `SearchEmployerController` | `lib/features/employer/controllers/search_employer_controller.dart` | Tìm kiếm và lọc ứng viên theo nhiều tiêu chí |
| `EmployerStatisticsController` | `lib/features/employer/controllers/employer_statistics_controller.dart` | Thống kê hoạt động tuyển dụng |

### Screens

| Screen | File | Vai trò |
|--------|------|---------|
| `EditJobScreen` | `lib/features/employer/screens/jobs/edit_job_screen.dart` | Tạo mới / chỉnh sửa tin tuyển dụng |
| `EmployerJobsScreen` | `lib/features/employer/screens/jobs/employer_jobs_screen.dart` | Danh sách quản lý tin đã đăng (tabs: tin thường + tin đối tác) |
| `JobApplicantsScreen` | `lib/features/employer/screens/jobs/job_applicants_screen.dart` | Quản lý ứng viên cho từng tin |
| `CVAnalysisScreen` | `lib/features/employer/screens/jobs/cv_analysis_screen.dart` | Phân tích AI matching cho từng CV |
| `CVScanAnalysisScreen` | `lib/features/employer/screens/jobs/cv_scan_analysis_screen.dart` | Scan CV bằng camera và phân tích |

### Repositories

| Repository | File | Vai trò |
|-----------|------|---------|
| `JobRepository` | `lib/core/repositories/job_repository.dart` | CRUD tin tuyển dụng, quản lý ứng viên, realtime streams |
| `CandidateRepository` | `lib/core/repositories/candidate_repository.dart` | Truy vấn thông tin ứng viên |
| `InterviewRepository` | `lib/core/repositories/interview_repository.dart` | Tạo lịch phỏng vấn khi chấp nhận ứng viên |
| `AIDataRepository` | `lib/core/repositories/ai_data_repository.dart` | Truy vấn dữ liệu cho AI chatbot (intent-based) |

### Services

| Service | File | Vai trò |
|---------|------|---------|
| `AIMatchingService` | `lib/core/services/ai_matching_service.dart` | Phân tích độ phù hợp CV-Job bằng Mistral AI |
| `SubscriptionService` | `lib/core/services/subscription_service.dart` | Kiểm tra giới hạn đăng tin theo gói đăng ký |
| `MistralService` | `lib/core/services/mistral_service.dart` | Gọi API Mistral AI |
| `MLKitOcrService` | `lib/core/services/mlkit_ocr_service.dart` | OCR text recognition từ CV upload/scan |
| `CVSupabaseService` | `lib/core/services/cv_supabase_service.dart` | Lấy dữ liệu CV từ Supabase |
| `ApplicationNotificationService` | `lib/core/services/notification/application_notification_service.dart` | Gửi thông báo kết quả ứng tuyển |
| `EmailJsService` | `lib/core/services/emailjs_service.dart` | Gửi email phản hồi cho ứng viên |

### Models

| Model | File | Vai trò |
|-------|------|---------|
| `JobModel` | `lib/core/models/job_model.dart` | Model chính cho tin tuyển dụng |
| `JobMetadata` | `lib/core/models/job_model.dart` | Thông tin chi tiết: title, salary, fields, requirements |
| `JobSalary` | `lib/core/models/job_model.dart` | Thông tin lương (min, max, currency, type) |
| `JobApplication` | `lib/core/models/job_model.dart` | Thông tin ứng tuyển (userId, cvId, status) |
| `CVMatchingResult` | `lib/core/models/cv_matching_result_model.dart` | Kết quả phân tích AI matching |

## Sơ đồ tổng quan

```mermaid
graph TB
    subgraph "Employer Flow"
        E1[Employer tạo tin] --> E2[Kiểm tra Subscription]
        E2 -->|Đủ quota| E3[Lưu vào Supabase]
        E2 -->|Hết quota| E4[Yêu cầu nâng cấp gói]
        E3 --> E5[Admin duyệt tin]
        E5 -->|Approved| E6[Tin hiển thị cho Candidate]
        E5 -->|Rejected| E7[Tin bị từ chối]
    end

    subgraph "Candidate Flow"
        C1[Candidate xem tin] --> C2[Ứng tuyển với CV]
        C2 --> C3[Lưu vào user_job_activities]
        C3 --> C4[Cập nhật applicants trong jobs]
    end

    subgraph "Matching Flow"
        M1[Employer xem ứng viên] --> M2[Phân tích AI]
        M2 --> M3[OCR/Structured CV]
        M3 --> M4[Mistral AI Matching]
        M4 --> M5[Kết quả: Score + Analysis]
    end

    subgraph "Decision Flow"
        D1[Employer quyết định] -->|Accept| D2[Tạo lịch phỏng vấn]
        D1 -->|Reject| D3[Gửi email từ chối]
        D2 --> D4[Gửi notification + email]
        D3 --> D5[Gửi notification]
    end

    E6 --> C1
    C4 --> M1
    M5 --> D1
```

## Luồng xử lý chi tiết

### 1. Luồng đăng tin tuyển dụng (Employer)

```mermaid
sequenceDiagram
    participant E as Employer
    participant UI as EditJobScreen
    participant SS as SubscriptionService
    participant JR as JobRepository
    participant DB as Supabase DB
    participant Admin as Admin

    E->>UI: Nhấn "Đăng tin mới"
    UI->>UI: Hiển thị form nhập liệu
    Note over UI: Thông tin cơ bản, Lương,<br/>Chi tiết công việc, Cài đặt

    E->>UI: Điền thông tin và nhấn "Lưu"
    UI->>UI: Validate form (_formKey)
    
    UI->>JR: createJob(JobModel)
    JR->>SS: _checkPostLimit(creatorId)
    SS->>DB: Lấy metadata.subscription từ profiles
    SS->>DB: Đếm jobs tháng này
    
    alt Hết quota đăng tin
        SS-->>JR: Throw Exception (giới hạn)
        JR-->>UI: Error
        UI->>E: Hiển thị SnackBar lỗi
    else Còn quota
        SS-->>JR: OK
        JR->>DB: INSERT vào bảng jobs (status='pending')
        DB-->>JR: Success
        JR-->>UI: Success
        UI->>E: Navigator.pop(context, true)
    end

    Note over DB,Admin: Tin ở trạng thái 'pending'
    Admin->>DB: approveJob(jobId) hoặc rejectJob(jobId)
    DB->>DB: UPDATE status = 'approved'/'rejected'
```

#### Chi tiết dữ liệu tin tuyển dụng (JobModel)

```dart
JobModel(
  creatorId: userId,          // ID nhà tuyển dụng
  isActive: true,             // Trạng thái hiển thị
  deadline: DateTime,         // Hạn nộp hồ sơ
  status: 'pending',          // pending → approved/rejected
  metadata: JobMetadata(
    title: 'Senior Flutter Developer',
    workingRegions: ['Hà Nội', 'TP.HCM'],
    experienceRequired: '2-3 năm',
    fields: ['Công nghệ thông tin'],
    requirementsTags: ['Flutter', 'Dart', 'Firebase'],
    salary: JobSalary(min: 15000000, max: 25000000, currency: 'VND'),
    employmentTypes: ['Toàn thời gian'],
    workLocations: ['123 Nguyễn Huệ, Q1, TP.HCM'],
    jobDescription: ['Phát triển ứng dụng mobile...'],
    candidateRequirements: ['Tốt nghiệp ĐH CNTT...'],
    benefits: ['Lương tháng 13...'],
  ),
)
```

### 2. Hệ thống Subscription (Giới hạn đăng tin)

```mermaid
graph LR
    subgraph "Gói đăng ký"
        F[Free<br/>4 tin/tháng<br/>0 VND]
        B[Basic<br/>5 tin/tháng<br/>5,000 VND]
        S[Standard<br/>6 tin/tháng<br/>6,000 VND]
        V[VIP<br/>7 tin/tháng<br/>7,000 VND]
    end

    F --> B --> S --> V
```

| Gói | Mã code | Giới hạn | Giá/tháng |
|-----|---------|----------|-----------|
| Free | FREE | 4 tin/tháng | 0 VND |
| Basic | EMP-CB | 5 tin/tháng | 5,000 VND |
| Standard | EMP-T | 6 tin/tháng | 6,000 VND |
| VIP | EMP-V | 7 tin/tháng | 7,000 VND |

**Logic kiểm tra:**
1. Lấy thông tin subscription từ `profiles.metadata.subscription`
2. Kiểm tra hết hạn (`expires_at`)
3. Đếm số tin đã đăng trong tháng (cả regular + partnership jobs)
4. So sánh với `maxJobsPerMonth` của gói hiện tại

### 3. Luồng ứng tuyển (Candidate)

```mermaid
sequenceDiagram
    participant C as Candidate
    participant UI as JobDetailScreen
    participant JR as JobRepository
    participant DB as Supabase DB
    participant RPC as Supabase RPC

    C->>UI: Xem chi tiết tin tuyển dụng
    C->>UI: Nhấn "Ứng tuyển" + chọn CV
    
    UI->>JR: applyForJob(jobId, userId, cvId)
    
    JR->>DB: SELECT user_job_activities (kiểm tra đã ứng tuyển chưa)
    
    alt Đã có activity record
        JR->>DB: UPDATE is_applied=true, cv_id, applied_at
    else Chưa có record
        JR->>DB: INSERT user_job_activities mới
    end

    JR->>RPC: apply_to_job(p_job_id, p_user_id, p_cv_id)
    Note over RPC: RPC cập nhật mảng applicants<br/>trong bảng jobs (legacy support)
    
    RPC-->>JR: Success
    JR-->>UI: Success
    UI->>C: Thông báo ứng tuyển thành công
```

### 4. Luồng AI Matching (Phân tích CV)

```mermaid
sequenceDiagram
    participant E as Employer
    participant UI as CVAnalysisScreen
    participant AIS as AIMatchingService
    participant OCR as MLKitOcrService
    participant AI as MistralService
    
    E->>UI: Nhấn "Phân tích AI" cho ứng viên
    UI->>AIS: analyzeCVMatching(cvData, job)
    
    AIS->>AIS: Xác định loại CV (upload vs structured)
    
    alt CV Upload (file PDF/image)
        AIS->>OCR: extractTextFromUrl(fileUrl)
        OCR-->>AIS: OcrResult (text)
        AIS->>AIS: _buildAnalysisPrompt(ocrText, job)
    else CV Structured (tạo trên app)
        AIS->>AIS: _buildStructuredText(cvData)
        AIS->>AIS: _buildAnalysisPrompt(structuredText, job)
    end
    
    AIS->>AI: sendIsolatedMessage(prompt)
    Note over AI: Mistral AI phân tích<br/>và trả về JSON
    AI-->>AIS: JSON response
    
    AIS->>AIS: Parse JSON → CVMatchingResult
    AIS-->>UI: CVMatchingResult
    
    UI->>E: Hiển thị kết quả:<br/>- Overall Score (%)<br/>- Semantic Similarity<br/>- Keyword Match Score<br/>- Matching Points<br/>- Missing Points
```

#### Cấu trúc kết quả AI Matching

```json
{
  "overall_score": 75,
  "semantic_similarity": 0.82,
  "keyword_match_score": 68,
  "summary": "Ứng viên có kinh nghiệm Flutter 2 năm, phù hợp 75%...",
  "matching_points": [
    "Có kinh nghiệm Flutter/Dart",
    "Đã làm việc với Firebase"
  ],
  "missing_points": [
    "Chưa có kinh nghiệm CI/CD",
    "Thiếu chứng chỉ AWS"
  ],
  "parsed_data": {
    "name": "Nguyễn Văn A",
    "skills": "Flutter, Dart, Firebase",
    "experience": "2 năm",
    "education": "ĐH Bách Khoa"
  }
}
```

### 5. Luồng so sánh ứng viên (Compare CVs)

```mermaid
sequenceDiagram
    participant E as Employer
    participant UI as JobApplicantsScreen
    participant CVS as CVSupabaseService
    participant AIS as AIMatchingService
    participant AI as MistralService

    E->>UI: Chọn nhiều ứng viên (selection mode)
    E->>UI: Nhấn "So sánh"
    
    UI->>CVS: getCVFullDataForEmployer(cvId) × N
    CVS-->>UI: List<cvData>
    
    UI->>AIS: compareCVsStructured(cvsData, names, job)
    AIS->>AIS: _getAllCVTexts (OCR hoặc structured)
    AIS->>AI: Prompt so sánh với tiêu chí đánh giá
    AI-->>AIS: JSON kết quả ranking
    AIS-->>UI: CVComparisonResult
    
    UI->>E: Hiển thị bảng so sánh:<br/>- Ranking<br/>- Skills/Experience/Education Score<br/>- Strengths/Weaknesses<br/>- Recommendation
```

### 6. Luồng xử lý ứng viên (Accept/Reject)

```mermaid
sequenceDiagram
    participant E as Employer
    participant UI as JobApplicantsScreen
    participant JR as JobRepository
    participant IR as InterviewRepository
    participant NS as NotificationService
    participant ES as EmailJsService
    participant DB as Supabase DB

    E->>UI: Chọn trạng thái cho ứng viên

    alt Accept (Chấp nhận)
        UI->>E: Chọn ngày + giờ phỏng vấn
        UI->>IR: checkInterviewConflict(employerId, time)
        
        alt Trùng lịch
            IR-->>UI: conflictingInterview
            UI->>E: Cảnh báo trùng lịch
        else Không trùng
            UI->>IR: createInterview(candidateId, jobId, ...)
            IR->>DB: INSERT interview_schedules
        end
        
        UI->>JR: updateApplicationStatus(jobId, userId, 'accepted')
        JR->>DB: UPDATE applicants array
        
        UI->>NS: notifyApplicationApproved(...)
        UI->>ES: sendAcceptanceEmail(userId)
        
    else Reject (Từ chối)
        UI->>JR: updateApplicationStatus(jobId, userId, 'rejected')
        JR->>DB: UPDATE applicants array
        
        UI->>NS: notifyApplicationRejected(...)
        UI->>ES: sendRejectionEmail(userId)
    end
```

### 7. Luồng Realtime Streams

```mermaid
graph TB
    subgraph "Supabase Realtime"
        RT1[jobs table stream]
        RT2[user_job_activities stream]
    end

    subgraph "Employer Side"
        ES1[getEmployerJobsStream] -->|Listen| RT1
        ES1 --> ES2[Cập nhật danh sách tin]
    end

    subgraph "Candidate Side"
        CS1[activeJobsStream] -->|Listen| RT1
        CS1 --> CS2[Filter: is_active + approved + deadline]
        CS2 --> CS3[Hydrate: fetch profiles]
        CS3 --> CS4[Hiển thị tin mới realtime]
        
        CS5[getSavedJobsStream] -->|Listen| RT2
        CS5 --> CS6[Cập nhật danh sách đã lưu]
        
        CS7[getAppliedJobsStream] -->|Listen| RT2
        CS7 --> CS8[Cập nhật trạng thái ứng tuyển]
    end
```

## Xử lý lỗi

| Tình huống | Xử lý | Thông báo |
|-----------|--------|-----------|
| Hết quota đăng tin | Throw Exception, hiển thị SnackBar | "Bạn đã đạt giới hạn đăng tin (X tin/tháng). Vui lòng nâng cấp gói." |
| Gói đăng ký hết hạn | Reset về Free plan, cho phép đăng 4 tin | "Gói đăng ký đã hết hạn. Đang sử dụng gói miễn phí." |
| Lỗi tạo tin | Catch Exception, hiển thị SnackBar | "Lỗi khi lưu tin: [chi tiết]" |
| Lỗi ứng tuyển | Throw Exception | "Failed to apply for job: [chi tiết]" |
| Đã ứng tuyển rồi | Detect P0001 error code | "Bạn đã ứng tuyển công việc này rồi." |
| OCR thất bại | Fallback về mock result | Return CVMatchingResult.fromMock(5) |
| AI không trả JSON hợp lệ | Sanitize + retry parse | Fallback CVMatchingResult.fromMock(10) |
| Trùng lịch phỏng vấn | Hiển thị dialog cảnh báo | "Bạn đã có lịch phỏng vấn vào thời gian này" |
| Lỗi gửi email/notification | Log warning, không hiển thị lỗi | Background operation, không ảnh hưởng UX |

## Cơ chế kiểm tra giới hạn đăng tin

```mermaid
flowchart TD
    A[Employer tạo tin mới] --> B[_checkPostLimit]
    B --> C{Lấy subscription info}
    C --> D{Gói hết hạn?}
    D -->|Có| E{Gói Free?}
    E -->|Không| F[Throw: Gói đã hết hạn]
    E -->|Có| G{canPostJob?}
    D -->|Không| G
    G -->|Không| H[Throw: Đạt giới hạn]
    G -->|Có| I[Cho phép đăng tin]
    
    style F fill:#ffcccc
    style H fill:#ffcccc
    style I fill:#ccffcc
```

## Tìm kiếm ứng viên (Employer Search)

`SearchEmployerController` cho phép nhà tuyển dụng tìm kiếm ứng viên với các bộ lọc:

| Bộ lọc | Mô tả |
|--------|--------|
| Lĩnh vực (Fields) | Lọc theo `metadata.interested_fields` |
| Trình độ học vấn | Lọc theo `metadata.education` |
| Khu vực | Lọc theo `metadata.work_locations` |
| Độ tuổi | Lọc theo `date_of_birth` (18-60) |
| Giới tính | Lọc theo `metadata.gender` |
| Từ khóa | Tìm trong fields + tags |

**Lưu ý:** Chỉ hiển thị ứng viên có `metadata.security = true` (đã xác minh).

## Bảng dữ liệu Supabase liên quan

| Bảng | Vai trò |
|------|---------|
| `jobs` | Lưu tin tuyển dụng (metadata JSONB, applicants JSONB array) |
| `user_job_activities` | Tracking: saved, applied, application_status |
| `profiles` | Thông tin user (employer/candidate), subscription metadata |
| `school_partnership_jobs` | Tin tuyển dụng đối tác (school + company) |
| `interview_schedules` | Lịch phỏng vấn |
| `email_templates` | Template email phản hồi tùy chỉnh |

## Liên kết liên quan

- [Tổng quan kiến trúc](../01_tong_quan_kien_truc.md)
- [Luồng AI Matching](./ai_matching_flow.md)
- [Luồng thông báo](./notification_flow.md)
- [Luồng phỏng vấn](./interview_flow.md)
- [Luồng thanh toán](./payment_flow.md)
- [Luồng quản lý CV](./cv_management_flow.md)
