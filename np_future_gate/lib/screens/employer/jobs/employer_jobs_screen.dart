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

class _EmployerJobsScreenState extends State<EmployerJobsScreen> {
  final JobRepository _jobRepository = JobRepository();
  List<JobModel> _jobs = [];
  bool _isLoading = true;

  // Filters
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _approvalStatusFilter = 'All'; // All, Pending, Approved, Rejected
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final jobs = await _jobRepository.getEmployerJobs(userId);
        setState(() {
          _jobs = jobs;
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

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _getFilteredJobs();

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
                          onPressed: _showFilterDialog,
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
                ],
              ),
            ),

            // Job List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredJobs.isEmpty
                      ? Center(
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
                        )
                      : RefreshIndicator(
                          onRefresh: _loadJobs,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredJobs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) => _buildJobCard(filteredJobs[index]),
                          ),
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

  Widget _buildJobCard(JobModel job) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                      child: Text(
                        job.metadata.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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
