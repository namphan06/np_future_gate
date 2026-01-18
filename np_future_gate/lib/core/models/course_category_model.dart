class CourseCategoryModel {
  final String id;
  final DateTime createdAt;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String color;
  final int order;
  final bool isActive;

  CourseCategoryModel({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    required this.color,
    required this.order,
    required this.isActive,
  });

  factory CourseCategoryModel.fromJson(Map<String, dynamic> json) {
    return CourseCategoryModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#3B82F6',
      order: json['order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'color': color,
      'order': order,
      'is_active': isActive,
    };
  }
}
