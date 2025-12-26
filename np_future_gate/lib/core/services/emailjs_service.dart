import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailJsService {
  // Load credentials from .env file
  static String get _serviceId => dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
  static String get _templateId => dotenv.env['EMAILJS_TEMPLATE_RESPONSE_ID'] ?? '';
  static String get _publicKey => dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

  /// Gửi email response đến ứng viên
  /// Message đã được format sẵn từ email_templates (có {{variables}} đã replace)
  Future<bool> sendEmployerResponse({
    required String toEmail,
    required String toName,
    required String subject,
    required String messageBody, // Body đã có đầy đủ nội dung
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': toName,
            'name': toName,
            'subject': subject,
            'message': messageBody,
            'time': DateTime.now().toString(),
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully to $toEmail');
        return true;
      } else {
        print('❌ Failed to send email: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }
}
