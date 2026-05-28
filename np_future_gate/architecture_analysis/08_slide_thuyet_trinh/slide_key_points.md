# Slide Key Points - Bảo vệ Đồ án Tốt nghiệp

## Mục đích

Liệt kê các điểm chính cho từng slide trong bài thuyết trình bảo vệ đồ án tốt nghiệp (15-20 phút). Mỗi slide bao gồm: tiêu đề, bullet points nội dung, và gợi ý hình ảnh minh họa.

---

## Slide 1: Giới thiệu

### Tiêu đề slide
**NP FutureGate - Nền tảng kết nối việc làm thông minh cho sinh viên**

### Bullet Points
- Họ tên: Phan Vũ Hoài Nam
- MSSV: 22010066
- Đề tài: Xây dựng ứng dụng di động kết nối việc làm cho sinh viên sử dụng Flutter và AI
- Giảng viên hướng dẫn: [Tên GVHD]
- Trường / Khoa: [Tên trường / Khoa CNTT]

### Hình ảnh minh họa gợi ý
- Logo NP FutureGate
- Ảnh chụp màn hình chính của ứng dụng
- Logo trường đại học

---

## Slide 2: Vấn đề (Problem Statement)

### Tiêu đề slide
**Thực trạng và vấn đề cần giải quyết**

### Bullet Points
- Sinh viên gặp khó khăn trong việc tìm kiếm việc làm phù hợp sau tốt nghiệp
- Thiếu kênh kết nối trực tiếp giữa sinh viên - nhà tuyển dụng - trường học
- Quy trình ứng tuyển truyền thống tốn thời gian, thiếu tự động hóa
- CV sinh viên thường không được đánh giá chuyên sâu, thiếu phản hồi
- Nhà tuyển dụng khó tiếp cận đúng đối tượng sinh viên phù hợp
- Trường học thiếu công cụ theo dõi tình trạng việc làm của sinh viên

### Hình ảnh minh họa gợi ý
- Biểu đồ thống kê tỷ lệ thất nghiệp sinh viên mới ra trường
- Sơ đồ minh họa khoảng cách giữa sinh viên và nhà tuyển dụng
- Icon minh họa các pain points (thời gian, kết nối, thông tin)

---

## Slide 3: Giải pháp (Solution)

### Tiêu đề slide
**NP FutureGate - Giải pháp kết nối việc làm toàn diện**

### Bullet Points
- Nền tảng di động đa vai trò: Sinh viên/Ứng viên, Nhà tuyển dụng, Trường học, Admin
- Tích hợp AI phân tích CV tự động và gợi ý việc làm phù hợp (Mistral AI)
- Hệ thống chat realtime giữa các bên liên quan
- OCR scanning CV từ ảnh/PDF giúp số hóa nhanh chóng
- Push notification thông minh cho lịch phỏng vấn và cập nhật trạng thái
- Thanh toán trực tuyến cho gói dịch vụ premium (PayOS)
- Kết nối 3 bên: Sinh viên ↔ Nhà tuyển dụng ↔ Trường học

### Hình ảnh minh họa gợi ý
- Sơ đồ tổng quan hệ thống với 4 vai trò người dùng
- Screenshots các tính năng chính của ứng dụng
- Biểu đồ luồng kết nối 3 bên

---

## Slide 4: Kiến trúc hệ thống (Architecture)

### Tiêu đề slide
**Kiến trúc MVC 3 tầng và Tech Stack**

### Bullet Points
- **Mô hình MVC** với BaseController + ChangeNotifier cho state management
- **3 tầng kiến trúc:**
  - Presentation Layer: Screens, Widgets (Flutter UI)
  - Business Logic Layer: Controllers, Services
  - Data Layer: Repositories, Models
- **Cấu trúc Feature-based:** Mỗi feature module có controllers/, screens/, widgets/
- **10 Feature modules:** Auth, AI, Candidate, Employer, School, Admin, Chat, CV, Interview, Notification
- **5 External Services:** Supabase, Firebase, Mistral AI, Google ML Kit, PayOS

### Hình ảnh minh họa gợi ý
- Sơ đồ Mermaid kiến trúc 3 tầng (từ file 01_tong_quan_kien_truc.md)
- Sơ đồ luồng dữ liệu: UI → Controller → Repository/Service → External API
- Cấu trúc thư mục dự án (tree diagram)

---

## Slide 5: Demo ứng dụng (Live Demo)

### Tiêu đề slide
**Demo các tính năng chính**

### Bullet Points
- **Đăng nhập/Đăng ký:** Email + Google Sign-In qua Supabase Auth
- **AI Matching:** Phân tích CV và gợi ý việc làm phù hợp bằng Mistral AI
- **OCR Scanning:** Quét CV từ ảnh, trích xuất thông tin tự động (Google ML Kit)
- **Chat Realtime:** Nhắn tin trực tiếp giữa ứng viên và nhà tuyển dụng
- **Quản lý phỏng vấn:** Đặt lịch, nhắc nhở tự động qua push notification
- **Dashboard nhà tuyển dụng:** Đăng tin, quản lý ứng viên, thống kê
- **AI Chatbot:** Hỏi đáp thông minh về việc làm, CV, phỏng vấn

### Hình ảnh minh họa gợi ý
- Video/GIF demo từng tính năng
- Screenshots theo thứ tự demo
- Lưu ý: Chuẩn bị sẵn dữ liệu test, kết nối internet ổn định

---

## Slide 6: Công nghệ sử dụng (Technology Stack)

### Tiêu đề slide
**Công nghệ và thư viện tích hợp**

### Bullet Points
- **Frontend:** Flutter (Dart) - Cross-platform mobile development
- **Backend & Database:** Supabase (PostgreSQL, Auth, Realtime, Storage)
- **AI/ML:**
  - Mistral AI - Phân tích CV, chatbot, intent-based queries
  - Google ML Kit - OCR text recognition
- **Notifications:** Firebase Cloud Messaging (FCM)
- **Payment:** PayOS - Thanh toán trực tuyến
- **State Management:** ChangeNotifier + BaseController pattern
- **Networking:** Dio với interceptors cho error handling
- **Charts:** FL Chart cho biểu đồ thống kê
- **Khác:** Speech-to-Text, PDF Viewer, QR Code, WebView

### Hình ảnh minh họa gợi ý
- Bảng tech stack phân loại theo nhóm (Backend, AI, UI, Payment...)
- Logo các công nghệ chính (Flutter, Supabase, Firebase, Mistral AI)
- Sơ đồ kết nối giữa các service bên ngoài

---

## Slide 7: Kết quả đạt được (Results)

### Tiêu đề slide
**Kết quả thực hiện và thống kê**

### Bullet Points
- **Tính năng hoàn thành:**
  - 10 feature modules hoàn chỉnh
  - 17 services xử lý business logic
  - 16 repositories quản lý data access
  - 24 models dữ liệu
  - 4 vai trò người dùng (Candidate, Employer, School, Admin)
- **Tích hợp thành công:**
  - 5 external services (Supabase, Firebase, Mistral AI, Google ML Kit, PayOS)
  - AI matching với độ chính xác cao
  - Realtime sync cho chat và notifications
- **Điểm sáng:**
  - Hệ thống AI phân tích CV tự động
  - Multi-role platform (4 vai trò)
  - OCR scanning CV từ ảnh
  - Realtime communication

### Hình ảnh minh họa gợi ý
- Bảng thống kê số liệu dự án
- Biểu đồ so sánh tính năng với hệ thống khác (TopCV, VietnamWorks)
- Screenshots kết quả AI matching, OCR scanning

---

## Slide 8: Hướng phát triển (Future Development)

### Tiêu đề slide
**Hướng phát triển và cải tiến tương lai**

### Bullet Points
- **Ngắn hạn:**
  - Tối ưu hiệu năng AI matching (caching, batch processing)
  - Thêm unit test và integration test coverage
  - Cải thiện UX/UI dựa trên feedback người dùng
- **Trung hạn:**
  - Mở rộng lên web platform (Flutter Web)
  - Tích hợp thêm AI models cho phỏng vấn ảo
  - Hệ thống recommendation nâng cao (collaborative filtering)
  - Đa ngôn ngữ (i18n)
- **Dài hạn:**
  - Mở rộng thị trường (nhiều trường đại học, doanh nghiệp)
  - Tích hợp blockchain cho xác thực bằng cấp
  - Analytics dashboard nâng cao cho trường học
  - API mở cho đối tác tích hợp

### Hình ảnh minh họa gợi ý
- Roadmap timeline (ngắn hạn → trung hạn → dài hạn)
- Sơ đồ mở rộng hệ thống
- Icon minh họa các tính năng tương lai

---

## Slide bổ sung: Q&A

### Tiêu đề slide
**Câu hỏi và thảo luận**

### Bullet Points
- Cảm ơn hội đồng đã lắng nghe
- Sẵn sàng trả lời câu hỏi
- Thông tin liên hệ

### Hình ảnh minh họa gợi ý
- Slide đơn giản với text "Cảm ơn" và thông tin liên hệ
- QR code link đến repository hoặc demo

---

## Tổng kết cấu trúc slide

| STT | Slide | Thời gian ước tính | Mục đích |
|-----|-------|-------------------|----------|
| 1 | Giới thiệu | 1-2 phút | Tạo ấn tượng ban đầu |
| 2 | Vấn đề | 2-3 phút | Đặt bối cảnh, tạo sự đồng cảm |
| 3 | Giải pháp | 2-3 phút | Trình bày ý tưởng giải quyết |
| 4 | Kiến trúc | 3-4 phút | Thể hiện năng lực kỹ thuật |
| 5 | Demo | 4-5 phút | Chứng minh sản phẩm hoạt động |
| 6 | Công nghệ | 2-3 phút | Giải thích lựa chọn công nghệ |
| 7 | Kết quả | 2-3 phút | Tổng kết thành tựu |
| 8 | Hướng phát triển | 1-2 phút | Thể hiện tầm nhìn |
| - | Q&A | 5-10 phút | Trả lời câu hỏi hội đồng |

**Tổng thời lượng thuyết trình:** 17-25 phút (bao gồm Q&A)

---

## Liên kết liên quan

- [Kịch bản nói từng slide](./slide_scripts.md)
- [Kịch bản thuyết trình chi tiết](../09_kich_ban_thuyet_trinh_chi_tiet.md)
- [Tổng quan kiến trúc](../01_tong_quan_kien_truc.md)
- [Điểm sáng kỹ thuật và business](../05_diem_sang_ky_thuat_va_business.md)
- [So sánh với hệ thống khác](../06_so_sanh_voi_he_thong_khac.md)
- [Tóm tắt để trình chiếu](../12_tom_tat_de_trinh_chieu.md)
