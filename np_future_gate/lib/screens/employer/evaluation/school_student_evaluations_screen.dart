import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/repositories/evaluation_repository.dart';
import '../../../widgets/speech_text_field.dart';

class SchoolStudentEvaluationsScreen extends StatefulWidget {
  const SchoolStudentEvaluationsScreen({super.key});

  @override
  State<SchoolStudentEvaluationsScreen> createState() => _SchoolStudentEvaluationsScreenState();
}

class _SchoolStudentEvaluationsScreenState extends State<SchoolStudentEvaluationsScreen> {
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

      final records = await _repository.getStudentWorkProgressForCompany(userId);
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
        final school = record['school'] ?? {};
        
        final studentName = (student['full_name'] ?? '').toString().toLowerCase();
        final studentEmail = (student['email'] ?? '').toString().toLowerCase();
        final schoolName = (school['full_name'] ?? '').toString().toLowerCase();
        final schoolEmail = (school['email'] ?? '').toString().toLowerCase();

        return studentName.contains(query) ||
            studentEmail.contains(query) ||
            schoolName.contains(query) ||
            schoolEmail.contains(query);
      }).toList();
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupBySchool(List<Map<String, dynamic>> records) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var record in records) {
      final school = record['school'];
      final schoolName = school != null ? school['full_name'] : 'Không xác định';
      if (!grouped.containsKey(schoolName)) {
        grouped[schoolName] = [];
      }
      grouped[schoolName]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupBySchool(_filteredRecords);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Đánh giá sinh viên thực tập'),
            floating: true,
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SpeechTextField(
                  controller: _searchController,
                  hint: 'Tìm kiếm theo tên, email, trường...',
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
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty 
                        ? 'Chưa có sinh viên nào.' 
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
                  final schoolName = groupedData.keys.elementAt(index);
                  final students = groupedData[schoolName]!;

                  return _buildSchoolGroup(schoolName, students);
                },
                childCount: groupedData.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSchoolGroup(String schoolName, List<Map<String, dynamic>> students) {
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
                const Icon(Icons.school, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schoolName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${students.length} SV',
                    style: const TextStyle(
                      color: Colors.indigo,
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
            itemCount: students.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) => _buildStudentItem(students[index]),
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
      onTap: () => _showEvaluationForm(record),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: student['avatar_url'] != null
                  ? NetworkImage(student['avatar_url'])
                  : null,
              child: student['avatar_url'] == null
                  ? Text((student['full_name'] ?? 'U')[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['full_name'] ?? 'Chưa cập nhật tên',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student['email'] ?? 'No email',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  if (record['position'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record['position'],
                      style: const TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasEvaluation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Đã đánh giá',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Chưa đánh giá',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                   const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
           
          ],
        ),
      ),
    );
  }

  void _showEvaluationForm(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentEvaluationSheet(
        record: record,
        onSave: (data) async {
          await _repository.updateStudentProgress(
            record['id'], 
            evaluations: data['evaluations'],
            workRoadmap: data['work_roadmap'],
            evaluatorName: data['evaluator_name'],
            workDuration: data['work_duration'],
          );
          _fetchData(); // Refresh list
        },
      ),
    );
  }
}

class StudentEvaluationSheet extends StatefulWidget {
  final Map<String, dynamic> record;
  final Function(Map<String, dynamic>) onSave;

  const StudentEvaluationSheet({
    super.key,
    required this.record,
    required this.onSave,
  });

  @override
  State<StudentEvaluationSheet> createState() => _StudentEvaluationSheetState();
}

class _StudentEvaluationSheetState extends State<StudentEvaluationSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> _evaluations;
  late List<Map<String, dynamic>> _workRoadmap;
  final TextEditingController _evaluatorController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  bool _isSaving = false;

  final List<String> _defaultCriteria = [
    'Thái độ làm việc',
    'Kỹ năng chuyên môn',
    'Khả năng làm việc nhóm',
    'Tuân thủ kỷ luật',
    'Tiến độ công việc'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _evaluatorController.text = widget.record['evaluator_name'] ?? '';
    _durationController.text = widget.record['work_duration'] ?? '';

    final rawEvaluations = widget.record['evaluations'] as List?;
    if (rawEvaluations != null && rawEvaluations.isNotEmpty) {
      _evaluations = List<Map<String, dynamic>>.from(rawEvaluations);
    } else {
      _evaluations = _defaultCriteria.map<Map<String, dynamic>>((c) => {
        'criteria': c,
        'score': 0,
        'comment': ''
      }).toList();
    }

    final rawRoadmap = widget.record['work_roadmap'] as List?;
    if (rawRoadmap != null && rawRoadmap.isNotEmpty) {
      _workRoadmap = List<Map<String, dynamic>>.from(rawRoadmap);
    } else {
      _workRoadmap = [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _evaluatorController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addCriteria() {
    setState(() {
      _evaluations.add(<String, dynamic>{
        'criteria': '',
        'score': 0,
        'comment': ''
      });
    });
  }

  void _removeCriteria(int index) {
    setState(() {
      _evaluations.removeAt(index);
    });
  }

  void _addTask() {
    setState(() {
      _workRoadmap.add(<String, dynamic>{
        'task': '',
        'result': 'Đang thực hiện',
        'deadline': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
    });
  }

  void _removeTask(int index) {
    setState(() {
      _workRoadmap.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.record['student'] ?? {};
    final school = widget.record['school'] ?? {};
    final position = widget.record['position'] ?? 'Chưa cập nhật vị trí';
    
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
                            'Đánh giá & Lộ trình',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student['full_name']} - ${school['full_name']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
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

               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // General Info Form
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: position,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Vị trí công việc',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Thời gian làm việc',
                              border: OutlineInputBorder(),
                              hintText: 'VD: 3 tháng',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _evaluatorController,
                      decoration: const InputDecoration(
                        labelText: 'Người đánh giá (Mentor/Leader)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ],
                ),
              ),

              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Lộ trình làm việc'),
                  Tab(text: 'Đánh giá kết quả'),
                ],
              ),
              
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoadmapTab(controller),
                    _buildEvaluationTab(controller),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: _isSaving 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Lưu thông tin', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor(dynamic score) {
    final s = (score as num).toDouble();
    if (s >= 8) return Colors.green;
    if (s >= 5) return Colors.blue;
    return Colors.orange;
  }

  Widget _buildRoadmapTab(ScrollController controller) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: _workRoadmap.length + 1,
      itemBuilder: (context, index) {
        if (index == _workRoadmap.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: OutlinedButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add),
                label: const Text('Thêm đầu việc mới'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          );
        }

        final item = _workRoadmap[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.assignment_outlined, color: Colors.orange.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: item['task'],
                      decoration: const InputDecoration(
                        hintText: 'Tên đầu việc / Nhiệm vụ',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 2,
                      minLines: 1,
                      onChanged: (v) => item['task'] = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _removeTask(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close, color: Colors.red.shade300, size: 20),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ['Đang thực hiện', 'Đã hoàn thành', 'Chưa hoàn thành', 'Hủy bỏ'].contains(item['result']) 
                              ? item['result'] 
                              : 'Đang thực hiện',
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          items: ['Đang thực hiện', 'Đã hoàn thành', 'Chưa hoàn thành', 'Hủy bỏ']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => item['result'] = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(item['deadline']) ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            item['deadline'] = DateFormat('yyyy-MM-dd').format(date);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              item['deadline'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvaluationTab(ScrollController controller) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: _evaluations.length + 1,
      itemBuilder: (context, index) {
        if (index == _evaluations.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: OutlinedButton.icon(
                onPressed: _addCriteria,
                icon: const Icon(Icons.add),
                label: const Text('Thêm tiêu chí đánh giá'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          );
        }

        final item = _evaluations[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.star_outline, color: Colors.blue.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: item['criteria'],
                      decoration: InputDecoration(
                        hintText: 'Nhập tiêu chí đánh giá',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87
                      ),
                      onChanged: (v) => item['criteria'] = v,
                    ),
                  ),
                  InkWell(
                    onTap: () => _removeCriteria(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Score Section
              Row(
                children: [
                  const Text(
                    'Điểm số:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(item['score']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item['score']}/10',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(item['score']),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getScoreColor(item['score']),
                  inactiveTrackColor: Colors.grey.shade100,
                  trackShape: const RoundedRectSliderTrackShape(),
                  trackHeight: 4.0,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0, elevation: 2),
                  overlayColor: _getScoreColor(item['score']).withOpacity(0.2),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                ),
                child: Slider(
                  value: (item['score'] as num).toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (v) {
                    setState(() {
                      item['score'] = v.round();
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),
              
              // Comment Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextFormField(
                  initialValue: item['comment'],
                  decoration: const InputDecoration(
                    hintText: 'Nhận xét chi tiết...',
                    border: InputBorder.none,
                    icon: Icon(Icons.edit_note, size: 20, color: Colors.grey),
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  minLines: 1,
                  onChanged: (v) => item['comment'] = v,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final data = {
        'evaluations': _evaluations,
        'work_roadmap': _workRoadmap,
        'evaluator_name': _evaluatorController.text,
        'work_duration': _durationController.text,
      };
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
