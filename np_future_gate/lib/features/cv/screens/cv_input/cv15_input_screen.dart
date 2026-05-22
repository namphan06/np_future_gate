import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv15.dart';

/// CV15 Input Screen - Education & Teaching
class CV15InputScreen extends BaseCVInputScreen {
  const CV15InputScreen({super.key, super.cvId});

  @override
  State<CV15InputScreen> createState() => _CV15InputScreenState();
}

class _CV15InputScreenState extends BaseCVInputScreenState<CV15InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV015',
    'type': 'field',
    'personal_info': {
      'full_name': '',
      'title': '',
      'email': '',
      'phone': '',
      'address': '',
      'avatar_url': '',
    },
    'summary': '',
    'experiences': [],
    'education': [],
    'skills': [],
    'certifications': [],
    'languages': [],
    'references': [],
    'activities': [],
    'awards': [],
    'projects': [],
  };

  @override
  String sectionTitle(String section) {
    switch (section) {
      case 'personal_info':
        return 'Thông tin cá nhân';
      case 'avatar':
        return 'Ảnh đại diện';
      case 'cv_name':
        return 'Tên / Chức danh';
      case 'summary':
        return 'Triết lý giáo dục';
      case 'experiences':
        return 'Kinh nghiệm giảng dạy';
      case 'education':
        return 'Học vấn & Bằng cấp';
      case 'skills':
        return 'Kỹ năng';
      case 'certifications':
        return 'Chứng chỉ';
      case 'projects':
        return 'Nghiên cứu & Công bố';
      case 'awards':
        return 'Giải thưởng';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv15(data: data, onSectionTap: onSectionTap);
  }
}
