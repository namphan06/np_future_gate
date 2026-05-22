import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv13.dart';

/// CV13 Input Screen - Bold Sidebar
class CV13InputScreen extends BaseCVInputScreen {
  const CV13InputScreen({super.key, super.cvId});

  @override
  State<CV13InputScreen> createState() => _CV13InputScreenState();
}

class _CV13InputScreenState extends BaseCVInputScreenState<CV13InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV013',
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
      case 'references':
        return 'Người giới thiệu';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv13(data: data, onSectionTap: onSectionTap);
  }
}
