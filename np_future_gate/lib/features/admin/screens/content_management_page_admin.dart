import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/admin/screens/user_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContentManagementPageAdmin extends StatefulWidget {
  const ContentManagementPageAdmin({super.key});

  @override
  State<ContentManagementPageAdmin> createState() => _ContentManagementPageAdminState();
}

class _ContentManagementPageAdminState extends State<ContentManagementPageAdmin> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _mainTabController;
  
  int _employerJobsPendingCount = 0;
  int _schoolRegularJobsPendingCount = 0;
  int _schoolPartnershipJobsPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _loadPendingCounts();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingCounts() async {
    try {
      // Count employer jobs
      final employerJobsData = await _supabase
          .from('jobs')
          .select('id, creator_id')
          .eq('status', 'pending');
      
      // Filter employer jobs (check role from profiles)
      int employerCount = 0;
      int schoolRegularCount = 0;
      
      for (var job in employerJobsData as List) {
        final creatorId = job['creator_id'];
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', creatorId)
            .single();
        
        if (profile['role'] == 'employer') {
          employerCount++;
        } else if (profile['role'] == 'school') {
          schoolRegularCount++;
        }
      }
      
      // Count school partnership jobs
      final partnershipJobs = await _supabase
          .from('school_partnership_jobs')
          .select('id')
          .eq('admin_status', 'pending');
      
      if (mounted) {
        setState(() {
          _employerJobsPendingCount = employerCount;
          _schoolRegularJobsPendingCount = schoolRegularCount;
          _schoolPartnershipJobsPendingCount = (partnershipJobs as List).length;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _employerJobsPendingCount + _schoolRegularJobsPendingCount + _schoolPartnershipJobsPendingCount;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duyệt việc làm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '$totalPending việc đang chờ duyệt',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              _loadPendingCounts();
              setState(() {});
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildMainTabButton('NTD', _employerJobsPendingCount, 0),
                const SizedBox(width: 12),
                _buildMainTabButton('Trường', _schoolRegularJobsPendingCount + _schoolPartnershipJobsPendingCount, 1),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildEmployerJobsList(),
          _buildSchoolTabView(),
        ],
      ),
    );
  }

  Widget _buildMainTabButton(String label, int count, int index) {
    final isActive = _mainTabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _mainTabController.animateTo(index);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppMainColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey.shade700,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppMainColors.primary : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployerJobsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('jobs')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allJobs = snapshot.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _filterEmployerJobs(allJobs),
          builder: (context, filteredSnapshot) {
            if (!filteredSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final jobs = filteredSnapshot.data!;

            if (jobs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                return _buildJobCard(jobs[index], 'employer');
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _filterEmployerJobs(List<Map<String, dynamic>> jobs) async {
    final employerJobs = <Map<String, dynamic>>[];
    
    for (var job in jobs) {
      final creatorId = job['creator_id'];
      try {
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', creatorId)
            .single();
        
        if (profile['role'] == 'employer') {
          employerJobs.add(job);
        }
      } catch (e) {
        // Skip if error
      }
    }
    
    return employerJobs;
  }

  Widget _buildSchoolTabView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Builder(
                builder: (context) {
                  // Use TabController directly from context
                  return TabBar(
                    controller: DefaultTabController.of(context),
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding: EdgeInsets.zero,
                    tabs: [
                      _buildSchoolTab('Việc thường', _schoolRegularJobsPendingCount, Colors.green),
                      _buildSchoolTab('Liên kết', _schoolPartnershipJobsPendingCount, Colors.purple),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSchoolRegularJobsList(),
                _buildSchoolPartnershipJobsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolTab(String label, int count, Color color) {
    return Tab(
      height: 44,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Remove old _buildSchoolSubTab method completely

  Widget _buildSchoolRegularJobsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('jobs')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allJobs = snapshot.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _filterSchoolJobs(allJobs),
          builder: (context, filteredSnapshot) {
            if (!filteredSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final jobs = filteredSnapshot.data!;

            if (jobs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                return _buildJobCard(jobs[index], 'school_regular');
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _filterSchoolJobs(List<Map<String, dynamic>> jobs) async {
    final schoolJobs = <Map<String, dynamic>>[];
    
    for (var job in jobs) {
      final creatorId = job['creator_id'];
      try {
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', creatorId)
            .single();
        
        if (profile['role'] == 'school') {
          schoolJobs.add(job);
        }
      } catch (e) {
        // Skip if error
      }
    }
    
    return schoolJobs;
  }

  Widget _buildSchoolPartnershipJobsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('school_partnership_jobs')
          .stream(primaryKey: ['id'])
          .eq('admin_status', 'pending')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = snapshot.data!;

        if (jobs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            return _buildJobCard(jobs[index], 'school_partnership');
          },
        );
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, String type) {
    final isPartnership = type == 'school_partnership';
    final metadata = job['metadata'] as Map<String, dynamic>?;
    final title = metadata?['title'] ?? 'N/A';
    final createdAt = job['created_at'] as String?;
    final creatorId = isPartnership ? job['school_id'] : job['creator_id'];
    
    // Extract job details
    final workingRegions = metadata?['working_regions'] as List?;
    final location = workingRegions?.isNotEmpty == true ? workingRegions!.first : 'N/A';
    
    final experience = metadata?['experience_required'] ?? 'N/A';
    
    final salary = metadata?['salary'] as Map<String, dynamic>?;
    final salaryMin = salary?['min'];
    final salaryMax = salary?['max'];
    final isNegotiable = salary?['is_negotiable'] == true;
    
    String salaryText;
    if (isNegotiable) {
      salaryText = 'Thỏa thuận';
    } else if (salaryMin != null && salaryMax != null) {
      salaryText = '${(salaryMin / 1000000).toStringAsFixed(0)}đ - ${(salaryMax / 1000000).toStringAsFixed(0)}đ';
    } else {
      salaryText = 'N/A';
    }
    
    final deadline = job['deadline'] as String?;
    String deadlineText = 'N/A';
    if (deadline != null) {
      final date = DateTime.tryParse(deadline);
      if (date != null) {
        deadlineText = DateFormat('dd/MM/yyyy').format(date);
      }
    }
    
    final fields = metadata?['fields'] as List?;
    final fieldTag = fields?.isNotEmpty == true ? fields!.first : null;
    
    Color badgeColor;
    String badgeText;
    
    switch (type) {
      case 'employer':
        badgeColor = Colors.blue;
        badgeText = 'Employer';
        break;
      case 'school_regular':
        badgeColor = Colors.green;
        badgeText = 'Thường';
        break;
      case 'school_partnership':
        badgeColor = Colors.purple;
        badgeText = 'Liên kết';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'N/A';
    }
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCreatorInfo(creatorId),
      builder: (context, creatorSnapshot) {
        final creatorName = creatorSnapshot.data?['name'] ?? 'Loading...';
        final creatorType = creatorSnapshot.data?['type'] ?? '';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type == 'employer' ? Icons.business : Icons.school,
                        size: 20,
                        color: badgeColor,
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
                                  creatorName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (creatorType == 'test') ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 14, color: Colors.blue),
                              ],
                            ],
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Job title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Job details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.location_on, location, Colors.blue),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.business_center, experience, Colors.purple),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.attach_money, salaryText, Colors.green),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.calendar_today, 'Hạn nộp: $deadlineText', Colors.orange),
                  ],
                ),
              ),
              
              if (fieldTag != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          fieldTag,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showJobDetail(job, type),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.blue.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                        label: const Text(
                          'Chi tiết',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveJob(job['id'], isPartnership),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text(
                          'Duyệt',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
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
                        onPressed: () => _rejectJob(job['id'], isPartnership),
                        icon: const Icon(Icons.close, color: Colors.red),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có việc cần duyệt',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Lỗi: $error'),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getCreatorInfo(String? creatorId) async {
    if (creatorId == null) return null;
    
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name, metadata')
          .eq('id', creatorId)
          .single();
      
      final metadata = response['metadata'] as Map<String, dynamic>?;
      final companyName = metadata?['company_name'];
      final schoolName = metadata?['school_name'];
      final isTest = metadata?['is_test_account'] == true;
      
      return {
        'name': companyName ?? schoolName ?? response['full_name'] ?? 'N/A',
        'type': isTest ? 'test' : 'real',
      };
    } catch (e) {
      return {'name': 'N/A', 'type': ''};
    }
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return '${diff.inDays} ngày trước';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} giờ trước';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(timestamp));
    }
  }

  Future<void> _approveJob(String jobId, bool isPartnership) async {
    try {
      final table = isPartnership ? 'school_partnership_jobs' : 'jobs';
      final statusField = isPartnership ? 'admin_status' : 'status';

      final updates = <String, dynamic>{statusField: 'approved'};
      
      // Update created_at for regular jobs so they appear as new
      if (!isPartnership) {
        updates['created_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from(table)
          .update(updates)
          .eq('id', jobId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã duyệt tin tuyển dụng'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showJobDetail(Map<String, dynamic> job, String type) {
    final isPartnership = type == 'school_partnership';
    final metadata = job['metadata'] as Map<String, dynamic>?;
    
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
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chi tiết việc làm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      metadata?['title'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Partnership Info (if partnership job)
                    if (isPartnership) ...{
                      _buildPartnershipInfoSection(
                        schoolId: job['school_id'],
                        companyId: job['company_id'],
                      ),
                      const SizedBox(height: 24),
                    }
                    // Creator Info (for regular jobs)
                    else ...{
                      _buildCreatorInfoSection(
                        creatorId: job['creator_id'],
                        type: type,
                      ),
                      const SizedBox(height: 24),
                    },
                    
                    
                    // Details Grid
                    _buildDetailSection('Thông tin cơ bản', [
                      _buildDetailItem('Khu vực', (metadata?['working_regions'] as List?)?.join(', ') ?? 'N/A', Icons.location_on),
                      _buildDetailItem('Kinh nghiệm', metadata?['experience_required'] ?? 'N/A', Icons.work),
                      _buildDetailItem('Hình thức', (metadata?['employment_types'] as List?)?.join(', ') ?? 'N/A', Icons.business_center),
                      _buildDetailItem('Địa điểm cụ thể', (metadata?['work_locations'] as List?)?.join(', ') ?? 'N/A', Icons.place),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    // Salary
                    _buildDetailSection('Lương', [
                      _buildSalaryInfo(metadata?['salary']),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    // Deadline
                    if (job['deadline'] != null)
                      _buildDetailSection('Hạn nộp hồ sơ', [
                        Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.parse(job['deadline'])),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ]),
                    
                    const SizedBox(height: 24),
                    
                    // Job Description
                    if (metadata?['job_description'] != null)
                      _buildListSection('Mô tả công việc', metadata!['job_description']),
                    
                    const SizedBox(height: 24),
                    
                    // Requirements
                    if (metadata?['candidate_requirements'] != null)
                      _buildListSection('Yêu cầu ứng viên', metadata!['candidate_requirements']),
                    
                    const SizedBox(height: 24),
                    
                    // Benefits
                    if (metadata?['benefits'] != null)
                      _buildListSection('Quyền lợi', metadata!['benefits']),
                    
                    const SizedBox(height: 24),
                    
                    // Tags
                    if (metadata?['requirements_tags'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Từ khóa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (metadata!['requirements_tags'] as List).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  tag.toString(),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
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
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppMainColors.primary),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInfo(Map<String, dynamic>? salary) {
    if (salary == null) return const Text('N/A');
    
    final min = salary['min'];
    final max = salary['max'];
    final isNegotiable = salary['is_negotiable'] == true;
    
    String text;
    if (isNegotiable) {
      text = 'Thỏa thuận';
    } else if (min != null && max != null) {
      text = '${NumberFormat('#,###').format(min)} - ${NumberFormat('#,###').format(max)} VNĐ';
    } else {
      text = 'N/A';
    }
    
    return Row(
      children: [
        const Icon(Icons.attach_money, color: Colors.green),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppMainColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _rejectJob(String jobId, bool isPartnership) async {
    try {
      final table = isPartnership ? 'school_partnership_jobs' : 'jobs';
      final statusField = isPartnership ? 'admin_status' : 'status';

      await _supabase
          .from(table)
          .update({statusField: 'rejected'})
          .eq('id', jobId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Đã từ chối tin tuyển dụng'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPendingCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Widget _buildCreatorInfoSection({
    required String creatorId,
    required String type,
  }) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCreatorInfo(creatorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final creator = snapshot.data!;
        final name = creator['name'] ?? 'N/A';
        
        Color cardColor;
        IconData cardIcon;
        String cardTitle;
        
        switch (type) {
          case 'employer':
            cardColor = Colors.blue;
            cardIcon = Icons.business;
            cardTitle = 'Công ty đăng tin';
            break;
          case 'school_regular':
            cardColor = Colors.green;
            cardIcon = Icons.school;
            cardTitle = 'Trường đăng tin';
            break;
          default:
            cardColor = Colors.grey;
            cardIcon = Icons.person;
            cardTitle = 'Người đăng';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor.withValues(alpha: 0.1), cardColor.withValues(alpha: 0.2)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(cardIcon, color: cardColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    cardTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProfileCard(
                name: name,
                icon: cardIcon,
                color: cardColor,
                onTap: () => _navigateToUserDetail(creatorId),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartnershipInfoSection({
    required String schoolId,
    required String companyId,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getBothProfiles(schoolId, companyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final school = snapshot.data!['school'];
        final company = snapshot.data!['company'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.purple.shade100],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.handshake, color: Colors.purple, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Thông tin liên kết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // School card
              _buildProfileCard(
                name: school['name'] ?? 'N/A',
                icon: Icons.school,
                color: Colors.green,
                onTap: () => _navigateToUserDetail(schoolId),
              ),

              const SizedBox(height: 12),

              // Company card  
              _buildProfileCard(
                name: company['name'] ?? 'N/A',
                icon: Icons.business,
                color: Colors.blue,
                onTap: () => _navigateToUserDetail(companyId),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getBothProfiles(String schoolId, String companyId) async {
    final schoolInfo = await _getCreatorInfo(schoolId);
    final companyInfo = await _getCreatorInfo(companyId);

    return {
      'school': schoolInfo ?? {'name': 'N/A'},
      'company': companyInfo ?? {'name': 'N/A'},
    };
  }

  Widget _buildProfileCard({
    required String name,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _navigateToUserDetail(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profile = Profile.fromJson(response);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(user: profile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
