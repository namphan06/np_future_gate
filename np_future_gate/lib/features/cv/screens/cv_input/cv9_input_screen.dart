import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv9.dart';

/// CV9 Input Screen - Medical
class CV9InputScreen extends BaseCVInputScreen {
  const CV9InputScreen({super.key, super.cvId});

  @override
  State<CV9InputScreen> createState() => _CV9InputScreenState();
}

class _CV9InputScreenState extends BaseCVInputScreenState<CV9InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV009',
    'type': 'field',
    'typeField': 'Y tế',
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
    return Cv9(data: data, onSectionTap: onSectionTap);
  }
}
