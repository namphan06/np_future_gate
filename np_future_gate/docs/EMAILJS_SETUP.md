# Hướng dẫn Setup EmailJS Template

## Bước 1: Đăng ký EmailJS

1. Truy cập: https://www.emailjs.com/
2. Đăng ký tài khoản miễn phí
3. Xác nhận email

## Bước 2: Tạo Email Service

1. Dashboard > **Email Services** > **Add New Service**
2. Chọn Gmail (hoặc email provider của bạn)
3. Connect tài khoản email
4. Lưu **Service ID**

## Bước 3: Tạo Email Template

1. Dashboard > **Email Templates** > **Create New Template**
2. Đặt tên: `employer_response_template`
3. **Copy toàn bộ nội dung** file `emailjs_template.html`
4. Paste vào **Content** tab
5. **Save** template
6. Lưu **Template ID**

## Bước 4: Lấy Public Key

1. Dashboard > **Account** > **General**
2. Copy **Public Key**

## Bước 5: Update Flutter Code

Mở file `lib/core/services/emailjs_service.dart` và update:

```dart
static const String _serviceId = 'service_xxxxxxx';    // Từ Bước 2
static const String _templateId = 'template_xxxxxxx';  // Từ Bước 3
static const String _publicKey = 'xxxxxxxxxxxxxx';     // Từ Bước 4
```

## Variables trong Template

Template đã config sẵn các variables:

### **Required:**
- `{{name}}` - Tên người nhận (candidate_name)
- `{{to_email}}` - Email người nhận (auto từ EmailJS)
- `{{subject}}` - Tiêu đề email
- `{{message}}` - Nội dung chính (body với variables đã replace)
- `{{company_name}}` - Tên công ty
- `{{time}}` - Thời gian gửi (auto)

### **Optional:**
- `{{job_title}}` - Vị trí công việc
- `{{interview_date}}` - Ngày phỏng vấn
- `{{interview_time}}` - Giờ phỏng vấn

## Test Template

1. EmailJS Dashboard > Email Templates > Your Template
2. Click **Test it**
3. Fill sample data:
   ```json
   {
     "name": "Nguyễn Văn A",
     "to_email": "test@example.com",
     "subject": "Chúc mừng bạn!",
     "message": "Bạn đã được chấp nhận...",
     "company_name": "ABC Company",
     "job_title": "Senior Developer",
     "time": "2025-01-15 14:30"
   }
   ```
4. Click **Send Test Email**

## Template Features

✅ **Responsive Design** - Tự động responsive trên mobile
✅ **Professional Layout** - Header gradient, card layout
✅ **Conditional Sections** - Job info chỉ hiện khi có data
✅ **Brand Colors** - Purple gradient (#667eea to #764ba2)
✅ **Clear Structure** - Greeting → Message → Job Info → Footer

## Customization

Để thay đổi màu sắc, tìm trong template:

```html
<!-- Header gradient -->
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

<!-- Accent color -->
border-left: 4px solid #667eea;
color: #667eea;
```

Thay bằng màu brand của bạn!

## Notes

- EmailJS **free plan**: 200 emails/tháng
- Template hỗ trợ **tiếng Việt**
- Auto format **line breaks** với `white-space: pre-wrap`
- Conditional rendering với `{{#if variable}}`

## Troubleshooting

**Lỗi: "Template not found"**
→ Check Template ID đúng chưa

**Lỗi: "Service not found"**
→ Check Service ID và đã connect email chưa

**Email không có định dạng**
→ Đảm bảo paste TOÀN BỘ HTML vào Content tab

**Variables không thay thế**
→ Check tên variable khớp với code Flutter
