# Tài liệu Kiến trúc MVC - Hệ thống NP FutureGate (Chi tiết)

Tài liệu này mô tả chi tiết các thành phần trong mô hình MVC của dự án NP FutureGate, bao gồm danh sách các hàm xử lý trong tầng Controller (Repository) tương tự như mẫu yêu cầu.

## 1. Model (Thực thể dữ liệu)

- **User / Profile (Người dùng):** Quản lý thông tin tài khoản người dùng (Ứng viên, NTD, Admin). Bao gồm: ID, họ tên, email, số điện thoại, ảnh đại diện, vai trò (role), trạng thái hoạt động (is_active) và các thông tin định hướng nghề nghiệp.
- **Job (Việc làm):** Chứa thông tin về bản tin tuyển dụng. Bao gồm: tên công việc, mô tả, yêu cầu, mức lương, địa điểm, ngành nghề, trạng thái (approved/pending/closed) và thời hạn nộp hồ sơ.
- **Application (Đơn ứng tuyển):** Thông tin ứng cử của ứng viên vào một công việc. Bao gồm: mã đơn, liên kết ứng viên, công việc, CV đi kèm, ngày ứng tuyển và trạng thái xét duyệt (pending, accepted, rejected).
- **Interview (Lịch phỏng vấn):** Quản lý thông tin các buổi phỏng vấn. Bao gồm: mã lịch, ứng viên, người phỏng vấn, thời gian, hình thức, địa điểm, trạng thái (scheduled, completed, cancelled) và đánh giá.
- **CV / Document (Hồ sơ & Tài liệu):** Quản lý các tệp tin CV. Chứa đường dẫn lưu trữ trên Storage, loại tệp, ngày tải lên và các thuộc tính trích xuất từ nội dung hồ sơ.
- **CareerNews / Course (Tin tức & Khóa học):** Lưu trữ bài viết hướng nghiệp và khóa học. Bao gồm tiêu đề, nội dung, hình ảnh, loại chủ đề và các liên kết liên quan.
- **AIIntent / MIResult (AI & Trắc nghiệm):** Lưu trữ lịch sử chat với AI và kết quả trắc nghiệm đa trí tuệ (MI) để phân tích thế mạnh và gợi ý việc làm.
- **Notification / Message (Thông báo & Tin nhắn):** Quản lý tương tác realtime, nội dung tin nhắn chat và thông báo đẩy (FCM).

## 2. View (Giao diện hiển thị)

- **Xác thực:** Màn hình Đăng nhập, Đăng ký, Quên mật khẩu và Xác thực OTP.
- **Trang chủ Ứng viên:** Hiển thị tin tuyển dụng gợi ý, tin tức nghề nghiệp và thanh tìm kiếm.
- **Tìm kiếm việc làm:** Màn hình lọc và tìm kiếm việc làm theo nhiều tiêu chí (ngành nghề, vị trí, lương).
- **Việc làm của tôi:** Danh sách các công việc đã ứng tuyển và theo dõi trạng thái hồ sơ.
- **Quản lý CV & Hồ sơ:** Giao diện tạo, tải lên và quản lý danh sách các bản CV chuyên nghiệp.
- **Lịch biểu phỏng vấn:** Màn hình hiển thị các buổi phỏng vấn sắp tới cho Ứng viên và NTD.
- **Định hướng chuyên sâu (MI):** Màn hình thực hiện bài test đa trí tuệ và xem kết quả phân tích.
- **Dashboard Nhà tuyển dụng:** Tổng quan tin tuyển dụng, ứng viên mới và các thống kê tuyển dụng.
- **Đăng tin tuyển dụng:** Giao diện tạo mới, chỉnh sửa và quản lý các bản tin tuyển dụng.
- **Quản lý ứng viên (NTD):** Danh sách hồ sơ ứng tuyển, xem chi tiết CV và chuyển trạng thái tuyển dụng.
- **Hệ thống AI Chatbot:** Giao diện chat tương tác hỗ trợ tìm việc và giải đáp thắc mắc.
- **Quản lý hệ thống (Admin):** Màn hình quản lý người dùng, duyệt tin đăng và cấu hình hệ thống.

## 3. Controller (Logic xử lý - Repositories & Services)

### AuthRepository (AuthController):
- `signUpWithEmail()`: Xử lý đăng ký tài khoản mới với email, mật khẩu và vai trò.
- `signInWithEmail()`: Xử lý đăng nhập người dùng bằng email và mật khẩu.
- `signInWithGoogle()`: Xử lý đăng nhập thông qua tài khoản Google.
- `signOut()`: Xử lý đăng xuất và xóa token thiết bị khỏi hệ thống.
- `resetPassword()`: Gửi yêu cầu đặt lại mật khẩu qua email.
- `getCurrentUserProfile()`: Lấy thông tin chi tiết profile người dùng hiện tại.
- `updateProfile()`: Cập nhật thông tin profile (họ tên, ảnh diện, số điện thoại...).
- `uploadAvatar()`: Tải lên và cập nhật ảnh đại diện người dùng.
- `updatePassword()`: Xử lý thay đổi mật khẩu người dùng.

### JobRepository (JobManagementController):
- `getActiveJobs()`: Hiển thị danh sách các công việc đang tuyển dụng (phía Ứng viên).
- `getJobById($id)`: Hiển thị chi tiết thông tin một bản tin tuyển dụng.
- `getEmployerJobs($creatorId)`: Hiển thị danh sách tin đã đăng của Nhà tuyển dụng.
- `createJob()`: Xử lý đăng tin tuyển dụng mới (có kiểm tra hạn mức gói).
- `updateJob($id)`: Cập nhật thông tin tin tuyển dụng hiện có.
- `deleteJob($id)`: Xóa tin tuyển dụng khỏi hệ thống.
- `applyForJob()`: Xử lý nộp hồ sơ ứng tuyển vào một công việc.
- `toggleSaveJob()`: Xử lý lưu hoặc bỏ lưu tin tuyển dụng yêu thích.
- `getSavedJobs()`: Hiển thị danh sách các công việc ứng viên đã lưu.
- `getAppliedJobs()`: Hiển thị danh sách các công việc ứng viên đã ứng tuyển.
- `updateApplicationStatus()`: NTD cập nhật trạng thái hồ sơ (Duyệt/Từ chối).
- `getEmployerStats()`: Thống kê số lượng tin đăng và ứng viên cho NTD.

### InterviewRepository (InterviewController):
- `getInterviewsByEmployer()`: Hiển thị danh sách lịch hẹn của Nhà tuyển dụng.
- `getInterviewsByCandidate()`: Hiển thị danh sách lịch hẹn của Ứng viên.
- `createInterview()`: Lập lịch phỏng vấn mới và cài đặt nhắc hẹn tự động.
- `updateStatus($id, $status)`: Cập nhật trạng thái buổi phỏng vấn (Hoàn thành/Hủy).
- `updateEvaluation($id)`: Lưu thông tin đánh giá ứng viên sau phỏng vấn.
- `updateShare($id, $bool)`: Cài đặt cho phép ứng viên xem kết quả đánh giá.
- `rescheduleInterview($id)`: Thay đổi thời gian buổi phỏng vấn.
- `deleteInterview($id)`: Xóa lịch hẹn phỏng vấn.

### AdminUserRepository (AdminManagementController):
- `getUsersByRole($role)`: Hiển thị danh sách người dùng theo vai trò.
- `getUserById($id)`: Hiển thị chi tiết thông tin người dùng.
- `toggleUserActiveStatus($id)`: Xử lý khóa hoặc kích hoạt lại tài khoản.
- `setPostLimit($id, $limit)`: Cài đặt hạn mức đăng tin cho Nhà tuyển dụng/Trường học.
- `deleteUserAccount($id)`: Xóa tài khoản người dùng khỏi hệ thống.
- `getUserStatistics($id)`: Thống kê chi tiết hoạt động của một người dùng.
- `searchUsers($query)`: Tìm kiếm người dùng trong hệ thống.

### AIService & Others:
- `detectIntent($text)`: Xử lý phân tích ý định người dùng trong Chatbot.
- `matchJobsForProfile()`: Gợi ý công việc phù hợp dựa trên AI.
- `getNews()`: Hiển thị danh sách tin tức nghề nghiệp.
- `getCourses()`: Hiển thị danh sách các khóa học đào tạo.
