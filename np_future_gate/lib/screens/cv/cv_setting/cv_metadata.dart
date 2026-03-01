import 'package:flutter/material.dart';

/// CV Metadata - Định nghĩa thông tin, tags và mcv cho mỗi mẫu CV
class CVMetadata {
  final String mcv; // Mã CV duy nhất
  final String title;
  final String description;
  final String type; // Loại CV: general, field, upload, etc.
  final List<CVTag> tags;
  final IconData icon;
  final String thumbnailPath;
  final String templatePath; // Đường dẫn tới file template UI
  final String? typeField;

  const CVMetadata({
    required this.mcv,
    required this.title,
    required this.description,
    required this.type,
    required this.tags,
    required this.icon,
    required this.thumbnailPath,
    required this.templatePath,
    this.typeField
  });

  Map<String, dynamic> toJson() => {
    'mcv': mcv,
    'title': title,
    'description': description,
    'type': type,
    'tags': tags.map((t) => t.toJson()).toList(),
    'icon': icon.codePoint,
    'thumbnailPath': thumbnailPath,
    'templatePath': templatePath,
  };

  factory CVMetadata.fromJson(Map<String, dynamic> json) => CVMetadata(
    mcv: json['mcv'],
    title: json['title'],
    description: json['description'],
    type: json['type'] ?? 'general',
    tags: (json['tags'] as List).map((t) => CVTag.fromJson(t)).toList(),
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    thumbnailPath: json['thumbnailPath'],
    templatePath: json['templatePath'],
  );
}

/// CV Tag - Thẻ phân loại CV
class CVTag {
  final String label;
  final Color color;
  final IconData? icon;

  const CVTag({
    required this.label,
    required this.color,
    this.icon,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'color': color.value,
    if (icon != null) 'icon': icon!.codePoint,
  };

  factory CVTag.fromJson(Map<String, dynamic> json) => CVTag(
    label: json['label'],
    color: Color(json['color']),
    icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
  );
}

/// Registry - Đăng ký tất cả CV templates
class CVRegistry {
  static final Map<String, CVMetadata> _registry = {};

  /// Đăng ký CV metadata
  static void register(CVMetadata metadata) {
    _registry[metadata.mcv] = metadata;
  }

  /// Lấy metadata theo MCV
  static CVMetadata? getByMCV(String mcv) => _registry[mcv];

  /// Lấy tất cả CVs
  static List<CVMetadata> getAll() => _registry.values.toList();

  /// Lọc CVs theo tags
  static List<CVMetadata> filterByTags(List<String> tagLabels) {
    return _registry.values.where((cv) {
      return cv.tags.any((tag) => tagLabels.contains(tag.label));
    }).toList();
  }

  /// Khởi tạo registry với các CV mẫu
  static void initialize() {
    // CV1 - Professional Template
    register(CVMetadata(
      mcv: 'CV001',
      title: 'Professional CV',
      description: 'Mẫu CV chuyên nghiệp, phù hợp cho mọi ngành nghề',
      type: 'general',
      icon: Icons.work_outline,
      thumbnailPath: 'assets/cv_thumbnails/cv1_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv1.dart',
      tags: [
        CVTag(label: 'Professional', color: Colors.blue, icon: Icons.business_center),
        CVTag(label: 'Modern', color: Colors.teal, icon: Icons.auto_awesome),
        CVTag(label: 'Clean', color: Colors.green, icon: Icons.check_circle),
        CVTag(label: 'All Industries', color: Colors.orange, icon: Icons.work),
      ],
    ));

    // CV2 - Creative Template
    register(CVMetadata(
      mcv: 'CV002',
      title: 'Creative CV',
      description: 'Mẫu CV sáng tạo cho designer, marketer',
      type: 'general',
      icon: Icons.palette_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv2_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv2.dart',
      tags: [
        CVTag(label: 'Creative', color: Colors.purple, icon: Icons.color_lens),
        CVTag(label: 'Designer', color: Colors.pink, icon: Icons.brush),
        CVTag(label: 'Bold', color: Colors.red, icon: Icons.flash_on),
      ],
    ));

    // CV3 - Technical Template
    register(CVMetadata(
      mcv: 'CV003',
      title: 'Technical CV',
      description: 'Mẫu CV kỹ thuật cho IT, Developer',
      type: 'field',
      typeField: 'Công nghệ',
      icon: Icons.code,
      thumbnailPath: 'assets/cv_thumbnails/cv3_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv3.dart',
      tags: [
        CVTag(label: 'Technical', color: Colors.indigo, icon: Icons.computer),
        CVTag(label: 'Developer', color: Colors.cyan, icon: Icons.code),
        CVTag(label: 'Detailed', color: Colors.blueGrey, icon: Icons.list),
      ],
    ));


    // CV4 - Technical IT Template (User Provided)
    register(CVMetadata(
      mcv: 'CV004',
      title: 'Technical IT CV',
      description: 'Mẫu CV kỹ thuật tối giản phối màu Cam - Đen chuyên nghiệp',
      type: 'field',
      typeField: 'Công nghệ',
      icon: Icons.computer_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv4_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv4.dart',
      tags: [
        CVTag(label: 'Technical', color: Colors.orange, icon: Icons.code),
        CVTag(label: 'IT Engineer', color: Colors.black87, icon: Icons.terminal),
        CVTag(label: 'Modern', color: Colors.blue, icon: Icons.auto_awesome),
      ],
    ));

    // CV5 - Business Administration Template
    register(CVMetadata(
      mcv: 'CV005',
      title: 'Business Administration CV',
      description: 'Mẫu CV quản trị kinh doanh chuyên nghiệp với bảng dự án chi tiết',
      type: 'field',
      typeField: 'Kinh doanh',
      icon: Icons.business_center_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv5_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv5.dart',
      tags: [
        CVTag(label: 'Business', color: Colors.blue, icon: Icons.business),
        CVTag(label: 'Sales', color: Colors.green, icon: Icons.trending_up),
        CVTag(label: 'Professional', color: Colors.indigo, icon: Icons.verified),
      ],
    ));

    // CV6 - Marketing Template
    register(CVMetadata(
      mcv: 'CV006',
      title: 'Marketing Strategy CV',
      description: 'Mẫu CV Marketing hiện đại, tập trung vào chiến dịch và kết quả',
      type: 'field',
      typeField: 'Marketing',
      icon: Icons.campaign_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv6_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv6.dart',
      tags: [
        CVTag(label: 'Marketing', color: Colors.orange, icon: Icons.campaign),
        CVTag(label: 'Creative', color: Colors.red, icon: Icons.auto_awesome),
        CVTag(label: 'Branding', color: Colors.blue, icon: Icons.star),
      ],
    ));

    // CV7 - Creative Design Template
    register(CVMetadata(
      mcv: 'CV007',
      title: 'Creative Design CV',
      description: 'Mẫu CV thiết kế tối giản, sang trọng theo phong cách editorial',
      type: 'field',
      typeField: 'Thiết kế',
      icon: Icons.palette_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv7_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv7.dart',
      tags: [
        CVTag(label: 'Design', color: Colors.black, icon: Icons.brush),
        CVTag(label: 'Minimalist', color: Colors.grey, icon: Icons.exposure_zero),
        CVTag(label: 'Elegant', color: Colors.amber, icon: Icons.workspace_premium),
      ],
    ));

    // CV8 - Finance & Banking Template
    register(CVMetadata(
      mcv: 'CV008',
      title: 'Finance & Banking CV',
      description: 'Mẫu CV tài chính ngân hàng truyền thống, chuyên nghiệp và tin cậy',
      type: 'field',
      typeField: 'Tài chính',
      icon: Icons.account_balance_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv8_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv8.dart',
      tags: [
        CVTag(label: 'Finance', color: Colors.indigo, icon: Icons.account_balance),
        CVTag(label: 'Analysis', color: Colors.blueGrey, icon: Icons.analytics),
        CVTag(label: 'Banking', color: Colors.blue, icon: Icons.savings),
      ],
    ));

    // CV9 - Healthcare & Medical Template
    register(CVMetadata(
      mcv: 'CV009',
      title: 'Healthcare & Medical CV',
      description: 'Mẫu CV y tế sạch sẽ, chính xác và chuyên nghiệp',
      type: 'field',
      typeField: 'Y tế',
      icon: Icons.medical_services_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv9_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv9.dart',
      tags: [
        CVTag(label: 'Medical', color: Colors.teal, icon: Icons.local_hospital),
        CVTag(label: 'Precise', color: Colors.cyan, icon: Icons.biotech),
        CVTag(label: 'Healthcare', color: Colors.green, icon: Icons.health_and_safety),
      ],
    ));
  }
}
