import 'package:flutter/material.dart';

/// CV Metadata - Định nghĩa thông tin, tags và mcv cho mỗi mẫu CV
class CVMetadata {

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
  final String mcv; // Mã CV duy nhất
  final String title;
  final String description;
  final String type; // Loại CV: general, field, upload, etc.
  final List<CVTag> tags;
  final IconData icon;
  final String thumbnailPath;
  final String templatePath; // Đường dẫn tới file template UI
  final String? typeField;

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
}

/// CV Tag - Thẻ phân loại CV
class CVTag {

  const CVTag({
    required this.label,
    required this.color,
    this.icon,
  });

  factory CVTag.fromJson(Map<String, dynamic> json) => CVTag(
    label: json['label'],
    color: Color(json['color']),
    icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
  );
  final String label;
  final Color color;
  final IconData? icon;

  Map<String, dynamic> toJson() => {
    'label': label,
    // ignore: deprecated_member_use
    'color': color.value,
    if (icon != null) 'icon': icon!.codePoint,
  };
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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
    register(const CVMetadata(
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

    // ===== 5 MẪU CV CHUNG MỚI (CV010 - CV014) =====

    // CV10 - Elegant Minimalist Template
    register(const CVMetadata(
      mcv: 'CV010',
      title: 'Elegant Minimalist CV',
      description: 'Mẫu CV tối giản sang trọng với typography đẹp và khoảng trắng hài hòa',
      type: 'general',
      icon: Icons.spa_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv10_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv10.dart',
      tags: [
        CVTag(label: 'Simple', color: Colors.grey, icon: Icons.remove_circle_outline),
        CVTag(label: 'Modern', color: Colors.blueGrey, icon: Icons.auto_awesome),
        CVTag(label: 'Professional', color: Colors.brown, icon: Icons.workspace_premium),
      ],
    ));

    // CV11 - Modern Gradient Template
    register(const CVMetadata(
      mcv: 'CV011',
      title: 'Modern Gradient CV',
      description: 'Mẫu CV hiện đại với gradient màu sắc bắt mắt, nổi bật',
      type: 'general',
      icon: Icons.gradient_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv11_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv11.dart',
      tags: [
        CVTag(label: 'Modern', color: Colors.deepPurple, icon: Icons.auto_awesome),
        CVTag(label: 'Creative', color: Colors.purple, icon: Icons.color_lens),
        CVTag(label: 'Bold', color: Colors.indigo, icon: Icons.flash_on),
      ],
    ));

    // CV12 - Classic Timeline Template
    register(const CVMetadata(
      mcv: 'CV012',
      title: 'Classic Timeline CV',
      description: 'Mẫu CV dòng thời gian cổ điển, rõ ràng và chuyên nghiệp',
      type: 'general',
      icon: Icons.timeline_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv12_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv12.dart',
      tags: [
        CVTag(label: 'Professional', color: Colors.red, icon: Icons.business_center),
        CVTag(label: 'Modern', color: Colors.deepOrange, icon: Icons.auto_awesome),
        CVTag(label: 'Clean', color: Colors.blueGrey, icon: Icons.check_circle),
      ],
    ));

    // CV13 - Bold Sidebar Template
    register(const CVMetadata(
      mcv: 'CV013',
      title: 'Bold Sidebar CV',
      description: 'Mẫu CV với thanh bên nổi bật, phong cách mạnh mẽ và hiện đại',
      type: 'general',
      icon: Icons.view_sidebar_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv13_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv13.dart',
      tags: [
        CVTag(label: 'Bold', color: Colors.cyan, icon: Icons.flash_on),
        CVTag(label: 'Modern', color: Colors.teal, icon: Icons.auto_awesome),
        CVTag(label: 'Professional', color: Colors.indigo, icon: Icons.business_center),
      ],
    ));

    // CV14 - Compact Professional Template
    register(const CVMetadata(
      mcv: 'CV014',
      title: 'Compact Professional CV',
      description: 'Mẫu CV chuyên nghiệp gọn gàng, tối ưu cho 1 trang A4',
      type: 'general',
      icon: Icons.compress_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv14_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv14.dart',
      tags: [
        CVTag(label: 'Simple', color: Colors.blue, icon: Icons.remove_circle_outline),
        CVTag(label: 'Professional', color: Colors.blueGrey, icon: Icons.business_center),
        CVTag(label: 'Clean', color: Colors.green, icon: Icons.check_circle),
      ],
    ));

    // ===== 5 MẪU CV THEO LĨNH VỰC MỚI (CV015 - CV019) =====

    // CV15 - Education & Teaching Template
    register(const CVMetadata(
      mcv: 'CV015',
      title: 'Education & Teaching CV',
      description: 'Mẫu CV dành cho giảng viên, giáo viên, nhà giáo dục',
      type: 'field',
      typeField: 'Giáo dục',
      icon: Icons.school_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv15_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv15.dart',
      tags: [
        CVTag(label: 'Education', color: Colors.green, icon: Icons.school),
        CVTag(label: 'Teaching', color: Colors.lightGreen, icon: Icons.cast_for_education),
        CVTag(label: 'Academic', color: Colors.teal, icon: Icons.auto_stories),
      ],
    ));

    // CV16 - Legal & Law Template
    register(const CVMetadata(
      mcv: 'CV016',
      title: 'Legal & Law CV',
      description: 'Mẫu CV dành cho luật sư, cố vấn pháp lý, chuyên viên luật',
      type: 'field',
      typeField: 'Luật',
      icon: Icons.gavel_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv16_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv16.dart',
      tags: [
        CVTag(label: 'Legal', color: Colors.brown, icon: Icons.gavel),
        CVTag(label: 'Professional', color: Colors.amber, icon: Icons.verified),
        CVTag(label: 'Formal', color: Colors.blueGrey, icon: Icons.account_balance),
      ],
    ));

    // CV17 - Engineering Template
    register(const CVMetadata(
      mcv: 'CV017',
      title: 'Engineering CV',
      description: 'Mẫu CV dành cho kỹ sư xây dựng, cơ khí, điện',
      type: 'field',
      typeField: 'Kỹ thuật',
      icon: Icons.engineering_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv17_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv17.dart',
      tags: [
        CVTag(label: 'Engineering', color: Colors.blueGrey, icon: Icons.engineering),
        CVTag(label: 'Technical', color: Colors.orange, icon: Icons.build),
        CVTag(label: 'Construction', color: Colors.brown, icon: Icons.construction),
      ],
    ));

    // CV18 - Hospitality & Tourism Template
    register(const CVMetadata(
      mcv: 'CV018',
      title: 'Hospitality & Tourism CV',
      description: 'Mẫu CV dành cho ngành du lịch, nhà hàng, khách sạn',
      type: 'field',
      typeField: 'Du lịch',
      icon: Icons.hotel_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv18_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv18.dart',
      tags: [
        CVTag(label: 'Hospitality', color: Colors.teal, icon: Icons.hotel),
        CVTag(label: 'Service', color: Colors.cyan, icon: Icons.room_service),
        CVTag(label: 'Tourism', color: Colors.lightBlue, icon: Icons.flight),
      ],
    ));

    // CV19 - Media & Journalism Template
    register(const CVMetadata(
      mcv: 'CV019',
      title: 'Media & Journalism CV',
      description: 'Mẫu CV dành cho nhà báo, biên tập viên, truyền thông',
      type: 'field',
      typeField: 'Truyền thông',
      icon: Icons.newspaper_outlined,
      thumbnailPath: 'assets/cv_thumbnails/cv19_thumb.png',
      templatePath: 'lib/screens/cv/cv_template/cv_ui/cv19.dart',
      tags: [
        CVTag(label: 'Media', color: Colors.purple, icon: Icons.videocam),
        CVTag(label: 'Journalism', color: Colors.deepPurple, icon: Icons.article),
        CVTag(label: 'Creative', color: Colors.pink, icon: Icons.create),
      ],
    ));
  }
}
