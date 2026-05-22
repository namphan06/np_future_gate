import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv7.dart';

/// CV7 Input Screen - Design
class CV7InputScreen extends BaseCVInputScreen {
  const CV7InputScreen({super.key, super.cvId});

  @override
  State<CV7InputScreen> createState() => _CV7InputScreenState();
}

class _CV7InputScreenState extends BaseCVInputScreenState<CV7InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV007',
    'type': 'field',
    'typeField': 'Thiết kế',
    'personal_info': {
      'full_name': '',
      'title': '',
      'email': '',
      'phone': '',
      'address': '',
      'website': '',
      'avatar_url': '',
    },
    'summary': '',
    'experiences': [],
    'education': [],
    'skills': [],
    'certifications': [],
    'activities': [],
    'projects': [],
    'awards': [],
    'languages': [],
    'references': [],
    'interests': '',
  };

  @override
  String sectionTitle(String section) {
    switch (section) {
      case 'personal_info':
        return 'Thông tin cá nhân';
      case 'avatar':
        return 'Ảnh đại diện';
      case 'summary':
        return 'Giới thiệu';
      case 'experiences':
        return 'Kinh nghiệm';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng';
      case 'certifications':
        return 'Chứng chỉ';
      case 'activities':
        return 'Hoạt động';
      case 'projects':
        return 'Dự án';
      case 'awards':
        return 'Giải thưởng';
      case 'references':
        return 'Người giới thiệu';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv7(data: data, onSectionTap: onSectionTap);
  }
}
