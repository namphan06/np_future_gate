import 'package:flutter/material.dart';
import '../cv_template/cv_ui/cv1.dart';
import '../cv_template/cv_ui/cv2.dart';
import '../cv_template/cv_ui/cv3.dart';
import '../cv_input/cv1_input_screen.dart';
import '../cv_input/cv2_input_screen.dart';
import '../cv_input/cv3_input_screen.dart';
import '../cv_upload_edit_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
      return _buildUploadView(context, cvData);
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
    final type = cvData['type'];

    if (mcv == 'UPLOAD' || type == 'upload') {
       return CVUploadEditScreen(cvId: cvId, initialData: cvData);
    }
    
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





  static Widget _buildUploadView(BuildContext context, Map<String, dynamic> cvData) {
    // Extract inner data if present (when passing the full DB row)
    final innerData = cvData['data'] is Map ? cvData['data'] as Map<String, dynamic> : cvData;
    
    final fileUrl = innerData['file_url'] ?? cvData['file_url'] ?? '';
    final fileName = innerData['file_name'] ?? cvData['file_name'] ?? 'Tài liệu CV';
    
    // Check extension
    final lowerUrl = fileUrl.toString().toLowerCase();
    final isImage = lowerUrl.endsWith('.jpg') || 
                    lowerUrl.endsWith('.png') || 
                    lowerUrl.endsWith('.jpeg') ||
                    lowerUrl.endsWith('.webp');
    final isPdf = lowerUrl.endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        title: Text(cvData['title'] ?? 'Xem CV'),
        backgroundColor: Colors.blue[700],
        actions: [
            // Button to open externally if needed
            IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () async {
                    if (fileUrl.isNotEmpty) {
                        try {
                           final uri = Uri.parse(fileUrl);
                           await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                           // ignore or show toast
                        }
                    }
                },
                tooltip: 'Mở bằng ứng dụng ngoài',
            )
        ],
      ),
      body: Center(
        child: Builder(
            builder: (ctx) {
                if (fileUrl.isEmpty) {
                    return const Text('Không tìm thấy nội dung file.');
                }

                if (isImage) {
                    return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                        fileUrl,
                        loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            Text('Không thể tải ảnh'),
                            ],
                        ),
                        ),
                    );
                } else if (isPdf) {
                    return SfPdfViewer.network(
                        fileUrl,
                        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                           debugPrint('PDF Load Error: ${details.error}');
                           debugPrint('PDF Load Desc: ${details.description}');
                        },
                    );
                } else {
                    // Fallback for Word/Other docs
                    return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(
                            Icons.description, 
                            size: 80, 
                            color: Colors.blue[700]
                        ),
                        const SizedBox(height: 24),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                            fileName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                             'Không hỗ trợ xem trực tiếp định dạng này.\nVui lòng mở bằng ứng dụng bên ngoài.',
                             textAlign: TextAlign.center,
                             style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                            onPressed: () async {
                                final uri = Uri.parse(fileUrl);
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Mở file'),
                        ),
                        ],
                    );
                }
            },
        ),
      ),
    );
  }
}
