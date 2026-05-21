import 'package:flutter/material.dart';
import 'package:np_future_gate/screens/cv/cv_setting/cv_field_templates_screen.dart';
import 'package:np_future_gate/screens/cv/cv_setting/cv_general_templates_screen.dart';
import 'package:np_future_gate/screens/cv/cv_upload_screen.dart';

/// Main CV Creation Screen with 3 options:
/// 1. Use general CV templates
/// 2. Use field-specific CV templates
/// 3. Upload CV from device
class CVCreationScreen extends StatelessWidget {
  const CVCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Back Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                     GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withValues(alpha: 0.05),
                          //     blurRadius: 10,
                          //     offset: const Offset(0, 2),
                          //   ),
                          // ],
                        ),
                        child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.blue[600]),
                      ),
                    ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.blue[700]!, Colors.blue[500]!],
                              ).createShader(bounds),
                              child: const Text(
                                'Tạo CV Của Bạn',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chọn cách tạo CV phù hợp nhất',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Option 1: General Templates
                _buildEnhancedOptionCard(
                  context,
                  icon: Icons.description_outlined,
                  iconColor: Colors.blue,
                  title: 'Mẫu CV Chung',
                  subtitle: 'Các mẫu phổ biến phù hợp mọi ngành nghề',
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

                const SizedBox(height: 20),

                // Option 2: Field-specific Templates
                _buildEnhancedOptionCard(
                  context,
                  icon: Icons.work_outline,
                  iconColor: Colors.orange,
                  title: 'Mẫu CV Theo Lĩnh Vực',
                  subtitle: 'CV được thiết kế riêng cho từng ngành nghề',
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

                const SizedBox(height: 20),

                // Option 3: Upload CV
                _buildEnhancedOptionCard(
                  context,
                  icon: Icons.cloud_upload_outlined,
                  iconColor: Colors.green,
                  title: 'Tải CV Từ Thiết Bị',
                  subtitle: 'Tải lên CV có sẵn từ điện thoại hoặc máy tính',
                  features: [
                    'Hỗ trợ file PDF, DOC, DOCX',
                    'Giữ nguyên định dạng',
                    'Nhanh chóng và tiện lợi',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CVUploadScreen(),
                      ),
                    ).then((result) {
                      // Reload CV list if upload was successful
                      if (result == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    });
                  },
                ),

                const SizedBox(height: 40),

                // Help Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mẹo tạo CV hiệu quả',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chọn mẫu CV theo lĩnh vực sẽ giúp tăng 30% cơ hội được nhà tuyển dụng chú ý.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Icon and Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 28),
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
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Features List
                  ...features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final feature = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < features.length - 1 ? 12 : 0,
                        left: 42,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
