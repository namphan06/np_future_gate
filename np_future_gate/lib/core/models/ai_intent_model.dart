/// Model cho AI Intent Detection
class AIIntent {

  AIIntent({
    required this.id,
    required this.name,
    required this.category,
    required this.keywords,
    required this.patterns,
    required this.description,
    required this.requiredRoles,
    required this.actionType,
    this.queryConfig,
  });

  factory AIIntent.fromJson(Map<String, dynamic> json) {
    return AIIntent(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      keywords: List<String>.from(json['keywords'] ?? []),
      patterns: List<String>.from(json['patterns'] ?? []),
      description: json['description'],
      requiredRoles: List<String>.from(json['required_roles'] ?? []),
      actionType: json['action_type'],
      queryConfig: json['query_config'],
    );
  }
  final String id;
  final String name;
  final String category;
  final List<String> keywords;
  final List<String> patterns;
  final String description;
  final List<String> requiredRoles; // ['employer', 'student', 'school']
  final String actionType; // 'data_query', 'general_chat', 'action'
  final Map<String, dynamic>? queryConfig;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'keywords': keywords,
      'patterns': patterns,
      'description': description,
      'required_roles': requiredRoles,
      'action_type': actionType,
      'query_config': queryConfig,
    };
  }
}

/// Model cho kết quả phân tích intent
class IntentAnalysisResult {

  IntentAnalysisResult({
    this.matchedIntent,
    required this.confidence,
    required this.isDataQuery,
    this.extractedParams,
  });
  final AIIntent? matchedIntent;
  final double confidence;
  final bool isDataQuery;
  final Map<String, dynamic>? extractedParams;
}

/// Model cho kết quả trả về từ AI với dữ liệu
class AIResponseWithData {

  AIResponseWithData({
    required this.message,
    this.chartType,
    this.data,
    this.metadata,
  });
  final String message;
  final String? chartType; // 'list', 'card', 'table', 'stats'
  final List<Map<String, dynamic>>? data;
  final Map<String, dynamic>? metadata;
}
