import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/screens/cv/cv_input/cv_input_form.dart';
import 'package:np_future_gate/screens/cv/cv_template/cv_ui/cv6.dart';

class CV6InputScreen extends StatefulWidget {
  const CV6InputScreen({super.key, this.cvId});
  final String? cvId;

  @override
  State<CV6InputScreen> createState() => _CV6InputScreenState();
}

class _CV6InputScreenState extends State<CV6InputScreen> {
  final CVSupabaseService _cvService = CVSupabaseService();
  Map<String, dynamic> _cvData = {};
  bool _isLoading = false;

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
        setState(() => _cvData = data ?? _getEmptyData());
      } catch (e) {
        setState(() => _cvData = _getEmptyData());
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _cvData = _getEmptyData();
    }
  }

  Map<String, dynamic> _getEmptyData() => {
    'mcv': 'CV006',
    'type': 'field',
    'typeField': 'Marketing',
    'personal_info': {
      'full_name': '',
      'title': '',
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
    'activities': [],
    'projects': [],
    'awards': [],
    'languages': [],
    'references': [],
    'interests': '',
  };

  void _onSectionTap(String section) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa thông tin')),
        body: CV1InputForm(
          section: section,
          data: _cvData,
          onDataChanged: (updated) => setState(() => _cvData = updated),
          onClose: () => Navigator.of(ctx).pop(),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cvId != null ? 'Chỉnh sửa Marketing CV' : 'Tạo Marketing CV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                if (widget.cvId != null) {
                  await _cvService.updateCVData(widget.cvId!, _cvData);
                } else {
                  await _cvService.createCV(_cvData);
                  if (!mounted) return;
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              } finally {
                setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Cv6(data: _cvData, onSectionTap: _onSectionTap),
      ),
    );
  }
}
