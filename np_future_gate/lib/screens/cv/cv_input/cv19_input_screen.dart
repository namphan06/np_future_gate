import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/screens/cv/cv_input/cv_input_form.dart';
import 'package:np_future_gate/screens/cv/cv_template/cv_ui/cv19.dart';

/// CV19 Input Screen - Media & Journalism
class CV19InputScreen extends StatefulWidget {
  const CV19InputScreen({super.key, this.cvId});
  final String? cvId;

  @override
  State<CV19InputScreen> createState() => _CV19InputScreenState();
}

class _CV19InputScreenState extends State<CV19InputScreen> {
  final CVSupabaseService _cvService = CVSupabaseService();
  Map<String, dynamic> _cvData = {};
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() { super.initState(); _initializeData(); }

  Future<void> _initializeData() async {
    if (widget.cvId != null) {
      setState(() => _isLoading = true);
      try {
        final data = await _cvService.getCVData(widget.cvId!);
        setState(() => _cvData = data ?? _getEmptyData());
      } catch (e) { _showError('Không thể tải dữ liệu CV: $e'); setState(() => _cvData = _getEmptyData()); }
      finally { setState(() => _isLoading = false); }
    } else { _cvData = _getEmptyData(); }
  }

  Map<String, dynamic> _getEmptyData() => {
    'mcv': 'CV019', 'type': 'field',
    'personal_info': {'full_name': '', 'title': '', 'email': '', 'phone': '', 'address': '', 'avatar_url': '', 'website': ''},
    'summary': '', 'experiences': [], 'education': [], 'skills': [], 'certifications': [], 'languages': [], 'references': [], 'activities': [], 'awards': [], 'projects': [],
  };

  void _onSectionTap(String section) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return Scaffold(
        appBar: AppBar(title: Text(_sectionTitle(section))),
        body: CV1InputForm(section: section, data: _cvData, onDataChanged: (updated) => setState(() => _cvData = updated), onClose: () => Navigator.of(ctx).pop()),
      );
    }));
  }

  String _sectionTitle(String section) {
    switch (section) {
      case 'personal_info': return 'Thông tin cá nhân';
      case 'avatar': return 'Ảnh đại diện';
      case 'cv_name': return 'Tên / Chức danh';
      case 'summary': return 'Giới thiệu';
      case 'experiences': return 'Kinh nghiệm làm việc';
      case 'education': return 'Học vấn';
      case 'skills': return 'Kỹ năng';
      case 'projects': return 'Tác phẩm / Dự án';
      case 'awards': return 'Giải thưởng';
      default: return section;
    }
  }

  Future<void> _saveCV() async {
    setState(() => _isLoading = true);
    try {
      if (widget.cvId != null) { await _cvService.updateCVData(widget.cvId!, _cvData); _showSuccess('Đã cập nhật CV'); }
      else { final newId = await _cvService.createCV(_cvData); _showSuccess('Đã tạo CV mới'); if (mounted) Navigator.pop(context, newId); }
    } catch (e) { _showError('Lỗi khi lưu CV: $e'); }
    finally { setState(() => _isLoading = false); }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(title: const Text('Đang tải...')), body: const Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(widget.cvId != null ? 'Chỉnh sửa CV' : 'Tạo CV mới'), actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveCV, tooltip: 'Lưu CV')]),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(controller: _scrollController, padding: const EdgeInsets.all(24),
          child: Center(child: Container(constraints: const BoxConstraints(maxWidth: 800), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Cv19(data: _cvData, onSectionTap: _onSectionTap),
          )),
        ),
      ),
    );
  }
}
