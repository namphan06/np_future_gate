import '../models/ai_intent_model.dart';

/// Service quản lý các Intent cho AI Assistant
class AIIntentService {
  static final AIIntentService _instance = AIIntentService._internal();
  factory AIIntentService() => _instance;
  AIIntentService._internal();

  // Cache các intent đã load
  List<AIIntent> _intents = [];

  /// Load tất cả intents từ config
  Future<void> loadIntents() async {
    _intents = _getDefaultIntents();
  }

  /// Phân tích câu hỏi của user để tìm intent phù hợp
  Future<IntentAnalysisResult> analyzeUserQuery(
    String query,
    String userRole,
  ) async {
    final normalizedQuery = query.toLowerCase().trim();

    // Lọc intents theo role
    final allowedIntents = _intents.where((intent) {
      return intent.requiredRoles.contains(userRole) ||
          intent.requiredRoles.contains('all');
    }).toList();

    AIIntent? bestMatch;
    double bestScore = 0.0;

    for (final intent in allowedIntents) {
      double score = _calculateMatchScore(normalizedQuery, intent);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = intent;
      }
    }

    // Threshold: 0.6 = có thể là intent này
    final isDataQuery = bestScore >= 0.6 && bestMatch != null;

    return IntentAnalysisResult(
      matchedIntent: isDataQuery ? bestMatch : null,
      confidence: bestScore,
      isDataQuery: isDataQuery,
      extractedParams: isDataQuery ? _extractParameters(normalizedQuery, bestMatch) : null,
    );
  }

  /// Tính điểm match giữa query và intent
  double _calculateMatchScore(String query, AIIntent intent) {
    double score = 0.0;
    int matchCount = 0;

    // Kiểm tra keywords (trọng số cao)
    for (final keyword in intent.keywords) {
      if (query.contains(keyword.toLowerCase())) {
        matchCount++;
        score += 0.3;
      }
    }

    // Kiểm tra patterns (regex hoặc string matching)
    for (final pattern in intent.patterns) {
      if (query.contains(pattern.toLowerCase())) {
        matchCount++;
        score += 0.4;
      }
    }

    // Bonus nếu match nhiều keywords
    if (matchCount >= 2) {
      score += 0.2;
    }

    return score > 1.0 ? 1.0 : score;
  }

  /// Trích xuất parameters từ query
  Map<String, dynamic> _extractParameters(String query, AIIntent intent) {
    final params = <String, dynamic>{};

    // Extract thời gian
    if (query.contains('hôm nay')) {
      params['time_filter'] = 'today';
    } else if (query.contains('hôm qua')) {
      params['time_filter'] = 'yesterday';
    } else if (query.contains('tuần này') || query.contains('tuần nay')) {
      params['time_filter'] = 'this_week';
    } else if (query.contains('tháng này') || query.contains('tháng nay')) {
      params['time_filter'] = 'this_month';
    }

    // Extract status
    if (query.contains('chờ duyệt') || query.contains('pending')) {
      params['status'] = 'pending';
    } else if (query.contains('đã duyệt') || query.contains('approved')) {
      params['status'] = 'approved';
    } else if (query.contains('từ chối') || query.contains('rejected')) {
      params['status'] = 'rejected';
    } else if (query.contains('hết hạn') || query.contains('expired')) {
      params['status'] = 'expired';
    } else if (query.contains('còn hạn') || query.contains('active')) {
      params['status'] = 'active';
    }

    // Extract sắp tới
    if (query.contains('sắp tới') || query.contains('sắp đến')) {
      params['upcoming'] = true;
    }

    return params;
  }

  /// Lấy danh sách intents mặc định
  List<AIIntent> _getDefaultIntents() {
    return [
      // ============= EMPLOYER INTENTS =============
      
      // Ứng viên ứng tuyển
      AIIntent(
        id: 'employer_applications_today',
        name: 'Xem ứng viên ứng tuyển hôm nay',
        category: 'applications',
        keywords: ['ứng tuyển', 'ứng viên', 'hôm nay', 'mới'],
        patterns: [
          'ứng tuyển hôm nay',
          'ứng viên hôm nay',
          'ứng viên mới',
          'danh sách ứng tuyển',
        ],
        description: 'Hiển thị danh sách các ứng viên đã ứng tuyển vào các công việc của bạn trong ngày hôm nay',
        requiredRoles: ['employer'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'applications',
          'filter': 'today',
          'include': ['student_profile', 'job_info'],
        },
      ),

      // Tình trạng tin tuyển dụng
      AIIntent(
        id: 'employer_job_status',
        name: 'Kiểm tra tình trạng tin tuyển dụng',
        category: 'jobs',
        keywords: ['tin', 'tình trạng', 'duyệt', 'chấp nhận', 'từ chối'],
        patterns: [
          'tình trạng tin',
          'tin đã duyệt',
          'tin chờ duyệt',
          'tin bị từ chối',
        ],
        description: 'Xem tình trạng các tin tuyển dụng: đã duyệt, chờ duyệt, bị từ chối',
        requiredRoles: ['employer'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'jobs',
          'group_by': 'status',
        },
      ),

      // Tin hết hạn
      AIIntent(
        id: 'employer_expired_jobs',
        name: 'Xem tin hết hạn',
        category: 'jobs',
        keywords: ['hết hạn', 'expired', 'đã hết'],
        patterns: ['tin hết hạn', 'công việc hết hạn'],
        description: 'Danh sách các tin tuyển dụng đã hết hạn',
        requiredRoles: ['employer'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'jobs',
          'filter': 'expired',
        },
      ),

      // Tin còn hạn
      AIIntent(
        id: 'employer_active_jobs',
        name: 'Xem tin còn hạn',
        category: 'jobs',
        keywords: ['còn hạn', 'active', 'đang tuyển'],
        patterns: ['tin còn hạn', 'công việc còn hạn', 'đang tuyển'],
        description: 'Danh sách các tin tuyển dụng còn hiệu lực',
        requiredRoles: ['employer'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'jobs',
          'filter': 'active',
        },
      ),

      // Lịch phỏng vấn
      AIIntent(
        id: 'employer_interviews',
        name: 'Xem lịch phỏng vấn',
        category: 'interviews',
        keywords: ['lịch', 'phỏng vấn', 'interview'],
        patterns: ['lịch phỏng vấn', 'cuộc phỏng vấn'],
        description: 'Xem tất cả lịch phỏng vấn đã lên lịch',
        requiredRoles: ['employer'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'interview_schedules',
          'filter': 'all',
        },
      ),

      // Lịch phỏng vấn sắp tới
      AIIntent(
        id: 'employer_upcoming_interviews',
        name: 'Lịch phỏng vấn sắp tới',
        category: 'interviews',
        keywords: ['sắp tới', 'sắp đến', 'phỏng vấn'],
        patterns: ['phỏng vấn sắp tới', 'lịch sắp tới'],
        description: 'Các buổi phỏng vấn sắp diễn ra trong thời gian tới',
        requiredRoles: ['employer'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'interview_schedules',
          'filter': 'upcoming',
        },
      ),

      // Yêu cầu liên kết (partnership)
      AIIntent(
        id: 'employer_partnership_requests',
        name: 'Yêu cầu liên kết với trường',
        category: 'partnership',
        keywords: ['liên kết', 'partnership', 'yêu cầu', 'hợp tác'],
        patterns: ['yêu cầu liên kết', 'liên kết trường', 'partnership'],
        description: 'Các yêu cầu liên kết với trường học',
        requiredRoles: ['employer'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'school_partnership_requests',
          'filter': 'pending',
        },
      ),

      // ============= STUDENT INTENTS =============

      // Công việc đã ứng tuyển
      AIIntent(
        id: 'student_applied_jobs',
        name: 'Xem công việc đã ứng tuyển',
        category: 'applications',
        keywords: ['đã ứng tuyển', 'công việc', 'applied'],
        patterns: ['đã ứng tuyển', 'công việc ứng tuyển'],
        description: 'Danh sách các công việc bạn đã ứng tuyển',
        requiredRoles: ['student'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'applications',
          'filter': 'my_applications',
        },
      ),

      // Lịch phỏng vấn của sinh viên
      AIIntent(
        id: 'student_interviews',
        name: 'Lịch phỏng vấn của tôi',
        category: 'interviews',
        keywords: ['lịch', 'phỏng vấn', 'của tôi'],
        patterns: ['lịch phỏng vấn', 'phỏng vấn của tôi'],
        description: 'Xem lịch phỏng vấn đã được nhà tuyển dụng đặt',
        requiredRoles: ['student'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'interview_schedules',
          'filter': 'my_interviews',
        },
      ),

      // Công việc được đề xuất
      AIIntent(
        id: 'student_recommended_jobs',
        name: 'Công việc đề xuất',
        category: 'jobs',
        keywords: ['đề xuất', 'gợi ý', 'recommended', 'phù hợp'],
        patterns: ['công việc đề xuất', 'gợi ý công việc', 'phù hợp'],
        description: 'Các công việc được đề xuất dựa trên hồ sơ của bạn',
        requiredRoles: ['student'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'jobs',
          'filter': 'recommended',
        },
      ),

      // ============= SCHOOL INTENTS =============

      // Doanh nghiệp liên kết
      AIIntent(
        id: 'school_partners',
        name: 'Doanh nghiệp liên kết',
        category: 'partnership',
        keywords: ['doanh nghiệp', 'liên kết', 'đối tác'],
        patterns: ['doanh nghiệp liên kết', 'đối tác'],
        description: 'Danh sách các doanh nghiệp đã liên kết với trường',
        requiredRoles: ['school'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'school_partnerships',
          'filter': 'active',
        },
      ),

      // Công việc từ đối tác
      AIIntent(
        id: 'school_partnership_jobs',
        name: 'Công việc từ đối tác',
        category: 'jobs',
        keywords: ['công việc', 'đối tác', 'partnership'],
        patterns: ['công việc đối tác', 'việc làm liên kết'],
        description: 'Các công việc từ doanh nghiệp liên kết',
        requiredRoles: ['school'],
        actionType: 'data_query',
        queryConfig: {
          'table': 'school_partnership_jobs',
          'filter': 'active',
        },
      ),

      // ============= COMMON INTENTS (Tất cả role) =============

      // Hướng dẫn sử dụng
      AIIntent(
        id: 'general_help',
        name: 'Hướng dẫn sử dụng',
        category: 'help',
        keywords: ['hướng dẫn', 'giúp', 'help', 'làm sao'],
        patterns: ['hướng dẫn', 'cách sử dụng', 'help'],
        description: 'Hướng dẫn sử dụng ứng dụng',
        requiredRoles: ['all'],
        actionType: 'general_chat',
      ),
    ];
  }

  /// Get intent by ID
  AIIntent? getIntentById(String id) {
    try {
      return _intents.firstWhere((intent) => intent.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all intents for a specific role
  List<AIIntent> getIntentsByRole(String role) {
    return _intents.where((intent) {
      return intent.requiredRoles.contains(role) ||
          intent.requiredRoles.contains('all');
    }).toList();
  }
}
