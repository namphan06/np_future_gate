import 'package:flutter/material.dart';
import 'package:np_future_gate/screens/cv/cv_creation_screen.dart';
import 'package:np_future_gate/screens/cv/cv_management_screen.dart';
import '../../core/theme/app_main_colors.dart';
import 'applied_jobs_screen.dart';

class ToolsPageCandidate extends StatelessWidget {
  const ToolsPageCandidate({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppMainColors.backgroundLightStart,
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Công cụ & Tiện ích',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppMainColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quản lý công việc và phát triển sự nghiệp',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Phần 1: CÔNG VIỆC
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.work, color: Colors.blue.shade700, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Quản lý công việc',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Job management cards
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _buildToolCard(
                              context,
                              icon: Icons.send,
                              title: 'Đã ứng tuyển',
                              subtitle: 'Xem danh sách',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AppliedJobsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.bookmark,
                              title: 'Đã lưu',
                              subtitle: '8 việc',
                              color: Colors.orange,
                              onTap: () => _showComingSoon(context, 'Việc đã lưu'),
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.business,
                              title: 'Công ty theo dõi',
                              subtitle: '5 công ty',
                              color: Colors.teal,
                              onTap: () => _showComingSoon(context, 'Công ty theo dõi'),
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.notifications_active,
                              title: 'Việc từ công ty',
                              subtitle: '3 việc mới',
                              color: Colors.indigo,
                              onTap: () => _showComingSoon(context, 'Việc từ công ty theo dõi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Phần 2: QUẢN LÝ CV
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.description, color: Colors.green.shade700, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Quản lý CV',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // CV management - Featured card for "Tạo CV mới"
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: (){
                                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CVCreationScreen(),
  ),
);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tạo CV mới',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Tạo CV chuyên nghiệp trong vài phút',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Other CV options
                        Row(
                          children: [
                            Expanded(
                              child: _buildToolCard(
                                context,
                                icon: Icons.folder,
                                title: 'CV đã tạo',
                                subtitle: '3 CV',
                                color: Colors.blue,
                                onTap: () {
                                   Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CVManagementScreen(),
  ),);
                                  
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildToolCard(
                                context,
                                icon: Icons.help_outline,
                                title: 'Hướng dẫn',
                                subtitle: 'Mẹo viết CV',
                                color: Colors.amber,
                                onTap: () => _showComingSoon(context, 'Hướng dẫn tạo CV'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Phần 3: CÁC CÔNG CỤ
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.build, color: Colors.pink.shade700, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Công cụ hỗ trợ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Tools grid
                        _buildToolListItem(
                          context,
                          icon: Icons.psychology,
                          title: 'MBTI Test',
                          subtitle: 'Khám phá tính cách của bạn',
                          color: Colors.purple,
                          onTap: () => _showComingSoon(context, 'MBTI Test'),
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.lightbulb,
                          title: 'MI Test',
                          subtitle: 'Đánh giá đa trí tuệ',
                          color: Colors.orange,
                          onTap: () => _showComingSoon(context, 'MI Test'),
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.calculate,
                          title: 'Tính thuế TNCN',
                          subtitle: 'Tính thuế thu nhập cá nhân',
                          color: Colors.teal,
                          onTap: () => _showComingSoon(context, 'Tính thuế TNCN'),
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.attach_money,
                          title: 'Tính lương NET',
                          subtitle: 'Chuyển đổi lương NET/GROSS',
                          color: Colors.green,
                          onTap: () => _showComingSoon(context, 'Tính lương NET'),
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.school,
                          title: 'Khóa học',
                          subtitle: 'Khóa học kỹ năng & nghề nghiệp',
                          color: Colors.blue,
                          onTap: () => _showComingSoon(context, 'Khóa học'),
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.article,
                          title: 'Tin tức nghề nghiệp',
                          subtitle: 'Xu hướng & cơ hội việc làm',
                          color: Colors.indigo,
                          onTap: () => _showComingSoon(context, 'Tin tức'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Gradient overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.85),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.2, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
