import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/interview_model.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/job_model.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/interview_repository.dart';
import '../../core/repositories/job_repository.dart';
import '../../core/theme/app_main_colors.dart';
import 'interview_detail_screen.dart';

class InterviewScheduleScreen extends StatefulWidget {
  const InterviewScheduleScreen({super.key});

  @override
  State<InterviewScheduleScreen> createState() => _InterviewScheduleScreenState();
}

class _InterviewScheduleScreenState extends State<InterviewScheduleScreen> {
  final InterviewRepository _interviewRepository = InterviewRepository();
  final AuthRepository _authRepository = AuthRepository();
  final JobRepository _jobRepository = JobRepository();
  
  List<InterviewModel> _allInterviews = [];
  Map<String, Profile> _candidateProfiles = {};
  Map<String, JobModel> _jobs = {};
  bool _isLoading = true;

  // Filters
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _statusFilter = 'All'; // All, Scheduled, Completed, Cancelled

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = _authRepository.currentUser?.id;
    if (userId != null) {
      try {
        // 1. Get Interviews
        final interviews = await _interviewRepository.getInterviewsByEmployer(userId);
        _allInterviews = interviews;

        // 2. Get Candidate Profiles
        final candidateIds = interviews.map((e) => e.candidateId).toSet().toList();
        if (candidateIds.isNotEmpty) {
          final profiles = await _authRepository.getProfilesByIds(candidateIds);
          _candidateProfiles = {for (var p in profiles) p.id: p};
        }

        // 3. Get Jobs
        final jobIds = interviews.map((e) => e.jobId).toSet().toList();
        if (jobIds.isNotEmpty) {
          // We need a method to get multiple jobs or loop. 
          // Since we don't have getJobsByIds, we might loop or add it.
          // For now, let's loop as it's likely small number of active jobs.
          // Or better, check if JobRepository has a way.
          // Assuming we can fetch individually for now or if there is a list method.
          // Let's just loop for now to be safe.
          for (var id in jobIds) {
             final job = await _jobRepository.getJobById(id);
             if (job != null) {
               _jobs[id] = job;
             }
          }
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<InterviewModel> _getFilteredInterviews() {
    final filtered = _allInterviews.where((interview) {
      // Search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final candidate = _candidateProfiles[interview.candidateId];
        final candidateName = candidate?.fullName?.toLowerCase() ?? '';
        final jobTitle = interview.jobTitle.toLowerCase();
        
        // Check tags
        final job = _jobs[interview.jobId];
        final tags = job?.metadata.requirementsTags.map((e) => e.toLowerCase()).toList() ?? [];
        final fields = job?.metadata.fields.map((e) => e.toLowerCase()).toList() ?? [];
        
        bool matchTags = tags.any((t) => t.contains(query));
        bool matchFields = fields.any((f) => f.contains(query));

        if (!candidateName.contains(query) && !jobTitle.contains(query) && !matchTags && !matchFields) {
          return false;
        }
      }

      // Date Range
      if (_dateRange != null) {
        final date = interview.interviewTime;
        if (date.isBefore(_dateRange!.start) || date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Status
      if (_statusFilter != 'All') {
        if (interview.status.toLowerCase() != _statusFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
    
    // Sort: upcoming first, past interviews at bottom
    final now = DateTime.now();
    final upcoming = filtered.where((i) => i.interviewTime.isAfter(now)).toList();
    final past = filtered.where((i) => !i.interviewTime.isAfter(now)).toList();
    
    upcoming.sort((a, b) => a.interviewTime.compareTo(b.interviewTime));
    past.sort((a, b) => b.interviewTime.compareTo(a.interviewTime)); // Latest past first
    
    return [...upcoming, ...past];
  }

  Map<String, Map<String, List<InterviewModel>>> _groupInterviews(List<InterviewModel> interviews) {
    // Group by Date -> Job Title
    final Map<String, Map<String, List<InterviewModel>>> grouped = {};

    for (var interview in interviews) {
      final dateKey = DateFormat('yyyy-MM-dd').format(interview.interviewTime);
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = {};
      }

      final jobKey = interview.jobTitle;
      if (!grouped[dateKey]!.containsKey(jobKey)) {
        grouped[dateKey]![jobKey] = [];
      }

      grouped[dateKey]![jobKey]!.add(interview);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final filteredInterviews = _getFilteredInterviews();
    final groupedInterviews = _groupInterviews(filteredInterviews);
    
    // Sort dates: upcoming first, then past
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final sortedDates = groupedInterviews.keys.toList();
    
    sortedDates.sort((a, b) {
      final dateA = DateTime.parse(a);
      final dateB = DateTime.parse(b);
      final isAFuture = dateA.isAfter(now);
      final isBFuture = dateB.isAfter(now);
      
      if (isAFuture && !isBFuture) return -1; // A is future, B is past → A comes first
      if (!isAFuture && isBFuture) return 1;  // A is past, B is future → B comes first
      
      // Both future or both past
      if (isAFuture) {
        return dateA.compareTo(dateB); // Future: earliest first
      } else {
        return dateB.compareTo(dateA); // Past: latest first
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Lịch phỏng vấn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),

            // Search & Filter
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên ứng viên, công việc...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppMainColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _dateRange = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dateRange == null
                                        ? 'Tất cả ngày'
                                        : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _statusFilter,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              items: ['All', 'Scheduled', 'Completed', 'Postponed']
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          _getStatusText(e),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _statusFilter = v!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // List
            Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInterviews.isEmpty
                    ? const Center(child: Text('Không có lịch phỏng vấn nào'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDates[index];
                          final jobsMap = groupedInterviews[dateKey]!;
                          final date = DateTime.parse(dateKey);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppMainColors.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(indent: 12)),
                                  ],
                                ),
                              ),

                              // Jobs
                              ...jobsMap.entries.map((entry) {
                                final jobTitle = entry.key;
                                final interviews = entry.value;
                                final isPartnership = interviews.any((i) => i.isPartnership);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Job Title Header
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.work, size: 18, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                jobTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (isPartnership)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Liên kết',
                                                  style: TextStyle(
                                                    color: Colors.purple,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      
                                      // Candidates
                                      ...interviews.map((interview) {
                                        final candidate = _candidateProfiles[interview.candidateId];
                                        return InkWell(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => InterviewDetailScreen(
                                                  interview: interview,
                                                  candidate: candidate,
                                                  job: _jobs[interview.jobId],
                                                ),
                                              ),
                                            );
                                            _loadData(); // Reload after returning
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(color: Colors.grey.shade100),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Time Column
                                                Column(
                                                  children: [
                                                    Text(
                                                      DateFormat('HH:mm').format(interview.interviewTime),
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(interview.status).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        _getStatusText(interview.status),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: _getStatusColor(interview.status),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                // Vertical Divider
                                                Container(
                                                  height: 40,
                                                  width: 2,
                                                  color: AppMainColors.primary.withOpacity(0.2),
                                                ),
                                                const SizedBox(width: 16),

                                                // Candidate Info
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 22,
                                                        backgroundImage: candidate?.avatarUrl != null
                                                            ? NetworkImage(candidate!.avatarUrl!)
                                                            : null,
                                                        child: candidate?.avatarUrl == null
                                                            ? const Icon(Icons.person, size: 22)
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              candidate?.fullName ?? 'Unknown Candidate',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 15,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            if (candidate?.email != null)
                                                              Text(
                                                                candidate!.email!,
                                                                style: TextStyle(
                                                                  color: Colors.grey.shade600,
                                                                  fontSize: 12,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'Tất cả trạng thái';
      case 'scheduled':
        return 'Sắp tới';
      case 'completed':
        return 'Hoàn thành';
      case 'postponed':
        return 'Tạm hoãn';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'scheduled':
        color = Colors.orange;
        text = 'Sắp tới';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Hoàn thành';
        break;
      case 'postponed':
        color = Colors.amber;
        text = 'Tạm hoãn';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'postponed':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
