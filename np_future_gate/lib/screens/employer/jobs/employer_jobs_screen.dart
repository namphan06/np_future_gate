import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/job_model.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/app_main_colors.dart';
import 'edit_job_screen.dart';
import 'job_applicants_screen.dart';

class EmployerJobsScreen extends StatefulWidget {
  const EmployerJobsScreen({super.key});

  @override
  State<EmployerJobsScreen> createState() => _EmployerJobsScreenState();
}

class _EmployerJobsScreenState extends State<EmployerJobsScreen> with SingleTickerProviderStateMixin {
  final JobRepository _jobRepository = JobRepository();
  List<JobModel> _jobs = [];
  List<JobModel> _partnershipJobs = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  // School info for partnership jobs
  Map<String, Map<String, dynamic>> _schoolInfo = {}; // school_id -> {name, email, ...}
  Map<String, String> _jobToSchoolMap = {}; // job_id -> school_id

  // Filters
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _approvalStatusFilter = 'All'; // All, Pending, Approved, Rejected
  DateTimeRange? _dateRange;
  List<String> _selectedSchools = []; // For filtering partnership jobs by school

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        // Load both regular jobs and partnership jobs in parallel
        final results = await Future.wait([
          _jobRepository.getEmployerJobs(userId),
          _jobRepository.getEmployerPartnershipJobs(userId),
        ]);
        
        final partnershipJobs = results[1] as List<JobModel>;
        
        // Fetch school info for partnership jobs
        if (partnershipJobs.isNotEmpty) {
          // Query school_partnership_jobs to get school_id and build mapping
          final partnershipJobsData = await Supabase.instance.client
              .from('school_partnership_jobs')
              .select('id, school_id')
              .eq('company_id', userId)
              .eq('company_status', 'accepted')
              .eq('admin_status', 'approved');
          
          // Build job to school mapping
          final jobToSchoolMap = <String, String>{};
          final schoolIds = <String>{};
          
          for (var data in partnershipJobsData as List) {
            final jobId = data['id'] as String;
            final schoolId = data['school_id'] as String;
            jobToSchoolMap[jobId] = schoolId;
            schoolIds.add(schoolId);
          }
          
          if (schoolIds.isNotEmpty) {
            // Fetch school profiles
            final schoolProfiles = await Supabase.instance.client
                .from('profiles')
                .select('id, full_name, email, metadata')
                .filter('id', 'in', schoolIds.toList());
            
            final schoolInfoMap = <String, Map<String, dynamic>>{};
            for (var profile in schoolProfiles) {
              schoolInfoMap[profile['id']] = profile;
            }
            
            setState(() {
              _schoolInfo = schoolInfoMap;
              _jobToSchoolMap = jobToSchoolMap;
            });
          }
        }
        
        setState(() {
          _jobs = results[0];
          _partnershipJobs = partnershipJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  List<JobModel> _getFilteredJobs() {
    return _jobs.where((job) {
      // Search
      final matchesSearch = job.metadata.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.metadata.requirementsTags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      // Status Filter
      bool matchesStatus = true;
      if (_statusFilter == 'Active') matchesStatus = job.isActive;
      if (_statusFilter == 'Inactive') matchesStatus = !job.isActive;

      // Approval Status Filter
      bool matchesApproval = true;
      if (_approvalStatusFilter != 'All') {
        matchesApproval = job.status.toLowerCase() == _approvalStatusFilter.toLowerCase();
      }

      // Date Range
      bool matchesDate = true;
      if (_dateRange != null && job.createdAt != null) {
        matchesDate = job.createdAt!.isAfter(_dateRange!.start) &&
            job.createdAt!.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesApproval && matchesDate;
    }).toList();
  }

  List<JobModel> _getFilteredPartnershipJobs() {
    return _partnershipJobs.where((job) {
      // Search
      final matchesSearch = job.metadata.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.metadata.requirementsTags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      // Status Filter
      bool matchesStatus = true;
      if (_statusFilter == 'Active') matchesStatus = job.isActive;
      if (_statusFilter == 'Inactive') matchesStatus = !job.isActive;

      // Approval Status Filter
      bool matchesApproval = true;
      if (_approvalStatusFilter != 'All') {
        matchesApproval = job.status.toLowerCase() == _approvalStatusFilter.toLowerCase();
      }

      // Date Range
      bool matchesDate = true;
      if (_dateRange != null && job.createdAt != null) {
        matchesDate = job.createdAt!.isAfter(_dateRange!.start) &&
            job.createdAt!.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }

      // School Filter (specific to partnership jobs)
      bool matchesSchool = true;
      if (_selectedSchools.isNotEmpty && job.id != null) {
        final schoolId = _jobToSchoolMap[job.id];
        matchesSchool = schoolId != null && _selectedSchools.contains(schoolId);
      }

      return matchesSearch && matchesStatus && matchesApproval && matchesDate && matchesSchool;
    }).toList();
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      await _jobRepository.deleteJob(jobId);
      _loadJobs(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting job: $e')),
        );
      }
    }
  }

  void _showPartnershipFilterDialog() {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Lọc việc làm đối tác'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trạng thái hiển thị'),
              DropdownButton<String>(
                value: _statusFilter,
                isExpanded: true,
                items: ['All', 'Active', 'Inactive']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == 'All'
                              ? 'Tất cả'
                              : e == 'Active'
                                  ? 'Đang hiển thị'
                                  : 'Đã ẩn'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
              const SizedBox(height: 16),
              const Text('Trạng thái duyệt'),
              DropdownButton<String>(
                value: _approvalStatusFilter,
                isExpanded: true,
                items: ['All', 'Pending', 'Approved', 'Rejected']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == 'All'
                              ? 'Tất cả'
                              : e == 'Pending'
                                  ? 'Đang chờ duyệt'
                                  : e == 'Approved'
                                      ? 'Đã duyệt'
                                      : 'Từ chối'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _approvalStatusFilter = v!),
              ),
              const SizedBox(height: 16),
              const Text('Khoảng thời gian'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dateRange == null
                    ? 'Chọn khoảng thời gian'
                    : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'),
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Trường đối tác', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_schoolInfo.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Chưa có trường đối tác nào', style: TextStyle(color: Colors.grey)),
                )
              else
                ..._schoolInfo.entries.map((entry) {
                  final schoolId = entry.key;
                  final schoolData = entry.value;
                  final schoolName = schoolData['full_name'] ?? 'Trường đối tác';
                  final isSelected = _selectedSchools.contains(schoolId);
                  
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(schoolName),
                    subtitle: schoolData['email'] != null 
                        ? Text(schoolData['email'], style: const TextStyle(fontSize: 12))
                        : null,
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSchools.add(schoolId);
                        } else {
                          _selectedSchools.remove(schoolId);
                        }
                      });
                      this.setState(() {}); // Update parent
                    },
                    activeColor: AppMainColors.primary,
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _statusFilter = 'All';
                _approvalStatusFilter = 'All';
                _dateRange = null;
                _selectedSchools.clear();
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

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _getFilteredJobs();
    final filteredPartnershipJobs = _getFilteredPartnershipJobs();

    return Scaffold(
      // backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              // color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý việc làm',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Danh sách việc làm đã đăng',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            // Check which tab is active and show appropriate filter dialog
                            if (_tabController.index == 0) {
                              _showFilterDialog(); // Regular jobs
                            } else {
                              _showPartnershipFilterDialog(); // Partnership jobs with school filter
                            }
                          },
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm theo tiêu đề hoặc tags...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tab Bar
                  Container(
                    height: 45,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppMainColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppMainColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black54,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: 'Tin thường'),
                        Tab(text: 'Tin đối tác'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Job List with TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Regular Jobs Tab
                  _buildJobList(filteredJobs, isPartnershipJobs: false),
                  // Partnership Jobs Tab
                  _buildJobList(filteredPartnershipJobs, isPartnershipJobs: true),
                ],
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _navigateToEditJob(),
      //   backgroundColor: AppMainColors.primary,
      //   icon: const Icon(Icons.add),
      //   label: const Text('Đăng tin mới'),
      // ),
    );
  }

  Widget _buildJobList(List<JobModel> jobs, {bool isPartnershipJobs = false}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có việc làm nào',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildJobCard(jobs[index], isPartnershipJob: isPartnershipJobs),
      ),
    );
  }

  Widget _buildJobCard(JobModel job, {bool isPartnershipJob = false}) {
    final isIntern = job.metadata.isIntern;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isIntern ? Border.all(
          color: Colors.deepPurple.withOpacity(0.3),
          width: 2,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.metadata.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (isIntern) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school,
                                    size: 14,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chương trình thực tập',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusChip(
                      label: job.isActive ? 'Đang hiển thị' : 'Đã ẩn',
                      color: job.isActive ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today, 'Hạn: ${job.deadline?.toString().split(' ')[0] ?? 'Không'}'),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.access_time, 'Đăng: ${job.createdAt?.toString().split(' ')[0] ?? 'Unknown'}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusChip(
                      label: _getApprovalStatusText(job.status),
                      color: _getApprovalStatusColor(job.status),
                      isOutline: true,
                    ),
                    const Spacer(),
                    Text(
                      '${job.applicants.length} ứng viên',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppMainColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobApplicantsScreen(
                            jobId: job.id!,
                            applicants: job.applicants,
                            isPartnershipJob: isPartnershipJob,
                          ),
                        ),
                      ).then((_) => _loadJobs());
                    },
                    icon: const Icon(Icons.people_outline, size: 20),
                    label: const Text('Xem ứng viên'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppMainColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _navigateToEditJob(job: job),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Sửa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _confirmDelete(job.id!),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatusChip({required String label, required Color color, bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: isOutline ? Border.all(color: color) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getApprovalStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return 'Đã duyệt';
      case 'rejected': return 'Từ chối';
      case 'closed': return 'Đã đóng';
      default: return 'Đang chờ duyệt';
    }
  }

  Color _getApprovalStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Lọc việc làm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trạng thái hiển thị'),
              DropdownButton<String>(
                value: _statusFilter,
                isExpanded: true,
                items: ['All', 'Active', 'Inactive']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == 'All'
                              ? 'Tất cả'
                              : e == 'Active'
                                  ? 'Đang hiển thị'
                                  : 'Đã ẩn'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
              const SizedBox(height: 16),
              const Text('Trạng thái duyệt'),
              DropdownButton<String>(
                value: _approvalStatusFilter,
                isExpanded: true,
                items: ['All', 'Pending', 'Approved', 'Rejected']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == 'All'
                              ? 'Tất cả'
                              : e == 'Pending'
                                  ? 'Đang chờ duyệt'
                                  : e == 'Approved'
                                      ? 'Đã duyệt'
                                      : 'Từ chối'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _approvalStatusFilter = v!),
              ),
              const SizedBox(height: 16),
              const Text('Khoảng thời gian'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dateRange == null
                    ? 'Chọn khoảng thời gian'
                    : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'),
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
                  _approvalStatusFilter = 'All';
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

  void _navigateToEditJob({JobModel? job}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditJobScreen(job: job),
      ),
    );

    if (result == true) {
      _loadJobs();
    }
  }

  void _confirmDelete(String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa việc làm'),
        content: const Text('Bạn có chắc chắn muốn xóa việc làm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJob(jobId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
