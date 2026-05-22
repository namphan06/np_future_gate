import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv2.dart';

/// CV2 Input Screen - Màn hình nhập liệu tương tác cho CV2
class CV2InputScreen extends BaseCVInputScreen {
  const CV2InputScreen({super.key, super.cvId});

  @override
  State<CV2InputScreen> createState() => _CV2InputScreenState();
}

class _CV2InputScreenState extends BaseCVInputScreenState<CV2InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV002',
    'type': 'general',
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
    'experiences': [],
    'education': [],
    'skills': [],
    'projects': [],
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
      case 'projects':
        return 'Dự án';
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
    return Cv2(data: data, onSectionTap: onSectionTap);
  }
}
