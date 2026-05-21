/// Model for Career News
class CareerNewsModel {

  CareerNewsModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    this.slug,
    this.excerpt,
    required this.content,
    this.coverImageUrl,
    required this.category,
    this.tags = const [],
    this.relatedCompanyIds = const [],
    this.status = 'draft',
    this.isFeatured = false,
    this.isPinned = false,
    this.authorId,
    this.viewCount = 0,
    this.metaTitle,
    this.metaDescription,
  });

  factory CareerNewsModel.fromJson(Map<String, dynamic> json) {
    return CareerNewsModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      title: json['title'] as String,
      slug: json['slug'] as String?,
      excerpt: json['excerpt'] as String?,
      content: json['content'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      relatedCompanyIds: (json['related_company_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] as String? ?? 'draft',
      isFeatured: json['is_featured'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      authorId: json['author_id'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      metaTitle: json['meta_title'] as String?,
      metaDescription: json['meta_description'] as String?,
    );
  }
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String? slug;
  final String? excerpt;
  final String content;
  final String? coverImageUrl;
  final String category;
  final List<String> tags;
  final List<String> relatedCompanyIds;
  final String status;
  final bool isFeatured;
  final bool isPinned;
  final String? authorId;
  final int viewCount;
  final String? metaTitle;
  final String? metaDescription;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title': title,
      'slug': slug,
      'excerpt': excerpt,
      'content': content,
      'cover_image_url': coverImageUrl,
      'category': category,
      'tags': tags,
      'related_company_ids': relatedCompanyIds,
      'status': status,
      'is_featured': isFeatured,
      'is_pinned': isPinned,
      'author_id': authorId,
      'view_count': viewCount,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
    };
  }

  String get categoryLabel {
    switch (category) {
      case 'market_trends':
        return 'Xu hướng thị trường';
      case 'company_news':
        return 'Tin công ty';
      case 'industry_insights':
        return 'Phân tích ngành';
      case 'career_tips':
        return 'Mẹo nghề nghiệp';
      case 'events':
        return 'Sự kiện';
      default:
        return category;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
