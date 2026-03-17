import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/job_model.dart';
import '../../core/repositories/job_repository.dart';
import '../candidate/job_detail_screen.dart';
import '../../core/services/chat_service.dart';
import '../chat/chat_detail_screen.dart';

class JobApprovalPageAdmin extends StatefulWidget {
  const JobApprovalPageAdmin({super.key});

  @override
  State<JobApprovalPageAdmin> createState() => _JobApprovalPageAdminState();
}

class _JobApprovalPageAdminState extends State<JobApprovalPageAdmin>
    with SingleTickerProviderStateMixin {
  final JobRepository _jobRepository = JobRepository();
  
  // Regular jobs
  List<JobModel> _pendingJobs = [];
  bool _isLoadingRegular = false;
  String? _errorMessageRegular;
  
  // Partnership jobs
  List<Map<String, dynamic>> _pendingPartnershipJobs = [];
  bool _isLoadingPartnership = false;
  String? _errorMessagePartnership;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update header count
    });
    _loadPendingJobs();
    _loadPendingPartnershipJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingJobs() async {
    setState(() {
      _isLoadingRegular = true;
      _errorMessageRegular = null;
    });

    try {
      final jobs = await _jobRepository.getPendingJobs();
      if (mounted) {
        setState(() {
          _pendingJobs = jobs;
          _isLoadingRegular = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessageRegular = e.toString();
          _isLoadingRegular = false;
        });
      }
    }
  }

  Future<void> _loadPendingPartnershipJobs() async {
    setState(() {
      _isLoadingPartnership = true;
      _errorMessagePartnership = null;
    });

    try {
      final jobs = await _jobRepository.getPendingPartnershipJobs();
      if (mounted) {
        setState(() {
          _pendingPartnershipJobs = jobs;
          _isLoadingPartnership = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessagePartnership = e.toString();
          _isLoadingPartnership = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadPendingJobs(),
      _loadPendingPartnershipJobs(),
    ]);
  }

  // Regular job actions
  Future<void> _approveJob(JobModel job) async {
    try {
      await _jobRepository.approveJob(job.id!);
      if (mounted) {
        _showSuccessSnackbar('Đã duyệt việc làm thành công!');
        _loadPendingJobs();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Lỗi: $e');
      }
    }
  }

  Future<void> _rejectJob(JobModel job) async {
    final confirmed = await _showConfirmDialog(
      'Xác nhận từ chối',
      'Bạn có chắc muốn từ chối việc làm "${job.metadata.title}"?',
    );
    if (confirmed != true) return;

    try {
      await _jobRepository.rejectJob(job.id!);
      if (mounted) {
        _showWarningSnackbar('Đã từ chối việc làm');
        _loadPendingJobs();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Lỗi: $e');
      }
    }
  }

  // Partnership job actions
  Future<void> _approvePartnershipJob(Map<String, dynamic> job) async {
    try {
      await _jobRepository.approvePartnershipJob(job['id']);
      if (mounted) {
        _showSuccessSnackbar('Đã duyệt việc làm liên kết thành công!');
        _loadPendingPartnershipJobs();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Lỗi: $e');
      }
    }
  }

  Future<void> _rejectPartnershipJob(Map<String, dynamic> job) async {
    final metadata = job['metadata'] as Map<String, dynamic>?;
    final title = metadata?['title'] ?? 'Không rõ';
    
    final confirmed = await _showConfirmDialog(
      'Xác nhận từ chối',
      'Bạn có chắc muốn từ chối việc làm liên kết "$title"?',
    );
    if (confirmed != true) return;

    try {
      await _jobRepository.rejectPartnershipJob(job['id']);
      if (mounted) {
        _showWarningSnackbar('Đã từ chối việc làm liên kết');
        _loadPendingPartnershipJobs();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Lỗi: $e');
      }
    }
  }

  // Show company/school info
  void _showCompanyInfo(Map<String, dynamic>? profile, String type) {
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildInfoBottomSheet(profile, type),
    );
  }

  Widget _buildInfoBottomSheet(Map<String, dynamic> profile, String type) {
    final metadata = profile['metadata'] != null 
        ? Map<String, dynamic>.from(profile['metadata'] as Map)
        : null;
    final iconData = type == 'school' ? Icons.school : Icons.business;
    final color = type == 'school' ? Colors.purple : Colors.orange;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == 'school' ? 'Thông tin nhà trường' : 'Thông tin công ty',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile['full_name'] ?? 'Không rõ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact info
          if (profile['email'] != null) ...[
            _buildInfoRow(Icons.email, 'Email', profile['email']),
            const SizedBox(height: 16),
          ],
          if (profile['phone'] != null) ...[
            _buildInfoRow(Icons.phone, 'Số điện thoại', profile['phone']),
            const SizedBox(height: 16),
          ],
          if (metadata != null) ...[
            if (metadata['address'] != null) ...[
              _buildInfoRow(Icons.location_on, 'Địa chỉ', metadata['address']),
              const SizedBox(height: 16),
            ],
            if (metadata['website'] != null) ...[
              _buildInfoRow(Icons.language, 'Website', metadata['website']),
              const SizedBox(height: 16),
            ],
            if (metadata['description'] != null) ...[
              _buildInfoRow(Icons.info_outline, 'Mô tả', metadata['description']),
            ],
          ],

          const SizedBox(height: 24),
          
          // Chat button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                _openChatWithUser(profile, type);
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Nhắn tin trao đổi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Đóng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for dialogs and snackbars
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Flexible(child: Text(title)),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showWarningSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.block, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRegularJobsTab(),
                _buildPartnershipJobsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Total count from BOTH tables
    final totalCount = _pendingJobs.length + _pendingPartnershipJobs.length;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
                  tooltip: 'Quay lại',
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duyệt việc làm',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalCount việc đang chờ duyệt',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _refreshAll,
                  icon: Icon(Icons.refresh, color: Colors.grey.shade700, size: 22),
                  tooltip: 'Làm mới',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildChipTab(
              label: 'Việc thường',
              count: _pendingJobs.length,
              isSelected: _tabController.index == 0,
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildChipTab(
              label: 'Liên kết',
              count: _pendingPartnershipJobs.length,
              isSelected: _tabController.index == 1,
              onTap: () => _tabController.animateTo(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegularJobsTab() {
    if (_isLoadingRegular) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessageRegular != null) {
      return _buildErrorState(_errorMessageRegular!, _loadPendingJobs);
    }

    if (_pendingJobs.isEmpty) {
      return _buildEmptyState('Không có việc làm thường nào cần duyệt');
    }

    return RefreshIndicator(
      onRefresh: _loadPendingJobs,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingJobs.length,
        itemBuilder: (context, index) {
          final job = _pendingJobs[index];
          return _buildRegularJobCard(job);
        },
      ),
    );
  }

  Widget _buildPartnershipJobsTab() {
    if (_isLoadingPartnership) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessagePartnership != null) {
      return _buildErrorState(_errorMessagePartnership!, _loadPendingPartnershipJobs);
    }

    if (_pendingPartnershipJobs.isEmpty) {
      return _buildEmptyState('Không có việc làm liên kết nào cần duyệt');
    }

    return RefreshIndicator(
      onRefresh: _loadPendingPartnershipJobs,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingPartnershipJobs.length,
        itemBuilder: (context, index) {
          final job = _pendingPartnershipJobs[index];
          return _buildPartnershipJobCard(job);
        },
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tất cả đã xong!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularJobCard(JobModel job) {
    final createdAt = job.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(job.createdAt!)
        : 'N/A';
    
    final deadline = job.deadline != null
        ? DateFormat('dd/MM/yyyy').format(job.deadline!)
        : 'N/A';

    // Use real company profile from job
    final companyProfile = job.creatorProfile;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company header - tappable
          InkWell(
            onTap: () => _showCompanyInfo(companyProfile, 'company'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.05), Colors.blue.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: job.creatorAvatarUrl != null
                          ? NetworkImage(job.creatorAvatarUrl!)
                          : null,
                      child: job.creatorAvatarUrl == null
                          ? Icon(Icons.business, color: Colors.blue, size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.creatorName ?? 'Unknown Company',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.touch_app, size: 14, color: Colors.blue.shade400),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              createdAt,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Thường',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Job details
          _buildJobDetails(
            title: job.metadata.title,
            location: job.metadata.workingRegions.join(', '),
            experience: job.metadata.experienceRequired,
            salary: _formatSalary(job.metadata.salary),
            deadline: deadline,
            fields: job.metadata.fields,
          ),

          // Actions
          _buildActionButtons(
            onView: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
            ),
            onApprove: () => _approveJob(job),
            onReject: () => _rejectJob(job),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnershipJobCard(Map<String, dynamic> job) {
    final metadata = job['metadata'] != null 
        ? Map<String, dynamic>.from(job['metadata'] as Map)
        : <String, dynamic>{};
    final schoolProfile = job['school_profile'] as Map<String, dynamic>?;
    final companyProfile = job['company_profile'] as Map<String, dynamic>?;
    
    final createdAt = job['created_at'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(job['created_at']))
        : 'N/A';
    
    final deadline = job['deadline'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(job['deadline']))
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partnership header with both school and company
          _buildPartnershipHeader(
            schoolProfile: schoolProfile,
            companyProfile: companyProfile,
            subtitle: createdAt,
          ),

          // Job details
          _buildJobDetails(
            title: metadata['title'] ?? 'Không rõ',
            location: (metadata['working_regions'] as List?)?.join(', ') ?? 'N/A',
            experience: metadata['experience_required'] ?? 'N/A',
            salary: _formatSalaryFromMetadata(metadata['salary']),
            deadline: deadline,
            fields: (metadata['fields'] as List?)?.cast<String>() ?? [],
          ),

          // Actions
          _buildActionButtons(
            onView: null,
            onApprove: () => _approvePartnershipJob(job),
            onReject: () => _rejectPartnershipJob(job),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnershipHeader({
    required Map<String, dynamic>? schoolProfile,
    required Map<String, dynamic>? companyProfile,
    required String subtitle,
  }) {
    final schoolName = schoolProfile?['full_name'] ?? 'Unknown School';
    final schoolAvatarUrl = schoolProfile?['avatar_url'];
    final companyName = companyProfile?['full_name'] ?? 'Unknown Company';
    final companyAvatarUrl = companyProfile?['avatar_url'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.05), Colors.purple.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // School - tappable
          InkWell(
            onTap: () => _showCompanyInfo(schoolProfile, 'school'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildPartnerAvatar(schoolAvatarUrl, Icons.school, Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      schoolName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.touch_app, size: 14, color: Colors.purple.shade400),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.purple.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.sync_alt, size: 16, color: Colors.purple.shade400),
                ),
                Expanded(child: Divider(color: Colors.purple.shade200)),
              ],
            ),
          ),
          // Company - tappable
          InkWell(
            onTap: () => _showCompanyInfo(companyProfile, 'company'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildPartnerAvatar(companyAvatarUrl, Icons.business, Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, size: 11, color: Colors.purple.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Liên kết',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerAvatar(String? avatarUrl, IconData defaultIcon, Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? Icon(defaultIcon, color: color, size: 20) : null,
      ),
    );
  }

  Widget _buildJobDetails({
    required String title,
    required String location,
    required String experience,
    required String salary,
    required String deadline,
    required List<String> fields,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow2(Icons.location_on, location, Colors.blue),
          const SizedBox(height: 10),
          _buildInfoRow2(Icons.work_outline, experience, Colors.purple),
          const SizedBox(height: 10),
          _buildInfoRow2(Icons.attach_money, salary, Colors.green),
          const SizedBox(height: 10),
          _buildInfoRow2(Icons.calendar_today, 'Hạn nộp: $deadline', Colors.orange),

          if (fields.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fields.take(3).map((field) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    field,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow2(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    VoidCallback? onView,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (onView != null) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Duyệt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  color: Colors.red,
                  tooltip: 'Từ chối',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSalary(JobSalary salary) {
    if (salary.isNegotiable) return 'Thỏa thuận';

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: salary.currency == 'VND' ? '₫' : salary.currency,
      decimalDigits: 0,
    );

    if (salary.min != null && salary.max != null) {
      return '${formatter.format(salary.min)} - ${formatter.format(salary.max)}';
    } else if (salary.min != null) {
      return 'Từ ${formatter.format(salary.min)}';
    } else if (salary.max != null) {
      return 'Lên đến ${formatter.format(salary.max)}';
    }

    return 'Chưa xác định';
  }

  String _formatSalaryFromMetadata(dynamic salaryData) {
    if (salaryData == null) return 'Chưa xác định';
    
    final salary = salaryData as Map<String, dynamic>?;
    if (salary == null) return 'Chưa xác định';
    
    if (salary['is_negotiable'] == true) return 'Thỏa thuận';

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: salary['currency'] == 'VND' ? '₫' : (salary['currency'] ?? ''),
      decimalDigits: 0,
    );

    final min = salary['min'];
    final max = salary['max'];

    if (min != null && max != null) {
      return '${formatter.format(min)} - ${formatter.format(max)}';
    } else if (min != null) {
      return 'Từ ${formatter.format(min)}';
    } else if (max != null) {
      return 'Lên đến ${formatter.format(max)}';
    }

    return 'Chưa xác định';
  }

  Future<void> _openChatWithUser(Map<String, dynamic> profile, String type) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final chatService = ChatService();
      final userId = profile['id'] as String;
      
      // Ensure role is compatible with chat constants
      String mappedType = type;
      if (mappedType == 'company') mappedType = 'employer';

      final conversation = await chatService.getOrCreateConversation(
        otherUserId: userId,
        otherUserType: mappedType,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (conversation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversation: conversation,
              otherUserName: profile['full_name'] ?? 'Người dùng',
              otherUserAvatar: profile['avatar_url'] ?? '',
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo cuộc trò chuyện. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
