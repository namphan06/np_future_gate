import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv4.dart';

/// CV4 Input Screen - Màn hình nhập liệu tương tác cho CV4
class CV4InputScreen extends BaseCVInputScreen {
  const CV4InputScreen({super.key, super.cvId});

  @override
  State<CV4InputScreen> createState() => _CV4InputScreenState();
}

class _CV4InputScreenState extends BaseCVInputScreenState<CV4InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV004',
    'type': 'field',
    'type_field': 'Công nghệ',
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
    'references': [],
    'activities': [],
    'awards': [],
    'interests': '',
  };

  @override
  String sectionTitle(String section) {
    switch (section) {
      case 'cv_name':
        return 'Tên CV / Họ và tên';
      case 'avatar':
        return 'Ảnh đại diện';
      case 'personal_details':
        return 'Thông tin cá nhân';
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
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv4(data: data, onSectionTap: onSectionTap);
  }
}
