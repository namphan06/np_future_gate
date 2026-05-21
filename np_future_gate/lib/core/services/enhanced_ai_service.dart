import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/models/ai_intent_model.dart';
import 'package:np_future_gate/core/repositories/ai_data_repository.dart';
import 'package:np_future_gate/core/services/ai_intent_service.dart';
import 'package:np_future_gate/core/services/mistral_service.dart';

/// Service kết hợp AI với data từ Supabase
class EnhancedAIService {
  factory EnhancedAIService() => _instance;
  EnhancedAIService._internal();
  static final EnhancedAIService _instance = EnhancedAIService._internal();

  final MistralService _mistralService = MistralService();
  final AIIntentService _intentService = AIIntentService();
  final AIDataRepository _dataRepository = AIDataRepository();

  bool _isInitialized = false;

  /// Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _intentService.loadIntents();
    _isInitialized = true;
  }

  /// Xử lý câu hỏi của user với AI và data
  Future<AIResponseWithData> processUserQuery({
    required String query,
    required String userId,
    required String userRole,
  }) async {
    await initialize();

    // Bước 1: Phân tích intent
    final intentResult = await _intentService.analyzeUserQuery(query, userRole);

    // Bước 2: Nếu là data query → lấy data từ Supabase
    if (intentResult.isDataQuery && intentResult.matchedIntent != null) {
      return await _handleDataQuery(
        query: query,
        intent: intentResult.matchedIntent!,
        params: intentResult.extractedParams ?? {},
        userId: userId,
        confidence: intentResult.confidence,
      );
    }

    // Bước 3: Nếu không phải data query → chat bình thường với AI
    return await _handleGeneralChat(query);
  }

  /// Xử lý câu hỏi liên quan đến data
  Future<AIResponseWithData> _handleDataQuery({
    required String query,
    required AIIntent intent,
    required Map<String, dynamic> params,
    required String userId,
    required double confidence,
  }) async {
    try {
      // Lấy data từ Supabase
      final data = await _dataRepository.fetchDataByIntent(intent, params, userId);

      if (data.isEmpty) {
        return AIResponseWithData(
          message: _getEmptyDataMessage(intent),
          chartType: null,
          data: null,
        );
      }

      // Tạo prompt cho AI để format data đẹp
      final aiPrompt = _buildDataPrompt(intent, data, query);
      final aiResponse = await _mistralService.sendMessage(aiPrompt);

      // Xác định chart type dựa trên intent
      final chartType = _determineChartType(intent);

      return AIResponseWithData(
        message: aiResponse,
        chartType: chartType,
        data: data,
        metadata: {
          'intent_id': intent.id,
          'confidence': confidence,
          'count': data.length,
        },
      );
    } catch (e) {
      debugPrint('Error handling data query: $e');
      return AIResponseWithData(
        message: 'Xin lỗi, đã có lỗi xảy ra khi lấy dữ liệu. Vui lòng thử lại.',
        chartType: null,
        data: null,
      );
    }
  }

  /// Xử lý chat thông thường
  Future<AIResponseWithData> _handleGeneralChat(String query) async {
    try {
      final response = await _mistralService.sendMessage(query);
      return AIResponseWithData(
        message: response,
        chartType: null,
        data: null,
      );
    } catch (e) {
      return AIResponseWithData(
        message: 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại.',
        chartType: null,
        data: null,
      );
    }
  }

  /// Tạo prompt cho AI để format data
  String _buildDataPrompt(
    AIIntent intent,
    List<Map<String, dynamic>> data,
    String originalQuery,
  ) {
    final dataCount = data.length;

    switch (intent.category) {
      case 'applications':
        return '''Người dùng hỏi: "$originalQuery"

Tôi đã tìm được $dataCount ứng tuyển. Hãy trả lời ngắn gọn, thân thiện và đề cập đến số lượng.
Không cần liệt kê chi tiết từng ứng tuyển, chỉ cần tổng quan.

Ví dụ: "Bạn có $dataCount ứng viên đã ứng tuyển hôm nay. Dưới đây là danh sách chi tiết:"''';

      case 'interviews':
        return '''Người dùng hỏi: "$originalQuery"

Tôi đã tìm được $dataCount buổi phỏng vấn. Hãy trả lời ngắn gọn và thân thiện.

Ví dụ: "Bạn có $dataCount cuộc phỏng vấn. Dưới đây là lịch chi tiết:"''';

      case 'jobs':
        return '''Người dùng hỏi: "$originalQuery"

Tôi đã tìm được $dataCount công việc. Hãy trả lời ngắn gọn.

Ví dụ: "Có $dataCount tin tuyển dụng. Dưới đây là danh sách:"''';

      case 'partnership':
        return '''Người dùng hỏi: "$originalQuery"

Tôi đã tìm được $dataCount kết quả liên quan đến đối tác/liên kết. Hãy trả lời thân thiện.''';

      default:
        return '''Người dùng hỏi: "$originalQuery"

Tôi đã tìm được $dataCount kết quả. Hãy trả lời ngắn gọn và đề cập đến số lượng.''';
    }
  }

  /// Xác định loại chart/UI để hiển thị data
  String _determineChartType(AIIntent intent) {
    switch (intent.category) {
      case 'applications':
        return 'application_list'; // Special list for applications
      case 'interviews':
        return 'interview_list'; // Calendar-like view
      case 'jobs':
        if (intent.id.contains('status')) {
          return 'job_stats'; // Stats/pie chart
        }
        return 'job_list';
      case 'partnership':
        return 'card_list';
      default:
        return 'list';
    }
  }

  /// Message khi không có data
  String _getEmptyDataMessage(AIIntent intent) {
    switch (intent.category) {
      case 'applications':
        return 'Hiện tại chưa có ứng viên nào ứng tuyển.';
      case 'interviews':
        return 'Bạn chưa có lịch phỏng vấn nào.';
      case 'jobs':
        if (intent.id.contains('expired')) {
          return 'Bạn không có tin tuyển dụng nào hết hạn.';
        } else if (intent.id.contains('active')) {
          return 'Bạn không có tin tuyển dụng nào đang hoạt động.';
        }
        return 'Không tìm thấy tin tuyển dụng nào.';
      case 'partnership':
        return 'Hiện tại chưa có yêu cầu liên kết nào.';
      default:
        return 'Không tìm thấy dữ liệu.';
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _mistralService.clearHistory();
  }

  /// Get suggested queries for user role
  List<String> getSuggestedQueries(String userRole) {
    final intents = _intentService.getIntentsByRole(userRole);
    return intents
        .where((intent) => intent.actionType == 'data_query')
        .take(5)
        .map((intent) => intent.patterns.first)
        .toList();
  }
}
