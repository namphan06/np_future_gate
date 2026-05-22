import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv11.dart';

/// CV11 Input Screen - Modern Gradient
class CV11InputScreen extends BaseCVInputScreen {
  const CV11InputScreen({super.key, super.cvId});

  @override
  State<CV11InputScreen> createState() => _CV11InputScreenState();
}

class _CV11InputScreenState extends BaseCVInputScreenState<CV11InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV011',
    'type': 'general',
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
        return 'Giới thiệu';
      case 'experiences':
        return 'Kinh nghiệm';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng';
      case 'certifications':
        return 'Chứng chỉ';
      case 'awards':
        return 'Giải thưởng';
      case 'activities':
        return 'Hoạt động';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv11(data: data, onSectionTap: onSectionTap);
  }
}
