class CourseModel {

  CourseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.slug,
    this.description,
    this.thumbnailUrl,
    this.categoryId,
    required this.level,
    required this.tags,
    required this.durationMinutes,
    required this.status,
    required this.isFeatured,
    this.authorId,
    required this.viewCount,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      categoryId: json['category_id'] as String?,
      level: json['level'] as String? ?? 'beginner',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      isFeatured: json['is_featured'] as bool? ?? false,
      authorId: json['author_id'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
    );
  }
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String slug;
  final String? description;
  final String? thumbnailUrl;
  final String? categoryId;
  final String level; // beginner, intermediate, advanced
  final List<String> tags;
  final int durationMinutes;
  final String status; // draft, published, archived
  final bool isFeatured;
  final String? authorId;
  final int viewCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title': title,
      'slug': slug,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'category_id': categoryId,
      'level': level,
      'tags': tags,
      'duration_minutes': durationMinutes,
      'status': status,
      'is_featured': isFeatured,
      'author_id': authorId,
      'view_count': viewCount,
    };
  }

  String get levelLabel {
    switch (level) {
      case 'beginner':
        return 'Cơ bản';
      case 'intermediate':
        return 'Trung cấp';
      case 'advanced':
        return 'Nâng cao';
      default:
        return 'Cơ bản';
    }
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
      return '$hours giờ $minutes phút';
    }
  }
}
