class MBTIQuestionOption {
  final String id;
  final String questionId;
  final String optionText;
  final String mappedLetter;
  final int order;
  final bool isActive;

  MBTIQuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.mappedLetter,
    this.order = 0,
    this.isActive = true,
  });

  factory MBTIQuestionOption.fromJson(Map<String, dynamic> json) {
    return MBTIQuestionOption(
      id: (json['id'] ?? '').toString(),
      questionId: (json['question_id'] ?? '').toString(),
      optionText: (json['option_text'] ?? '').toString(),
      mappedLetter: (json['mapped_letter'] ?? '').toString(),
      order: (json['order'] ?? 0) as int,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }
}

class MBTIQuestion {
  final String id;
  final String questionText;
  final String? questionDimension;
  final String? placeholderHint;
  final int order;
  final bool isActive;
  final List<MBTIQuestionOption> options;

  MBTIQuestion({
    required this.id,
    required this.questionText,
    this.questionDimension,
    this.placeholderHint,
    this.order = 0,
    this.isActive = true,
    this.options = const [],
  });

  factory MBTIQuestion.fromJson(Map<String, dynamic> json) {
    return MBTIQuestion(
      id: (json['id'] ?? '').toString(),
      questionText: (json['question_text'] ?? '').toString(),
      questionDimension: json['question_dimension']?.toString(),
      placeholderHint: json['placeholder_hint']?.toString(),
      order: (json['order'] ?? 0) as int,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }

  MBTIQuestion copyWith({List<MBTIQuestionOption>? options}) {
    return MBTIQuestion(
      id: id,
      questionText: questionText,
      questionDimension: questionDimension,
      placeholderHint: placeholderHint,
      order: order,
      isActive: isActive,
      options: options ?? this.options,
    );
  }
}

class MBTITypeSection {
  final String id;
  final String mbtiTypeId;
  final String title;
  final String content;
  final int order;
  final bool isActive;

  MBTITypeSection({
    required this.id,
    required this.mbtiTypeId,
    required this.title,
    required this.content,
    this.order = 0,
    this.isActive = true,
  });

  factory MBTITypeSection.fromJson(Map<String, dynamic> json) {
    return MBTITypeSection(
      id: (json['id'] ?? '').toString(),
      mbtiTypeId: (json['mbti_type_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      order: (json['order'] ?? 0) as int,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }
}

class MBTIType {
  final String id;
  final String code;
  final String? name;
  final String? shortDescription;
  final String? imageUrl;
  final String? colorHex;
  final bool isActive;
  final List<MBTITypeSection> sections;

  MBTIType({
    required this.id,
    required this.code,
    this.name,
    this.shortDescription,
    this.imageUrl,
    this.colorHex,
    this.isActive = true,
    this.sections = const [],
  });

  factory MBTIType.fromJson(Map<String, dynamic> json) {
    return MBTIType(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: json['name']?.toString(),
      shortDescription: json['short_description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      colorHex: json['color_hex']?.toString(),
      isActive: (json['is_active'] ?? true) as bool,
    );
  }

  MBTIType copyWith({List<MBTITypeSection>? sections}) {
    return MBTIType(
      id: id,
      code: code,
      name: name,
      shortDescription: shortDescription,
      imageUrl: imageUrl,
      colorHex: colorHex,
      isActive: isActive,
      sections: sections ?? this.sections,
    );
  }
}

class MBTIAnsweredQuestion {
  final MBTIQuestion question;
  final MBTIQuestionOption selectedOption;

  MBTIAnsweredQuestion({required this.question, required this.selectedOption});
}

class MBTIAnalysisResult {
  final String resultCode;
  final String? reasoning;

  MBTIAnalysisResult({required this.resultCode, this.reasoning});
}
