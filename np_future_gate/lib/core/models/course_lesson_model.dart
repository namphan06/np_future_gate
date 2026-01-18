class CourseLessonModel {
  final String id;
  final DateTime createdAt;
  final String courseId;
  final String title;
  final String? description;
  final String youtubeUrl;
  final int order;
  final int durationMinutes;
  final bool isPreview;

  CourseLessonModel({
    required this.id,
    required this.createdAt,
    required this.courseId,
    required this.title,
    this.description,
    required this.youtubeUrl,
    required this.order,
    required this.durationMinutes,
    required this.isPreview,
  });

  factory CourseLessonModel.fromJson(Map<String, dynamic> json) {
    return CourseLessonModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      youtubeUrl: json['youtube_url'] as String,
      order: json['order'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      isPreview: json['is_preview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'course_id': courseId,
      'title': title,
      'description': description,
      'youtube_url': youtubeUrl,
      'order': order,
      'duration_minutes': durationMinutes,
      'is_preview': isPreview,
    };
  }

  String get durationText {
    if (durationMinutes < 60) {
      return '$durationMinutes phút';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours giờ';
      }
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
  }

  // Extract YouTube video ID from URL
  String? get youtubeVideoId {
    final uri = Uri.tryParse(youtubeUrl);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }
    return null;
  }
}
