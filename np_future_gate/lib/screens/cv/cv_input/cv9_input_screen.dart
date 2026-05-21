import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/screens/cv/cv_input/cv_input_form.dart';
import 'package:np_future_gate/screens/cv/cv_template/cv_ui/cv9.dart';

class CV9InputScreen extends StatefulWidget {
  const CV9InputScreen({super.key, this.cvId});
  final String? cvId;

  @override
  State<CV9InputScreen> createState() => _CV9InputScreenState();
}

class _CV9InputScreenState extends State<CV9InputScreen> {
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
    'mcv': 'CV009',
    'type': 'field',
    'typeField': 'Y tế',
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
        title: Text(widget.cvId != null ? 'Chỉnh sửa Medical CV' : 'Tạo Medical CV'),
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
        child: Cv9(data: _cvData, onSectionTap: _onSectionTap),
      ),
    );
  }
}
