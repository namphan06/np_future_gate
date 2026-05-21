import 'dart:io';

import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/cv_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

      debugPrint('Creating CV Record for user $userId');
      debugPrint('CV Data Payload: $cvData');

      // Insert and select ALL columns to verify what was saved
      final response = await _supabase.from('cv_templates').insert({
        'mcv': cvData['mcv'], 
        'title': cvData['title'] ?? cvData['personal_info']?['full_name'] ?? 'Untitled CV',
        'description': cvData['description'] ?? cvData['summary'] ?? '',
        'tags': _extractTags(cvData),
        'data': cvData,
        'type': cvData['type'] ?? 'general',
        'user_create': userId,
      }).select().single();

      debugPrint('✅ CV Created successfully. Inserted Record: $response');
      
      final newId = response['id'] as String;

      // IMMEDIATE VERIFICATION: Try to read it back
      debugPrint('🔍 Verifying storage by reading back ID: $newId ...');
      final verifyRead = await _supabase.from('cv_templates').select().eq('id', newId).maybeSingle();
      
      if (verifyRead != null) {
        debugPrint('✅ Verification Success: Record found in DB.');
      } else {
        debugPrint('❌ Verification FAILED: Record NOT found immediately after insert!');
      }

      return newId;
    } catch (e, st) {
      debugPrint('❌ CVSupabaseService.createCV error: $e');
      debugPrintStack(stackTrace: st, label: 'createCV stacktrace');
      throw Exception('Không thể tạo CV: $e');
    }
  }

  /// Cập nhật CV
  Future<void> updateCVData(String cvId, Map<String, dynamic> cvData) async {
    try {
      debugPrint('Updating CV $cvId with data: $cvData');
      await _supabase.from('cv_templates').update({
        'title': cvData['personal_info']?['full_name'] ?? 'Untitled CV',
        'description': cvData['summary'] ?? '',
        'tags': _extractTags(cvData),
        'data': cvData,
      }).eq('id', cvId);
      debugPrint('✅ CV Updated successfully.');
    } catch (e, st) {
      debugPrint('CVSupabaseService.updateCVData error: $e');
      debugPrintStack(stackTrace: st, label: 'updateCVData stacktrace');
      throw Exception('Không thể cập nhật CV: $e');
    }
  }

  /// Lấy dữ liệu CV theo ID
  Future<Map<String, dynamic>?> getCVData(String cvId) async {
    try {
      debugPrint('Getting CV Data for ID: $cvId');
      final response = await _supabase
          .from('cv_templates')
          .select('data')
          .eq('id', cvId)
          .single();

      debugPrint('✅ GetCVData success. Found data keys: ${(response['data'] as Map).keys.toList()}');
      return response['data'] as Map<String, dynamic>?;
    } catch (e, st) {
      debugPrint('CVSupabaseService.getCVData error: $e');
      debugPrintStack(stackTrace: st, label: 'getCVData stacktrace');
      throw Exception('Không thể tải CV: $e');
    }
  }
  
  // ... (Lines 70-168 remain mostly the same, skipping to uploadCVFile) 

  /// Upload CV file to Storage
  Future<String> uploadCVFile(File file, String userId) async {
    try {
      if (!file.existsSync()) {
        throw Exception('File does not exist at path: ${file.path}');
      }
      
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';
      
      debugPrint('📂 Preparing to upload file:');
      debugPrint('   - Local Path: ${file.path}');
      debugPrint('   - Size: ${await file.length()} bytes');
      debugPrint('   - Target Supabase Path: $path');

      await _supabase.storage.from('cv_upload').upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      final publicUrl = _supabase.storage.from('cv_upload').getPublicUrl(path);
      debugPrint('✅ File uploaded successfully. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      throw Exception('Lỗi khi upload file: $e');
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

  /// Lấy CV cho employer (dành cho xem CV của applicants)
  /// Sử dụng maybeSingle() để tránh lỗi RLS
  Future<Map<String, dynamic>?> getCVFullDataForEmployer(String cvId) async {
    try {
      debugPrint('🔍 Getting CV for employer: $cvId');
      
      // Try with maybeSingle to avoid RLS error
      final response = await _supabase
          .from('cv_templates')
          .select('*')
          .eq('id', cvId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ CV not found or access denied (RLS): $cvId');
        // In production, you might want to use an RPC function with SECURITY DEFINER
        // to properly handle employer access to applicant CVs
        throw Exception('CV không tồn tại hoặc bạn không có quyền truy cập');
      }

      debugPrint('✅ CV retrieved successfully for employer');
      return response;
    } catch (e, st) {
      debugPrint('CVSupabaseService.getCVFullDataForEmployer error: $e');
      debugPrintStack(stackTrace: st, label: 'getCVFullDataForEmployer stacktrace');
      throw Exception('Không thể tải thông tin CV: $e');
    }
  }



  /// Trích xuất tags từ CV data
  List<String> _extractTags(Map<String, dynamic> cvData) {
    // If tags are already provided in cvData, prioritize them
    if (cvData['tags'] != null) {
        if (cvData['tags'] is List) {
            return List<String>.from(cvData['tags']);
        }
    }

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

  const CVOutputWidget({
    super.key,
    this.cvId,
    this.mcv,
  });
  final String? cvId;
  final String? mcv;

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
      case 'UPLOAD':
        return _buildUploadOutput(data);
      default:
        // Fallback for upload type if mcv is missing but type is upload
        if (data['type'] == 'upload') {
          return _buildUploadOutput(data);
        }
        return _buildCV1Output(data);
    }
  }

  Widget _buildUploadOutput(Map<String, dynamic> data) {
    final fileUrl = data['file_url'] ?? '';
    final title = data['title'] ?? 'CV Upload';
    final fileName = data['file_name'] ?? 'Tài liệu CV';
    
    final lowerUrl = fileUrl.toString().toLowerCase();
    final isImage = lowerUrl.endsWith('.jpg') || 
                    lowerUrl.endsWith('.png') || 
                    lowerUrl.endsWith('.jpeg') ||
                    lowerUrl.endsWith('.webp');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isImage && fileUrl.isNotEmpty)
              Image.network(
                fileUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator();
                },
                errorBuilder: (_, __, ___) => const Column(
                  children: [
                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    Text('Không thể tải ảnh'),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Icon(
                    fileName.toString().toLowerCase().endsWith('.pdf') 
                        ? Icons.picture_as_pdf 
                        : Icons.description, 
                    size: 80, 
                    color: Colors.blue[700]
                  ),
                  const SizedBox(height: 24),
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchCVUrl(fileUrl),
                    child: Text(
                      'Nhấn để mở file',
                      style: TextStyle(
                        color: Colors.blue[700], 
                        decoration: TextDecoration.underline,
                        fontStyle: FontStyle.italic
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _launchCVUrl(fileUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Mở tài liệu'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCVUrl(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có đường dẫn file')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to platform default
        if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
           throw 'Could not launch $url';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở file: $e')),
        );
      }
      debugPrint('Error launching URL: $e');
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
              color: Colors.black.withValues(alpha: 0.1),
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
