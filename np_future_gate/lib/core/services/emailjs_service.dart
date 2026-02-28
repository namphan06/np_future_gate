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
  /// attachments: danh sách file đã upload lên Storage [{url, name, size, type}]
  Future<bool> sendEmployerResponse({
    required String toEmail,
    required String toName,
    required String subject,
    required String messageBody,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      // Build HTML email content
      final htmlMessage = _buildHtmlEmail(
        body: messageBody,
        attachments: attachments,
      );

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
            'message': htmlMessage,
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

  /// Build HTML email with styled attachments
  String _buildHtmlEmail({
    required String body,
    List<Map<String, dynamic>>? attachments,
  }) {
    // Convert plain text body to HTML (preserve line breaks)
    final htmlBody = body
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br/>');

    final buffer = StringBuffer();

    // Email body
    buffer.write('<div style="font-family: Arial, sans-serif; font-size: 14px; color: #333; line-height: 1.6;">');
    buffer.write(htmlBody);
    buffer.write('</div>');

    // Attachments section
    if (attachments != null && attachments.isNotEmpty) {
      buffer.write('<br/>');
      buffer.write('<div style="margin-top: 20px; padding-top: 16px; border-top: 1px solid #e0e0e0;">');
      buffer.write('<p style="font-size: 14px; font-weight: bold; color: #555; margin-bottom: 12px;">📎 File đính kèm:</p>');
      buffer.write('<div style="display: flex; flex-wrap: wrap; gap: 12px;">');

      for (var attachment in attachments) {
        final name = attachment['name'] as String? ?? 'File';
        final fileUrl = attachment['url'] as String? ?? '';
        final type = attachment['type'] as String? ?? '';
        final size = attachment['size'] as int? ?? 0;
        final sizeText = _formatFileSize(size);

        if (fileUrl.isEmpty) continue;

        final isImage = type.startsWith('image/');
        final isPdf = type == 'application/pdf';

        buffer.write('<div style="display: inline-block; width: 180px; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.08);">');

        // Preview area
        buffer.write('<a href="$fileUrl" target="_blank" style="text-decoration: none;">');
        buffer.write('<div style="width: 180px; height: 130px; background: #f5f5f5; display: flex; align-items: center; justify-content: center; overflow: hidden;">');

        if (isImage) {
          // Show image thumbnail
          buffer.write('<img src="$fileUrl" alt="$name" style="width: 100%; height: 100%; object-fit: cover;" />');
        } else if (isPdf) {
          // PDF icon
          buffer.write('<div style="text-align: center;">');
          buffer.write('<div style="font-size: 40px;">📄</div>');
          buffer.write('<div style="font-size: 12px; color: #d32f2f; font-weight: bold; margin-top: 4px;">PDF</div>');
          buffer.write('</div>');
        } else {
          // Generic file icon
          buffer.write('<div style="text-align: center;">');
          buffer.write('<div style="font-size: 40px;">📁</div>');
          buffer.write('<div style="font-size: 12px; color: #666; margin-top: 4px;">${_getFileExtension(name)}</div>');
          buffer.write('</div>');
        }

        buffer.write('</div>');
        buffer.write('</a>');

        // File info area
        buffer.write('<div style="padding: 8px 10px; border-top: 1px solid #f0f0f0;">');
        buffer.write('<a href="$fileUrl" target="_blank" style="text-decoration: none; color: #1a73e8; font-size: 12px; font-weight: 600; display: block; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="$name">');
        buffer.write(name);
        buffer.write('</a>');
        buffer.write('<div style="font-size: 11px; color: #999; margin-top: 2px;">$sizeText</div>');
        buffer.write('</div>');

        buffer.write('</div>');
      }

      buffer.write('</div>');
      buffer.write('</div>');
    }

    return buffer.toString();
  }

  /// Format file size to human readable string
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  /// Get file extension from filename
  String _getFileExtension(String filename) {
    final parts = filename.split('.');
    if (parts.length > 1) return parts.last.toUpperCase();
    return 'FILE';
  }
}
