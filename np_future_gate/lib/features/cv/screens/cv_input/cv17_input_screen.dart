import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv17.dart';

/// CV17 Input Screen - Engineering
class CV17InputScreen extends BaseCVInputScreen {
  const CV17InputScreen({super.key, super.cvId});

  @override
  State<CV17InputScreen> createState() => _CV17InputScreenState();
}

class _CV17InputScreenState extends BaseCVInputScreenState<CV17InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV017',
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
        return 'Mục tiêu nghề nghiệp';
      case 'experiences':
        return 'Kinh nghiệm làm việc';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng kỹ thuật';
      case 'certifications':
        return 'Chứng chỉ';
      case 'projects':
        return 'Dự án kỹ thuật';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv17(data: data, onSectionTap: onSectionTap);
  }
}
