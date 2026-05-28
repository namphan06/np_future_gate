# Tài liệu Phân tích Kiến trúc - NP FutureGate

## Mục đích

Bộ tài liệu phân tích kiến trúc toàn diện cho dự án **NP FutureGate** — nền tảng kết nối việc làm giữa sinh viên/ứng viên với nhà tuyển dụng và trường học. Tài liệu phục vụ cho việc thuyết trình và bảo vệ đồ án tốt nghiệp đại học.

## Cấu trúc thư mục

```
architecture_analysis/
├── README.md                                              ← Bạn đang ở đây
├── 01_tong_quan_kien_truc.md
├── 02_co_che_tung_chuc_nang/
│   ├── authentication_flow.md
│   ├── ai_matching_flow.md
│   ├── notification_flow.md
│   ├── realtime_sync_flow.md
│   ├── payment_flow.md
│   ├── interview_flow.md
│   ├── cv_management_flow.md
│   ├── job_posting_flow.md
│   └── chat_flow.md
├── 03_so_do_flow/
│   ├── mermaid_sequence_diagrams.md
│   ├── state_management_flow.mermaid
│   └── navigation_flow.mermaid
├── 04_cong_nghe_su_dung/
│   ├── tech_stack_overview.md
│   └── tech_comparison_reason.md
├── 05_diem_sang_ky_thuat_va_business.md
├── 06_so_sanh_voi_he_thong_khac.md
├── 07_phan_tich_diem_con_thieu_va_khac_biet_noi_bat.md
├── 08_slide_thuyet_trinh/
│   ├── slide_key_points.md
│   └── slide_scripts.md
├── 09_kich_ban_thuyet_trinh_chi_tiet.md
├── 10_giai_thich_cong_nghe_tung_cai/
│   ├── flutter.md
│   ├── state_management_changenotifier.md
│   ├── supabase.md
│   ├── mistral_ai.md
│   ├── firebase_fcm.md
│   ├── google_mlkit_ocr.md
│   ├── dio_vs_http.md
│   ├── fl_chart.md
│   ├── speech_to_text.md
│   └── payos_payment.md
├── 11_phan_tich_cac_file_dung_chung/
│   ├── utils_analysis.md
│   ├── themes_analysis.md
│   ├── constants_analysis.md
│   ├── routes_analysis.md
│   └── network_interceptor_analysis.md
└── 12_tom_tat_de_trinh_chieu.md
```

## Mục lục tài liệu

### 1. Tổng quan kiến trúc

| Tài liệu | Mô tả |
|-----------|--------|
| [01. Tổng quan kiến trúc](./01_tong_quan_kien_truc.md) | Kiến trúc MVC tổng thể, sơ đồ phân tầng, state management, cấu trúc thư mục dự án |

### 2. Cơ chế từng chức năng

| Tài liệu | Mô tả |
|-----------|--------|
| [Authentication Flow](./02_co_che_tung_chuc_nang/authentication_flow.md) | Luồng đăng nhập/đăng ký qua Supabase Auth và Google Sign-In |
| [AI Matching Flow](./02_co_che_tung_chuc_nang/ai_matching_flow.md) | Cơ chế phân tích CV bằng Mistral AI, chatbot, intent-based queries |
| [Notification Flow](./02_co_che_tung_chuc_nang/notification_flow.md) | Push notification qua Firebase Cloud Messaging |
| [Realtime Sync Flow](./02_co_che_tung_chuc_nang/realtime_sync_flow.md) | Đồng bộ realtime qua Supabase Realtime |
| [Payment Flow](./02_co_che_tung_chuc_nang/payment_flow.md) | Luồng thanh toán qua PayOS |
| [Interview Flow](./02_co_che_tung_chuc_nang/interview_flow.md) | Quản lý phỏng vấn và nhắc nhở |
| [CV Management Flow](./02_co_che_tung_chuc_nang/cv_management_flow.md) | Quản lý CV và OCR scanning bằng Google ML Kit |
| [Job Posting Flow](./02_co_che_tung_chuc_nang/job_posting_flow.md) | Đăng tin tuyển dụng và matching |
| [Chat Flow](./02_co_che_tung_chuc_nang/chat_flow.md) | Chat realtime giữa các vai trò |

### 3. Sơ đồ luồng (Flow Diagrams)

| Tài liệu | Mô tả |
|-----------|--------|
| [Sequence Diagrams](./03_so_do_flow/mermaid_sequence_diagrams.md) | Sơ đồ tuần tự cho các luồng chính |
| [State Management Flow](./03_so_do_flow/state_management_flow.mermaid) | Sơ đồ luồng state management |
| [Navigation Flow](./03_so_do_flow/navigation_flow.mermaid) | Sơ đồ navigation giữa các màn hình theo vai trò |

### 4. Công nghệ sử dụng

| Tài liệu | Mô tả |
|-----------|--------|
| [Tech Stack Overview](./04_cong_nghe_su_dung/tech_stack_overview.md) | Tổng quan toàn bộ công nghệ và thư viện |
| [Tech Comparison & Reason](./04_cong_nghe_su_dung/tech_comparison_reason.md) | Lý do chọn từng công nghệ, so sánh với lựa chọn thay thế |

### 5. Điểm sáng kỹ thuật và Business

| Tài liệu | Mô tả |
|-----------|--------|
| [Điểm sáng kỹ thuật và Business](./05_diem_sang_ky_thuat_va_business.md) | Điểm nổi bật về kỹ thuật và giá trị business |

### 6. So sánh với hệ thống khác

| Tài liệu | Mô tả |
|-----------|--------|
| [So sánh với hệ thống khác](./06_so_sanh_voi_he_thong_khac.md) | So sánh với TopCV, VietnamWorks, LinkedIn |

### 7. Phân tích điểm còn thiếu và khác biệt nổi bật

| Tài liệu | Mô tả |
|-----------|--------|
| [Gap Analysis](./07_phan_tich_diem_con_thieu_va_khac_biet_noi_bat.md) | Điểm cần cải thiện và hướng phát triển tương lai |

### 8. Slide thuyết trình

| Tài liệu | Mô tả |
|-----------|--------|
| [Slide Key Points](./08_slide_thuyet_trinh/slide_key_points.md) | Điểm chính cho từng slide |
| [Slide Scripts](./08_slide_thuyet_trinh/slide_scripts.md) | Kịch bản nói cho từng slide |

### 9. Kịch bản thuyết trình chi tiết

| Tài liệu | Mô tả |
|-----------|--------|
| [Kịch bản thuyết trình](./09_kich_ban_thuyet_trinh_chi_tiet.md) | Kịch bản chi tiết 15-20 phút, câu hỏi dự kiến từ hội đồng |

### 10. Giải thích công nghệ từng cái

| Tài liệu | Mô tả |
|-----------|--------|
| [Flutter](./10_giai_thich_cong_nghe_tung_cai/flutter.md) | Framework phát triển ứng dụng đa nền tảng |
| [State Management (ChangeNotifier)](./10_giai_thich_cong_nghe_tung_cai/state_management_changenotifier.md) | Quản lý trạng thái với ChangeNotifier + BaseController |
| [Supabase](./10_giai_thich_cong_nghe_tung_cai/supabase.md) | Backend-as-a-Service: Auth, Database, Realtime, Storage |
| [Mistral AI](./10_giai_thich_cong_nghe_tung_cai/mistral_ai.md) | AI phân tích CV, chatbot, intent-based queries |
| [Firebase FCM](./10_giai_thich_cong_nghe_tung_cai/firebase_fcm.md) | Push notifications |
| [Google ML Kit OCR](./10_giai_thich_cong_nghe_tung_cai/google_mlkit_ocr.md) | Nhận dạng văn bản từ hình ảnh |
| [Dio vs Http](./10_giai_thich_cong_nghe_tung_cai/dio_vs_http.md) | So sánh HTTP client và lý do chọn Dio |
| [FL Chart](./10_giai_thich_cong_nghe_tung_cai/fl_chart.md) | Biểu đồ thống kê |
| [Speech to Text](./10_giai_thich_cong_nghe_tung_cai/speech_to_text.md) | Nhận dạng giọng nói |
| [PayOS Payment](./10_giai_thich_cong_nghe_tung_cai/payos_payment.md) | Cổng thanh toán |

### 11. Phân tích các file dùng chung

| Tài liệu | Mô tả |
|-----------|--------|
| [Utils Analysis](./11_phan_tich_cac_file_dung_chung/utils_analysis.md) | Phân tích các utility files |
| [Themes Analysis](./11_phan_tich_cac_file_dung_chung/themes_analysis.md) | Phân tích hệ thống theme |
| [Constants Analysis](./11_phan_tich_cac_file_dung_chung/constants_analysis.md) | Phân tích constants và enums |
| [Routes Analysis](./11_phan_tich_cac_file_dung_chung/routes_analysis.md) | Phân tích cấu trúc routing/navigation |
| [Network Interceptor Analysis](./11_phan_tich_cac_file_dung_chung/network_interceptor_analysis.md) | Phân tích Dio interceptors và xử lý network |

### 12. Tóm tắt để trình chiếu

| Tài liệu | Mô tả |
|-----------|--------|
| [Tóm tắt trình chiếu](./12_tom_tat_de_trinh_chieu.md) | Tóm tắt toàn bộ kiến trúc (tối đa 3 trang A4) |

## Hướng dẫn sử dụng

### Đọc theo thứ tự

Nếu bạn muốn hiểu toàn bộ hệ thống từ đầu đến cuối, hãy đọc theo thứ tự số:

1. Bắt đầu với [Tổng quan kiến trúc](./01_tong_quan_kien_truc.md) để nắm bức tranh tổng thể
2. Đọc [Cơ chế từng chức năng](./02_co_che_tung_chuc_nang/) để hiểu chi tiết từng module
3. Xem [Sơ đồ luồng](./03_so_do_flow/) để hình dung trực quan
4. Tham khảo [Công nghệ sử dụng](./04_cong_nghe_su_dung/) để hiểu lý do chọn tech stack

### Chuẩn bị thuyết trình

Nếu bạn đang chuẩn bị cho buổi bảo vệ đồ án:

1. Đọc [Tóm tắt trình chiếu](./12_tom_tat_de_trinh_chieu.md) để nắm nhanh nội dung
2. Xem [Slide Key Points](./08_slide_thuyet_trinh/slide_key_points.md) cho nội dung từng slide
3. Luyện tập với [Kịch bản thuyết trình](./09_kich_ban_thuyet_trinh_chi_tiet.md)
4. Chuẩn bị câu trả lời từ phần Q&A trong kịch bản

### Tra cứu nhanh

- **Muốn biết công nghệ X hoạt động thế nào?** → Xem thư mục [10_giai_thich_cong_nghe_tung_cai/](./10_giai_thich_cong_nghe_tung_cai/)
- **Muốn biết file dùng chung nào làm gì?** → Xem thư mục [11_phan_tich_cac_file_dung_chung/](./11_phan_tich_cac_file_dung_chung/)
- **Muốn so sánh với hệ thống khác?** → Xem [So sánh hệ thống](./06_so_sanh_voi_he_thong_khac.md)
- **Muốn biết điểm mạnh của dự án?** → Xem [Điểm sáng](./05_diem_sang_ky_thuat_va_business.md)

## Quy ước

- **Ngôn ngữ**: Toàn bộ nội dung mô tả bằng tiếng Việt, code giữ nguyên tiếng Anh
- **Sơ đồ**: Sử dụng Mermaid diagrams (render được trên GitHub/GitLab)
- **Liên kết**: Sử dụng relative links cho tất cả liên kết chéo giữa các tài liệu
- **Tên file**: Snake_case, prefix số thứ tự, tiếng Việt không dấu
- **Heading**: Tuân theo hierarchy h1 > h2 > h3, không skip level

## Thông tin dự án

| Thông tin | Giá trị |
|-----------|---------|
| Tên dự án | NP FutureGate |
| Loại ứng dụng | Flutter mobile app (đa nền tảng) |
| Kiến trúc | MVC với ChangeNotifier |
| Feature modules | 10 (auth, ai, candidate, employer, school, admin, chat, cv, interview, notification) |
| Services | 17 |
| Repositories | 16 |
| Models | 24 |
| External integrations | 5 (Supabase, Firebase, Mistral AI, Google ML Kit, PayOS) |
| User roles | 4 (Candidate, Employer, School, Admin) |
