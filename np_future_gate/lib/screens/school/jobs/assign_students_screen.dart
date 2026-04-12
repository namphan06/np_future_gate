import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/job_model.dart';
import '../../../core/theme/app_main_colors.dart';
import '../../../core/services/cv_supabase_service.dart';
import '../../cv/cv_setting/cv_display_manager.dart';

class AssignStudentsScreen extends StatefulWidget {
  final JobModel job;
  final List<String> assignedStudents;
  final bool isPartnershipJob;

  const AssignStudentsScreen({
    super.key,
    required this.job,
    required this.assignedStudents,
    required this.isPartnershipJob,
  });

  @override
  State<AssignStudentsScreen> createState() => _AssignStudentsScreenState();
}

class _AssignStudentsScreenState extends State<AssignStudentsScreen> {
  final CVSupabaseService _cvService = CVSupabaseService();
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  Map<String, List<Map<String, dynamic>>> _studentAssignedJobsMap = {};
  List<String> _selectedStudents = [];
  List<String> _originalAssignedStudents = []; // Track original assignments
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadJobMetadata(); // Load metadata first to get latest assigned students
    _loadStudents();
  }

  Future<void> _loadJobMetadata() async {
    try {
      final table = widget.isPartnershipJob
          ? 'school_partnership_jobs'
          : 'jobs';

      // Get current metadata from database
      final jobData = await Supabase.instance.client
          .from(table)
          .select('metadata')
          .eq('id', widget.job.id!)
          .single();

      final metadata = jobData['metadata'] as Map<String, dynamic>? ?? {};
      final assignedStudents =
          (metadata['assigned_students'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        _selectedStudents = List.from(assignedStudents);
        _originalAssignedStudents = List.from(assignedStudents);
      });

      await _loadAssignedJobsMap(currentJobAssignedStudents: assignedStudents);
    } catch (e) {
      // Fallback to widget data if error
      setState(() {
        _selectedStudents = List.from(widget.assignedStudents);
        _originalAssignedStudents = List.from(widget.assignedStudents);
      });
      print('Error loading job metadata: $e');

      await _loadAssignedJobsMap(
        currentJobAssignedStudents: widget.assignedStudents,
      );
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final schoolProfile = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', userId)
          .single();

      final schoolMetadata =
          schoolProfile['metadata'] as Map<String, dynamic>? ?? {};
      final schoolEmail = schoolMetadata['school_email'] as String?;

      if (schoolEmail == null || !schoolEmail.contains('@')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng thiết lập email trường trước'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final schoolDomain = '@${schoolEmail.split('@').last}';

      final studentsData = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, metadata, role, created_at')
          .ilike('email', '%$schoolDomain')
          .neq('id', userId)
          .order('full_name');

      setState(() {
        _students = studentsData;
        _filteredStudents = studentsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải sinh viên: $e')));
      }
    }
  }

  Future<void> _loadAssignedJobsMap({
    List<String>? currentJobAssignedStudents,
  }) async {
    try {
      final schoolId = Supabase.instance.client.auth.currentUser?.id;
      if (schoolId == null) return;

      final partnershipJobsData = await Supabase.instance.client
          .from('school_partnership_jobs')
          .select('id, metadata, created_at, deadline')
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);

      final regularJobsData = await Supabase.instance.client
          .from('jobs')
          .select('id, metadata, created_at, deadline')
          .eq('creator_id', schoolId)
          .order('created_at', ascending: false);

      final assignedJobsMap = <String, List<Map<String, dynamic>>>{};

      void addRowsToAssignedMap(
        List<dynamic> rows, {
        required String expireKey,
      }) {
        for (final row in rows) {
          final rowMap = Map<String, dynamic>.from(row as Map);
          final metadata = _parseMetadata(rowMap['metadata']);
          final assignedStudents = _extractAssignedStudentIds(metadata);
          if (assignedStudents.isEmpty) continue;

          final title =
              (metadata['title'] ?? rowMap['title'] ?? 'Tin không có tiêu đề')
                  .toString();
          final jobInfo = {
            'id': rowMap['id'].toString(),
            'title': title,
            'created_at': rowMap['created_at'],
            'expired_at': rowMap[expireKey],
          };

          for (final studentId in assignedStudents) {
            assignedJobsMap.putIfAbsent(studentId, () => []).add(jobInfo);
          }
        }
      }

      addRowsToAssignedMap(
        partnershipJobsData as List<dynamic>,
        expireKey: 'deadline',
      );
      addRowsToAssignedMap(
        regularJobsData as List<dynamic>,
        expireKey: 'deadline',
      );

      for (final entry in assignedJobsMap.entries) {
        final uniqueById = <String, Map<String, dynamic>>{};
        for (final item in entry.value) {
          final id = (item['id'] ?? '').toString();
          if (id.isEmpty) continue;
          uniqueById.putIfAbsent(id, () => item);
        }
        assignedJobsMap[entry.key] = uniqueById.values.toList();
      }

      final currentJobAssigned =
          (currentJobAssignedStudents ?? const <String>[])
              .map(_normalizeStudentId)
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
      final currentJobId = (widget.job.id ?? '').toString();
      if (currentJobId.isNotEmpty && currentJobAssigned.isNotEmpty) {
        final currentJobInfo = {
          'id': currentJobId,
          'title': widget.job.metadata.title,
          'created_at': widget.job.createdAt?.toIso8601String(),
          'expired_at': widget.job.deadline?.toIso8601String(),
        };

        for (final studentId in currentJobAssigned) {
          final jobs = assignedJobsMap.putIfAbsent(studentId, () => []);
          final hasCurrentJob = jobs.any(
            (job) => (job['id']?.toString() ?? '') == currentJobId,
          );
          if (!hasCurrentJob) {
            jobs.add(currentJobInfo);
          }
        }
      }

      if (mounted) {
        setState(() {
          _studentAssignedJobsMap = assignedJobsMap;
        });
      }
    } catch (e) {
      if (!mounted) return;
    }
  }

  Map<String, dynamic> _parseMetadata(dynamic rawMetadata) {
    if (rawMetadata is Map<String, dynamic>) {
      return rawMetadata;
    }
    if (rawMetadata is Map) {
      return Map<String, dynamic>.from(rawMetadata);
    }
    if (rawMetadata is String && rawMetadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  String _normalizeStudentId(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  List<String> _extractAssignedStudentIds(Map<String, dynamic> metadata) {
    final raw = metadata['assigned_students'];
    final ids = <String>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);
          final candidateId =
              itemMap['student_id'] ??
              itemMap['user_id'] ??
              itemMap['candidate_id'] ??
              itemMap['id'];
          final id = _normalizeStudentId(candidateId);
          if (id.isNotEmpty) ids.add(id);
        } else {
          final id = _normalizeStudentId(item);
          if (id.isNotEmpty) ids.add(id);
        }
      }
      return ids.toSet().toList();
    }

    if (raw is String && raw.trim().isNotEmpty) {
      final rawText = raw.trim();

      try {
        final decoded = jsonDecode(rawText);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final itemMap = Map<String, dynamic>.from(item);
              final candidateId =
                  itemMap['student_id'] ??
                  itemMap['user_id'] ??
                  itemMap['candidate_id'] ??
                  itemMap['id'];
              final id = _normalizeStudentId(candidateId);
              if (id.isNotEmpty) ids.add(id);
            } else {
              final id = _normalizeStudentId(item);
              if (id.isNotEmpty) ids.add(id);
            }
          }
          return ids.toSet().toList();
        }

        if (decoded is String && decoded.trim().isNotEmpty) {
          final secondPass = decoded.trim();
          if (secondPass.startsWith('[') && secondPass.endsWith(']')) {
            final secondDecoded = jsonDecode(secondPass);
            if (secondDecoded is List) {
              for (final item in secondDecoded) {
                final id = _normalizeStudentId(item);
                if (id.isNotEmpty) ids.add(id);
              }
              return ids.toSet().toList();
            }
          }
        }
      } catch (_) {
        if (rawText.startsWith('{') && rawText.endsWith('}')) {
          final pgArrayItems = rawText
              .substring(1, rawText.length - 1)
              .split(',')
              .map((e) => e.replaceAll('"', '').trim())
              .where((e) => e.isNotEmpty)
              .toList();
          for (final item in pgArrayItems) {
            final id = _normalizeStudentId(item);
            if (id.isNotEmpty) ids.add(id);
          }
          return ids.toSet().toList();
        }

        if (rawText.contains(',')) {
          final csvItems = rawText
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          for (final item in csvItems) {
            final id = _normalizeStudentId(item);
            if (id.isNotEmpty) ids.add(id);
          }
          return ids.toSet().toList();
        }

        final id = _normalizeStudentId(rawText);
        if (id.isNotEmpty) ids.add(id);
      }
    }

    return ids.toSet().toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAssignedJobsForStudent(
    String normalizedStudentId,
  ) async {
    final schoolId = Supabase.instance.client.auth.currentUser?.id;
    if (schoolId == null || normalizedStudentId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final rows = await Supabase.instance.client
        .from('school_partnership_jobs')
        .select('id, metadata, created_at, deadline')
        .eq('school_id', schoolId)
        .order('created_at', ascending: false);

    final result = <Map<String, dynamic>>[];
    for (final row in rows as List<dynamic>) {
      final rowMap = Map<String, dynamic>.from(row as Map);
      final metadata = _parseMetadata(rowMap['metadata']);
      final assignedIds = _extractAssignedStudentIds(metadata);
      final hasStudent = assignedIds.any((id) => id == normalizedStudentId);
      if (!hasStudent) continue;

      result.add({
        'id': rowMap['id']?.toString() ?? '',
        'title': (metadata['title'] ?? 'Tin không có tiêu đề').toString(),
        'created_at': rowMap['created_at'],
        'expired_at': rowMap['deadline'],
      });
    }

    final uniqueById = <String, Map<String, dynamic>>{};
    for (final item in result) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;
      uniqueById.putIfAbsent(id, () => item);
    }

    return uniqueById.values.toList();
  }

  Future<void> _showAssignedJobsDialog(Map<String, dynamic> student) async {
    final studentId = _normalizeStudentId(student['id']);
    final mappedJobs = await _fetchAssignedJobsForStudent(studentId);
    if (!mounted) return;

    final isAssignedInCurrentJob =
        _selectedStudents.any((id) => _normalizeStudentId(id) == studentId) ||
        _originalAssignedStudents.any(
          (id) => _normalizeStudentId(id) == studentId,
        );
    final currentJobId = (widget.job.id ?? '').toString();
    if (isAssignedInCurrentJob && currentJobId.isNotEmpty) {
      final hasCurrentJob = mappedJobs.any(
        (job) => (job['id']?.toString() ?? '') == currentJobId,
      );
      if (!hasCurrentJob) {
        mappedJobs.add({
          'id': currentJobId,
          'title': widget.job.metadata.title,
          'created_at': widget.job.createdAt?.toIso8601String(),
          'expired_at': widget.job.deadline?.toIso8601String(),
        });
      }
    }

    final jobsById = <String, Map<String, dynamic>>{};
    for (final job in mappedJobs) {
      final jobId = (job['id'] ?? '').toString();
      if (jobId.isEmpty) continue;
      jobsById.putIfAbsent(jobId, () => job);
    }
    final jobs = jobsById.values.toList();

    jobs.sort((a, b) {
      final aDate = DateTime.tryParse((a['created_at'] ?? '').toString());
      final bDate = DateTime.tryParse((b['created_at'] ?? '').toString());
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch sử phân công: ${student['full_name'] ?? 'Sinh viên'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (jobs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Sinh viên này chưa được phân công vào tin thực tập nào.',
                      style: TextStyle(fontSize: 14),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: jobs.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = jobs[index];
                        final isCurrentJob =
                            item['id'].toString() == widget.job.id;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCurrentJob
                                  ? Icons.push_pin
                                  : Icons.work_outline,
                              color: isCurrentJob
                                  ? Colors.orange
                                  : AppMainColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']?.toString() ??
                                        'Tin không có tiêu đề',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCurrentJob
                                              ? Colors.orange.shade100
                                              : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          isCurrentJob
                                              ? 'Tin hiện tại'
                                              : 'Tin khác',
                                          style: TextStyle(
                                            color: isCurrentJob
                                                ? Colors.orange.shade900
                                                : Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (item['created_at'] != null)
                                        Text(
                                          'Đăng: ${_formatDate(item['created_at'].toString())}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String value) {
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final name = (student['full_name'] ?? '').toString().toLowerCase();
          final email = (student['email'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _saveAssignment() async {
    // Check if any students were unassigned
    final unassignedStudents = _originalAssignedStudents
        .where((id) => !_selectedStudents.contains(id))
        .toList();

    if (unassignedStudents.isNotEmpty) {
      // Show confirmation dialog
      final shouldContinue = await _showUnassignConfirmDialog(
        unassignedStudents,
      );
      if (shouldContinue != true) return;
    }

    setState(() => _isSaving = true);
    try {
      final table = widget.isPartnershipJob
          ? 'school_partnership_jobs'
          : 'jobs';

      // Get current metadata
      final jobData = await Supabase.instance.client
          .from(table)
          .select('metadata')
          .eq('id', widget.job.id!)
          .single();

      final metadata = Map<String, dynamic>.from(jobData['metadata'] ?? {});
      metadata['assigned_students'] = _selectedStudents;

      // Update metadata
      await Supabase.instance.client
          .from(table)
          .update({'metadata': metadata})
          .eq('id', widget.job.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật danh sách sinh viên thực tập'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
      }
    }
  }

  Future<bool?> _showUnassignConfirmDialog(List<String> unassignedIds) async {
    final unassignedStudents = _students
        .where((s) => unassignedIds.contains(s['id']))
        .toList();

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Xác nhận hủy phân công',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đã hủy phân công ${unassignedStudents.length} sinh viên:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: unassignedStudents.length,
                      itemBuilder: (context, index) {
                        final student = unassignedStudents[index];
                        final studentId = student['id'] as String;
                        final isReselected = _selectedStudents.contains(
                          studentId,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            value: isReselected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedStudents.add(studentId);
                                } else {
                                  _selectedStudents.remove(studentId);
                                }
                              });
                              setDialogState(() {}); // Update dialog
                            },
                            title: Text(
                              student['full_name'] ?? 'Không có tên',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: isReselected
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isReselected ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              student['email'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: isReselected
                                  ? Colors.grey
                                  : Colors.red.shade100,
                              child: Text(
                                (student['full_name'] ?? 'N')[0].toUpperCase(),
                                style: TextStyle(
                                  color: isReselected
                                      ? Colors.white
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            activeColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tích lại để khôi phục phân công',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy bỏ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewStudentProfile(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileDetailScreen(student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Phân công sinh viên thực tập'),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedStudents.length} đã chọn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Job Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_ind,
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
                        'VỊ TRÍ THỰC TẬP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.job.metadata.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sinh viên...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _filterStudents,
            ),
          ),

          const SizedBox(height: 16),

          // Student List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Chưa có sinh viên nào'
                              : 'Không tìm thấy sinh viên',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final studentId = student['id'] as String;
                      final normalizedStudentId = _normalizeStudentId(
                        studentId,
                      );
                      final isSelected = _selectedStudents.contains(studentId);
                      final wasOriginallyAssigned = _originalAssignedStudents
                          .contains(studentId);
                      final assignedJobs =
                          _studentAssignedJobsMap[normalizedStudentId] ??
                          const <Map<String, dynamic>>[];
                      final assignedOtherJobsCount = assignedJobs
                          .where((job) => job['id'].toString() != widget.job.id)
                          .length;
                      final metadata =
                          student['metadata'] as Map<String, dynamic>? ?? {};

                      // Extract info from metadata
                      final education = metadata['education'] as String?;
                      final address = metadata['address'] as String?;
                      final interestedFields =
                          metadata['interested_fields'] as List?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.orange
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedStudents.remove(studentId);
                              } else {
                                _selectedStudents.add(studentId);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: isSelected
                                          ? Colors.orange
                                          : AppMainColors.primary,
                                      child: Text(
                                        (student['full_name'] ?? 'N')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Basic Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  student['full_name'] ??
                                                      'Không có tên',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (wasOriginallyAssigned) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.green.shade300,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle,
                                                        size: 12,
                                                        color: Colors
                                                            .green
                                                            .shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Đã phân công',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors
                                                              .green
                                                              .shade700,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.email,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  student['email'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Checkbox
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedStudents.add(studentId);
                                          } else {
                                            _selectedStudents.remove(studentId);
                                          }
                                        });
                                      },
                                      activeColor: Colors.orange,
                                    ),
                                  ],
                                ),

                                // Additional Info Chips
                                if (education != null ||
                                    address != null ||
                                    interestedFields != null) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (education != null)
                                        _buildInfoChip(
                                          Icons.school,
                                          education,
                                          Colors.blue,
                                        ),
                                      if (address != null)
                                        _buildInfoChip(
                                          Icons.location_on,
                                          address,
                                          Colors.green,
                                        ),
                                      if (interestedFields != null &&
                                          interestedFields.isNotEmpty)
                                        _buildInfoChip(
                                          Icons.work_outline,
                                          '${interestedFields.length} lĩnh vực',
                                          Colors.purple,
                                        ),
                                    ],
                                  ),
                                ],

                                // View Profile Button
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _viewStudentProfile(student),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppMainColors.primary,
                                      side: BorderSide(
                                        color: AppMainColors.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.person_outline,
                                      size: 18,
                                    ),
                                    label: const Text('Xem profile đầy đủ'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showAssignedJobsDialog(student),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.deepOrange,
                                      side: BorderSide(
                                        color: Colors.deepOrange.shade200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.assignment_turned_in_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      assignedOtherJobsCount > 0
                                          ? 'Xem tin đã phân công ($assignedOtherJobsCount tin khác)'
                                          : 'Xem tin đã phân công',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving
                  ? 'Đang lưu...'
                  : 'Lưu phân công (${_selectedStudents.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final CVSupabaseService _cvService = CVSupabaseService();

  StudentProfileDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final metadata = student['metadata'] as Map<String, dynamic>? ?? {};
    final createdAt = student['created_at'] != null
        ? DateTime.parse(student['created_at'])
        : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Thông tin sinh viên')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppMainColors.primary,
                    AppMainColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: Text(
                        (student['full_name'] ?? 'N')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppMainColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    student['full_name'] ?? 'Không có tên',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      student['role']?.toString().toUpperCase() ?? 'CANDIDATE',
                      style: TextStyle(
                        color: AppMainColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Basic Info Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'Thông tin cơ bản',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    student['email'] ?? 'Chưa có',
                  ),
                  if (createdAt != null) ...[
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Ngày tạo',
                      '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    ),
                  ],
                ],
              ),
            ),

            // Metadata Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      Icon(
                        Icons.account_box_rounded,
                        color: AppMainColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Profile chi tiết',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (metadata.isEmpty || !_hasAnyProfileData(metadata))
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sinh viên chưa cập nhật thông tin profile',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Profile sẽ được hiển thị khi sinh viên hoàn tất cập nhật',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Bio
                    if (metadata['bio'] != null) ...[
                      _buildSection(
                        'Giới thiệu bản thân',
                        Icons.person_outline,
                        Colors.blue,
                        child: Text(
                          metadata['bio'].toString(),
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 32),
                    ],

                    // Education
                    if (metadata['education'] != null) ...[
                      _buildInfoRow(
                        Icons.school,
                        'Trình độ',
                        metadata['education'].toString(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Date of birth
                    if (metadata['date_of_birth'] != null) ...[
                      _buildInfoRow(
                        Icons.cake,
                        'Ngày sinh',
                        DateTime.parse(
                          metadata['date_of_birth'],
                        ).toString().split(' ')[0],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Address
                    if (metadata['address'] != null &&
                        metadata['address'].toString().trim().isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.location_on,
                        'Địa chỉ',
                        metadata['address'].toString(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // CV Files
                    if (metadata['cv_ids'] != null &&
                        (metadata['cv_ids'] as List).isNotEmpty) ...[
                      _buildSection(
                        'Hồ sơ CV',
                        Icons.description,
                        Colors.red,
                        child: Column(
                          children: (metadata['cv_ids'] as List)
                              .asMap()
                              .entries
                              .map((entry) {
                                final index = entry.key;
                                final cvId = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      'CV ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: ${cvId.toString().substring(0, 8)}...',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _viewCV(context, cvId.toString()),
                                      color: Colors.red,
                                      tooltip: 'Xem CV',
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Interested Fields
                    if (metadata['interested_fields'] != null &&
                        (metadata['interested_fields'] as List).isNotEmpty) ...[
                      _buildSection(
                        'Lĩnh vực quan tâm',
                        Icons.interests,
                        Colors.purple,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (metadata['interested_fields'] as List)
                              .map(
                                (field) => Chip(
                                  label: Text(field.toString()),
                                  backgroundColor: Colors.purple.withOpacity(
                                    0.1,
                                  ),
                                  side: BorderSide(
                                    color: Colors.purple.withOpacity(0.3),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Work Locations
                    if (metadata['work_locations'] != null &&
                        (metadata['work_locations'] as List).isNotEmpty) ...[
                      _buildSection(
                        'Địa điểm làm việc mong muốn',
                        Icons.location_city,
                        Colors.green,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (metadata['work_locations'] as List)
                              .map(
                                (loc) => Chip(
                                  label: Text(loc.toString()),
                                  backgroundColor: Colors.green.withOpacity(
                                    0.1,
                                  ),
                                  side: BorderSide(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Work Types
                    if (metadata['work_types'] != null &&
                        (metadata['work_types'] as List).isNotEmpty) ...[
                      _buildSection(
                        'Hình thức làm việc',
                        Icons.work_outline,
                        Colors.orange,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (metadata['work_types'] as List)
                              .map(
                                (type) => Chip(
                                  label: Text(type.toString()),
                                  backgroundColor: Colors.orange.withOpacity(
                                    0.1,
                                  ),
                                  side: BorderSide(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tags/Skills
                    if (metadata['tags'] != null &&
                        (metadata['tags'] as List).isNotEmpty) ...[
                      _buildSection(
                        'Kỹ năng',
                        Icons.sell,
                        Colors.blue,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (metadata['tags'] as List)
                              .map(
                                (tag) => Chip(
                                  label: Text(tag.toString()),
                                  avatar: const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                  ),
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  side: BorderSide(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Experience
                    if (metadata['experience'] != null &&
                        (metadata['experience'] as List).isNotEmpty) ...[
                      _buildSection(
                        'Kinh nghiệm làm việc',
                        Icons.business_center,
                        Colors.teal,
                        child: Column(
                          children: (metadata['experience'] as List).map((exp) {
                            final expMap = exp as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expMap['position'] ?? 'Vị trí',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    expMap['company'] ?? 'Công ty',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (expMap['date'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      expMap['date'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (expMap['description'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      expMap['description'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color, {
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  bool _hasAnyProfileData(Map<String, dynamic> metadata) {
    return metadata['bio'] != null ||
        metadata['education'] != null ||
        metadata['date_of_birth'] != null ||
        metadata['address'] != null ||
        (metadata['cv_ids'] != null &&
            (metadata['cv_ids'] as List).isNotEmpty) ||
        (metadata['interested_fields'] != null &&
            (metadata['interested_fields'] as List).isNotEmpty) ||
        (metadata['work_locations'] != null &&
            (metadata['work_locations'] as List).isNotEmpty) ||
        (metadata['work_types'] != null &&
            (metadata['work_types'] as List).isNotEmpty) ||
        (metadata['tags'] != null && (metadata['tags'] as List).isNotEmpty) ||
        (metadata['experience'] != null &&
            (metadata['experience'] as List).isNotEmpty);
  }

  void _viewCV(BuildContext context, String cvId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Use getCVFullDataForEmployer for school access (similar to employer)
      final cvData = await _cvService.getCVFullDataForEmployer(cvId);

      // Hide loading indicator
      if (context.mounted) Navigator.pop(context);

      if (cvData != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CVDisplayManager.buildViewWidget(context, cvData),
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CV không tồn tại hoặc đã bị xóa')),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if error
      if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải CV: $e')));
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
