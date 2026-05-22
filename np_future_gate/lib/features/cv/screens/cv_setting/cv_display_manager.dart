import 'package:flutter/material.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv10_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv11_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv12_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv13_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv14_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv15_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv16_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv17_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv18_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv19_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv1_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv2_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv3_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv4_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv5_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv6_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv7_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv8_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv9_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv1.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv10.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv11.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv12.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv13.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv14.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv15.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv16.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv17.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv18.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv19.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv2.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv3.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv4.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv5.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv6.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv7.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv8.dart';
import 'package:np_future_gate/features/cv/screens/cv_template/cv_ui/cv9.dart';
import 'package:np_future_gate/features/cv/screens/cv_upload_edit_screen.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

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
      case 'CV004':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv4(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV005':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv5(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV006':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv6(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV007':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv7(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV008':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv8(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV009':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv9(
            data: cvData['data'] ?? cvData,
            onSectionTap: null,
          ),
        );
      case 'CV010':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv10(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV011':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv11(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV012':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv12(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV013':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv13(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV014':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv14(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV015':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv15(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV016':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv16(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV017':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv17(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV018':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv18(data: cvData['data'] ?? cvData, onSectionTap: null),
        );
      case 'CV019':
        return _buildScaffold(
          title: cvData['title'] ?? 'Xem CV',
          child: Cv19(data: cvData['data'] ?? cvData, onSectionTap: null),
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
      case 'CV004':
        return CV4InputScreen(cvId: cvId);
      case 'CV005':
        return CV5InputScreen(cvId: cvId);
      case 'CV006':
        return CV6InputScreen(cvId: cvId);
      case 'CV007':
        return CV7InputScreen(cvId: cvId);
      case 'CV008':
        return CV8InputScreen(cvId: cvId);
      case 'CV009':
        return CV9InputScreen(cvId: cvId);
      case 'CV010':
        return CV10InputScreen(cvId: cvId);
      case 'CV011':
        return CV11InputScreen(cvId: cvId);
      case 'CV012':
        return CV12InputScreen(cvId: cvId);
      case 'CV013':
        return CV13InputScreen(cvId: cvId);
      case 'CV014':
        return CV14InputScreen(cvId: cvId);
      case 'CV015':
        return CV15InputScreen(cvId: cvId);
      case 'CV016':
        return CV16InputScreen(cvId: cvId);
      case 'CV017':
        return CV17InputScreen(cvId: cvId);
      case 'CV018':
        return CV18InputScreen(cvId: cvId);
      case 'CV019':
        return CV19InputScreen(cvId: cvId);
      default:
        return CV1InputScreen(cvId: cvId);
    }
  }





  static Widget _buildUploadView(BuildContext context, Map<String, dynamic> cvData) {
    // Extract inner data if present (when passing the full DB row)
    final innerData = cvData['data'] is Map ? cvData['data'] as Map<String, dynamic> : cvData;
    
    final fileUrl = innerData['file_url'] ?? cvData['file_url'] ?? '';
    final fileName = innerData['file_name'] ?? cvData['file_name'] ?? 'Tài liệu CV';
    final cvTitle = cvData['title'] ?? 'Xem CV';
    
    // Check extension
    final lowerUrl = fileUrl.toString().toLowerCase();
    final isImage = lowerUrl.endsWith('.jpg') || 
                    lowerUrl.endsWith('.png') || 
                    lowerUrl.endsWith('.jpeg') ||
                    lowerUrl.endsWith('.webp');
    final isPdf = lowerUrl.endsWith('.pdf');

    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F7FA), // Light grey-blue background instead of gradient
        child: Stack(
          children: [
            // Main Content with Card/Border
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 72, // Space for floating bar
                  left: 12,
                  right: 12,
                  bottom: 12,
                ),
                child: Builder(
                  builder: (ctx) {
                    if (fileUrl.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Không tìm thấy nội dung file',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Content card wrapper
                    Widget contentWidget;

                    if (isImage) {
                      contentWidget = Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              fileUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.white,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Đang tải ảnh...',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.white,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Không thể hiển thị ảnh',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if (isPdf) {
                      // PDF Viewer optimized for multi-page documents
                      contentWidget = Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SfPdfViewer.network(
                            fileUrl,
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                            enableDoubleTapZooming: true,
                            pageLayoutMode: PdfPageLayoutMode.continuous, // Enable multi-page scrolling
                            scrollDirection: PdfScrollDirection.vertical, // Vertical scroll for pages
                            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                              debugPrint('PDF Load Error: ${details.error}');
                              debugPrint('PDF Load Description: ${details.description}');
                            },
                          ),
                        ),
                      );
                    } else {
                      // Fallback for Word/Other docs
                      contentWidget = Center(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.description,
                                  size: 64,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Định dạng này không hỗ trợ xem trực tiếp',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final uri = Uri.parse(fileUrl);
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Không thể mở file: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Mở bằng ứng dụng khác'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return contentWidget;
                  },
                ),
              ),
            ),
            
            // Floating Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF5F7FA),
                      const Color(0xFFF5F7FA).withValues(alpha: 0.9),
                      const Color(0xFFF5F7FA).withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.arrow_back, size: 24, color: Colors.blue[700]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          cvTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // More Options Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton(
                        icon: Icon(Icons.more_vert, size: 24, color: Colors.blue[700]),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        offset: const Offset(0, 50),
                        elevation: 8,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, size: 20, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                const Text('Mở bằng ứng dụng khác'),
                              ],
                            ),
                            onTap: () async {
                              if (fileUrl.isNotEmpty) {
                                try {
                                  final uri = Uri.parse(fileUrl);
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  // Ignore
                                }
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                const Text('Thông tin file'),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(Duration.zero, () {
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Thông tin file'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.insert_drive_file, size: 20, color: Colors.blue[700]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                fileName,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Đường dẫn:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        SelectableText(
                                          fileUrl,
                                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Đóng'),
                                      ),
                                    ],
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
