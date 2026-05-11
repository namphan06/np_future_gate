import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/repositories/evaluation_repository.dart';
import '../../core/services/supabase_service.dart';
import 'package:intl/intl.dart';

class InternshipProgressScreen extends StatefulWidget {
  const InternshipProgressScreen({super.key});

  @override
  State<InternshipProgressScreen> createState() => _InternshipProgressScreenState();
}

class _InternshipProgressScreenState extends State<InternshipProgressScreen> with SingleTickerProviderStateMixin {
  late final EvaluationRepository _evaluationRepo;
  final _supabaseService = SupabaseService.instance;
  
  Map<String, dynamic>? _progressData;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _evaluationRepo = EvaluationRepository(Supabase.instance.client);
    _tabController = TabController(length: 2, vsync: this);
    _loadProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = _supabaseService.currentUserId;
      if (userId != null) {
        final data = await _evaluationRepo.getStudentWorkProgressForStudent(userId);
        if (mounted) {
          setState(() => _progressData = data);
        }
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải lộ trình: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lộ trình thực tập',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppMainColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppMainColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Lộ trình công việc'),
            Tab(text: 'Đánh giá'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progressData == null
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoadmapTab(),
                    _buildEvaluationsTab(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có lộ trình thực tập',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Lộ trình và đánh giá sẽ xuất hiện khi nhà trường hoặc doanh nghiệp cập nhật thông tin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapTab() {
    final roadmap = List<Map<String, dynamic>>.from(_progressData?['work_roadmap'] ?? []);
    
    if (roadmap.isEmpty) {
      return const Center(child: Text('Chưa có thông tin lộ trình công việc'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: roadmap.length,
      itemBuilder: (context, index) {
        final step = roadmap[index];
        final isLast = index == roadmap.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppMainColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppMainColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppMainColors.primary.withOpacity(0.2),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['task'] ?? 'Giai đoạn ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['result'] ?? 'Chưa có mô tả chi tiết cho giai đoạn này.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      if (step['deadline'] != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: AppMainColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Hạn chót: ${step['deadline']}',
                              style: TextStyle(color: AppMainColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvaluationsTab() {
    final evaluations = List<Map<String, dynamic>>.from(_progressData?['evaluations'] ?? []);
    final company = _progressData?['company'];
    final school = _progressData?['school'];
    final evaluatorName = _progressData?['evaluator_name'];
    final workDuration = _progressData?['work_duration'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppMainColors.primary, AppMainColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppMainColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_center, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company?['full_name'] ?? 'Đang thực tập',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            'Đơn vị tiếp nhận',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(Icons.person, 'Người đánh giá', evaluatorName ?? 'Chưa cập nhật'),
                    _buildInfoItem(Icons.calendar_today, 'Thời gian', workDuration ?? 'Chưa xác định'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Chi tiết đánh giá',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (evaluations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Chưa có đánh giá chi tiết từ nhà tuyển dụng.',
                  style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...evaluations.map((e) => _buildEvaluationCard(e)).toList(),
            
          const SizedBox(height: 20),
          
          // School Info
          if (school != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: school['avatar_url'] != null ? NetworkImage(school['avatar_url']) : null,
                    child: school['avatar_url'] == null ? const Icon(Icons.school) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school['full_name'] ?? 'Trường đại học',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Cơ quan quản lý thực tập', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildEvaluationCard(Map<String, dynamic> eval) {
    final score = eval['score'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                eval['criteria'] ?? 'Tiêu chí đánh giá',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score/10',
                  style: TextStyle(color: _getScoreColor(score), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 10,
            backgroundColor: Colors.grey.shade100,
            color: _getScoreColor(score),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),
          Text(
            eval['comment'] ?? 'Chưa có nhận xét.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(num score) {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }
}
