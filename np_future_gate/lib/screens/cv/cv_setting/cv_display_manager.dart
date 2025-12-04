import 'package:flutter/material.dart';
import '../cv_template/cv_ui/cv1.dart';
import '../cv_template/cv_ui/cv2.dart';
import '../cv_template/cv_ui/cv3.dart';
import '../cv_input/cv1_input_screen.dart';
import '../cv_input/cv2_input_screen.dart';
import '../cv_input/cv3_input_screen.dart';

/// CV Display Manager
/// Quản lý việc hiển thị CV (View/Edit) dựa trên template code (mcv) và loại CV.
class CVDisplayManager {
  
  /// Trả về Widget hiển thị CV (Read-only / Preview)
  /// [cvData] là dữ liệu đầy đủ của CV
  static Widget buildViewWidget(BuildContext context, Map<String, dynamic> cvData) {
    final mcv = cvData['mcv']; // mcv can be null
    final type = cvData['type'] ?? 'general';

    // Nếu là CV upload (PDF/Image), có thể cần widget hiển thị riêng
    if (type == 'upload') {
      return _buildUploadView(cvData);
    }

    // Dựa vào MCV để chọn template hiển thị
    switch (mcv) {
      case 'CV001':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv1(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV002':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv2(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV003':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv3(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      default:
        // Fallback to CV1 if unknown or null (though null usually implies upload or error)
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv1(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
    }
  }

  static Widget _buildScaffold({required String title, required Widget child}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            color: Colors.white,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Trả về Widget chỉnh sửa CV (Edit Form)
  static Widget buildEditWidget(String cvId, Map<String, dynamic> cvData) {
    final mcv = cvData['mcv'];
    
    switch (mcv) {
      case 'CV001':
        return CV1InputScreen(cvId: cvId);
      case 'CV002':
        return CV2InputScreen(cvId: cvId);
      case 'CV003':
        return CV3InputScreen(cvId: cvId);
      default:
        return CV1InputScreen(cvId: cvId);
    }
  }

  static Widget _buildUploadView(Map<String, dynamic> cvData) {
    final fileUrl = cvData['file_url'] ?? '';
    final isImage = fileUrl.toLowerCase().endsWith('.jpg') || 
                    fileUrl.toLowerCase().endsWith('.png') || 
                    fileUrl.toLowerCase().endsWith('.jpeg') ||
                    fileUrl.toLowerCase().endsWith('.webp');

    return Scaffold(
      appBar: AppBar(title: const Text('Xem CV Upload')),
      body: Center(
        child: isImage && fileUrl.isNotEmpty
            ? Image.network(
                fileUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    Text('Không thể tải ảnh'),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text('File: $fileUrl'),
                  const SizedBox(height: 16),
                  if (fileUrl.isEmpty) const Text('Không có đường dẫn file'),
                ],
              ),
      ),
    );
  }
}
