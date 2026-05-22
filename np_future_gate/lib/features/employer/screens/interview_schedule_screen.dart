import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:np_future_gate/features/employer/controllers/interview_schedule_controller.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/employer/screens/interview_detail_screen.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';

class InterviewScheduleScreen extends StatefulWidget {
  const InterviewScheduleScreen({super.key});

  @override
  State<InterviewScheduleScreen> createState() => _InterviewScheduleScreenState();
}

class _InterviewScheduleScreenState extends State<InterviewScheduleScreen> {
  late final InterviewScheduleController _controller;
  late final TextEditingController _searchTextController;

  @override
  void initState() {
    super.initState();
    _controller = InterviewScheduleController();
    _controller.addListener(_onControllerChanged);
    _controller.loadInterviews();
    _searchTextController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInterviews = _controller.filteredInterviews;
    final groupedInterviews = _controller.groupedByDate;
    final sortedDates = _controller.sortedDateKeys;

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
                    controller: _searchTextController,
                    hint: 'Tìm theo tên ứng viên, công việc...',
                    prefixIcon: Icons.search,
                    onChanged: (value) => _controller.setSearchQuery(value),
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
                              _controller.setDateRange(picked);
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
                                    _controller.dateRange == null
                                        ? 'Tất cả ngày'
                                        : '${DateFormat('dd/MM').format(_controller.dateRange!.start)} - ${DateFormat('dd/MM').format(_controller.dateRange!.end)}',
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
                              value: _controller.statusFilter,
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
                              onChanged: (v) => _controller.setStatusFilter(v!),
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
            child: _controller.isLoading
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

                                // Check if any interview is for intern job
                                final jobId = interviews.first.jobId;
                                final job = _controller.jobs[jobId];
                                final isIntern = job?.metadata.isIntern ?? false;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: isIntern
                                        ? Colors.deepPurple.withValues(alpha: 0.03)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isIntern ? Border.all(
                                      color: Colors.deepPurple,
                                      width: 2,
                                    ) : null,
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
                                      // Intern Badge at top if applicable
                                      if (isIntern)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: const BoxDecoration(
                                            color: Colors.deepPurple,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.school,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'CHƯƠNG TRÌNH THỰC TẬP',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                                                  color: Colors.purple.withValues(alpha: 0.1),
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
                                        final candidate = _controller.candidateProfiles[interview.candidateId];
                                        return InkWell(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => InterviewDetailScreen(
                                                  interview: interview,
                                                  candidate: candidate,
                                                  job: _controller.jobs[interview.jobId],
                                                ),
                                              ),
                                            );
                                            _controller.loadInterviews(); // Reload after returning
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
