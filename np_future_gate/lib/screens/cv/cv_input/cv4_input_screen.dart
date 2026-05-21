import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/screens/cv/cv_input/cv_input_form.dart';
import 'package:np_future_gate/screens/cv/cv_template/cv_ui/cv4.dart';

/// CV4 Input Screen - Màn hình nhập liệu tương tác cho CV4
class CV4InputScreen extends StatefulWidget {

  const CV4InputScreen({super.key, this.cvId});
  final String? cvId;

  @override
  State<CV4InputScreen> createState() => _CV4InputScreenState();
}

class _CV4InputScreenState extends State<CV4InputScreen> {
  final CVSupabaseService _cvService = CVSupabaseService();
  Map<String, dynamic> _cvData = {};
  // ignore: unused_field
  String? _selectedSection;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.cvId != null) {
      setState(() => _isLoading = true);
      try {
        final data = await _cvService.getCVData(widget.cvId!);
        setState(() => _cvData = data ?? _getEmptyCV4Data());
      } catch (e) {
        _showError('Không thể tải dữ liệu CV: $e');
        setState(() => _cvData = _getEmptyCV4Data());
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _cvData = _getEmptyCV4Data();
    }
  }

  Map<String, dynamic> _getEmptyCV4Data() => {
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

  void _onSectionTap(String section) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return Scaffold(
        appBar: AppBar(title: Text(_sectionTitle(section))),
        body: CV1InputForm(
          section: section,
          data: _cvData,
          onDataChanged: (updated) {
            setState(() => _cvData = updated);
          },
          onClose: () {
            Navigator.of(ctx).pop();
          },
        ),
      );
    }));
  }

  String _sectionTitle(String section) {
    switch (section) {
      case 'cv_name': return 'Tên CV / Họ và tên';
      case 'avatar': return 'Ảnh đại diện';
      case 'personal_details': return 'Thông tin cá nhân';
      case 'summary': return 'Mục tiêu nghề nghiệp';
      case 'experiences': return 'Kinh nghiệm làm việc';
      case 'education': return 'Học vấn';
      case 'skills': return 'Kỹ năng';
      case 'awards': return 'Danh hiệu & Giải thưởng';
      case 'certifications': return 'Chứng chỉ';
      case 'activities': return 'Hoạt động';
      case 'interests': return 'Sở thích';
      case 'references': return 'Người giới thiệu';
      default: return section;
    }
  }

  Future<void> _saveCV() async {
    setState(() => _isLoading = true);
    try {
      if (widget.cvId != null) {
        await _cvService.updateCVData(widget.cvId!, _cvData);
        _showSuccess('Đã cập nhật CV thành công');
      } else {
        final newId = await _cvService.createCV(_cvData);
        _showSuccess('Đã tạo CV mới: $newId');
        // ignore: use_build_context_synchronously
        Navigator.pop(context, newId);
      }
    } catch (e) {
      _showError('Lỗi khi lưu CV: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tải...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cvId != null ? 'Chỉnh sửa CV' : 'Tạo CV mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCV,
            tooltip: 'Lưu CV',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Cv4(
                data: _cvData,
                onSectionTap: _onSectionTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
