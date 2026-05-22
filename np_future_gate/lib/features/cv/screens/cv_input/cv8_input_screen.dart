import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv8.dart';

/// CV8 Input Screen - Finance
class CV8InputScreen extends BaseCVInputScreen {
  const CV8InputScreen({super.key, super.cvId});

  @override
  State<CV8InputScreen> createState() => _CV8InputScreenState();
}

class _CV8InputScreenState extends BaseCVInputScreenState<CV8InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV008',
    'type': 'field',
    'typeField': 'Tài chính',
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
    return Cv8(data: data, onSectionTap: onSectionTap);
  }
}
