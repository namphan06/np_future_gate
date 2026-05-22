import 'package:flutter/material.dart';
import 'package:np_future_gate/core/repositories/evaluation_repository.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolViewEvaluationsScreen extends StatefulWidget {
  const SchoolViewEvaluationsScreen({super.key});

  @override
  State<SchoolViewEvaluationsScreen> createState() => _SchoolViewEvaluationsScreenState();
}

class _SchoolViewEvaluationsScreenState extends State<SchoolViewEvaluationsScreen> {
  late final EvaluationRepository _repository;
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = EvaluationRepository(Supabase.instance.client);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final records = await _repository.getStudentWorkProgressForSchool(userId);
      setState(() {
        _allRecords = records;
        _filterData();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _filterData() {
    if (_searchQuery.isEmpty) {
      _filteredRecords = List.from(_allRecords);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredRecords = _allRecords.where((record) {
        final student = record['student'] ?? {};
        final company = record['company'] ?? {};
        
        final studentName = (student['full_name'] ?? '').toString().toLowerCase();
        final studentEmail = (student['email'] ?? '').toString().toLowerCase();
        final companyName = (company['full_name'] ?? '').toString().toLowerCase();
        final companyEmail = (company['email'] ?? '').toString().toLowerCase();

        return studentName.contains(query) ||
            studentEmail.contains(query) ||
            companyName.contains(query) ||
            companyEmail.contains(query);
      }).toList();
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByCompany(List<Map<String, dynamic>> records) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var record in records) {
      final company = record['company'];
      final companyName = company != null ? company['full_name'] : 'Công ty không xác định';
      if (!grouped.containsKey(companyName)) {
        grouped[companyName] = [];
      }
      grouped[companyName]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupByCompany(_filteredRecords);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Đánh giá từ Doanh nghiệp'),
            floating: true,
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SpeechTextField(
                  controller: _searchController,
                  hint: 'Tìm sinh viên, doanh nghiệp...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterData();
                    });
                  },
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredRecords.isEmpty)
             SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty 
                        ? 'Chưa có dữ liệu đánh giá.' 
                        : 'Không tìm thấy kết quả.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final companyName = groupedData.keys.elementAt(index);
                  final records = groupedData[companyName]!;

                  return _buildCompanyGroup(companyName, records);
                },
                childCount: groupedData.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyGroup(String companyName, List<Map<String, dynamic>> records) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${records.length} SV',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) => _buildStudentItem(records[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(Map<String, dynamic> record) {
    final student = record['student'] ?? {};
    final evaluations = (record['evaluations'] as List?) ?? [];
    final hasEvaluation = evaluations.isNotEmpty;

    return InkWell(
      onTap: () => _showDetailSheet(record),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: student['avatar_url'] != null
                  ? NetworkImage(student['avatar_url'])
                  : null,
              child: student['avatar_url'] == null
                  ? Text((student['full_name'] ?? 'U')[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['full_name'] ?? 'Không tên',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                   if (record['position'] != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 4),
                       child: Text(
                         record['position'],
                         style: TextStyle(color: Colors.grey[600], fontSize: 13),
                       ),
                     ),
                ],
              ),
            ),
            if (hasEvaluation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Đã đánh giá',
                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            else
              const Text(
                'Chưa đánh giá',
                style: TextStyle(color: Colors.orange, fontSize: 11),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentEvaluationDetailSheet(record: record),
    );
  }
}

class StudentEvaluationDetailSheet extends StatelessWidget {

  const StudentEvaluationDetailSheet({super.key, required this.record});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final student = record['student'] ?? {};
    final company = record['company'] ?? {};
    final evaluations = List<Map<String, dynamic>>.from(record['evaluations'] ?? []);
    final roadmap = List<Map<String, dynamic>>.from(record['work_roadmap'] ?? []);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiết Đánh giá',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student['full_name']} @ ${company['full_name']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Info Cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        'Vị trí', 
                        record['position'] ?? 'N/A', 
                        Icons.work_outline
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        'Thời gian', 
                        record['work_duration'] ?? 'N/A', 
                        Icons.access_time
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs content (using DefaultTabController for simplicity in read-only view)
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: [
                          Tab(text: 'Kết quả đánh giá'),
                          Tab(text: 'Lộ trình thực tập'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildEvaluationView(evaluations),
                            _buildRoadmapView(roadmap),
                          ],
                        ),
                      ),
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

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationView(List<Map<String, dynamic>> evaluations) {
    if (evaluations.isEmpty) {
      return Center(
        child: Text('Chưa có đánh giá nào.', style: TextStyle(color: Colors.grey[500])),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: evaluations.length,
      itemBuilder: (context, index) {
        final item = evaluations[index];
        final score = (item['score'] as num).toDouble();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['criteria'] ?? 'Tiêu chí',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$score/10',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(score),
                      ),
                    ),
                  ),
                ],
              ),
              if (item['comment'] != null && item['comment'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['comment'],
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoadmapView(List<Map<String, dynamic>> roadmap) {
    if (roadmap.isEmpty) {
      return Center(
        child: Text('Chưa có lộ trình.', style: TextStyle(color: Colors.grey[500])),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roadmap.length,
      itemBuilder: (context, index) {
        final item = roadmap[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle_outline, size: 20, color: Colors.blue.shade300),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['task'] ?? 'Nhiệm vụ',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _tag(item['result'] ?? 'Pending', Colors.grey),
                        const SizedBox(width: 8),
                        if (item['deadline'] != null)
                          Text(
                            'Hạn: ${item['deadline']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tag(String text, Color color) {
    Color bg = color;
    Color fg = Colors.white;
    
    if (text == 'Đã hoàn thành') {
      bg = Colors.green.withValues(alpha: 0.1);
      fg = Colors.green;
    } else if (text == 'Đang thực hiện') {
      bg = Colors.blue.withValues(alpha: 0.1);
      fg = Colors.blue;
    } else {
       bg = Colors.grey.withValues(alpha: 0.1);
       fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.blue;
    return Colors.orange;
  }
}
