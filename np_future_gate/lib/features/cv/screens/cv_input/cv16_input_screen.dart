import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/base_cv_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv16.dart';

/// CV16 Input Screen - Legal & Law
class CV16InputScreen extends BaseCVInputScreen {
  const CV16InputScreen({super.key, super.cvId});

  @override
  State<CV16InputScreen> createState() => _CV16InputScreenState();
}

class _CV16InputScreenState extends BaseCVInputScreenState<CV16InputScreen> {
  @override
  Map<String, dynamic> getEmptyDataSchema() => {
    'mcv': 'CV016',
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
        return 'Tóm tắt chuyên môn';
      case 'experiences':
        return 'Kinh nghiệm pháp lý';
      case 'education':
        return 'Học vấn & Hành nghề';
      case 'skills':
        return 'Lĩnh vực chuyên môn';
      case 'certifications':
        return 'Chứng chỉ';
      case 'projects':
        return 'Vụ việc tiêu biểu';
      default:
        return section;
    }
  }

  @override
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap) {
    return Cv16(data: data, onSectionTap: onSectionTap);
  }
}
