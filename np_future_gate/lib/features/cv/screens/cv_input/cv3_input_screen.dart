import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv3.dart';

/// CV3 Input Screen - Màn hình nhập liệu cho CV3 (Technical/IT)
class CV3InputScreen extends BaseCVInputScreen {
  const CV3InputScreen({super.key, super.cvId});

  @override
  State<CV3InputScreen> createState() => _CV3InputScreenState();
}

class _CV3InputScreenState extends BaseCVInputScreenState<CV3InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV003',
    'type': 'field',
    'typeField': 'Công nghệ',
    'tags': ['Công nghệ', 'Technical', 'Developer'],
    'personal_info': {
      'full_name': '',
      'title': '',
      'email': '',
      'phone': '',
      'address': '',
      'avatar_url': '',
      'website': '',
    },
    'summary': '',
    'skills': [],
    'experiences': [],
    'projects': [],
    'education': [],
    'certifications': [],
    'languages': [],
    'references': [],
    'activities': [],
    'awards': [],
  };

  @override
  String sectionTitle(String section) {
    switch (section) {
      case 'cv_name':
        return 'Tên CV / Họ và tên';
      case 'avatar':
        return 'Ảnh đại diện';
      case 'personal_details':
      case 'personal_info':
        return 'Thông tin cá nhân';
      case 'summary':
        return 'Tóm tắt';
      case 'experiences':
        return 'Kinh nghiệm làm việc';
      case 'projects':
        return 'Dự án nổi bật';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng chuyên môn';
      case 'certifications':
        return 'Chứng chỉ';
      case 'activities':
        return 'Hoạt động';
      case 'awards':
        return 'Danh hiệu & Giải thưởng';
      case 'references':
        return 'Người giới thiệu';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv3(data: data, onSectionTap: onSectionTap);
  }
}
