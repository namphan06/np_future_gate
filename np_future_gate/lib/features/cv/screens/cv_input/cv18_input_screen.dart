import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv18.dart';

/// CV18 Input Screen - Hospitality & Tourism
class CV18InputScreen extends BaseCVInputScreen {
  const CV18InputScreen({super.key, super.cvId});

  @override
  State<CV18InputScreen> createState() => _CV18InputScreenState();
}

class _CV18InputScreenState extends BaseCVInputScreenState<CV18InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV018',
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
        return 'Giới thiệu bản thân';
      case 'experiences':
        return 'Kinh nghiệm làm việc';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng';
      case 'certifications':
        return 'Ngoại ngữ';
      case 'activities':
        return 'Hoạt động';
      case 'awards':
        return 'Giải thưởng';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv18(data: data, onSectionTap: onSectionTap);
  }
}
