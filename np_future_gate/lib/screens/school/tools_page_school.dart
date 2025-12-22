import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import 'jobs/school_jobs_screen.dart';
import 'jobs/create_school_job_screen.dart';
import 'partnership/partnership_requests_screen.dart';
import 'partnership/companies_list_screen.dart';

class ToolsPageSchool extends StatelessWidget {
  const ToolsPageSchool({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Công cụ',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildToolCard(
                      context,
                      title: 'Quản lý tin',
                      subtitle: 'Tất cả tin tuyển dụng',
                      icon: Icons.work_outline,
                      gradient: LinearGradient(
                        colors: [AppMainColors.primary, AppMainColors.primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SchoolJobsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      context,
                      title: 'Tạo tin thường',
                      subtitle: 'Đăng tin trực tiếp',
                      icon: Icons.add_circle_outline,
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateSchoolJobScreen(isPartnership: false),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      context,
                      title: 'Tin liên kết',
                      subtitle: 'Kết nối doanh nghiệp',
                      icon: Icons.handshake_outlined,
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateSchoolJobScreen(isPartnership: true),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      context,
                      title: 'Yêu cầu liên kết',
                      subtitle: 'Theo dõi trạng thái',
                      icon: Icons.pending_actions_outlined,
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFF9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PartnershipRequestsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      context,
                      title: 'Danh sách DN',
                      subtitle: 'Tìm đối tác',
                      icon: Icons.business_outlined,
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Color(0xFF2196F3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CompaniesListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      context,
                      title: 'Thống kê',
                      subtitle: 'Báo cáo & phân tích',
                      icon: Icons.analytics_outlined,
                      gradient: const LinearGradient(
                        colors: [Colors.teal, Color(0xFF009688)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chức năng đang phát triển')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
