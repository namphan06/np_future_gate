import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MistralService {
  static final MistralService _instance = MistralService._internal();
  factory MistralService() => _instance;
  MistralService._internal();

  final String _apiKey = dotenv.env['MISTRAL_API_KEY'] ?? '';
  final String _model = dotenv.env['MISTRAL_MODEL'] ?? 'open-mistral-7b';
  final String _baseUrl = 'https://api.mistral.ai/v1';

  List<Map<String, String>> _conversationHistory = [];

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
      print('❌ Mistral API Error: $e');
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
}
