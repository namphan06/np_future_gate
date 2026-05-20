import 'dart:io';
import 'package:dio/dio.dart';

class OcrService {
  // URL server mới trên Render
  static const String apiUrl = 'https://ocr-server-7w2k.onrender.com/api/ocr';
  
  static final Dio _dio = Dio();
  
  /// Trích xuất text từ file (PDF hoặc ảnh)
  /// 
  /// [file] - File cần xử lý
  /// [language] - Ngôn ngữ: 'eng' (English) hoặc 'vie' (Vietnamese)
  /// 
  /// Returns: Map chứa kết quả OCR
  static Future<Map<String, dynamic>> extractText({
    required File file,
    String language = 'eng',
  }) async {
    try {
      // Tạo FormData
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'lang': language,
      });
      
      // Cấu hình timeout (60 giây cho cold start)
      _dio.options.connectTimeout = const Duration(seconds: 120); // Tăng timeout cho cold start
      _dio.options.receiveTimeout = const Duration(seconds: 120);
      
      // Gọi API
      final response = await _dio.post(
        apiUrl,
        data: formData,
      );
      
      print('🚀 OCR Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Đồng nhất key 'text' từ server (thường là 'full_text')
        if (data.containsKey('full_text')) {
          data['text'] = data['full_text'];
        }
        return {
          'success': true,
          ...data,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        // Retry sau 5 giây (đợi server wake up từ cold start)
        print('⏳ Server cold start, retrying in 5 seconds...');
        await Future.delayed(const Duration(seconds: 5));
        return await extractText(file: file, language: language);
      }
      return {
        'success': false,
        'error': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Kiểm tra server đang chạy
  static Future<bool> isServerHealthy() async {
    try {
      final response = await _dio.get('https://ocr-server-7w2k.onrender.com/api/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
