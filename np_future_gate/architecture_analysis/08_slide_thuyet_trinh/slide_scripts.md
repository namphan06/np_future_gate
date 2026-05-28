# Kịch Bản Nói Cho Từng Slide

## Mục đích

Tài liệu này cung cấp kịch bản nói chi tiết cho từng slide trong buổi thuyết trình bảo vệ đồ án NP FutureGate. Mỗi slide bao gồm nội dung cần nói, thời gian ước tính, và ghi chú về cách trình bày.

---

## Tổng Quan Thời Lượng

| Phần | Slide | Thời gian | Tích lũy |
|------|-------|-----------|----------|
| Mở đầu & Giới thiệu | 1-2 | 2 phút | 2 phút |
| Vấn đề & Giải pháp | 3-4 | 2.5 phút | 4.5 phút |
| Kiến trúc hệ thống | 5-7 | 4 phút | 8.5 phút |
| Công nghệ & Tích hợp | 8-10 | 3.5 phút | 12 phút |
| Demo & Kết quả | 11-12 | 3 phút | 15 phút |
| Điểm sáng & Khác biệt | 13-14 | 2.5 phút | 17.5 phút |
| Hướng phát triển & Kết luận | 15-16 | 2.5 phút | 20 phút |

**Tổng thời lượng: ~18-20 phút** (linh hoạt ±2 phút tùy phần demo)

---

## Slide 1: Trang bìa — Giới thiệu đề tài

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> Kính chào thầy/cô và các bạn. Em tên là Phan Vũ Hoài Nam, sinh viên khóa 22, mã số 22010066. Hôm nay em xin trình bày đồ án tốt nghiệp với đề tài: "NP FutureGate — Nền tảng kết nối việc làm thông minh dành cho sinh viên".
>
> Đây là một ứng dụng mobile được phát triển bằng Flutter, tích hợp trí tuệ nhân tạo để hỗ trợ sinh viên tìm kiếm việc làm phù hợp, đồng thời kết nối nhà tuyển dụng và trường học trên cùng một nền tảng.

**Ghi chú trình bày:**
- Nói chậm, rõ ràng
- Nhìn hội đồng khi giới thiệu bản thân
- Chuyển sang slide tiếp theo sau khi nêu tên đề tài

---

## Slide 2: Mục tiêu đồ án

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> Đồ án của em hướng đến 4 mục tiêu chính:
>
> Thứ nhất, xây dựng nền tảng kết nối 3 bên: sinh viên, nhà tuyển dụng, và trường học — điều mà các nền tảng hiện tại như TopCV hay VietnamWorks chưa làm được.
>
> Thứ hai, ứng dụng AI vào quy trình tuyển dụng — cụ thể là phân tích CV tự động và gợi ý mức độ phù hợp giữa ứng viên với công việc.
>
> Thứ ba, tích hợp các công nghệ hiện đại: realtime sync, push notifications, OCR scanning, thanh toán trực tuyến.
>
> Và cuối cùng, đảm bảo trải nghiệm người dùng mượt mà trên cả Android và iOS thông qua Flutter.

**Ghi chú trình bày:**
- Đếm ngón tay khi liệt kê từng mục tiêu
- Nhấn mạnh "kết nối 3 bên" và "AI" vì đây là điểm khác biệt

---

## Slide 3: Vấn đề thực tế

**⏱ Thời gian: 1.5 phút**

**Kịch bản nói:**

> Trước khi đi vào giải pháp, em xin trình bày vấn đề thực tế mà em quan sát được.
>
> Hiện nay, sinh viên gặp nhiều khó khăn khi tìm việc: không biết mình phù hợp với công việc nào, CV viết chưa đúng cách, và thiếu kênh kết nối trực tiếp với nhà tuyển dụng.
>
> Về phía nhà tuyển dụng, họ mất rất nhiều thời gian sàng lọc hàng trăm CV thủ công, khó tiếp cận nguồn sinh viên chất lượng từ các trường.
>
> Còn trường học thì hầu như không có công cụ nào để theo dõi tình hình việc làm của sinh viên sau khi ra trường, cũng như kết nối với doanh nghiệp một cách có hệ thống.
>
> Các nền tảng hiện tại như TopCV, VietnamWorks chủ yếu phục vụ người đi làm có kinh nghiệm, chưa tối ưu cho đối tượng sinh viên mới ra trường.

**Ghi chú trình bày:**
- Nói với giọng đồng cảm khi mô tả vấn đề
- Có thể hỏi "Chắc hẳn nhiều bạn sinh viên cũng từng gặp tình huống này"

---

## Slide 4: Giải pháp — NP FutureGate

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> NP FutureGate ra đời để giải quyết những vấn đề trên. Đây là một nền tảng kết nối việc làm thông minh với 3 điểm cốt lõi:
>
> Một là, hệ thống đa vai trò — 4 loại người dùng: sinh viên, nhà tuyển dụng, trường học, và admin — tất cả tương tác trên cùng một ứng dụng.
>
> Hai là, AI-powered matching — sử dụng Mistral AI để phân tích CV và đánh giá mức độ phù hợp với công việc, cho điểm từ 0 đến 100.
>
> Ba là, realtime experience — chat trực tiếp, thông báo tức thì, cập nhật trạng thái ngay lập tức nhờ Supabase Realtime.

**Ghi chú trình bày:**
- Giọng tự tin, thể hiện sự hào hứng với giải pháp
- Chỉ vào sơ đồ tổng quan trên slide nếu có

---

## Slide 5: Kiến trúc tổng thể — MVC Pattern

**⏱ Thời gian: 1.5 phút**

**Kịch bản nói:**

> Về kiến trúc, em áp dụng mô hình MVC kết hợp với ChangeNotifier của Flutter. Hệ thống được phân thành 3 tầng rõ ràng:
>
> Tầng Presentation — gồm các Screens và Widgets, chịu trách nhiệm hiển thị giao diện.
>
> Tầng Business Logic — gồm Controllers kế thừa từ BaseController, và các Services xử lý logic phức tạp.
>
> Tầng Data — gồm Repositories giao tiếp với database, và Models ánh xạ dữ liệu.
>
> Điểm đặc biệt là em tự thiết kế một BaseController abstract class kế thừa ChangeNotifier, cung cấp sẵn quản lý loading state, error handling, và safe notification — tức là kiểm tra widget đã bị dispose chưa trước khi gọi notifyListeners. Tất cả feature controllers đều kế thừa từ lớp này, đảm bảo tính nhất quán trong toàn bộ ứng dụng.

**Ghi chú trình bày:**
- Chỉ vào sơ đồ phân tầng trên slide
- Nhấn mạnh "BaseController" và "safe notification" — đây là thiết kế riêng

---

## Slide 6: Cấu trúc dự án & Feature Modules

**⏱ Thời gian: 1.5 phút**

**Kịch bản nói:**

> Dự án được tổ chức thành 10 feature modules, mỗi module tuân theo cấu trúc nhất quán: controllers, screens, và widgets.
>
> Các module chính bao gồm: auth cho xác thực, ai cho matching và chatbot, candidate cho ứng viên, employer cho nhà tuyển dụng, school cho trường học, admin cho quản trị, chat cho nhắn tin realtime, cv cho quản lý CV, interview cho phỏng vấn, và notification cho thông báo đẩy.
>
> Ngoài ra, phần core chứa 17 services, 16 repositories, và 24 data models — tất cả được tổ chức rõ ràng và tái sử dụng xuyên suốt ứng dụng.
>
> Em cũng thiết kế PaginationMixin — một mixin có thể gắn vào bất kỳ controller nào cần phân trang, giúp tránh lặp code khi load danh sách dữ liệu lớn.

**Ghi chú trình bày:**
- Có thể show cấu trúc thư mục trên slide
- Nhấn mạnh con số: 10 modules, 17 services, 16 repositories, 24 models

---

## Slide 7: Luồng dữ liệu & State Management

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> Luồng dữ liệu trong ứng dụng đi theo một chiều rõ ràng: Người dùng tương tác trên UI → Controller nhận sự kiện và set loading state → Repository hoặc Service xử lý → Kết quả trả về Controller → Controller gọi notifyListeners → UI tự động rebuild.
>
> Cơ chế này đảm bảo UI luôn phản ánh đúng trạng thái hiện tại: đang loading, có lỗi, hay đã có dữ liệu. Và nhờ safe notification, ứng dụng không bị crash khi navigate ra khỏi màn hình trong lúc đang load dữ liệu.

**Ghi chú trình bày:**
- Chỉ vào sequence diagram trên slide
- Nói nhanh gọn vì phần này khá technical

---

## Slide 8: Công nghệ sử dụng — Tech Stack

**⏱ Thời gian: 1.5 phút**

**Kịch bản nói:**

> Về công nghệ, em sử dụng Flutter làm framework chính — cho phép build ứng dụng chạy trên cả Android và iOS từ một codebase duy nhất.
>
> Backend em chọn Supabase — một nền tảng open-source cung cấp đầy đủ: Authentication, PostgreSQL Database với Row Level Security, Realtime qua WebSocket, và Storage cho file uploads.
>
> Về AI, em tích hợp Mistral AI — một Large Language Model hỗ trợ tiếng Việt tốt — cho việc phân tích CV và chatbot.
>
> OCR scanning sử dụng Google ML Kit — xử lý hoàn toàn trên thiết bị, không gửi dữ liệu CV nhạy cảm lên server.
>
> Push notifications qua Firebase Cloud Messaging V1 API với OAuth2 authentication.
>
> Và thanh toán qua PayOS — cổng thanh toán nội địa Việt Nam.

**Ghi chú trình bày:**
- Có thể dùng bảng hoặc icon cho từng công nghệ trên slide
- Nhấn mạnh lý do chọn: "open-source", "hỗ trợ tiếng Việt", "on-device"

---

## Slide 9: Tích hợp AI — Mistral AI Pipeline

**⏱ Thời gian: 1.5 phút**

**Kịch bản nói:**

> Đây là phần em muốn nhấn mạnh nhất — pipeline AI trong ứng dụng.
>
> Hệ thống AI có 3 chức năng chính:
>
> Thứ nhất, CV Matching — nhận CV của ứng viên và yêu cầu công việc, gửi đến Mistral AI, nhận về điểm phù hợp tổng thể, điểm tương đồng ngữ nghĩa, điểm keyword match, cùng danh sách điểm phù hợp và điểm còn thiếu.
>
> Thứ hai, Chatbot thông minh — duy trì ngữ cảnh hội thoại, hỗ trợ tiếng Việt hoàn toàn, có thể trả lời câu hỏi về việc làm, lịch phỏng vấn, trạng thái ứng tuyển.
>
> Thứ ba, Intent-based queries — đây là điểm đặc biệt. Khi người dùng hỏi bằng ngôn ngữ tự nhiên, ví dụ "Có bao nhiêu việc IT ở Hà Nội?", hệ thống sẽ phân tích intent, truy vấn dữ liệu thực từ database, rồi dùng AI format câu trả lời. Tức là AI không bịa số liệu mà lấy dữ liệu thật.

**Ghi chú trình bày:**
- Chỉ vào flowchart AI pipeline trên slide
- Nhấn mạnh "dữ liệu thật, không bịa" khi nói về intent-based queries
- Đây là điểm sáng lớn nhất — nói chậm và rõ

---

## Slide 10: OCR & Realtime — Công nghệ nổi bật

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> Hai công nghệ nổi bật khác em muốn trình bày:
>
> OCR Scanning với Google ML Kit — hỗ trợ 3 loại input: ảnh chụp, file PDF, và URL. Đặc biệt, PDF được render ở độ phân giải 3x rồi mới OCR để đảm bảo chất lượng. Toàn bộ xử lý diễn ra trên thiết bị, đảm bảo bảo mật thông tin CV.
>
> Realtime Sync với Supabase — sử dụng WebSocket để đồng bộ dữ liệu tức thì. Chat hiển thị tin nhắn ngay lập tức, số tin chưa đọc cập nhật realtime, trạng thái công việc thông báo ngay khi thay đổi.

**Ghi chú trình bày:**
- Nói ngắn gọn, tập trung vào điểm khác biệt
- Chuẩn bị chuyển sang phần demo

---

## Slide 11: Demo ứng dụng

**⏱ Thời gian: 2 phút**

**Kịch bản nói:**

> Bây giờ em xin demo trực tiếp ứng dụng.
>
> *(Mở ứng dụng trên điện thoại/emulator)*
>
> Đầu tiên, em đăng nhập với vai trò ứng viên. Đây là màn hình chính với danh sách việc làm được gợi ý.
>
> Em sẽ demo tính năng AI Matching — chọn một công việc, bấm "Phân tích CV". Hệ thống sẽ gửi CV của em lên Mistral AI và trả về kết quả... Như các thầy cô thấy, điểm phù hợp là [X]/100, với danh sách điểm mạnh và điểm cần cải thiện.
>
> Tiếp theo, em demo chatbot — hỏi "Có việc gì phù hợp với em không?" — chatbot sẽ phân tích intent và trả lời dựa trên dữ liệu thực.
>
> Cuối cùng, em chuyển sang vai trò nhà tuyển dụng để show tính năng quản lý ứng viên và so sánh CV.

**Ghi chú trình bày:**
- Chuẩn bị sẵn dữ liệu demo, đảm bảo internet ổn định
- Nếu demo lỗi, có screenshot backup
- Thời gian demo linh hoạt: có thể rút ngắn nếu cần

---

## Slide 12: Kết quả đạt được

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> Về kết quả, ứng dụng đã hoàn thành với các con số:
>
> 10 feature modules hoạt động đầy đủ, 17 services tích hợp, 5 dịch vụ bên ngoài kết nối thành công: Supabase, Firebase, Mistral AI, Google ML Kit, và PayOS.
>
> Hệ thống hỗ trợ 4 vai trò người dùng với giao diện và quyền truy cập riêng biệt. Bảo mật được đảm bảo ở cấp database với Row Level Security.
>
> Ứng dụng chạy mượt trên cả Android và iOS, hỗ trợ tiếng Việt hoàn toàn trong cả giao diện lẫn AI chatbot.

**Ghi chú trình bày:**
- Có thể dùng infographic với con số nổi bật
- Nói tự tin về kết quả

---

## Slide 13: Điểm sáng & Khác biệt

**⏱ Thời gian: 1.5 phút**

**Kịch bản nói:**

> So với các nền tảng tuyển dụng hiện có, NP FutureGate có những điểm khác biệt nổi bật:
>
> Một, vai trò trường học — đây là điều TopCV và VietnamWorks không có. Trường có thể liên kết với doanh nghiệp, giới thiệu việc làm cho sinh viên, và theo dõi tình hình việc làm.
>
> Hai, AI pipeline hoàn chỉnh — từ OCR scan CV → trích xuất text → AI phân tích → kết quả có cấu trúc. Không chỉ matching đơn giản mà còn phân tích chi tiết điểm mạnh, điểm yếu.
>
> Ba, bảo mật dữ liệu — OCR xử lý on-device, RLS ở database level, OAuth2 cho push notifications. Dữ liệu CV nhạy cảm không bao giờ rời khỏi thiết bị trong bước OCR.
>
> Bốn, intent-based AI — chatbot không chỉ trả lời chung chung mà truy vấn dữ liệu thực từ database, đảm bảo thông tin chính xác.

**Ghi chú trình bày:**
- Dùng bảng so sánh trên slide
- Nhấn mạnh từng điểm bằng cách đếm ngón tay

---

## Slide 14: So sánh với hệ thống khác

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> Em xin tóm tắt so sánh nhanh với các hệ thống tương tự:
>
> TopCV và VietnamWorks — phục vụ người đi làm có kinh nghiệm, không có vai trò trường học, AI matching hạn chế, không có chat realtime trực tiếp.
>
> LinkedIn — nền tảng quốc tế, không tối ưu cho thị trường Việt Nam, không có OCR tiếng Việt, không tích hợp thanh toán nội địa.
>
> NP FutureGate — tập trung vào sinh viên Việt Nam, có AI phân tích CV tiếng Việt, kết nối 3 bên, và tích hợp PayOS cho thanh toán nội địa.

**Ghi chú trình bày:**
- Chỉ vào bảng so sánh trên slide
- Nói ngắn gọn, không cần đi sâu vào từng tiêu chí

---

## Slide 15: Hạn chế & Hướng phát triển

**⏱ Thời gian: 1.5 phút**

**Kịch bản nói:**

> Em cũng nhận thức được một số hạn chế hiện tại:
>
> Về AI, độ chính xác phụ thuộc vào chất lượng CV đầu vào và khả năng của Mistral AI với tiếng Việt. Trong tương lai, em có thể fine-tune model riêng cho domain tuyển dụng Việt Nam.
>
> Về scalability, hiện tại hệ thống phù hợp cho quy mô vừa. Để mở rộng lớn hơn, cần thêm caching layer, CDN cho media, và có thể chuyển sang microservices.
>
> Về tính năng, em dự định bổ sung: video interview trực tiếp trong app, AI gợi ý cải thiện CV chi tiết hơn, hệ thống đánh giá và review công ty, và mở rộng sang web platform.
>
> Hướng phát triển dài hạn là xây dựng hệ sinh thái việc làm hoàn chỉnh cho sinh viên Việt Nam — từ khi còn đi học đến khi đi làm.

**Ghi chú trình bày:**
- Thể hiện sự trung thực khi nói về hạn chế
- Giọng lạc quan khi nói về hướng phát triển

---

## Slide 16: Kết luận & Cảm ơn

**⏱ Thời gian: 1 phút**

**Kịch bản nói:**

> Tóm lại, NP FutureGate là một nền tảng kết nối việc làm thông minh, được xây dựng với kiến trúc MVC rõ ràng, tích hợp 5 dịch vụ bên ngoài, và ứng dụng AI vào quy trình tuyển dụng.
>
> Điểm nổi bật nhất là pipeline AI hoàn chỉnh: OCR → phân tích → matching → gợi ý, cùng với mô hình kết nối 3 bên mà các nền tảng hiện tại chưa có.
>
> Em xin cảm ơn thầy/cô đã lắng nghe. Em sẵn sàng trả lời câu hỏi từ hội đồng.

**Ghi chú trình bày:**
- Nói chậm, trang trọng
- Cúi đầu cảm ơn
- Sẵn sàng tinh thần cho phần Q&A

---

## Phụ Lục: Câu Hỏi Dự Kiến & Gợi Ý Trả Lời

### Q1: "Tại sao chọn Supabase thay vì Firebase?"

> Supabase sử dụng PostgreSQL — database quan hệ mạnh mẽ với Row Level Security, phù hợp cho hệ thống đa vai trò. Firebase dùng NoSQL (Firestore) khó thực hiện query phức tạp và join bảng. Ngoài ra, Supabase là open-source, có thể self-host nếu cần.

### Q2: "Tại sao chọn ChangeNotifier thay vì Bloc hoặc Riverpod?"

> ChangeNotifier là giải pháp native của Flutter, không cần thêm dependency. Với quy mô dự án đồ án, ChangeNotifier đủ mạnh và dễ hiểu. Em đã thiết kế BaseController để chuẩn hóa cách sử dụng, tránh các lỗi phổ biến như gọi notifyListeners sau dispose.

### Q3: "AI matching có chính xác không? Đánh giá thế nào?"

> Độ chính xác phụ thuộc vào chất lượng prompt và dữ liệu đầu vào. Em đã thiết kế prompt chi tiết với các tiêu chí đánh giá rõ ràng. Kết quả trả về dạng JSON có cấu trúc, bao gồm cả giải thích lý do — giúp người dùng tự đánh giá tính hợp lý.

### Q4: "Bảo mật dữ liệu CV như thế nào?"

> Ba lớp bảo mật: (1) OCR xử lý on-device — CV không gửi lên server bên thứ ba, (2) Row Level Security ở database — mỗi user chỉ truy cập được dữ liệu của mình, (3) Supabase Storage với access control — file CV chỉ người sở hữu mới download được.

### Q5: "Hệ thống có thể mở rộng được không?"

> Có. Kiến trúc phân tầng rõ ràng cho phép thay thế từng thành phần. Ví dụ: có thể đổi Mistral AI sang GPT-4 mà không ảnh hưởng UI, hoặc thêm caching layer giữa Repository và Supabase. Supabase cũng hỗ trợ scale horizontal.

### Q6: "Tại sao chọn Mistral AI mà không phải ChatGPT?"

> Mistral AI có API pricing hợp lý hơn cho đồ án sinh viên, hỗ trợ tiếng Việt tốt, và response time nhanh. Kiến trúc của em cho phép dễ dàng chuyển sang model khác trong tương lai vì logic AI được đóng gói trong MistralService.

---

## Liên kết liên quan

- [Điểm chính từng slide](./slide_key_points.md)
- [Kịch bản thuyết trình chi tiết](../09_kich_ban_thuyet_trinh_chi_tiet.md)
- [Điểm sáng kỹ thuật và business](../05_diem_sang_ky_thuat_va_business.md)
- [Tổng quan kiến trúc](../01_tong_quan_kien_truc.md)
- [So sánh với hệ thống khác](../06_so_sanh_voi_he_thong_khac.md)
