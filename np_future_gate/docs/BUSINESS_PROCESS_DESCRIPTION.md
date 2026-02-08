# 2.2.1. MÔ TẢ QUY TRÌNH NGHIỆP VỤ HỆ THỐNG NP FUTUREGATE

Hệ thống **NP FutureGate** vận hành như một hệ sinh thái kết nối chặt chẽ giữa Ứng viên, Doanh nghiệp và Nhà trường dưới sự kiểm soát của Quản trị viên. Dưới đây là mô tả chi tiết cách thức xử lý và các luồng hoạt động của hệ thống.

---

## 1. QUY TRÌNH QUẢN LÝ TIN TUYỂN DỤNG VÀ PHÊ DUYỆT

Quy trình này đảm bảo mọi thông tin việc làm đưa đến ứng viên đều được kiểm chứng và có chất lượng.

### 1.1. Luồng đăng tin trực tiếp từ Doanh nghiệp
- **Khởi tạo:** Doanh nghiệp nhập nội dung tuyển dụng (yêu cầu, quyền lợi, mức lương). Hệ thống sẽ tự động đối chiếu với hạn mức đăng tin của tài khoản đó. Nếu vượt quá giới hạn, hệ thống yêu cầu xử lý các tin cũ trước khi tạo tin mới.
- **Xử lý trung gian:** Tin sau khi đăng sẽ rơi vào trạng thái "Chờ duyệt". Hệ thống thông báo cho Quản trị viên về nội dung mới cần kiểm tra.
- **Phê duyệt:** Quản trị viên xem xét tính hợp lệ của nội dung. Nếu đạt yêu cầu, tin sẽ được kích hoạt và bắt đầu xuất hiện trên bảng tin của Ứng viên. Nếu bị từ chối, Doanh nghiệp nhận được lý do cụ thể để chỉnh sửa.

### 1.2. Luồng đăng tin phối hợp (Nhà trường - Doanh nghiệp)
- **Đề xuất:** Nhà trường thay mặt Doanh nghiệp đối tác để tạo tin tuyển dụng (thường dành cho sinh viên thực tập).
- **Xác nhận 2 lớp:**
    - **Lớp 1 (Doanh nghiệp):** Tin nhắn yêu cầu được gửi tới Doanh nghiệp. Doanh nghiệp xem xét nội dung Nhà trường đã soạn thảo có đúng với thực tế không. Doanh nghiệp có quyền đồng ý hoặc yêu cầu Nhà trường sửa lại.
    - **Lớp 2 (Admin):** Sau khi Doanh nghiệp đã "gật đầu", tin mới được chuyển đến Quản trị viên để kiểm duyệt cuối cùng về mặt ngôn ngữ và tiêu chuẩn hệ thống.
- **Kích hoạt:** Sau khi vượt qua 2 lớp xác nhận, tin chính thức được xuất bản.

---

## 2. QUY TRÌNH ỨNG TUYỂN VÀ SÀNG LỌC HỒ SƠ

Đây là luồng tương tác chính giữa người tìm việc và người tuyển dụng.

### 2.1. Phía Ứng viên: Chọn lọc và Nộp đơn
- **Tìm kiếm:** Ứng viên sử dụng các tiêu chí về ngành nghề, mức lương, khu vực để lọc việc làm.
- **Ứng tuyển:** Khi chọn được việc làm, ứng viên chọn hồ sơ năng lực (CV) có sẵn trên hệ thống. Hệ thống sẽ ghi nhận hành động này và đồng thời thực hiện 3 việc:
    1. Cập nhật vào danh sách "Việc làm đã ứng tuyển" của cá nhân Ứng viên.
    2. Đẩy thông tin ứng viên vào kho dữ liệu quản lý của Doanh nghiệp sở hữu tin đăng.
    3. Gửi thông báo tức thời (chuông báo) tới Doanh nghiệp để họ biết có người vừa nộp hồ sơ.

### 2.2. Phía Doanh nghiệp: Kiểm tra và Phản hồi
- **Sàng lọc:** Doanh nghiệp xem trực tiếp hồ sơ của ứng viên. Họ có thể đánh dấu các hồ sơ tiềm năng hoặc loại bỏ các hồ sơ không phù hợp.
- **Phản hồi trạng thái:** Khi Doanh nghiệp thay đổi trạng thái hồ sơ (ví dụ: Chấp nhận hồ sơ), hệ thống sẽ ngay lập tức gửi phản hồi về cho Ứng viên. Điều này giúp Ứng viên không phải chờ đợi trong vô vọng và biết được tiến trình của mình.

---

## 3. QUY TRÌNH PHỎNG VẤN VÀ KẾT NỐI TRỰC TIẾP

- **Lên lịch hẹn:** Sau khi chấp nhận hồ sơ, Doanh nghiệp đề xuất một mốc thời gian phỏng vấn. Hệ thống đóng vai trò "Trợ lý" bằng cách kiểm tra lịch làm việc hiện tại của Doanh nghiệp để tránh việc đặt lịch trùng lặp.
- **Xác nhận:** Lịch hẹn sau khi tạo sẽ được hiển thị trên lịch cá nhân của cả hai bên. Cả Doanh nghiệp và Ứng viên đều nhận được nhắc nhở khi gần đến giờ hẹn.
- **Ghi nhận kết quả:** Sau buổi gặp, Doanh nghiệp nhập nhận xét và kết quả đạt/không đạt. Kết quả này sẽ quyết định việc ứng viên có đi tiếp vào quy trình làm việc thực tế hay không.

---

## 4. QUY TRÌNH QUẢN LÝ TIẾN ĐỘ THỰC TẬP VÀ ĐÁNH GIÁ (BA BÊN)

Đây là quy trình đặc trưng nhất của hệ thống, thể hiện sự phối hợp giữa Nhà trường và Doanh nghiệp trong việc quản lý sinh viên.

### 4.1. Lập kế hoạch và Giao việc
- **Khởi tạo lộ trình:** Khi sinh viên bắt đầu làm việc, Doanh nghiệp sẽ lập một "Bản đồ công việc" (Roadmap). Bản đồ này liệt kê các đầu công việc cụ thể, mục tiêu cần đạt và thời hạn hoàn thành.
- **Giám sát chung:** Nhà trường có một màn hình quản lý riêng để theo dõi lộ trình này. Khi Doanh nghiệp cập nhật tiến độ cho từng đầu việc, Nhà trường sẽ nhìn thấy ngay lập tức mà không cần phải gọi điện hay gửi báo cáo giấy.

### 4.2. Đánh giá cuối kỳ
- **Chấm điểm:** Kết thúc đợt làm việc, Doanh nghiệp thực hiện đánh giá tổng thể dựa trên 3 tiêu chí chính: Thái độ làm việc, Kỹ năng chuyên môn và Tính kỷ luật.
- **Công nhận kết quả:** Kết quả từ Doanh nghiệp được gửi trực tiếp về hệ thống quản lý của Nhà trường. Nhà trường căn cứ vào đây để đưa ra đánh giá cuối cùng về kết quả thực tập/làm việc của sinh viên.

---

## 5. QUY TRÌNH GIAO TIẾP VÀ THÔNG TIN ĐA KÊNH

- **Nhắn tin trực tiếp:** Ứng viên và Doanh nghiệp có thể trao đổi qua lại về các chi tiết công việc. Luồng thông tin này được lưu giữ để hai bên có thể tra cứu lại khi cần.
- **Thông báo hệ thống:** Mọi thay đổi về trạng thái (tin tuyển dụng được duyệt, có hồ sơ mới, có lịch phỏng vấn, có đánh giá mới) đều được hệ thống tự động xử lý và đẩy thông báo tới đúng đối tượng liên quan ngay lập tức.
- **Kênh thông tin bổ trợ:** Ngoài tuyển dụng, hệ thống còn vận hành luồng tin tức nghề nghiệp và các khóa học để Ứng viên chủ động nâng cao năng lực trong thời gian chờ đợi việc làm.

---
*Tổng kết: Hệ thống xử lý thông tin dưới dạng các "luồng chuyển trạng thái". Mỗi hành động của một đối tượng sẽ kích hoạt các phản ứng tương ứng của hệ thống để thông báo và cập nhật dữ liệu cho các đối tượng còn lại, tạo nên một quy trình khép kín và minh bạch.*
