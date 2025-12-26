# EmailJS Integration - Simple Flow

## Template đơn giản
Template EmailJS chỉ hiển thị `{{message}}` - body đã được customize trong `email_templates` table.

## Variables trong EmailJS Template
- `{{to_email}}` - Email người nhận (auto)
- `{{name}}` - Tên người nhận
- `{{subject}}` - Tiêu đề (không hiển thị trong body, chỉ cho email subject)
- `{{message}}` - **Nội dung chính** (từ email_templates.body)
- `{{time}}` - Thời gian gửi (auto)

## Flow

```
1. Employer customize template trong app
   ├─ Subject: "Chúc mừng {{candidate_name}}!"
   └─ Body: "Bạn được nhận vào {{job_title}}..."
   
2. Khi cần gửi email (từ màn khác):
   ├─ Load template từ email_templates
   ├─ Replace {{variables}} với data thật
   ├─ Gọi EmailJS
   └─ EmailJS gửi email với message đã replace

3. Candidate nhận email với nội dung đã customize
```

## Usage Example

```dart
import '../../core/services/emailjs_service.dart';
import '../../core/services/supabase_service.dart';

Future<void> sendAcceptanceEmail({
  required String candidateId,
  required String candidateEmail,
  required String candidateName,
  required String jobId,
}) async {
  final _supabase = SupabaseService.instance;
  final _emailService = EmailJsService();
  
  try {
    // 1. Load template từ DB
    final employerId = _supabase.currentUserId!;
    final template = await _supabase.client
        .from('email_templates')
        .select()
        .eq('employer_id', employerId)
        .eq('response_type', 'accepted')
        .single();
    
    // 2. Load job & company data
    final job = await _getJobData(jobId);
    final company = await _getCompanyData(employerId);
    
    // 3. Replace variables
    String subject = template['subject']
        .replaceAll('{{candidate_name}}', candidateName)
        .replaceAll('{{job_title}}', job['title'])
        .replaceAll('{{company_name}}', company['name']);
    
    String body = template['body']
        .replaceAll('{{candidate_name}}', candidateName)
        .replaceAll('{{job_title}}', job['title'])
        .replaceAll('{{company_name}}', company['name'])
        .replaceAll('{{salary_range}}', job['salary_range']);
    
    // 4. Send via EmailJS
    final success = await _emailService.sendEmployerResponse(
      toEmail: candidateEmail,
      toName: candidateName,
      subject: subject,
      messageBody: body, // Body đã replace variables
    );
    
    if (success) {
      print('✅ Email sent!');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

## Đơn giản hơn với helper function

```dart
// Helper to replace common variables
String replaceTemplateVariables(String text, Map<String, String> data) {
  String result = text;
  data.forEach((key, value) {
    result = result.replaceAll('{{$key}}', value);
  });
  return result;
}

// Usage
final data = {
  'candidate_name': candidateName,
  'job_title': job['title'],
  'company_name': company['name'],
  'salary_range': job['salary_range'],
};

String subject = replaceTemplateVariables(template['subject'], data);
String body = replaceTemplateVariables(template['body'], data);
```

## EmailJS Template (Paste vào Dashboard)

```html
<div style="font-family: system-ui, sans-serif, Arial; font-size: 12px">
  <div style="margin-top: 20px; padding: 15px 0; border-width: 1px 0; border-style: dashed; border-color: lightgrey;">
    <table role="presentation">
      <tr>
        <td style="vertical-align: top">
          <div style="padding: 6px 10px; margin: 0 10px; background-color: aliceblue; border-radius: 5px; font-size: 26px" role="img">
            📧
          </div>
        </td>
        <td style="vertical-align: top">
          <div style="color: #2c3e50; font-size: 16px">
            <strong>{{name}}</strong>
          </div>
          <div style="color: #cccccc; font-size: 13px">{{time}}</div>
          <p style="font-size: 16px; white-space: pre-wrap;">{{message}}</p>
        </td>
      </tr>
    </table>
  </div>
</div>
```

## Setup Credentials

File: `lib/core/services/emailjs_service.dart`

```dart
static const String _serviceId = 'service_abc123';    // Từ EmailJS
static const String _templateId = 'template_xyz789';  // Từ EmailJS
static const String _publicKey = 'your_public_key';   // Từ EmailJS
```

## Notes

✅ Template chỉ hiển thị `{{message}}` - đơn giản, clean
✅ Logic replace variables ở Flutter, không ở EmailJS
✅ `white-space: pre-wrap` để giữ line breaks
✅ Emoji 📧 để friendly hơn
