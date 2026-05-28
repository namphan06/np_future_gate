# Lý Do Chọn Công Nghệ và So Sánh Với Các Lựa Chọn Thay Thế

## Mục đích

Tài liệu này giải thích lý do chọn từng công nghệ chính trong dự án NP FutureGate so với các lựa chọn thay thế phổ biến. Mỗi quyết định công nghệ được phân tích dựa trên các tiêu chí: phù hợp với yêu cầu dự án, chi phí, hiệu năng, khả năng mở rộng, và trải nghiệm phát triển.

---

## 1. Supabase vs Firebase vs Appwrite

### Bối cảnh lựa chọn

Dự án cần một Backend-as-a-Service (BaaS) cung cấp: xác thực người dùng, cơ sở dữ liệu quan hệ, realtime subscriptions, và file storage. Hệ thống có nhiều vai trò (Candidate, Employer, School, Admin) với quan hệ dữ liệu phức tạp.

### Bảng so sánh

| Tiêu chí | Supabase ✅ | Firebase | Appwrite |
|----------|-------------|----------|----------|
| **Cơ sở dữ liệu** | PostgreSQL (quan hệ, SQL) | Firestore (NoSQL, document) | MariaDB (quan hệ) |
| **Truy vấn phức tạp** | SQL đầy đủ, JOIN, subquery | Hạn chế, không hỗ trợ JOIN | SQL cơ bản |
| **Row Level Security** | Có (RLS policies mạnh mẽ) | Security Rules (phức tạp) | Permissions cơ bản |
| **Realtime** | Realtime subscriptions qua WebSocket | Realtime listeners tốt | Realtime events |
| **Authentication** | Email, OAuth, Magic Link | Email, OAuth, Phone, Anonymous | Email, OAuth |
| **Storage** | Có (S3-compatible) | Cloud Storage (mạnh) | Có (built-in) |
| **Chi phí** | Free tier rộng rãi, pay-as-you-go | Free tier, nhưng scale đắt | Self-hosted miễn phí |
| **Open Source** | Có (100% open source) | Không | Có |
| **Self-hosting** | Có thể tự host | Không | Có thể tự host |
| **Edge Functions** | Deno-based Edge Functions | Cloud Functions (Node.js) | Cloud Functions |
| **Cộng đồng Flutter** | Tốt, SDK chính thức | Rất lớn, FlutterFire | Nhỏ hơn |
| **Vendor lock-in** | Thấp (PostgreSQL chuẩn) | Cao (proprietary) | Thấp |

### Lý do chọn Supabase

1. **Cơ sở dữ liệu quan hệ (PostgreSQL):** Dự án NP FutureGate có mô hình dữ liệu phức tạp với nhiều quan hệ giữa các bảng (users, jobs, applications, interviews, CVs, notifications). PostgreSQL cho phép sử dụng JOIN, foreign keys, và truy vấn SQL phức tạp — điều mà Firestore (NoSQL) không hỗ trợ tốt.

2. **Row Level Security (RLS):** Hệ thống có 4 vai trò người dùng với quyền truy cập khác nhau. RLS policies của Supabase cho phép kiểm soát quyền truy cập ở cấp database, đảm bảo bảo mật mà không cần viết logic phức tạp ở backend.

3. **Chi phí hợp lý cho đồ án:** Free tier của Supabase đủ cho giai đoạn phát triển và demo. Không phát sinh chi phí bất ngờ như Firebase khi có nhiều reads/writes.

4. **Open source và không bị vendor lock-in:** Nếu cần migrate sang self-hosted PostgreSQL trong tương lai, dữ liệu và schema hoàn toàn tương thích.

5. **Realtime tích hợp sẵn:** Supabase Realtime cho phép subscribe changes trên bảng dữ liệu — phù hợp cho tính năng chat và thông báo realtime.

### Điểm Firebase vượt trội nhưng không cần thiết cho dự án

- Firebase có hệ sinh thái lớn hơn (Analytics, Crashlytics, Remote Config) — nhưng dự án chỉ cần FCM cho push notifications.
- Firestore phù hợp hơn cho dữ liệu phi cấu trúc — nhưng dữ liệu tuyển dụng có cấu trúc rõ ràng.

---

## 2. ChangeNotifier vs Bloc vs Riverpod vs GetX

### Bối cảnh lựa chọn

Dự án cần giải pháp state management cho ứng dụng Flutter với nhiều màn hình, nhiều vai trò người dùng, và các luồng dữ liệu phức tạp (AI matching, realtime chat, notifications).

### Bảng so sánh

| Tiêu chí | ChangeNotifier ✅ | Bloc/Cubit | Riverpod | GetX |
|----------|-------------------|------------|----------|------|
| **Độ phức tạp** | Thấp, dễ hiểu | Cao, nhiều boilerplate | Trung bình | Thấp nhưng magic |
| **Learning curve** | Thấp (Flutter native) | Cao (Events, States, Bloc) | Trung bình | Thấp |
| **Boilerplate code** | Ít | Nhiều (Event, State, Bloc classes) | Trung bình | Ít |
| **Testing** | Đơn giản | Rất tốt (bloc_test) | Tốt | Khó test |
| **Scalability** | Tốt với BaseController pattern | Rất tốt | Rất tốt | Trung bình |
| **Performance** | Tốt (granular rebuild) | Tốt | Tốt | Tốt |
| **Flutter native** | Có (foundation library) | Không (package bên ngoài) | Không (package bên ngoài) | Không |
| **Dependency injection** | Manual hoặc Provider | Bloc Provider | Tự động | Get.put/Get.find |
| **Phù hợp MVC** | Rất phù hợp | Phù hợp MVVM/Clean | Phù hợp mọi pattern | Phù hợp riêng GetX |
| **Cộng đồng** | Lớn (Flutter official) | Rất lớn | Đang phát triển | Lớn nhưng controversial |
| **Maintenance** | Flutter team duy trì | Community maintained | Community maintained | Community maintained |

### Lý do chọn ChangeNotifier

1. **Phù hợp với kiến trúc MVC:** Dự án sử dụng mô hình MVC với BaseController kế thừa ChangeNotifier. Pattern này cho phép Controller quản lý state và thông báo UI rebuild khi dữ liệu thay đổi — đúng với triết lý MVC.

2. **Flutter native, không phụ thuộc package bên ngoài:** ChangeNotifier là một phần của Flutter foundation library, được Flutter team duy trì. Không lo package bị deprecated hoặc breaking changes từ bên thứ ba.

3. **Ít boilerplate, phát triển nhanh:** Với đồ án tốt nghiệp có timeline giới hạn, ChangeNotifier cho phép viết code nhanh mà vẫn có cấu trúc rõ ràng. Không cần tạo nhiều file Event/State như Bloc.

4. **BaseController pattern tái sử dụng:** Dự án xây dựng BaseController abstract class với các tính năng chung (loading state, error handling, safe dispose) — tất cả feature controllers kế thừa và mở rộng.

5. **Dễ giải thích khi bảo vệ đồ án:** ChangeNotifier có cơ chế đơn giản (notify listeners → rebuild widgets), dễ trình bày và giải thích cho hội đồng chấm.

### Khi nào nên chọn Bloc/Riverpod thay thế

- **Bloc:** Khi dự án có team lớn (>5 người), cần strict architecture, hoặc có nhiều complex business logic cần test kỹ.
- **Riverpod:** Khi cần dependency injection mạnh mẽ, code generation, và compile-time safety.
- **GetX:** Không khuyến khích cho dự án nghiêm túc do thiếu separation of concerns và khó test.

---

## 3. Dio vs Http Package

### Bối cảnh lựa chọn

Dự án cần HTTP client để gọi các API bên ngoài: Mistral AI API (phân tích CV, chatbot), PayOS API (thanh toán), và Firebase Cloud Messaging V1 API. Cần xử lý interceptors, retry logic, và error handling nâng cao.

### Bảng so sánh

| Tiêu chí | Dio ✅ | http package |
|----------|--------|--------------|
| **Interceptors** | Có (request, response, error) | Không có built-in |
| **Retry logic** | Có (dio_retry, custom interceptor) | Phải tự implement |
| **Cancel requests** | Có (CancelToken) | Không hỗ trợ |
| **Upload/Download progress** | Có (onSendProgress, onReceiveProgress) | Không có |
| **FormData** | Có (multipart/form-data) | Phải tự xây dựng |
| **Timeout configuration** | Chi tiết (connect, send, receive) | Chỉ có timeout chung |
| **Base URL** | Có (BaseOptions) | Không có |
| **Request transformation** | Có (Transformer) | Không có |
| **Error handling** | DioException chi tiết | Chỉ có status code |
| **Logging** | LogInterceptor built-in | Phải tự implement |
| **Kích thước package** | Lớn hơn (~200KB) | Nhỏ (~50KB) |
| **Dependencies** | Nhiều hơn | Ít (Dart team maintained) |
| **Learning curve** | Trung bình | Thấp |

### Lý do chọn Dio (làm HTTP client chính)

1. **Interceptors cho authentication:** Dự án cần tự động gắn JWT token vào mọi request gọi Mistral AI và PayOS. Dio interceptors cho phép thêm headers, refresh token, và retry request một cách tự động.

2. **Error handling nâng cao:** Khi gọi Mistral AI API, cần phân biệt các loại lỗi (timeout, server error, rate limit). DioException cung cấp thông tin chi tiết hơn so với http package.

3. **Retry logic cho AI requests:** Gọi API AI có thể timeout hoặc rate-limited. Dio cho phép cấu hình retry với exponential backoff mà không cần viết logic phức tạp.

4. **Cancel requests:** Khi người dùng rời khỏi màn hình đang gọi AI, cần cancel request để tránh lãng phí tài nguyên. CancelToken của Dio hỗ trợ điều này.

5. **Upload progress cho CV:** Khi upload file CV, cần hiển thị progress bar. Dio cung cấp `onSendProgress` callback.

### Tại sao vẫn giữ http package

Dự án vẫn sử dụng `http` package cho một số request đơn giản (lightweight calls) không cần interceptors hay retry logic, giúp giảm overhead cho các API call nhỏ.

---

## 4. Flutter vs React Native vs Kotlin Multiplatform

### Bối cảnh lựa chọn

Dự án cần phát triển ứng dụng mobile cross-platform (Android + iOS) với giao diện phức tạp, tích hợp nhiều dịch vụ bên ngoài, và cần hiệu năng tốt cho realtime features.

### Bảng so sánh

| Tiêu chí | Flutter ✅ | React Native | Kotlin Multiplatform |
|----------|-----------|--------------|---------------------|
| **Ngôn ngữ** | Dart | JavaScript/TypeScript | Kotlin |
| **UI rendering** | Custom engine (Skia/Impeller) | Native components | Native components |
| **Hiệu năng** | Gần native (compiled AOT) | Bridge overhead | Native |
| **Hot reload** | Có (rất nhanh) | Có | Có (hạn chế) |
| **UI consistency** | Giống nhau mọi platform | Khác nhau theo platform | Khác nhau theo platform |
| **Hệ sinh thái** | Đang phát triển mạnh | Rất lớn (npm) | Nhỏ hơn |
| **Desktop/Web** | Có (single codebase) | Có (nhưng hạn chế) | Không (mobile only) |
| **Learning curve** | Trung bình (Dart mới) | Thấp (nếu biết JS) | Cao (Kotlin + platform) |
| **Google support** | Chính thức (Google) | Meta (Facebook) | JetBrains |
| **Supabase SDK** | Có (chính thức) | Có | Có (hạn chế) |
| **ML Kit integration** | Tốt (google_mlkit) | Tốt | Native |
| **State management** | Đa dạng (Provider, Bloc, etc.) | Redux, MobX, Context | MVVM native |

### Lý do chọn Flutter

1. **Single codebase cho nhiều nền tảng:** Một codebase Dart chạy trên Android, iOS, Web, macOS, Windows — tiết kiệm thời gian phát triển đáng kể cho đồ án cá nhân.

2. **UI rendering nhất quán:** Flutter sử dụng engine riêng (Skia/Impeller) để vẽ UI, đảm bảo giao diện giống nhau trên mọi thiết bị — quan trọng khi demo trước hội đồng.

3. **Hiệu năng tốt cho realtime:** Flutter compile sang native code (AOT), không có JavaScript bridge như React Native — phù hợp cho tính năng chat realtime và AI processing.

4. **Hệ sinh thái tích hợp tốt:** Supabase, Firebase, Google ML Kit đều có SDK Flutter chính thức, giảm thiểu vấn đề tương thích.

5. **Hot reload tăng tốc phát triển:** Thay đổi UI được phản ánh ngay lập tức — rất hữu ích khi phát triển đồ án với timeline ngắn.

6. **Được Google hỗ trợ chính thức:** Đảm bảo long-term support và cập nhật liên tục.

---

## 5. PayOS vs Stripe vs VNPay vs MoMo

### Bối cảnh lựa chọn

Dự án cần tích hợp cổng thanh toán cho tính năng mua gói dịch vụ (nhà tuyển dụng mua gói đăng tin). Yêu cầu: hỗ trợ thanh toán tại Việt Nam, tích hợp đơn giản, chi phí thấp cho đồ án.

### Bảng so sánh

| Tiêu chí | PayOS ✅ | Stripe | VNPay | MoMo |
|----------|---------|--------|-------|------|
| **Hỗ trợ Việt Nam** | Có (chuyên VN) | Hạn chế (chưa chính thức) | Có (phổ biến nhất) | Có (ví điện tử) |
| **Phương thức thanh toán** | QR, chuyển khoản, thẻ | Thẻ quốc tế, ví | Thẻ ATM, QR, ví | Ví MoMo, QR |
| **Tích hợp** | REST API + WebView (đơn giản) | SDK phức tạp | SDK + redirect | SDK + redirect |
| **Phí giao dịch** | Thấp | Cao (2.9% + 30¢) | Trung bình | Trung bình |
| **Đăng ký** | Nhanh, ít giấy tờ | Cần business verification | Nhiều giấy tờ, lâu | Cần hợp đồng |
| **Sandbox/Test** | Có (dễ test) | Có (rất tốt) | Có (phức tạp) | Có |
| **Documentation** | Tiếng Việt, rõ ràng | Tiếng Anh, rất chi tiết | Tiếng Việt, vừa | Tiếng Việt |
| **Flutter SDK** | Không (dùng REST + WebView) | Có (stripe_flutter) | Không chính thức | Không chính thức |
| **Webhook** | Có | Có (mạnh) | Có | Có |
| **Phù hợp đồ án** | Rất phù hợp | Khó đăng ký tại VN | Phức tạp đăng ký | Cần hợp đồng |

### Lý do chọn PayOS

1. **Đăng ký nhanh, phù hợp đồ án:** PayOS cho phép đăng ký tài khoản test nhanh chóng mà không cần giấy tờ doanh nghiệp — lý tưởng cho sinh viên làm đồ án.

2. **Hỗ trợ thanh toán Việt Nam:** Hỗ trợ QR code và chuyển khoản ngân hàng nội địa — phương thức thanh toán phổ biến nhất tại Việt Nam.

3. **Tích hợp đơn giản:** Chỉ cần gọi REST API để tạo payment link, sau đó mở WebView — không cần SDK phức tạp hay native integration.

4. **Chi phí thấp:** Phí giao dịch thấp hơn Stripe, phù hợp cho dự án quy mô nhỏ.

5. **Documentation tiếng Việt:** Tài liệu hướng dẫn bằng tiếng Việt, dễ hiểu và triển khai nhanh.

---

## 6. Mistral AI vs OpenAI (GPT) vs Google Gemini

### Bối cảnh lựa chọn

Dự án cần AI model để: phân tích CV và trích xuất thông tin, chatbot tư vấn nghề nghiệp, và hệ thống intent-based queries cho matching ứng viên với công việc.

### Bảng so sánh

| Tiêu chí | Mistral AI ✅ | OpenAI (GPT-4/3.5) | Google Gemini |
|----------|--------------|---------------------|---------------|
| **Chi phí API** | Thấp (rẻ hơn GPT-4 nhiều lần) | Cao (GPT-4), trung bình (GPT-3.5) | Trung bình, free tier có |
| **Chất lượng output** | Tốt (Mistral Large/Medium) | Rất tốt (GPT-4) | Tốt (Gemini Pro) |
| **Tốc độ response** | Nhanh | Trung bình (GPT-4 chậm) | Nhanh |
| **Rate limits** | Rộng rãi | Hạn chế (free tier) | Rộng rãi (free tier) |
| **Hỗ trợ tiếng Việt** | Tốt | Rất tốt | Tốt |
| **API đơn giản** | Có (OpenAI-compatible) | Có (chuẩn) | Có |
| **Free tier** | Có (generous) | Hạn chế | Có |
| **Open source models** | Có (Mistral 7B, Mixtral) | Không | Không |
| **EU data residency** | Có (Pháp) | Không đảm bảo | Không đảm bảo |
| **JSON mode** | Có | Có | Có |
| **Function calling** | Có | Có | Có |
| **Context window** | 32K-128K tokens | 8K-128K tokens | 32K-1M tokens |

### Lý do chọn Mistral AI

1. **Chi phí thấp, phù hợp đồ án sinh viên:** Mistral AI có pricing rẻ hơn đáng kể so với OpenAI GPT-4, cho phép gọi API nhiều lần trong quá trình phát triển và demo mà không lo chi phí.

2. **Free tier rộng rãi:** Mistral cung cấp free tier đủ cho phát triển và testing — quan trọng cho sinh viên với ngân sách hạn chế.

3. **Chất lượng đủ tốt cho use case:** Phân tích CV, chatbot tư vấn, và intent matching không yêu cầu model mạnh nhất (GPT-4). Mistral Medium/Large đáp ứng tốt các tác vụ này.

4. **API tương thích OpenAI:** Mistral API có format tương tự OpenAI, dễ dàng switch sang OpenAI nếu cần trong tương lai mà không cần thay đổi nhiều code.

5. **Tốc độ response nhanh:** Quan trọng cho trải nghiệm người dùng khi sử dụng chatbot và phân tích CV realtime.

6. **Open source models:** Có thể self-host Mistral 7B/Mixtral nếu muốn giảm chi phí hoặc tăng privacy trong tương lai.

---

## 7. Google ML Kit (On-device) vs Cloud Vision API vs Tesseract

### Bối cảnh lựa chọn

Dự án cần OCR (Optical Character Recognition) để trích xuất văn bản từ ảnh CV mà người dùng chụp hoặc upload.

### Bảng so sánh

| Tiêu chí | Google ML Kit ✅ | Cloud Vision API | Tesseract (on-device) |
|----------|-----------------|------------------|----------------------|
| **Xử lý** | On-device (offline) | Cloud (cần internet) | On-device (offline) |
| **Tốc độ** | Nhanh (không cần network) | Chậm hơn (network latency) | Trung bình |
| **Chi phí** | Miễn phí | Trả phí theo request | Miễn phí |
| **Độ chính xác** | Tốt | Rất tốt | Trung bình |
| **Hỗ trợ tiếng Việt** | Tốt | Rất tốt | Cần training data |
| **Flutter SDK** | Có (google_mlkit) | Cần REST API | Không chính thức |
| **Privacy** | Cao (data không rời device) | Thấp (gửi lên cloud) | Cao |
| **Offline support** | Có | Không | Có |
| **Setup complexity** | Thấp | Trung bình | Cao |

### Lý do chọn Google ML Kit

1. **Xử lý on-device, bảo mật cao:** CV chứa thông tin cá nhân nhạy cảm. ML Kit xử lý trực tiếp trên thiết bị, không gửi dữ liệu lên cloud — đảm bảo privacy.

2. **Miễn phí hoàn toàn:** Không phát sinh chi phí API call — phù hợp cho đồ án sinh viên.

3. **Hoạt động offline:** Người dùng có thể scan CV ngay cả khi không có internet.

4. **Flutter SDK chính thức:** Package `google_mlkit_text_recognition` được maintain tốt, dễ tích hợp.

5. **Tốc độ nhanh:** Không có network latency, kết quả OCR trả về gần như tức thì.

---

## Tổng kết quyết định công nghệ

| Lĩnh vực | Lựa chọn | Lý do chính |
|-----------|----------|-------------|
| Backend/Database | Supabase | PostgreSQL quan hệ, RLS, chi phí thấp |
| State Management | ChangeNotifier | Flutter native, ít boilerplate, phù hợp MVC |
| HTTP Client | Dio | Interceptors, retry, cancel, progress |
| Framework | Flutter | Cross-platform, hiệu năng, single codebase |
| Payment | PayOS | Đăng ký nhanh, hỗ trợ VN, chi phí thấp |
| AI Model | Mistral AI | Chi phí thấp, free tier, chất lượng đủ tốt |
| OCR | Google ML Kit | On-device, miễn phí, bảo mật, offline |

### Nguyên tắc chung khi chọn công nghệ

1. **Chi phí phù hợp sinh viên:** Ưu tiên free tier hoặc chi phí thấp
2. **Tích hợp đơn giản:** Ưu tiên SDK chính thức, documentation rõ ràng
3. **Phù hợp use case:** Không chọn công nghệ mạnh nhất mà chọn phù hợp nhất
4. **Khả năng mở rộng:** Có thể upgrade hoặc migrate trong tương lai
5. **Cộng đồng hỗ trợ:** Có tài liệu, ví dụ, và community support

---

## Liên kết liên quan

- [Tổng quan Tech Stack](./tech_stack_overview.md)
- [Tổng quan kiến trúc hệ thống](../01_tong_quan_kien_truc.md)
- [Giải thích chi tiết từng công nghệ](../10_giai_thich_cong_nghe_tung_cai/)
- [Điểm sáng kỹ thuật và business](../05_diem_sang_ky_thuat_va_business.md)
