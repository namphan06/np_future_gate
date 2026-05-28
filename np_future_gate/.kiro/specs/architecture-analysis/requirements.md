# Requirements Document

## Introduction

Tạo thư mục tài liệu phân tích kiến trúc toàn diện (`architecture_analysis/`) cho dự án NP FutureGate - nền tảng kết nối việc làm giữa sinh viên/ứng viên với nhà tuyển dụng và trường học. Tài liệu phục vụ cho việc thuyết trình và bảo vệ đồ án tốt nghiệp đại học, được viết bằng tiếng Việt.

## Glossary

- **Documentation_Generator**: Hệ thống tạo tài liệu phân tích kiến trúc
- **Architecture_Overview_Doc**: Tài liệu tổng quan kiến trúc hệ thống (01_tong_quan_kien_truc.md)
- **Feature_Flow_Docs**: Bộ tài liệu mô tả cơ chế từng chức năng (thư mục 02_co_che_tung_chuc_nang/)
- **Flow_Diagrams**: Bộ sơ đồ luồng dữ liệu và tương tác (thư mục 03_so_do_flow/)
- **Tech_Stack_Docs**: Bộ tài liệu công nghệ sử dụng (thư mục 04_cong_nghe_su_dung/)
- **Highlights_Doc**: Tài liệu điểm sáng kỹ thuật và business (05_diem_sang_ky_thuat_va_business.md)
- **Comparison_Doc**: Tài liệu so sánh với hệ thống khác (06_so_sanh_voi_he_thong_khac.md)
- **Gap_Analysis_Doc**: Tài liệu phân tích điểm còn thiếu và khác biệt nổi bật (07_phan_tich_diem_con_thieu_va_khac_biet_noi_bat.md)
- **Presentation_Slides**: Bộ tài liệu slide thuyết trình (thư mục 08_slide_thuyet_trinh/)
- **Presentation_Script**: Kịch bản thuyết trình chi tiết (09_kich_ban_thuyet_trinh_chi_tiet.md)
- **Tech_Explanations**: Bộ tài liệu giải thích từng công nghệ (thư mục 10_giai_thich_cong_nghe_tung_cai/)
- **Shared_Files_Analysis**: Bộ tài liệu phân tích các file dùng chung (thư mục 11_phan_tich_cac_file_dung_chung/)
- **Summary_Doc**: Tài liệu tóm tắt để trình chiếu (12_tom_tat_de_trinh_chieu.md)
- **Mermaid_Diagram**: Sơ đồ được viết bằng cú pháp Mermaid để hiển thị trực quan
- **MVC_Architecture**: Mô hình Model-View-Controller được sử dụng trong dự án
- **NP_FutureGate**: Ứng dụng Flutter kết nối việc làm cho sinh viên

## Requirements

### Requirement 1: Tổng quan kiến trúc hệ thống

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có tài liệu tổng quan kiến trúc từ high-level đến low-level, để giảng viên hiểu được toàn bộ cấu trúc hệ thống.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo file `architecture_analysis/01_tong_quan_kien_truc.md` chứa mô tả kiến trúc MVC tổng thể của dự án
2. THE Architecture_Overview_Doc SHALL bao gồm sơ đồ phân tầng (Presentation Layer, Business Logic Layer, Data Layer)
3. THE Architecture_Overview_Doc SHALL mô tả cơ chế state management dựa trên ChangeNotifier và BaseController
4. THE Architecture_Overview_Doc SHALL liệt kê cấu trúc thư mục dự án với giải thích vai trò từng thư mục (core/, features/, screens/, shared/)
5. THE Architecture_Overview_Doc SHALL mô tả luồng dữ liệu từ UI qua Controller đến Repository và Service
6. THE Architecture_Overview_Doc SHALL bao gồm sơ đồ tương tác giữa các thành phần chính (Supabase, Firebase, Mistral AI, Google ML Kit)

### Requirement 2: Cơ chế từng chức năng

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có tài liệu chi tiết cơ chế hoạt động của từng chức năng, để có thể giải thích rõ ràng khi được hỏi.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo thư mục `architecture_analysis/02_co_che_tung_chuc_nang/` chứa các file tài liệu riêng cho từng luồng chức năng
2. THE Feature_Flow_Docs SHALL bao gồm file `authentication_flow.md` mô tả luồng đăng nhập/đăng ký qua Supabase Auth và Google Sign-In
3. THE Feature_Flow_Docs SHALL bao gồm file `ai_matching_flow.md` mô tả cơ chế phân tích CV bằng Mistral AI, chatbot, và hệ thống intent-based queries
4. THE Feature_Flow_Docs SHALL bao gồm file `notification_flow.md` mô tả luồng push notification qua Firebase Cloud Messaging và local notifications
5. THE Feature_Flow_Docs SHALL bao gồm file `realtime_sync_flow.md` mô tả cơ chế đồng bộ realtime qua Supabase Realtime
6. THE Feature_Flow_Docs SHALL bao gồm file `payment_flow.md` mô tả luồng thanh toán qua PayOS
7. THE Feature_Flow_Docs SHALL bao gồm file `interview_flow.md` mô tả cơ chế quản lý phỏng vấn và nhắc nhở
8. THE Feature_Flow_Docs SHALL bao gồm file `cv_management_flow.md` mô tả luồng quản lý CV bao gồm OCR scanning bằng Google ML Kit
9. THE Feature_Flow_Docs SHALL bao gồm file `job_posting_flow.md` mô tả luồng đăng tin tuyển dụng và matching
10. THE Feature_Flow_Docs SHALL bao gồm file `chat_flow.md` mô tả cơ chế chat realtime giữa các vai trò
11. WHEN mô tả một luồng chức năng, THE Feature_Flow_Docs SHALL bao gồm: mục đích, các thành phần tham gia, luồng xử lý step-by-step, xử lý lỗi, và các service/repository liên quan

### Requirement 3: Sơ đồ luồng (Flow Diagrams)

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có sơ đồ trực quan bằng Mermaid, để minh họa luồng hoạt động khi thuyết trình.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo thư mục `architecture_analysis/03_so_do_flow/` chứa các file sơ đồ Mermaid
2. THE Flow_Diagrams SHALL bao gồm file `mermaid_sequence_diagrams.md` chứa sequence diagrams cho các luồng chính (authentication, AI matching, notification, payment)
3. THE Flow_Diagrams SHALL bao gồm file `state_management_flow.mermaid` mô tả luồng state management từ user action đến UI update
4. THE Flow_Diagrams SHALL bao gồm file `navigation_flow.mermaid` mô tả cấu trúc navigation giữa các màn hình theo vai trò (Candidate, Employer, School, Admin)
5. WHEN tạo sequence diagram, THE Flow_Diagrams SHALL sử dụng cú pháp Mermaid hợp lệ có thể render được
6. THE Flow_Diagrams SHALL bao gồm chú thích tiếng Việt cho từng bước trong sơ đồ

### Requirement 4: Công nghệ sử dụng

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có tài liệu tổng hợp và so sánh công nghệ, để giải thích lý do chọn từng công nghệ.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo thư mục `architecture_analysis/04_cong_nghe_su_dung/` chứa tài liệu về tech stack
2. THE Tech_Stack_Docs SHALL bao gồm file `tech_stack_overview.md` liệt kê toàn bộ công nghệ và thư viện từ pubspec.yaml kèm mô tả vai trò
3. THE Tech_Stack_Docs SHALL bao gồm file `tech_comparison_reason.md` giải thích lý do chọn từng công nghệ so với các lựa chọn thay thế (ví dụ: Supabase vs Firebase, ChangeNotifier vs Bloc/Riverpod, Dio vs Http)
4. THE Tech_Stack_Docs SHALL phân loại công nghệ theo nhóm: Backend, AI/ML, UI, Networking, Storage, Authentication, Payment, Notifications

### Requirement 5: Điểm sáng kỹ thuật và business

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có tài liệu nêu bật các điểm sáng, để tạo ấn tượng tốt với hội đồng chấm.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo file `architecture_analysis/05_diem_sang_ky_thuat_va_business.md`
2. THE Highlights_Doc SHALL liệt kê các điểm sáng kỹ thuật bao gồm: tích hợp AI (Mistral), OCR scanning, realtime sync, multi-role system, push notifications
3. THE Highlights_Doc SHALL liệt kê các điểm sáng business bao gồm: job matching algorithm, CV analysis tự động, hệ thống phỏng vấn, kết nối đa bên (sinh viên - nhà tuyển dụng - trường học)
4. THE Highlights_Doc SHALL giải thích giá trị thực tiễn của từng điểm sáng đối với người dùng cuối

### Requirement 6: So sánh với hệ thống khác

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có bảng so sánh với các hệ thống tương tự, để chứng minh tính mới và giá trị của đồ án.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo file `architecture_analysis/06_so_sanh_voi_he_thong_khac.md`
2. THE Comparison_Doc SHALL so sánh NP FutureGate với các nền tảng tuyển dụng phổ biến (TopCV, VietnamWorks, LinkedIn)
3. THE Comparison_Doc SHALL sử dụng bảng so sánh theo các tiêu chí: tính năng AI, đối tượng mục tiêu, công nghệ, tính năng đặc biệt
4. THE Comparison_Doc SHALL nêu rõ các tính năng mà NP FutureGate có mà các hệ thống khác chưa có hoặc chưa tập trung

### Requirement 7: Phân tích điểm còn thiếu và khác biệt nổi bật

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn tự nhận diện điểm còn thiếu và khác biệt, để thể hiện tư duy phản biện trước hội đồng.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo file `architecture_analysis/07_phan_tich_diem_con_thieu_va_khac_biet_noi_bat.md`
2. THE Gap_Analysis_Doc SHALL liệt kê các điểm còn thiếu hoặc cần cải thiện trong hệ thống hiện tại
3. THE Gap_Analysis_Doc SHALL đề xuất hướng phát triển tương lai cho từng điểm còn thiếu
4. THE Gap_Analysis_Doc SHALL nêu rõ các khác biệt nổi bật so với đồ án cùng loại (tích hợp AI, multi-role, realtime)

### Requirement 8: Slide thuyết trình

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có nội dung slide và kịch bản nói, để chuẩn bị thuyết trình hiệu quả.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo thư mục `architecture_analysis/08_slide_thuyet_trinh/` chứa nội dung slide
2. THE Presentation_Slides SHALL bao gồm file `slide_key_points.md` liệt kê các điểm chính cho từng slide (tiêu đề, bullet points, hình ảnh minh họa gợi ý)
3. THE Presentation_Slides SHALL bao gồm file `slide_scripts.md` chứa kịch bản nói cho từng slide với thời gian ước tính
4. THE Presentation_Slides SHALL bao gồm cấu trúc slide theo thứ tự: Giới thiệu, Vấn đề, Giải pháp, Kiến trúc, Demo, Công nghệ, Kết quả, Hướng phát triển

### Requirement 9: Kịch bản thuyết trình chi tiết

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có kịch bản thuyết trình chi tiết từng phút, để tự tin khi trình bày.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo file `architecture_analysis/09_kich_ban_thuyet_trinh_chi_tiet.md`
2. THE Presentation_Script SHALL bao gồm kịch bản nói chi tiết cho toàn bộ buổi thuyết trình (ước tính 15-20 phút)
3. THE Presentation_Script SHALL bao gồm các câu hỏi dự kiến từ hội đồng và câu trả lời gợi ý
4. THE Presentation_Script SHALL bao gồm các điểm nhấn cần lưu ý khi trình bày (ngôn ngữ cơ thể, thời điểm chuyển slide, demo)
5. THE Presentation_Script SHALL phân chia thời gian rõ ràng cho từng phần: mở đầu, nội dung chính, demo, Q&A

### Requirement 10: Giải thích công nghệ từng cái

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có tài liệu giải thích chi tiết từng công nghệ, để trả lời câu hỏi chuyên sâu từ hội đồng.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo thư mục `architecture_analysis/10_giai_thich_cong_nghe_tung_cai/` chứa file giải thích cho từng công nghệ
2. THE Tech_Explanations SHALL bao gồm các file: `flutter.md`, `state_management_changenotifier.md`, `supabase.md`, `mistral_ai.md`, `firebase_fcm.md`, `google_mlkit_ocr.md`, `dio_vs_http.md`, `fl_chart.md`, `speech_to_text.md`, `payos_payment.md`
3. WHEN giải thích một công nghệ, THE Tech_Explanations SHALL bao gồm: định nghĩa, lý do sử dụng trong dự án, cách tích hợp, ưu điểm, nhược điểm, và ví dụ code minh họa từ dự án
4. THE Tech_Explanations SHALL bao gồm file giải thích cho tất cả thư viện có trong pubspec.yaml (bao gồm: flutter_svg, qr_flutter, file_picker, image_picker, intl, url_launcher, share_plus, permission_handler, device_info_plus, package_info_plus, googleapis_auth, timezone, path_provider, pdfx, syncfusion_flutter_pdfviewer, flutter_widget_from_html, youtube_player_flutter, google_fonts, webview_flutter)

### Requirement 11: Phân tích các file dùng chung

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có tài liệu phân tích các file dùng chung, để giải thích cách tổ chức code hiệu quả.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo thư mục `architecture_analysis/11_phan_tich_cac_file_dung_chung/` chứa phân tích các module dùng chung
2. THE Shared_Files_Analysis SHALL bao gồm file `utils_analysis.md` phân tích các utility functions (date_time_utils, job_utils, snackbar_utils, statistics_utils)
3. THE Shared_Files_Analysis SHALL bao gồm file `themes_analysis.md` phân tích hệ thống theme (app_colors, app_gradients, app_main_colors, app_text_styles, app_theme)
4. THE Shared_Files_Analysis SHALL bao gồm file `constants_analysis.md` phân tích các hằng số và cấu hình (supabase_config, enums)
5. THE Shared_Files_Analysis SHALL bao gồm file `routes_analysis.md` phân tích cấu trúc navigation và routing
6. THE Shared_Files_Analysis SHALL bao gồm file `network_interceptor_analysis.md` phân tích cơ chế xử lý network (Dio interceptors, error handling)
7. WHEN phân tích một file dùng chung, THE Shared_Files_Analysis SHALL bao gồm: mục đích, cấu trúc, cách sử dụng trong dự án, và mối quan hệ với các module khác

### Requirement 12: Tóm tắt để trình chiếu

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn có bản tóm tắt ngắn gọn, để sử dụng như tài liệu tham khảo nhanh khi thuyết trình.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo file `architecture_analysis/12_tom_tat_de_trinh_chieu.md`
2. THE Summary_Doc SHALL tóm tắt toàn bộ kiến trúc hệ thống trong tối đa 3 trang A4
3. THE Summary_Doc SHALL bao gồm: tổng quan dự án, kiến trúc chính, công nghệ nổi bật, điểm sáng, và kết luận
4. THE Summary_Doc SHALL sử dụng bullet points và bảng để dễ đọc nhanh
5. THE Summary_Doc SHALL bao gồm các con số thống kê về dự án (số features, số screens, số services, số repositories)

### Requirement 13: Cấu trúc thư mục và tính nhất quán

**User Story:** Là một sinh viên bảo vệ đồ án, tôi muốn toàn bộ tài liệu có cấu trúc rõ ràng và nhất quán, để dễ tìm kiếm và tham khảo.

#### Acceptance Criteria

1. THE Documentation_Generator SHALL tạo thư mục gốc `architecture_analysis/` tại root của dự án
2. THE Documentation_Generator SHALL tạo file `architecture_analysis/README.md` mô tả cấu trúc thư mục và hướng dẫn sử dụng tài liệu
3. WHEN tạo tài liệu, THE Documentation_Generator SHALL sử dụng tiếng Việt cho toàn bộ nội dung
4. WHEN tạo tài liệu, THE Documentation_Generator SHALL sử dụng định dạng Markdown với heading, bullet points, code blocks, và bảng
5. THE Documentation_Generator SHALL đảm bảo các liên kết chéo giữa các tài liệu hoạt động chính xác (relative links)
6. THE Documentation_Generator SHALL sử dụng naming convention nhất quán: số thứ tự prefix, snake_case cho tên file, tiếng Việt không dấu cho tên file
