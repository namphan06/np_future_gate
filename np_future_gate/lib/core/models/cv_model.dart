class CVModel {
  final String id;
  final String name;
  final DateTime updatedAt;
  final Map<String, dynamic> data;

  CVModel({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.data,
  });

  factory CVModel.fromJson(Map<String, dynamic> json) {
    return CVModel(
      id: json['id'] ?? '',
      name: json['title'] ?? 'Untitled CV',
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      data: json['data'] ?? {},
    );
  }
}
