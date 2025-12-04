import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'cv_setting/cv_general_templates_screen.dart';
import 'cv_setting/cv_field_templates_screen.dart';

/// Main CV Creation Screen with 3 options:
/// 1. Use general CV templates
/// 2. Use field-specific CV templates
/// 3. Upload CV from device
class CVCreationScreen extends StatelessWidget {
  const CVCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo CV'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Chọn cách tạo CV của bạn',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có thể chọn mẫu có sẵn hoặc tải lên CV của riêng bạn',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Option 1: General Templates
            _buildOptionCard(
              context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: 'Mẫu CV Chung',
              subtitle: 'Chọn từ các mẫu CV phổ biến, phù hợp với mọi ngành nghề',
              features: [
                'Nhiều mẫu thiết kế đa dạng',
                'Dễ dàng chỉnh sửa',
                'Phù hợp mọi vị trí',
              ],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CVGeneralTemplatesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Option 2: Field-specific Templates
            _buildOptionCard(
              context,
              icon: Icons.work,
              iconColor: Colors.orange,
              title: 'Mẫu CV Theo Lĩnh Vực',
              subtitle: 'Chọn mẫu CV được thiết kế riêng cho từng ngành nghề cụ thể',
              features: [
                'Tối ưu cho từng lĩnh vực',
                'Nội dung chuyên biệt',
                'Tăng cơ hội được tuyển dụng',
              ],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CVFieldTemplatesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Option 3: Upload CV
            _buildOptionCard(
              context,
              icon: Icons.upload_file,
              iconColor: Colors.green,
              title: 'Tải CV Từ Thiết Bị',
              subtitle: 'Tải lên CV có sẵn từ điện thoại hoặc máy tính của bạn',
              features: [
                'Hỗ trợ file PDF, DOC, DOCX',
                'Giữ nguyên định dạng',
                'Nhanh chóng và tiện lợi',
              ],
              onTap: () async {
                await _handleUploadCV(context);
              },
            ),

            const SizedBox(height: 32),

            // Help Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mẹo tạo CV hiệu quả',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chọn mẫu CV phù hợp với ngành nghề của bạn sẽ giúp tăng 30% cơ hội được nhà tuyển dụng chú ý.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUploadCV(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;
        
        if (!context.mounted) return;

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('Tải lên thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'File: ${file.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kích thước: ${(file.size / 1024).toStringAsFixed(2)} KB',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CV của bạn đã được tải lên thành công. Chúng tôi sẽ xử lý và hiển thị CV của bạn trong giây lát.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to CV preview/edit screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng đang phát triển...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Xem CV'),
              ),
            ],
          ),
        );
      } else {
        // User canceled
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy tải lên'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 64),
          title: const Text('Lỗi tải lên'),
          content: Text(
            'Không thể tải file lên. Vui lòng thử lại.\n\nChi tiết: ${e.toString()}',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleUploadCV(context);
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
  }
}
