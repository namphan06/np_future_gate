import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:np_future_gate/core/models/interview_model.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/interview_repository.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/candidate/screens/interview_detail_candidate_screen.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';

class InterviewScheduleCandidateScreen extends StatefulWidget {
  const InterviewScheduleCandidateScreen({super.key});

  @override
  State<InterviewScheduleCandidateScreen> createState() => _InterviewScheduleCandidateScreenState();
}

class _InterviewScheduleCandidateScreenState extends State<InterviewScheduleCandidateScreen> {
  final InterviewRepository _interviewRepository = InterviewRepository();
  final AuthRepository _authRepository = AuthRepository();
  final JobRepository _jobRepository = JobRepository();
  
  List<InterviewModel> _allInterviews = [];
  Map<String, Profile> _employerProfiles = {};
  final Map<String, JobModel> _jobs = {};
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
        final interviews = await _interviewRepository.getInterviewsByCandidate(userId);
        _allInterviews = interviews;

        // 2. Get Employer Profiles
        final employerIds = interviews.map((e) => e.employerId).toSet().toList();
        if (employerIds.isNotEmpty) {
          final profiles = await _authRepository.getProfilesByIds(employerIds);
          _employerProfiles = {for (var p in profiles) p.id: p};
        }

        // 3. Get Jobs
        final jobIds = interviews.map((e) => e.jobId).toSet().toList();
        if (jobIds.isNotEmpty) {
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
        final employer = _employerProfiles[interview.employerId];
        final employerName = employer?.fullName?.toLowerCase() ?? '';
        final jobTitle = interview.jobTitle.toLowerCase();
        
        if (!employerName.contains(query) && !jobTitle.contains(query)) {
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
    
    final now = DateTime.now();
    final sortedDates = groupedInterviews.keys.toList();
    
    sortedDates.sort((a, b) {
      final dateA = DateTime.parse(a);
      final dateB = DateTime.parse(b);
      final isAFuture = dateA.isAfter(now);
      final isBFuture = dateB.isAfter(now);
      
      if (isAFuture && !isBFuture) return -1;
      if (!isAFuture && isBFuture) return 1;
      
      if (isAFuture) {
        return dateA.compareTo(dateB);
      } else {
        return dateB.compareTo(dateA);
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
                      'Lịch phỏng vấn của tôi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Search & Filter
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: Colors.white,
              child: Column(
                children: [
                  SpeechTextField(
                    controller: TextEditingController(),
                    hint: 'Tìm theo tên công ty, công việc...',
                    prefixIcon: Icons.search,
                    onChanged: (value) => setState(() => _searchQuery = value),
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
                                    colorScheme: const ColorScheme.light(
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
                              items: ['All', 'Scheduled', 'Completed', 'Postponed', 'Cancelled']
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Không có lịch phỏng vấn nào',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
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

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
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
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        
                                        // Interviews for this job on this date
                                        ...interviews.map((interview) {
                                          final employer = _employerProfiles[interview.employerId];
                                          return InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => InterviewDetailCandidateScreen(
                                                    interview: interview,
                                                    employer: employer,
                                                    job: _jobs[interview.jobId],
                                                  ),
                                                ),
                                              ).then((_) => _loadData());
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
                                                          color: _getStatusColor(interview.status).withValues(alpha: 0.1),
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
                                                    color: AppMainColors.primary.withValues(alpha: 0.2),
                                                  ),
                                                  const SizedBox(width: 16),

                                                  // Employer Info
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 22,
                                                          backgroundImage: employer?.avatarUrl != null
                                                              ? NetworkImage(employer!.avatarUrl!)
                                                              : null,
                                                          child: employer?.avatarUrl == null
                                                              ? const Icon(Icons.business, size: 22)
                                                              : null,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                employer?.fullName ?? 'Nhà tuyển dụng',
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  fontSize: 15,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              Text(
                                                                'Phỏng vấn trực tiếp', // Default assume 
                                                                style: TextStyle(
                                                                  color: Colors.grey.shade600,
                                                                  fontSize: 12,
                                                                ),
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
