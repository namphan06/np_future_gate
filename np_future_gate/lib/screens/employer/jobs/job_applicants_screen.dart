import 'package:flutter/material.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/models/job_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/repositories/candidate_repository.dart';
import '../../../core/repositories/interview_repository.dart';
import '../../../core/services/cv_supabase_service.dart';
import '../../cv/cv_setting/cv_display_manager.dart';
import '../../../core/theme/app_main_colors.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final List<JobApplication> applicants;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.applicants,
  });

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final JobRepository _jobRepository = JobRepository();
  final CandidateRepository _candidateRepository = CandidateRepository();
  final InterviewRepository _interviewRepository = InterviewRepository();
  final CVSupabaseService _cvService = CVSupabaseService();
  
  Map<String, Profile> _profiles = {};
  bool _isLoading = true;
  late List<JobApplication> _currentApplicants;
  String? _jobTitle;
  
  // Filters
  String _statusFilter = 'All';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _currentApplicants = widget.applicants;
    _loadProfiles();
    _loadJobDetails();
  }

  Future<void> _loadProfiles() async {
    try {
      final userIds = _currentApplicants.map((e) => e.userId).toList();
      if (userIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final profiles = await _authRepository.getProfilesByIds(userIds);
      setState(() {
        _profiles = {for (var p in profiles) p.id: p};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  Future<void> _loadJobDetails() async {
    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      if (job != null) {
        setState(() {
          _jobTitle = job.metadata.title;
        });
      }
    } catch (e) {
      print('Error loading job details: $e');
    }
  }

  List<JobApplication> _getFilteredApplicants() {
    return _currentApplicants.where((app) {
      // Status Filter
      bool matchesStatus = true;
      if (_statusFilter != 'All') {
        matchesStatus = app.status.toLowerCase() == _statusFilter.toLowerCase();
      }

      // Date Range Filter
      bool matchesDate = true;
      if (_dateRange != null) {
        final appliedDate = app.appliedAt;
        matchesDate = appliedDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            appliedDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }

      return matchesStatus && matchesDate;
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Lọc ứng viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trạng thái'),
              DropdownButton<String>(
                value: _statusFilter,
                isExpanded: true,
                items: ['All', 'Pending', 'Viewed', 'Accepted', 'Rejected']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(_getStatusText(e) == e && e == 'All' ? 'Tất cả' : _getStatusText(e)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
              const SizedBox(height: 16),
              const Text('Ngày ứng tuyển'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dateRange == null
                    ? 'Chọn khoảng thời gian'
                    : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _dateRange = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _statusFilter = 'All';
                  _dateRange = null;
                });
                this.setState(() {}); // Update parent state
                Navigator.pop(context);
              },
              child: const Text('Đặt lại'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {}); // Update parent state
                Navigator.pop(context);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String userId, String newStatus) async {
    if (newStatus.toLowerCase() == 'accepted') {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'Chọn ngày phỏng vấn',
      );

      if (pickedDate == null) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        helpText: 'Chọn giờ phỏng vấn',
      );

      if (pickedTime == null) return;

      final interviewTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      try {
        // Find the applicant to get CV ID
        final applicant = _currentApplicants.firstWhere((app) => app.userId == userId);
        final employerId = _authRepository.currentUser?.id;

        if (employerId != null && _jobTitle != null) {
          await _interviewRepository.createInterview(
            candidateId: userId,
            jobId: widget.jobId,
            employerId: employerId,
            cvId: applicant.cvId,
            interviewTime: interviewTime,
            jobTitle: _jobTitle!,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tạo lịch phỏng vấn: $e')),
          );
        }
        return; // Stop if interview creation fails
      }
    }

    try {
      await _jobRepository.updateApplicationStatus(widget.jobId, userId, newStatus);
      
      setState(() {
        final index = _currentApplicants.indexWhere((app) => app.userId == userId);
        if (index != -1) {
          _currentApplicants[index] = JobApplication(
            userId: _currentApplicants[index].userId,
            cvId: _currentApplicants[index].cvId,
            appliedAt: _currentApplicants[index].appliedAt,
            status: newStatus,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái thành ${_getStatusText(newStatus)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')),
        );
      }
    }
  }

  Future<void> _deleteApplication(String userId) async {
    try {
      await _jobRepository.deleteApplication(widget.jobId, userId);
      
      setState(() {
        _currentApplicants.removeWhere((app) => app.userId == userId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ứng viên khỏi danh sách')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa ứng viên: $e')),
        );
      }
    }
  }

  Future<void> _viewCV(String cvId, String userId, String currentStatus) async {
    try {
      // Update status to 'viewed' if it is 'pending'
      if (currentStatus == 'pending') {
        await _updateStatus(userId, 'viewed');
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final cvData = await _cvService.getCVFullData(cvId);
      
      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      if (cvData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CVDisplayManager.buildViewWidget(context, cvData),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CV không tồn tại hoặc đã bị xóa')),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if error
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải CV: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'viewed':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Đang chờ';
      case 'viewed':
        return 'Đã xem';
      case 'accepted':
        return 'Được nhận';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  void _showCandidateDetail(Profile profile) {
    // Check privacy setting
    if (profile.metadata['security'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ứng viên không cho phép xem hồ sơ')),
      );
      return;
    }

    final meta = profile.metadata;
    final fields = (meta['interested_fields'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final tags = (meta['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final workLocations = (meta['work_locations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final experience = (meta['experience'] as List<dynamic>?) ?? [];

    final currentUserId = _authRepository.currentUser?.id;
    final ValueNotifier<bool> isFollowingNotifier = ValueNotifier(false);
    final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);

    if (currentUserId != null) {
      _candidateRepository.getFollowedCandidateIds(currentUserId).then((ids) {
        isFollowingNotifier.value = ids.contains(profile.id);
        isLoadingNotifier.value = false;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Header Profile
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        profile.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, color: Colors.grey, size: 50);
                                        },
                                      )
                                    : const Icon(Icons.person, color: Colors.grey, size: 50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profile.fullName ?? 'Ứng viên',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (meta['bio'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                meta['bio'],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                              ),
                            ],
                            if (currentUserId != null) ...[
                              const SizedBox(height: 16),
                              ValueListenableBuilder<bool>(
                                valueListenable: isLoadingNotifier,
                                builder: (context, isLoading, _) {
                                  if (isLoading) {
                                    return const SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                    );
                                  }
                                  
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: isFollowingNotifier,
                                    builder: (context, isFollowing, _) {
                                      return OutlinedButton.icon(
                                        onPressed: () async {
                                          try {
                                            isLoadingNotifier.value = true;
                                            if (isFollowing) {
                                              await _candidateRepository.unfollowCandidate(currentUserId, profile.id);
                                            } else {
                                              await _candidateRepository.followCandidate(currentUserId, profile.id);
                                            }
                                            isFollowingNotifier.value = !isFollowing;
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Lỗi: $e')),
                                              );
                                            }
                                          } finally {
                                            isLoadingNotifier.value = false;
                                          }
                                        },
                                        icon: Icon(
                                          isFollowing ? Icons.bookmark : Icons.bookmark_border, 
                                          color: isFollowing ? AppMainColors.primary : Colors.grey
                                        ),
                                        label: Text(
                                          isFollowing ? 'Đã lưu' : 'Lưu ứng viên',
                                          style: TextStyle(
                                            color: isFollowing ? AppMainColors.primary : Colors.grey
                                          )
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isFollowing ? AppMainColors.primary : Colors.grey.shade300
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                        ),
                                      );
                                    }
                                  );
                                }
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Info Sections
                      _buildDetailSection('Thông tin cơ bản', [
                        _buildDetailRow(Icons.email, 'Email', profile.email ?? 'Chưa cập nhật'),
                        if (profile.phone != null) _buildDetailRow(Icons.phone, 'Số điện thoại', profile.phone!),
                        if (profile.dateOfBirth != null) 
                          _buildDetailRow(Icons.cake, 'Tuổi', '${DateTime.now().year - profile.dateOfBirth!.year} tuổi'),
                        if (meta['education'] != null)
                          _buildDetailRow(Icons.school, 'Học vấn', meta['education']),
                        if (workLocations.isNotEmpty)
                          _buildDetailRow(Icons.location_on, 'Khu vực làm việc', workLocations.join(', ')),
                      ],),

                      if (fields.isNotEmpty || tags.isNotEmpty)
                        _buildDetailSection('Kỹ năng & Lĩnh vực', [
                          if (fields.isNotEmpty) ...[
                            const Text('Lĩnh vực quan tâm:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: fields.map((f) => _buildTag(f, isField: true)).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (tags.isNotEmpty) ...[
                            const Text('Tags:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((t) => _buildTag(t)).toList(),
                            ),
                          ],
                        ]),

                      if (experience.isNotEmpty)
                        _buildDetailSection('Kinh nghiệm làm việc', [
                          ...experience.map((exp) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp['company'] ?? 'Công ty',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exp['position'] ?? 'Vị trí',
                                  style: TextStyle(color: AppMainColors.primary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exp['date'] ?? '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                if (exp['description'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(exp['description'], style: const TextStyle(height: 1.4)),
                                ],
                              ],
                            ),
                          )),
                        ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppMainColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppMainColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {bool isField = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isField ? AppMainColors.primary.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: isField ? Border.all(color: AppMainColors.primary.withOpacity(0.2)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isField ? Icons.work : Icons.label,
            size: 12,
            color: isField ? AppMainColors.primary : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isField ? AppMainColors.primary : Colors.black87,
              fontWeight: isField ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredApplicants = _getFilteredApplicants();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách ứng viên',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${filteredApplicants.length} hồ sơ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: Colors.black87),
                if (_statusFilter != 'All' || _dateRange != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredApplicants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.people_outline, size: 48, color: Colors.blue.shade300),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có ứng viên nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_statusFilter != 'All' || _dateRange != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = 'All';
                                _dateRange = null;
                              });
                            },
                            child: const Text('Xóa bộ lọc'),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredApplicants.length,
                  itemBuilder: (context, index) {
                    final applicant = filteredApplicants[index];
                    final profile = _profiles[applicant.userId];

                    if (profile == null) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _showCandidateDetail(profile),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      image: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(profile.avatarUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                                        ? Icon(Icons.person, color: Colors.grey.shade400, size: 30)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              profile.fullName ?? 'Ứng viên',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(applicant.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _getStatusText(applicant.status),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(applicant.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.email ?? 'Chưa cập nhật',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ứng tuyển: ${_formatDate(applicant.appliedAt)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _viewCV(applicant.cvId, applicant.userId, applicant.status),
                                    icon: const Icon(Icons.description_outlined, size: 18),
                                    label: const Text('Xem CV'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      side: const BorderSide(color: Colors.blue),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showCandidateDetail(profile),
                                    icon: const Icon(Icons.person_outline, size: 18),
                                    label: const Text('Profile'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.purple,
                                      side: const BorderSide(color: Colors.purple),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (['pending', 'viewed'].contains(applicant.status.toLowerCase()))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateStatus(applicant.userId, 'Rejected'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        foregroundColor: Colors.red,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Từ chối'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateStatus(applicant.userId, 'Accepted'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade50,
                                        foregroundColor: Colors.green,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Đồng ý'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (['accepted', 'rejected'].contains(applicant.status.toLowerCase()))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _deleteApplication(applicant.userId),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text('Xóa ứng viên'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade100,
                                    foregroundColor: Colors.grey.shade700,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
