import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/chat_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/candidate/screens/applied_jobs_screen.dart';
import 'package:np_future_gate/features/candidate/screens/companies_list_screen.dart';
import 'package:np_future_gate/features/candidate/screens/internship_progress_screen.dart';
import 'package:np_future_gate/features/candidate/screens/interview_schedule_candidate_screen.dart';
import 'package:np_future_gate/features/candidate/screens/mbti_question_screen.dart';
import 'package:np_future_gate/features/candidate/screens/mi_question_screen.dart';
import 'package:np_future_gate/features/candidate/screens/saved_jobs_screen.dart';
import 'package:np_future_gate/features/candidate/screens/school_jobs_screen.dart';
import 'package:np_future_gate/screens/career_news/career_news_screen.dart';
import 'package:np_future_gate/features/chat/screens/chat_detail_screen.dart';
import 'package:np_future_gate/features/chat/screens/chat_list_screen.dart';
import 'package:np_future_gate/screens/courses/courses_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_creation_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
                        const Text(
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
                              child: Icon(
                                Icons.work,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
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
                                    builder: (context) =>
                                        const AppliedJobsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.bookmark,
                              title: 'Đã lưu',
                              subtitle: 'Xem danh sách',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedJobsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.business,
                              title: 'Công ty theo dõi',
                              subtitle: 'Danh sách công ty',
                              color: Colors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CompaniesListScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.school,
                              title: 'Việc từ trường',
                              subtitle: 'Xem tin liên kết',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SchoolJobsForCandidateScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.event_note,
                              title: 'Lịch phỏng vấn',
                              subtitle: 'Xem lịch của tôi',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const InterviewScheduleCandidateScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildToolCard(
                              context,
                              icon: Icons.timeline,
                              title: 'Lộ trình thực tập',
                              subtitle: 'Xem tiến độ & Đánh giá',
                              color: Colors.indigo,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const InternshipProgressScreen(),
                                  ),
                                );
                              },
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
                              child: Icon(
                                Icons.description,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
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
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CVCreationScreen(),
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
                                        color: Colors.white.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.add_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 20,
                                    ),
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
                                      builder: (context) =>
                                          const CVManagementScreen(),
                                    ),
                                  );
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
                                onTap: () => _showComingSoon(
                                  context,
                                  'Hướng dẫn tạo CV',
                                ),
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
                              child: Icon(
                                Icons.build,
                                color: Colors.pink.shade700,
                                size: 20,
                              ),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MBTIQuestionScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.lightbulb,
                          title: 'MI Test',
                          subtitle: 'Đánh giá đa trí tuệ',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MIQuestionScreen(),
                              ),
                            );
                          },
                        ),
                        // const SizedBox(height: 12),
                        // _buildToolListItem(
                        //   context,
                        //   icon: Icons.calculate,
                        //   title: 'Tính thuế TNCN',
                        //   subtitle: 'Tính thuế thu nhập cá nhân',
                        //   color: Colors.teal,
                        //   onTap: () => _showComingSoon(context, 'Tính thuế TNCN'),
                        // ),
                        // const SizedBox(height: 12),
                        // _buildToolListItem(
                        //   context,
                        //   icon: Icons.attach_money,
                        //   title: 'Tính lương NET',
                        //   subtitle: 'Chuyển đổi lương NET/GROSS',
                        //   color: Colors.green,
                        //   onTap: () => _showComingSoon(context, 'Tính lương NET'),
                        // ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.school,
                          title: 'Khóa học',
                          subtitle: 'Khóa học kỹ năng & nghề nghiệp',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CoursesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.article,
                          title: 'Tin tức nghề nghiệp',
                          subtitle: 'Xu hướng & cơ hội việc làm',
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CareerNewsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.support_agent_outlined,
                          title: 'Hỗ trợ khách hàng',
                          subtitle: 'Chat với đội ngũ Admin',
                          color: Colors.purple,
                          onTap: () => _openChatWithAdmin(context),
                        ),
                        const SizedBox(height: 12),
                        _buildToolListItem(
                          context,
                          icon: Icons.chat_bubble_outline,
                          title: 'Tin nhắn',
                          subtitle: 'Chat với nhà tuyển dụng',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatListScreen(),
                              ),
                            );
                          },
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
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.85),
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
            color: Colors.black.withValues(alpha: 0.06),
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
                    color: color.withValues(alpha: 0.1),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
            color: Colors.black.withValues(alpha: 0.06),
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
                    color: color.withValues(alpha: 0.1),
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
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
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

  Future<void> _openChatWithAdmin(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Find admin user from profiles
      final adminResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();

      if (adminResponse == null) {
        if (context.mounted) Navigator.pop(context); // Close loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy Admin. Vui lòng thử lại sau.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final adminId = adminResponse['id'] as String;
      final adminName = adminResponse['full_name'] as String? ?? 'Admin';
      final adminAvatar = adminResponse['avatar_url'] as String? ?? '';

      // Create or get existing conversation with admin
      final chatService = ChatService();
      final conversation = await chatService.getOrCreateConversation(
        otherUserId: adminId,
        otherUserType: 'admin',
      );

      if (context.mounted) Navigator.pop(context); // Close loading

      if (conversation != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversation: conversation,
              otherUserName: adminName,
              otherUserAvatar: adminAvatar,
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo cuộc trò chuyện. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
