import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MistralService {
  factory MistralService() => _instance;
  MistralService._internal();
  static final MistralService _instance = MistralService._internal();

  final String _apiKey = dotenv.env['MISTRAL_API_KEY'] ?? '';
  final String _model = dotenv.env['MISTRAL_MODEL'] ?? 'open-mistral-7b';
  final String _baseUrl = 'https://api.mistral.ai/v1';

  final List<Map<String, String>> _conversationHistory = [];

  /// Gửi tin nhắn đến Mistral AI và nhận phản hồi
  Future<String> sendMessage(String message) async {
    if (_apiKey.isEmpty) {
      throw Exception('Mistral API key chưa được cấu hình');
    }

    // Thêm tin nhắn của user vào lịch sử
    _conversationHistory.add({
      'role': 'user',
      'content': message,
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''Bạn là trợ lý AI thông minh của NP FutureGate - nền tảng kết nối sinh viên với cơ hội việc làm.
              
Nhiệm vụ của bạn:
- Tư vấn về tìm việc, viết CV, chuẩn bị phỏng vấn
- Hướng dẫn sử dụng các tính năng của app
- Giải đáp thắc mắc về quy trình ứng tuyển
- Gợi ý ngành nghề phù hợp với profile sinh viên

Hãy trả lời thân thiện, chuyên nghiệp và súc tích bằng tiếng Việt.'''
            },
            ..._conversationHistory,
          ],
          'temperature': 0.7,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final assistantMessage = data['choices'][0]['message']['content'];

        // Thêm phản hồi vào lịch sử
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });

        return assistantMessage;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('Lỗi API: ${error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Mistral API Error: $e');
      rethrow;
    }
  }

  /// Xóa lịch sử hội thoại
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Lấy lịch sử hội thoại
  List<Map<String, String>> getHistory() {
    return List.from(_conversationHistory);
  }

  /// Gửi tin nhắn ĐỘC LẬP - không lưu history, không bị nhiễu
  /// Dùng cho CV analysis (mỗi lần là 1 session riêng)
  /// Có retry logic nếu thất bại
  Future<String> sendIsolatedMessage(String message, {String? systemPrompt, int maxRetries = 2}) async {
    if (_apiKey.isEmpty) {
      throw Exception('Mistral API key chưa được cấu hình');
    }

    final system = systemPrompt ?? 
      'Bạn là chuyên gia phân tích CV và tuyển dụng. '
      'Luôn trả lời chính xác bằng tiếng Việt. '
      'Khi được yêu cầu trả về JSON, CHỈ trả về đúng 1 object JSON hợp lệ, KHÔNG thêm bất kỳ text nào khác trước hoặc sau JSON.';

    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          // Đợi lâu hơn mỗi lần retry (3s, 8s) để tránh rate limit
          final delay = attempt == 1 ? 3 : 8;
          debugPrint('🔄 Retry attempt $attempt (đợi ${delay}s)...');
          await Future.delayed(Duration(seconds: delay));
        }

        final response = await http.post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': system},
              {'role': 'user', 'content': message},
            ],
            'temperature': 0.1,
            'max_tokens': 4096,
            'response_format': {'type': 'json_object'},
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return data['choices'][0]['message']['content'];
        } else if (response.statusCode == 429) {
          // Rate limit - chỉ retry 1 lần với delay dài
          if (attempt == 0) {
            debugPrint('⏳ Rate limit 429 - đợi 30s...');
            await Future.delayed(const Duration(seconds: 30));
          } else {
            // Đã retry rồi mà vẫn 429 → throw ngay với message rõ ràng
            throw Exception('Hệ thống AI đang quá tải. Vui lòng đợi 1 phút rồi thử lại.');
          }
        } else if (response.statusCode == 422 || response.statusCode == 400) {
          // response_format không hỗ trợ → thử không có json mode
          return await _sendWithoutJsonMode(system, message);
        } else {
          final error = jsonDecode(utf8.decode(response.bodyBytes));
          lastError = Exception('API ${response.statusCode}: ${error['message'] ?? ''}');
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ Isolated API attempt $attempt error: $e');
      }
    }

    throw lastError ?? Exception('Không thể kết nối Mistral AI');
  }

  /// Fallback: gửi không có json_object mode
  Future<String> _sendWithoutJsonMode(String system, String message) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': message},
        ],
        'temperature': 0.1,
        'max_tokens': 4096,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception('API ${response.statusCode}: ${error['message'] ?? ''}');
    }
  }
}
