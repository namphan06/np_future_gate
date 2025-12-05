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
      appBar: AppBar(
        title: const Text('Posted Jobs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title or tags...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
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
                            const Icon(Icons.work_off_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No jobs found'),
                            if (_jobs.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _navigateToEditJob(),
                                child: const Text('Post a Job'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = filteredJobs[index];
                            return _buildJobCard(job);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditJob(),
        backgroundColor: AppMainColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.metadata.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToEditJob(job: job);
                    } else if (value == 'delete') {
                      _confirmDelete(job.id!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(
                  label: job.isActive ? 'Active' : 'Inactive',
                  color: job.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  label: job.status.toUpperCase(),
                  color: _getApprovalStatusColor(job.status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${job.deadline?.toString().split(' ')[0] ?? 'None'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                Text(
                  'Posted: ${job.createdAt?.toString().split(' ')[0] ?? 'Unknown'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${job.applicants.length} Applicants',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobApplicantsScreen(
                          jobId: job.id!,
                          applicants: job.applicants,
                        ),
                      ),
                    ).then((_) => _loadJobs()); // Refresh on return
                  },
                  icon: const Icon(Icons.people_outline),
                  label: const Text('View Applicants'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
          title: const Text('Filter Jobs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status'),
              DropdownButton<String>(
                value: _statusFilter,
                isExpanded: true,
                items: ['All', 'Active', 'Inactive']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
              const SizedBox(height: 16),
              const Text('Approval Status'),
              DropdownButton<String>(
                value: _approvalStatusFilter,
                isExpanded: true,
                items: ['All', 'Pending', 'Approved', 'Rejected']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _approvalStatusFilter = v!),
              ),
              const SizedBox(height: 16),
              const Text('Date Range'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dateRange == null
                    ? 'Select Date Range'
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
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {}); // Update parent state
                Navigator.pop(context);
              },
              child: const Text('Apply'),
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
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJob(jobId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
