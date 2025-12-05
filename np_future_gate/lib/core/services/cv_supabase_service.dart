import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cv_model.dart';

/// CV Supabase Service - Quản lý lưu trữ và truy xuất CV từ Supabase
class CVSupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Tạo CV mới trong database
  Future<String> createCV(Map<String, dynamic> cvData) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final response = await _supabase.from('cv_templates').insert({
        'mcv': cvData['mcv'], // Allow null if not provided
        'title': cvData['personal_info']?['full_name'] ?? 'Untitled CV',
        'description': cvData['summary'] ?? '',
        'tags': _extractTags(cvData),
        'data': cvData,
        'type': cvData['type'] ?? 'general', // Use type from data or default to general
        'user_create': userId,
      }).select('id').single();

      return response['id'] as String;
    } catch (e, st) {
      // Log to terminal for debugging
      debugPrint('CVSupabaseService.createCV error: $e');
      debugPrintStack(stackTrace: st, label: 'createCV stacktrace');
      // Re-throw with message for UI
      throw Exception('Không thể tạo CV: $e');
    }
  }

  /// Cập nhật CV
  Future<void> updateCVData(String cvId, Map<String, dynamic> cvData) async {
    try {
      await _supabase.from('cv_templates').update({
        'title': cvData['personal_info']?['full_name'] ?? 'Untitled CV',
        'description': cvData['summary'] ?? '',
        'tags': _extractTags(cvData),
        'data': cvData,
      }).eq('id', cvId);
    } catch (e, st) {
      debugPrint('CVSupabaseService.updateCVData error: $e');
      debugPrintStack(stackTrace: st, label: 'updateCVData stacktrace');
      throw Exception('Không thể cập nhật CV: $e');
    }
  }

  /// Lấy dữ liệu CV theo ID
  Future<Map<String, dynamic>?> getCVData(String cvId) async {
    try {
      final response = await _supabase
          .from('cv_templates')
          .select('data')
          .eq('id', cvId)
          .single();

      return response['data'] as Map<String, dynamic>?;
    } catch (e, st) {
      debugPrint('CVSupabaseService.getCVData error: $e');
      debugPrintStack(stackTrace: st, label: 'getCVData stacktrace');
      throw Exception('Không thể tải CV: $e');
    }
  }

  /// Lấy CV theo MCV code
  Future<Map<String, dynamic>?> getCVByMCV(String mcv) async {
    try {
      final response = await _supabase
          .from('cv_templates')
          .select('*')
          .eq('mcv', mcv)
          .maybeSingle();

      return response;
    } catch (e, st) {
      debugPrint('CVSupabaseService.getCVByMCV error: $e');
      debugPrintStack(stackTrace: st, label: 'getCVByMCV stacktrace');
      throw Exception('Không thể tải CV theo MCV: $e');
    }
  }

  /// Lấy tất cả CVs của user hiện tại
  Future<List<Map<String, dynamic>>> getMyCVs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final response = await _supabase
          .from('cv_templates')
          .select('*')
          .eq('user_create', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      debugPrint('CVSupabaseService.getMyCVs error: $e');
      debugPrintStack(stackTrace: st, label: 'getMyCVs stacktrace');
      throw Exception('Không thể tải danh sách CV: $e');
    }
  }

  /// Lấy danh sách CV dưới dạng Model cho Job Application
  Future<List<CVModel>> getUserCVs(String userId) async {
    try {
      final response = await _supabase
          .from('cv_templates')
          .select()
          .eq('user_create', userId)
          .order('updated_at', ascending: false);

      return (response as List).map((e) => CVModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching user CVs: $e');
      return [];
    }
  }

  /// Lấy CVs theo tags
  Future<List<Map<String, dynamic>>> getCVsByTags(List<String> tags) async {
    try {
      final response = await _supabase
          .from('cv_templates')
          .select('*')
          .contains('tags', tags);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      debugPrint('CVSupabaseService.getCVsByTags error: $e');
      debugPrintStack(stackTrace: st, label: 'getCVsByTags stacktrace');
      throw Exception('Không thể tìm CV theo tags: $e');
    }
  }

  /// Xóa CV
  Future<void> deleteCV(String cvId) async {
    try {
      await _supabase.from('cv_templates').delete().eq('id', cvId);
    } catch (e, st) {
      debugPrint('CVSupabaseService.deleteCV error: $e');
      debugPrintStack(stackTrace: st, label: 'deleteCV stacktrace');
      throw Exception('Không thể xóa CV: $e');
    }
  }

  /// Lấy dữ liệu đầy đủ của CV theo ID (bao gồm mcv, type, title, data...)
  Future<Map<String, dynamic>?> getCVFullData(String cvId) async {
    try {
      final response = await _supabase
          .from('cv_templates')
          .select('*')
          .eq('id', cvId)
          .single();

      return response;
    } catch (e, st) {
      debugPrint('CVSupabaseService.getCVFullData error: $e');
      debugPrintStack(stackTrace: st, label: 'getCVFullData stacktrace');
      throw Exception('Không thể tải thông tin CV: $e');
    }
  }

  /// Trích xuất tags từ CV data
  List<String> _extractTags(Map<String, dynamic> cvData) {
    final tags = <String>[];
    
    // Thêm tags dựa trên dữ liệu có sẵn
    if (cvData['experiences']?.isNotEmpty ?? false) {
      tags.add('Có kinh nghiệm');
    }
    
    if (cvData['skills']?.isNotEmpty ?? false) {
      tags.add('Có kỹ năng');
    }
    
    if (cvData['certifications']?.isNotEmpty ?? false) {
      tags.add('Có chứng chỉ');
    }

    // Thêm MCV tag
    if (cvData['mcv'] != null) {
      tags.add(cvData['mcv']);
    }

    return tags;
  }
}

/// CV Output Widget - Hiển thị CV từ database
class CVOutputWidget extends StatefulWidget {
  final String? cvId;
  final String? mcv;

  const CVOutputWidget({
    Key? key,
    this.cvId,
    this.mcv,
  }) : super(key: key);

  @override
  State<CVOutputWidget> createState() => _CVOutputWidgetState();
}

class _CVOutputWidgetState extends State<CVOutputWidget> {
  final CVSupabaseService _cvService = CVSupabaseService();
  Map<String, dynamic>? _cvData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCV();
  }

  Future<void> _loadCV() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? data;
      
      if (widget.cvId != null) {
        data = await _cvService.getCVData(widget.cvId!);
      } else if (widget.mcv != null) {
        final cvRecord = await _cvService.getCVByMCV(widget.mcv!);
        data = cvRecord?['data'] as Map<String, dynamic>?;
      }

      setState(() {
        _cvData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCV,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_cvData == null) {
      return const Center(child: Text('Không tìm thấy CV'));
    }

    // Render CV based on MCV code
    return _buildCVByMCV(_cvData!);
  }

  Widget _buildCVByMCV(Map<String, dynamic> data) {
    final mcv = data['mcv'] ?? 'CV001';

    // Dynamically load CV template based on MCV
    // You can expand this to support multiple templates
    switch (mcv) {
      case 'CV001':
        return _buildCV1Output(data);
      case 'CV002':
        return _buildCV2Output(data);
      case 'CV003':
        return _buildCV3Output(data);
      default:
        return _buildCV1Output(data);
    }
  }

  Widget _buildCV1Output(Map<String, dynamic> data) {
    final info = data['personal_info'] ?? {};
    final summary = data['summary'] ?? '';
    final experiences = data['experiences'] ?? [];
    final education = data['education'] ?? [];
    final skills = data['skills'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Info
            Text(
              info['full_name'] ?? 'N/A',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              info['title'] ?? '',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (info['email']?.isNotEmpty ?? false)
                  Text('📧 ${info['email']}  '),
                if (info['phone']?.isNotEmpty ?? false)
                  Text('📱 ${info['phone']}'),
              ],
            ),
            const Divider(height: 32),

            // Summary
            if (summary.isNotEmpty) ...[
              const Text(
                'TÓM TẮT',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(summary),
              const Divider(height: 32),
            ],

            // Experiences
            if (experiences.isNotEmpty) ...[
              const Text(
                'KINH NGHIỆM LÀM VIỆC',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...experiences.map<Widget>((exp) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp['position'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${exp['company']} • ${exp['duration']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (exp['description']?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(exp['description']),
                        ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: 32),
            ],

            // Education
            if (education.isNotEmpty) ...[
              const Text(
                'HỌC VẤN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...education.map<Widget>((edu) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edu['degree'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${edu['school']} • ${edu['year']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: 32),
            ],

            // Skills
            if (skills.isNotEmpty) ...[
              const Text(
                'KỸ NĂNG',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map<Widget>((skill) {
                  return Chip(
                    label: Text(skill['name'] ?? ''),
                    backgroundColor: Colors.blue[50],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCV2Output(Map<String, dynamic> data) {
    // TODO: Implement CV2 template output
    return _buildCV1Output(data);
  }

  Widget _buildCV3Output(Map<String, dynamic> data) {
    // TODO: Implement CV3 template output
    return _buildCV1Output(data);
  }
}
