import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/models/job_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/repositories/candidate_repository.dart';
import '../../../core/repositories/interview_repository.dart';
import '../../../core/services/cv_supabase_service.dart';
import '../../../core/services/emailjs_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/notification/application_notification_service.dart';
import '../../cv/cv_setting/cv_display_manager.dart';
import '../../../core/theme/app_main_colors.dart';
import '../../../core/services/ai_matching_service.dart';
import 'cv_analysis_screen.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final List<JobApplication> applicants;
  final bool isPartnershipJob;
  final bool isReadOnly; // New flag for read-only mode

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.applicants,
    this.isPartnershipJob = false,
    this.isReadOnly = false, // Default to false
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
  final EmailJsService _emailService = EmailJsService();
  final ApplicationNotificationService _notificationService = ApplicationNotificationService();
  
  Map<String, Profile> _profiles = {};
  bool _isLoading = true;
  late List<JobApplication> _currentApplicants;
  String? _jobTitle;
  JobModel? _jobModel;
  
  // Filters
  String _statusFilter = 'All';
  DateTimeRange? _dateRange;
  final AIMatchingService _aiMatchingService = AIMatchingService();
  final Set<String> _selectedUserIds = {};
  bool _isSelectionMode = false;

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
      // Use appropriate method based on job type
      final job = widget.isPartnershipJob
          ? await _jobRepository.getPartnershipJobById(widget.jobId)
          : await _jobRepository.getJobById(widget.jobId);
          
      if (job != null) {
        setState(() {
          _jobTitle = job.metadata.title;
          _jobModel = job;
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
          // Check for interview conflicts
          final conflictingInterview = await _interviewRepository.checkInterviewConflict(
            employerId,
            interviewTime,
          );

          if (conflictingInterview != null) {
            // Show conflict warning
            if (mounted) {
              final shouldContinue = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Trùng lịch phỏng vấn'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bạn đã có lịch phỏng vấn vào thời gian này:'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conflictingInterview.jobTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(conflictingInterview.interviewTime)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Vui lòng chọn thời gian khác.'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Đóng'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppMainColors.primary,
                      ),
                      child: const Text('Chọn lại giờ'),
                    ),
                  ],
                ),
              );

              if (shouldContinue == true) {
                // Recursively call _updateStatus to pick new time
                return _updateStatus(userId, newStatus);
              }
            }
            return; // Stop if user doesn't want to pick new time
          }

          // No conflict - proceed with creating interview
          await _interviewRepository.createInterview(
            candidateId: userId,
            jobId: widget.jobId,
            employerId: employerId,
            cvId: applicant.cvId,
            interviewTime: interviewTime,
            jobTitle: _jobTitle!,
            isPartnershipJob: widget.isPartnershipJob,
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
      // Use appropriate method based on job type
      if (widget.isPartnershipJob) {
        await _jobRepository.updatePartnershipApplicationStatus(widget.jobId, userId, newStatus);
      } else {
        await _jobRepository.updateApplicationStatus(widget.jobId, userId, newStatus);
      }
      
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
      
      // Send notification to candidate based on status
      try {
        final employerProfile = await _candidateRepository.getProfileById(_authRepository.currentUser!.id);
        final employerName = employerProfile?.fullName ?? 'Nhà tuyển dụng';
        
        if (newStatus.toLowerCase() == 'accepted') {
          // Send approved notification
          await _notificationService.notifyApplicationApproved(
            candidateId: userId,
            jobId: widget.jobId,
            jobTitle: _jobTitle ?? 'Công việc',
            employerName: employerName,
          );
          print('✅ Sent application approved notification to candidate $userId');
        } else if (newStatus.toLowerCase() == 'rejected') {
          // Send rejected notification
          await _notificationService.notifyApplicationRejected(
            candidateId: userId,
            jobId: widget.jobId,
            jobTitle: _jobTitle ?? 'Công việc',
            employerName: employerName,
          );
          print('✅ Sent application rejected notification to candidate $userId');
        }
      } catch (e) {
        print('⚠️ Error sending notification to candidate: $e');
        // Don't show error to user - notification is not critical
      }
      
      // Send rejection email if status is 'rejected'
      if (newStatus.toLowerCase() == 'rejected') {
        await _sendRejectionEmail(userId);
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
      // Use appropriate method based on job type
      if (widget.isPartnershipJob) {
        await _jobRepository.deletePartnershipApplication(widget.jobId, userId);
      } else {
        await _jobRepository.deleteApplication(widget.jobId, userId);
      }
      
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

      // Use getCVFullDataForEmployer for employer access
      final cvData = await _cvService.getCVFullDataForEmployer(cvId);
      
      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      if (cvData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CVDisplayManager.buildViewWidget(context, cvData),
          ),
        );
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

  Future<void> _analyzeAI(JobApplication applicant, Profile profile) async {
    if (_jobModel == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final cvData = await _cvService.getCVFullDataForEmployer(applicant.cvId);
      if (mounted) Navigator.pop(context);

      if (cvData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CVAnalysisScreen(
              job: _jobModel!,
              cvData: cvData,
              applicantName: profile.fullName ?? 'Ứng viên',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedUserIds.clear();
    });
  }

  Future<void> _compareSelectedCVs() async {
    if (_selectedUserIds.length < 2 || _jobModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 2 ứng viên để so sánh')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final List<Map<String, dynamic>> cvsToCompare = [];
      for (final userId in _selectedUserIds) {
        final applicant = widget.applicants.firstWhere((a) => a.userId == userId);
        final data = await _cvService.getCVFullDataForEmployer(applicant.cvId);
        if (data != null) cvsToCompare.add(data);
      }

      final comparisonResult = await _aiMatchingService.compareCVs(
        cvsData: cvsToCompare,
        job: _jobModel!,
      );

      if (mounted) {
        Navigator.pop(context);
        _showComparisonResult(comparisonResult);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showComparisonResult(String result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_outlined, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'So sánh ứng viên (AI)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Phân tích dựa trên kỹ năng, kinh nghiệm và yêu cầu công việc.',
                              style: TextStyle(fontSize: 13, color: Colors.orange, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      result,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRejectionEmail(String userId) async {
    try {
      final profile = _profiles[userId];
      if (profile == null || profile.email == null) {
        print('Cannot send rejection email: profile or email not found for user $userId');
        return;
      }

      final candidateName = profile.fullName ?? 'Ứng viên';
      final candidateEmail = profile.email!;
      final jobTitle = _jobTitle ?? 'Vị trí ứng tuyển';
      
      // Get employer profile to get the full name
      final employerProfile = await _authRepository.getCurrentUserProfile();
      final employerId = employerProfile?.id;
      final employerName = employerProfile?.fullName ?? 'Nhà tuyển dụng';
      final companyName = employerProfile?.metadata['company_name'] ?? employerName;

      if (employerId == null) {
        print('Cannot send rejection email: employer not found');
        return;
      }

      // Load template from database
      final templateResponse = await SupabaseService.instance.client
          .from('email_templates')
          .select()
          .eq('employer_id', employerId)
          .eq('response_type', 'rejected')
          .maybeSingle();

      // Prepare all variable values from job model
      final jobField = _jobModel?.metadata.fields.join(', ') ?? '';
      final jobLocation = _jobModel?.metadata.workLocations.join(', ') ?? '';
      final salaryRange = _jobModel != null ? _formatSalaryRange(_jobModel!.metadata.salary) : '';
      final employmentType = _jobModel?.metadata.employmentTypes.join(', ') ?? '';
      final companyAddress = employerProfile?.metadata['company_address'] ?? '';

      String subject;
      String messageBody;

      if (templateResponse != null) {
        // Use template from database
        subject = templateResponse['subject'] as String? ?? 'Thông báo kết quả ứng tuyển';
        messageBody = templateResponse['body'] as String? ?? '';

        // Replace ALL variables in subject and body
        subject = _replaceTemplateVariables(
          subject,
          candidateName: candidateName,
          candidateEmail: candidateEmail,
          candidatePhone: profile.phone ?? '',
          jobTitle: jobTitle,
          jobField: jobField,
          jobLocation: jobLocation,
          salaryRange: salaryRange,
          employmentType: employmentType,
          companyName: companyName,
          employerEmail: employerProfile?.email ?? '',
          employerPhone: employerProfile?.phone ?? '',
          companyAddress: companyAddress,
        );

        messageBody = _replaceTemplateVariables(
          messageBody,
          candidateName: candidateName,
          candidateEmail: candidateEmail,
          candidatePhone: profile.phone ?? '',
          jobTitle: jobTitle,
          jobField: jobField,
          jobLocation: jobLocation,
          salaryRange: salaryRange,
          employmentType: employmentType,
          companyName: companyName,
          employerEmail: employerProfile?.email ?? '',
          employerPhone: employerProfile?.phone ?? '',
          companyAddress: companyAddress,
        );

        print('📧 Using custom template for rejection email');
      } else {
        // Fallback to default template
        subject = 'Thông báo kết quả ứng tuyển - $jobTitle';
        messageBody = '''
Kính gửi $candidateName,

Cảm ơn bạn đã quan tâm và ứng tuyển vào vị trí "$jobTitle" tại công ty chúng tôi.

Sau khi xem xét hồ sơ của bạn, chúng tôi rất tiếc phải thông báo rằng hồ sơ của bạn chưa phù hợp với yêu cầu của vị trí này tại thời điểm hiện tại.

Chúng tôi đánh giá cao sự quan tâm của bạn và hy vọng sẽ có cơ hội hợp tác trong tương lai.

Chúc bạn thành công trong sự nghiệp!

Trân trọng,
$employerName
''';
        print('📧 Using default rejection email template');
      }
      // Get attachments from template 
      List<Map<String, dynamic>> attachments = [];
      if (templateResponse != null) {
        final attachmentsData = templateResponse['attachments'];
        if (attachmentsData != null && attachmentsData is List) {
          attachments = List<Map<String, dynamic>>.from(
            attachmentsData.map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      final success = await _emailService.sendEmployerResponse(
        toEmail: candidateEmail,
        toName: candidateName,
        subject: subject,
        messageBody: messageBody,
        attachments: attachments.isNotEmpty ? attachments : null,
      );

      if (success) {
        print('✅ Rejection email sent successfully to $candidateEmail');
      } else {
        print('⚠️ Failed to send rejection email to $candidateEmail');
      }
    } catch (e) {
      print('❌ Error sending rejection email: $e');
      // Don't show error to user as this is a background operation
    }
  }

  /// Replace all template variables in a text string
  String _replaceTemplateVariables(
    String text, {
    required String candidateName,
    required String candidateEmail,
    required String candidatePhone,
    required String jobTitle,
    required String jobField,
    required String jobLocation,
    required String salaryRange,
    required String employmentType,
    required String companyName,
    required String employerEmail,
    required String employerPhone,
    required String companyAddress,
    String interviewDate = '',
    String interviewTime = '',
    String interviewLocation = '',
    String interviewType = '',
  }) {
    return text
        // Candidate variables
        .replaceAll('{{candidate_name}}', candidateName)
        .replaceAll('{{candidate_email}}', candidateEmail)
        .replaceAll('{{candidate_phone}}', candidatePhone)
        // Job variables
        .replaceAll('{{job_title}}', jobTitle)
        .replaceAll('{{job_field}}', jobField)
        .replaceAll('{{job_location}}', jobLocation)
        .replaceAll('{{salary_range}}', salaryRange)
        .replaceAll('{{employment_type}}', employmentType)
        // Company variables
        .replaceAll('{{company_name}}', companyName)
        .replaceAll('{{employer_email}}', employerEmail)
        .replaceAll('{{employer_phone}}', employerPhone)
        .replaceAll('{{company_address}}', companyAddress)
        // Interview variables
        .replaceAll('{{interview_date}}', interviewDate)
        .replaceAll('{{interview_time}}', interviewTime)
        .replaceAll('{{interview_location}}', interviewLocation)
        .replaceAll('{{interview_type}}', interviewType);
  }

  /// Format salary range for template variable
  String _formatSalaryRange(JobSalary salary) {
    if (salary.isNegotiable) return 'Thỏa thuận';
    if (salary.min != null && salary.max != null) {
      return '${salary.min!.toStringAsFixed(0)} - ${salary.max!.toStringAsFixed(0)} ${salary.currency}';
    }
    if (salary.min != null) {
      return 'Từ ${salary.min!.toStringAsFixed(0)} ${salary.currency}';
    }
    if (salary.max != null) {
      return 'Đến ${salary.max!.toStringAsFixed(0)} ${salary.currency}';
    }
    return 'Thỏa thuận';
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
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.compare_arrows, color: Colors.blue),
            onPressed: _toggleSelectionMode,
          ),
        ],
      ),
      bottomNavigationBar: _selectedUserIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton.icon(
                onPressed: _compareSelectedCVs,
                icon: const Icon(Icons.analytics, color: Colors.white),
                label: Text('So sánh ${_selectedUserIds.length} ứng viên chọn lọc (AI)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppMainColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          : null,
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
                                if (_isSelectionMode)
                                  Checkbox(
                                    value: _selectedUserIds.contains(applicant.userId),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedUserIds.add(applicant.userId);
                                        } else {
                                          _selectedUserIds.remove(applicant.userId);
                                        }
                                      });
                                    },
                                  ),
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
                                const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _analyzeAI(applicant, profile),
                                      icon: const Icon(Icons.auto_awesome, size: 18),
                                      label: const Text('Phân tích AI'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                        side: const BorderSide(color: Colors.orange),
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
                          if (['pending', 'viewed'].contains(applicant.status.toLowerCase()) && !widget.isReadOnly)
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
                          if (widget.isReadOnly)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _viewEvaluation(profile.id, profile.fullName ?? 'Ứng viên'),
                                  icon: const Icon(Icons.star_outline, size: 18),
                                  label: const Text('Xem đánh giá'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
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

  // View evaluation from interview_schedules
  Future<void> _viewEvaluation(String userId, String candidateName) async {
    print('🔍 ========== VIEW EVALUATION DEBUG ==========');
    print('📋 Input Parameters:');
    print('   candidateId: $userId');
    print('   jobId: ${widget.jobId}');
    print('   candidateName: $candidateName');
    
    try {
      // Get evaluation from repository
      print('⏳ Calling repository.getEvaluationForCandidate()...');
      final evaluationData = await _interviewRepository.getEvaluationForCandidate(
        candidateId: userId,
        jobId: widget.jobId,
      );

      print('📦 Repository Response:');
      if (evaluationData == null) {
        print('   ❌ Result: NULL (No interview found)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chưa có lịch phỏng vấn cho ứng viên này')),
          );
        }
        return;
      }

      print('   ✅ Result: Data found');
      print('   📊 Keys: ${evaluationData.keys.toList()}');
      print('   🔓 is_shared: ${evaluationData['is_shared']}');
      print('   📝 evaluation: ${evaluationData['evaluation']}');
      print('   🕐 interview_time: ${evaluationData['interview_time']}');

      final isShared = evaluationData['is_shared'] as bool;
      
      if (!isShared) {
        print('   🔒 Share status: FALSE - showing locked dialog');
        if (mounted) {
          _showNotSharedDialog(candidateName);
        }
        return;
      }

      print('   ✅ Share status: TRUE - showing evaluation detail');
      // Show evaluation detail
      final evaluation = evaluationData['evaluation'] as Map<String, dynamic>;
      final interviewTime = evaluationData['interview_time'] as String;
      
      if (mounted) {
        _showEvaluationDetail(candidateName, evaluation, interviewTime);
      }
      print('🔍 ========== END DEBUG ==========');
    } catch (e, stackTrace) {
      print('❌ ERROR in _viewEvaluation:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải đánh giá: $e')),
        );
      }
    }
  }

  void _showNotSharedDialog(String candidateName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 12),
            Text('Đánh giá không được chia sẻ'),
          ],
        ),
        content: Text(
          'Nhà tuyển dụng không cho phép chia sẻ thông tin đánh giá cho ứng viên $candidateName',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showEvaluationDetail(String candidateName, Map<String, dynamic> evaluation, String interviewTime) {
    final rating = (evaluation['rating'] as num?)?.toDouble() ?? 0;
    final envRating = (evaluation['environment_rating'] as num?)?.toDouble() ?? 0;
    final posRating = (evaluation['position_rating'] as num?)?.toDouble() ?? 0;
    final potRating = (evaluation['potential_rating'] as num?)?.toDouble() ?? 0;
    final commRating = (evaluation['communication_rating'] as num?)?.toDouble() ?? 0;
    final tags = (evaluation['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final note = evaluation['note'] as String? ?? '';
    final reqEval = evaluation['requirements_evaluation'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đánh giá ứng viên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              candidateName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppMainColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rating.toStringAsFixed(1)}/10',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppMainColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Overall Ratings
                    const Text(
                      'Đánh giá tổng quát',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildEvalRatingRow('Xếp hạng chung', rating),
                    _buildEvalRatingRow('Môi trường làm việc', envRating),
                    _buildEvalRatingRow('Phù hợp với vị trí', posRating),
                    _buildEvalRatingRow('Tiềm năng phát triển', potRating),
                    _buildEvalRatingRow('Kỹ năng giao tiếp', commRating),
                    const SizedBox(height: 20),

                    // Requirements Evaluation
                    if (reqEval.isNotEmpty) ...[
                      const Text(
                        'Đánh giá yêu cầu công việc',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...reqEval.entries.map((e) => _buildEvalRatingRow(e.key, (e.value as num?)?.toDouble() ?? 0)),
                      const SizedBox(height: 20),
                    ],

                    // Tags
                    if (tags.isNotEmpty) ...[
                      const Text(
                        'Ghi chú đặc biệt',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppMainColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppMainColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: AppMainColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Note
                    if (note.isNotEmpty) ...[
                      const Text(
                        'Nhận xét',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          note,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalRatingRow(String label, double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppMainColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${rating.toStringAsFixed(1)}/10',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppMainColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rating / 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  rating >= 8 ? Colors.green : rating >= 6 ? Colors.orange : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
