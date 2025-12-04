import 'package:flutter/material.dart';
import '../cv_template/cv_ui/cv3.dart';
import 'cv_input_form.dart';
import '../../../core/services/cv_supabase_service.dart';

/// CV3 Input Screen - Màn hình nhập liệu cho CV3 (Technical/IT)
class CV3InputScreen extends StatefulWidget {
  final String? cvId; // null = tạo mới, có giá trị = chỉnh sửa

  const CV3InputScreen({Key? key, this.cvId}) : super(key: key);

  @override
  State<CV3InputScreen> createState() => _CV3InputScreenState();
}

class _CV3InputScreenState extends State<CV3InputScreen> {
  final CVSupabaseService _cvService = CVSupabaseService();
  Map<String, dynamic> _cvData = {};
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
        setState(() => _cvData = data ?? _getEmptyCV3Data());
      } catch (e) {
        _showError('Không thể tải dữ liệu CV: $e');
        setState(() => _cvData = _getEmptyCV3Data());
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _cvData = _getEmptyCV3Data();
    }
  }

  Map<String, dynamic> _getEmptyCV3Data() => {
    'mcv': 'CV003',
    'type': 'field', // Changed from 'domain' to 'field' to match metadata
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
    'skills': [], // Skills are important for Tech CV
    'experiences': [],
    'projects': [],
    'education': [],
    'certifications': [],
    'languages': [],
    'references': [],
    'activities': [],
    'awards': [],
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

  Future<void> _saveCV() async {
    setState(() => _isLoading = true);
    try {
      if (widget.cvId != null) {
        await _cvService.updateCVData(widget.cvId!, _cvData);
        _showSuccess('Đã cập nhật CV thành công');
      } else {
        final newId = await _cvService.createCV(_cvData);
        _showSuccess('Đã tạo CV mới: $newId');
        Navigator.pop(context, newId);
      }
    } catch (e) {
      _showError('Lỗi khi lưu CV: $e');
      debugPrint('Error saving CV: $e');
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
        title: Text(widget.cvId != null ? 'Chỉnh sửa CV (IT)' : 'Tạo CV IT mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCV,
            tooltip: 'Lưu CV',
          ),
        ],
      ),
      body: _selectedSection == null
          ? Container(
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Cv3(
                      data: _cvData,
                      onSectionTap: _onSectionTap,
                    ),
                  ),
                ),
              ),
            )
          : Row(
              children: [
                // Left: CV Preview (Interactive)
                Expanded(
                  flex: 3,
                  child: Container(
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
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Cv3(
                            data: _cvData,
                            onSectionTap: _onSectionTap,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right: Input Form
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(-2, 0),
                        ),
                      ],
                    ),
                    child: _selectedSection != null
                        ? CV1InputForm(
                            section: _selectedSection!,
                            data: _cvData,
                            onDataChanged: (updatedData) {
                              setState(() => _cvData = updatedData);
                            },
                            onClose: () => setState(() => _selectedSection = null),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
    );
  }
}
