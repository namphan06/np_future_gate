import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv6.dart';

/// CV6 Input Screen - Marketing
class CV6InputScreen extends BaseCVInputScreen {
  const CV6InputScreen({super.key, super.cvId});

  @override
  State<CV6InputScreen> createState() => _CV6InputScreenState();
}

class _CV6InputScreenState extends BaseCVInputScreenState<CV6InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV006',
    'type': 'field',
    'typeField': 'Marketing',
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
    return Cv6(data: data, onSectionTap: onSectionTap);
  }
}
