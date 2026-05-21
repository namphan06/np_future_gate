
class MIQuestion {

  MIQuestion({
    required this.id,
    required this.questionText,
    required this.intelligenceType,
    this.order = 0,
    this.isActive = true,
  });

  factory MIQuestion.fromJson(Map<String, dynamic> json) {
    return MIQuestion(
      id: json['id'],
      questionText: json['question_text'],
      intelligenceType: json['intelligence_type'],
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
  final String id;
  final String questionText;
  final String intelligenceType;
  final int order;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'intelligence_type': intelligenceType,
      'order': order,
      'is_active': isActive,
    };
  }
}

class MIResult {

  MIResult({
    required this.scores,
    this.analysis,
    required this.createdAt,
  });

  factory MIResult.fromJson(Map<String, dynamic> json) {
    return MIResult(
      scores: Map<String, int>.from(json['scores'] ?? {}),
      analysis: json['analysis'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  final Map<String, int> scores; // intelligenceType -> score
  final String? analysis;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'scores': scores,
      'analysis': analysis,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
