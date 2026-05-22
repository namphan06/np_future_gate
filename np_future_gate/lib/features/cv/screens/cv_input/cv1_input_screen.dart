import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv1.dart';

/// CV1 Input Screen - Màn hình nhập liệu tương tác cho CV1
class CV1InputScreen extends BaseCVInputScreen {
  const CV1InputScreen({super.key, super.cvId});

  @override
  State<CV1InputScreen> createState() => _CV1InputScreenState();
}

class _CV1InputScreenState extends BaseCVInputScreenState<CV1InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV001',
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
        return 'Kinh nghiệm';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng';
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
    return Cv1(data: data, onSectionTap: onSectionTap);
  }
}
