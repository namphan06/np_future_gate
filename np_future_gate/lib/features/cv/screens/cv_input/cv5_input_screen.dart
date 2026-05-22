import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv5.dart';

/// CV5 Input Screen - Màn hình nhập liệu tương tác cho CV5
class CV5InputScreen extends BaseCVInputScreen {
  const CV5InputScreen({super.key, super.cvId});

  @override
  State<CV5InputScreen> createState() => _CV5InputScreenState();
}

class _CV5InputScreenState extends BaseCVInputScreenState<CV5InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV005',
    'type': 'general',
    'personal_info': {
      'full_name': '',
      'dob': '',
      'gender': '',
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
    'references': [],
    'activities': [],
    'awards': [],
    'projects': [],
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
        return 'Mục tiêu nghề nghiệp';
      case 'experiences':
        return 'Kinh nghiệm làm việc';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng';
      case 'awards':
        return 'Danh hiệu & Giải thưởng';
      case 'certifications':
        return 'Chứng chỉ';
      case 'activities':
        return 'Hoạt động';
      case 'interests':
        return 'Sở thích';
      case 'references':
        return 'Người giới thiệu';
      case 'projects':
        return 'Dự án';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv5(data: data, onSectionTap: onSectionTap);
  }
}
