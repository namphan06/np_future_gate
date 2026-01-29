User:
- Việc làm hôm nay đang lấy theo ngày tạo nên khi sửa lại deadline cho tin tuyển dụng thì vẫn không hiển thị chỉ hiển thị ở tìm kiếm việc làm (done)
- Chưa có phân trang trong phần tìm kiếm (done)
- profile nơi có thể làm việc phải hiện list chứ không phải nhập 


Employer:
- Lịch phỏng vấn có thể xoá dữ liệu cũ với các lịch quá 10 ngày với các lịch tạm hoãn có thể dữ nguyên (dữ nguyên)
- Thêm phần lưu trữ các đánh giá ứng viên trong phỏng vấn (không cần)
- Cài đặt email thông báo còn thiếu với phần chấp nhận và tiêu đề chưa thể gán biến có sẵn , test thêm file và cải thiện giao diện
- Tại phần home danh sách các tin deadline đã được cập nhật nhưng lại hiện là hết hạn vừa xong kiểm tra lại logic (done)
- Thêm bảng đánh giá quá trình đối với học sinh nhà trường (done)



Admin:
- Hiện tại các tin liên kết từ đối tác khi doanh nghiệp chưa đồng ý đã hiện ở phía admin xác nhận (xem lại logic xem có nên chuyển đổi không)


School:
- Hiện tại liên kết doanh nghiệp chưa có dấu hiệu phên biệt doanh nghiệp đã liên kết và chưa liên kết ở trang tìm kiếm nhà tuyển dụng (done)
- Hiện tại chưa thay đổi được trạng thái dừng liên kết
- Tin tuyển dụng liên kết doanh nghiệp cần lấy thông tin doanh nghiệp hoặc thay đổi phương thức để có thẻ sửa được (hiện tại lấy thiếu doanh nghiệp không thể sửa được)
- Tin liên kết chưa xoá được
- Homepage thống kê mặc định là 0 cho các chỉ số (done)
- Hiện tại việc sửa tin liên kết có thể không khả thi vì công ty sẽ phải duyệt nhiều lần và thường sẽ lấy tin từ thông tin có sẵn nên có thể xem xét
- Nhà trường chưa có phần thông báo


Chung:
- Thêm thông báo khi gửi thông báo đến thiết bị 
- Có thể xem lại cách xác minh tài khoản trường học và học sinh trong trường (hiện tại đang xác minh thông qua đuôi email)
- Notification và device token đang RLS disable (Kiểm tra lại các quyền để chỉnh sau )
- Chưa dùng đến notification_reads
- Thông báo chưa chuyển được đến action cần thiết chỉnh lại sau
- Chi tiết công việc cần cải thiện giao 
- Trang cài đặt thông báo cần chỉnh lại tuỳ cho từng đối tượng và có thể liên kết đến việc các côgn ty ứng viên theo dõi 
- Tìm hiểu thêm chức năng mạng xã hội có thể học hỏi LinkedIn để có thể tạo thương hiệu cho bản thân ( xem xét có nên thêm không vì hiện tại nhà tuyển dụng đã có thể tìm kiếm ứng viên và gửi email đến ứng viên để cung cấp thông tin về việc làm)
- Thiếu các bài Skill Test trực tuyến (trắc nghiệm, code test) để ứng viên tự chứng minh năng lực trước khi Employer đánh giá thủ công.


Supabase:
- Hiện tại đã thay đổi delete cho role school để có thể xoá ngay cả khi company đã phê duyệt ban đầu là chỉ được xoá trước khi phê duyệt

Device:
- Hiện tại mỗi lần đăng nhập sẽ lưu vào bảng dữ liệu cần lọc trước khi lưu để tránh trùng
- Hiện tại buil trên máy nào thì mới gửi đi được thông báo trên thiết bị (test lại sau)

Notification:
- Hiện tại đã tạo thông báo với ứng tuyển cv,từ chối và đồng ý chưa test cơ chế giống từ chối
