import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/cv_supabase_service.dart';
import '../cv/cv_setting/cv_display_manager.dart';

class PendingRecruitmentDecisionsScreen extends StatefulWidget {
  const PendingRecruitmentDecisionsScreen({Key? key}) : super(key: key);

  @override
  State<PendingRecruitmentDecisionsScreen> createState() =>
      _PendingRecruitmentDecisionsScreenState();
}

class _PendingRecruitmentDecisionsScreenState
    extends State<PendingRecruitmentDecisionsScreen> {
  final _supabase = Supabase.instance.client;
  final CVSupabaseService _cvService = CVSupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobsWithPendingCandidates = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  
  // Search & Filter states
  final TextEditingController _searchController = TextEditingController();
  String _selectedTimeFilter = 'all'; // all, today, week, month, year
  String _selectedJobTypeFilter = 'all'; // all, regular, partnership
  String _selectedRatingFilter = 'all'; // all, high, medium, low
  
  // Comparison mode states
  bool _isComparisonMode = false;
  Set<String> _selectedCandidatesForComparison = {}; // Store interview IDs
  static const int _maxComparisonCandidates = 3;

  @override
  void initState() {
    super.initState();
    _loadPendingDecisions();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingDecisions() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Lấy tất cả các job của employer
      final jobsData = await _supabase
          .from('jobs')
          .select('id, metadata, applicants')
          .eq('creator_id', userId);

      // Lấy tất cả các school_partnership_jobs của employer
      final partnershipJobsData = await _supabase
          .from('school_partnership_jobs')
          .select('id, metadata, applicants')
          .eq('company_id', userId)
          .eq('company_status', 'accepted');

      List<Map<String, dynamic>> allJobs = [];

      // Process jobs
      for (var job in jobsData as List) {
        final interviews = await _supabase
            .from('interview_schedules')
            .select('*')
            .eq('job_id', job['id'])
            .eq('employer_id', userId)
            .eq('status', 'completed');

        if (interviews.isNotEmpty) {
          // Load candidate profiles separately
          final candidateIds = (interviews as List)
              .map((i) => i['candidate_id'] as String)
              .toList();
          
          final profiles = await _supabase
              .from('profiles')
              .select('id, full_name, email, avatar_url, metadata')
              .inFilter('id', candidateIds);

          // Map profiles to interviews
          final profileMap = {
            for (var p in profiles as List) p['id']: p
          };

          // Filter only interviews without recruitment decision (pending)
          final enrichedInterviews = (interviews as List)
              .map((interview) {
                final interviewMap = interview as Map<String, dynamic>;
                return <String, dynamic>{
                  ...interviewMap,
                  'candidate': profileMap[interviewMap['candidate_id']],
                };
              })
              .where((interview) {
                final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
                final decision = evaluation['recruitment_decision'];
                return decision == null || decision == 'pending';
              })
              .toList();

          // Only add job if it has pending candidates
          if (enrichedInterviews.isNotEmpty) {
            allJobs.add({
              'job_id': job['id'],
              'job_metadata': job['metadata'],
              'job_type': 'regular',
              'interviews': enrichedInterviews,
            });
          }
        }
      }

      // Process partnership jobs
      for (var job in partnershipJobsData as List) {
        final interviews = await _supabase
            .from('interview_schedules')
            .select('*')
            .eq('job_id', job['id'])
            .eq('employer_id', userId)
            .eq('status', 'completed');

        if (interviews.isNotEmpty) {
          // Load candidate profiles separately
          final candidateIds = (interviews as List)
              .map((i) => i['candidate_id'] as String)
              .toList();
          
          final profiles = await _supabase
              .from('profiles')
              .select('id, full_name, email, avatar_url, metadata')
              .inFilter('id', candidateIds);

          // Map profiles to interviews
          final profileMap = {
            for (var p in profiles as List) p['id']: p
          };

          // Filter only interviews without recruitment decision (pending)
          final enrichedInterviews = (interviews as List)
              .map((interview) {
                final interviewMap = interview as Map<String, dynamic>;
                return <String, dynamic>{
                  ...interviewMap,
                  'candidate': profileMap[interviewMap['candidate_id']],
                };
              })
              .where((interview) {
                final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
                final decision = evaluation['recruitment_decision'];
                return decision == null || decision == 'pending';
              })
              .toList();

          // Only add job if it has pending candidates
          if (enrichedInterviews.isNotEmpty) {
            allJobs.add({
              'job_id': job['id'],
              'job_metadata': job['metadata'],
              'job_type': 'partnership',
              'interviews': enrichedInterviews,
            });
          }
        }
      }

      setState(() {
        _jobsWithPendingCandidates = allJobs;
        _filteredJobs = allJobs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pending decisions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _jobsWithPendingCandidates.where((job) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final jobTitle = (job['job_metadata']?['title'] ?? '').toString().toLowerCase();
        
        // Get candidate names
        final interviews = job['interviews'] as List;
        final candidateNames = interviews
            .map((i) => (i['candidate']?['full_name'] ?? '').toString().toLowerCase())
            .join(' ');
        
        final matchesSearch = searchQuery.isEmpty || 
            jobTitle.contains(searchQuery) || 
            candidateNames.contains(searchQuery);
        
        if (!matchesSearch) return false;

        // Job type filter
        final jobType = job['job_type'] as String;
        final matchesJobType = _selectedJobTypeFilter == 'all' || 
            jobType == _selectedJobTypeFilter;
        
        if (!matchesJobType) return false;

        // Time filter
        if (_selectedTimeFilter != 'all') {
          final now = DateTime.now();
          bool hasMatchingInterview = false;

          for (var interview in interviews) {
            final interviewTime = DateTime.tryParse(interview['interview_time']?.toString() ?? '');
            if (interviewTime != null) {
              switch (_selectedTimeFilter) {
                case 'today':
                  if (interviewTime.year == now.year &&
                      interviewTime.month == now.month &&
                      interviewTime.day == now.day) {
                    hasMatchingInterview = true;
                  }
                  break;
                case 'week':
                  final weekStart = now.subtract(Duration(days: now.weekday - 1));
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  if (interviewTime.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                      interviewTime.isBefore(weekEnd.add(const Duration(days: 1)))) {
                    hasMatchingInterview = true;
                  }
                  break;
                case 'month':
                  if (interviewTime.year == now.year && interviewTime.month == now.month) {
                    hasMatchingInterview = true;
                  }
                  break;
                case 'year':
                  if (interviewTime.year == now.year) {
                    hasMatchingInterview = true;
                  }
                  break;
              }
            }
          }
          
          if (!hasMatchingInterview) return false;
        }

        // Rating filter
        if (_selectedRatingFilter != 'all') {
          bool hasMatchingRating = false;
          
          for (var interview in interviews) {
            final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
            final rating = (evaluation['rating'] as num?)?.toDouble() ?? 0;
            
            switch (_selectedRatingFilter) {
              case 'high':
                if (rating >= 4) hasMatchingRating = true;
                break;
              case 'medium':
                if (rating >= 2.5 && rating < 4) hasMatchingRating = true;
                break;
              case 'low':
                if (rating < 2.5) hasMatchingRating = true;
                break;
            }
          }
          
          if (!hasMatchingRating) return false;
        }

        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedTimeFilter = 'all';
      _selectedJobTypeFilter = 'all';
      _selectedRatingFilter = 'all';
      _filteredJobs = _jobsWithPendingCandidates;
    });
  }

  void _toggleComparisonMode() {
    setState(() {
      _isComparisonMode = !_isComparisonMode;
      if (!_isComparisonMode) {
        _selectedCandidatesForComparison.clear();
      }
    });
  }

  void _toggleCandidateSelection(String interviewId) {
    setState(() {
      if (_selectedCandidatesForComparison.contains(interviewId)) {
        _selectedCandidatesForComparison.remove(interviewId);
      } else {
        if (_selectedCandidatesForComparison.length < _maxComparisonCandidates) {
          _selectedCandidatesForComparison.add(interviewId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chỉ có thể so sánh tối đa $_maxComparisonCandidates ứng viên'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _showComparisonScreen() {
    // Get all selected interviews from all jobs
    List<Map<String, dynamic>> selectedInterviews = [];
    
    for (var job in _filteredJobs) {
      final interviews = job['interviews'] as List;
      for (var interview in interviews) {
        if (_selectedCandidatesForComparison.contains(interview['id'])) {
          selectedInterviews.add({
            ...interview as Map<String, dynamic>,
            'job_title': job['job_metadata']?['title'] ?? 'Chưa có tiêu đề',
            'job_id': job['job_id'],
            'job_type': job['job_type'],
          });
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CandidateComparisonScreen(
          interviews: selectedInterviews,
          onViewCV: _viewCV,
        ),
      ),
    );
  }

  Future<void> _updateRecruitmentDecision({
    required String jobId,
    required String jobType,
    required String interviewId,
    required String decision,
  }) async {
    try {
      // Cập nhật evaluation trong interview_schedules
      final currentInterview = await _supabase
          .from('interview_schedules')
          .select('evaluation')
          .eq('id', interviewId)
          .single();

      final evaluation = currentInterview['evaluation'] as Map<String, dynamic>? ?? {};
      evaluation['recruitment_decision'] = decision;
      evaluation['decision_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('interview_schedules')
          .update({'evaluation': evaluation}).eq('id', interviewId);

      // Cập nhật trạng thái trong applicants array
      final table = jobType == 'regular' ? 'jobs' : 'school_partnership_jobs';
      
      // Lấy thông tin job hiện tại
      final jobData = await _supabase
          .from(table)
          .select('applicants')
          .eq('id', jobId)
          .single();
      
      // Lấy thông tin interview để tìm candidate_id
      final interviewData = await _supabase
          .from('interview_schedules')
          .select('candidate_id, cv_id')
          .eq('id', interviewId)
          .single();
      
      final candidateId = interviewData['candidate_id'];
      final cvId = interviewData['cv_id'];
      
      // Cập nhật applicants array
      List<dynamic> applicants = List.from(jobData['applicants'] ?? []);
      
      // Tìm và cập nhật ứng viên
      bool found = false;
      for (int i = 0; i < applicants.length; i++) {
        final applicant = applicants[i] as Map<String, dynamic>;
        if (applicant['user_id'] == candidateId || 
            (cvId != null && applicant['cv_id'] == cvId)) {
          applicants[i] = {
            ...applicant,
            'recruitment_status': decision,
            'decision_at': DateTime.now().toIso8601String(),
          };
          found = true;
          break;
        }
      }
      
      // Nếu không tìm thấy trong applicants, thêm mới
      if (!found && candidateId != null) {
        applicants.add({
          'user_id': candidateId,
          'cv_id': cvId,
          'recruitment_status': decision,
          'decision_at': DateTime.now().toIso8601String(),
          'applied_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Lưu lại applicants array
      await _supabase.from(table).update({
        'applicants': applicants,
      }).eq('id', jobId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'accepted' ? 'Đã chấp nhận ứng viên' : 'Đã từ chối ứng viên',
          ),
          backgroundColor:
              decision == 'accepted' ? AppColors.primaryGreen : Colors.red,
        ),
      );

      _loadPendingDecisions();
    } catch (e) {
      print('Error updating decision: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _viewCV(String cvId) async {
    try {
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

  void _showDecisionDialog({
    required String jobId,
    required String jobType,
    required String interviewId,
    required String candidateName,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Quyết định tuyển dụng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Bạn có muốn tuyển dụng $candidateName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRecruitmentDecision(
                jobId: jobId,
                jobType: jobType,
                interviewId: interviewId,
                decision: 'rejected',
              );
            },
            child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRecruitmentDecision(
                jobId: jobId,
                jobType: jobType,
                interviewId: interviewId,
                decision: 'accepted',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: _isComparisonMode && _selectedCandidatesForComparison.length >= 2
          ? Tooltip(
              message: 'So sánh ${_selectedCandidatesForComparison.length} ứng viên',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _showComparisonScreen,
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 8,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.compare_arrows, size: 28, color: Colors.white),
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_selectedCandidatesForComparison.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // Custom AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: _isComparisonMode
                      ? const LinearGradient(
                          colors: [AppColors.primaryGreen, Color(0xFF45B649)],
                        )
                      : null,
                  color: _isComparisonMode ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isComparisonMode
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  icon: Icon(
                    _isComparisonMode ? Icons.compare_arrows : Icons.compare,
                    color: _isComparisonMode ? Colors.white : AppColors.textSecondary,
                  ),
                  onPressed: _toggleComparisonMode,
                  tooltip: _isComparisonMode ? 'Thoát chế độ so sánh' : 'So sánh ứng viên',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      AppColors.primaryBlue.withOpacity(0.05),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue,
                                    AppColors.primaryGreen
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.how_to_vote_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quyết định tuyển dụng',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ứng viên đã phỏng vấn',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_jobsWithPendingCandidates.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.primaryBlue.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không có quyết định đang chờ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tất cả ứng viên đã được xử lý',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Search & Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm job hoặc ứng viên...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Time Filter
                          _buildFilterChip(
                            label: _getTimeFilterLabel(),
                            icon: Icons.calendar_today,
                            isSelected: _selectedTimeFilter != 'all',
                            onTap: _showTimeFilterMenu,
                          ),
                          const SizedBox(width: 8),
                          
                          // Job Type Filter
                          _buildFilterChip(
                            label: _getJobTypeFilterLabel(),
                            icon: Icons.work_outline,
                            isSelected: _selectedJobTypeFilter != 'all',
                            onTap: _showJobTypeFilterMenu,
                          ),
                          const SizedBox(width: 8),
                          
                          // Rating Filter
                          _buildFilterChip(
                            label: _getRatingFilterLabel(),
                            icon: Icons.star_outline,
                            isSelected: _selectedRatingFilter != 'all',
                            onTap: _showRatingFilterMenu,
                          ),
                          const SizedBox(width: 8),
                          
                          // Reset Button
                          if (_selectedTimeFilter != 'all' ||
                              _selectedJobTypeFilter != 'all' ||
                              _selectedRatingFilter != 'all' ||
                              _searchController.text.isNotEmpty)
                            _buildFilterChip(
                              label: 'Xóa bộ lọc',
                              icon: Icons.clear,
                              isSelected: false,
                              onTap: _resetFilters,
                              color: Colors.red,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Results count
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Tìm thấy ${_filteredJobs.length} job',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Jobs List
            if (_filteredJobs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy kết quả',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thử điều chỉnh bộ lọc hoặc từ khóa',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = _filteredJobs[index];
                      return _buildJobCard(job);
                    },
                    childCount: _filteredJobs.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primaryBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : chipColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeFilterLabel() {
    switch (_selectedTimeFilter) {
      case 'today':
        return 'Hôm nay';
      case 'week':
        return 'Tuần này';
      case 'month':
        return 'Tháng này';
      case 'year':
        return 'Năm nay';
      default:
        return 'Thời gian';
    }
  }

  String _getJobTypeFilterLabel() {
    switch (_selectedJobTypeFilter) {
      case 'regular':
        return 'Job thường';
      case 'partnership':
        return 'Liên kết';
      default:
        return 'Loại job';
    }
  }

  String _getRatingFilterLabel() {
    switch (_selectedRatingFilter) {
      case 'high':
        return 'Đánh giá cao';
      case 'medium':
        return 'TB';
      case 'low':
        return 'Thấp';
      default:
        return 'Đánh giá';
    }
  }

  void _showTimeFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Lọc theo thời gian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(),
            _buildFilterOption('Tất cả', 'all', Icons.all_inclusive),
            _buildFilterOption('Hôm nay', 'today', Icons.today),
            _buildFilterOption('Tuần này', 'week', Icons.date_range),
            _buildFilterOption('Tháng này', 'month', Icons.calendar_month),
            _buildFilterOption('Năm nay', 'year', Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  void _showJobTypeFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Lọc theo loại job',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(),
            _buildJobTypeOption('Tất cả', 'all', Icons.work_outline),
            _buildJobTypeOption('Job thường', 'regular', Icons.work),
            _buildJobTypeOption('Job liên kết', 'partnership', Icons.handshake_outlined),
          ],
        ),
      ),
    );
  }

  void _showRatingFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Lọc theo đánh giá',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(),
            _buildRatingOption('Tất cả', 'all', Icons.star_outline),
            _buildRatingOption('Cao (≥4⭐)', 'high', Icons.star, Colors.amber),
            _buildRatingOption('Trung bình (2.5-4⭐)', 'medium', Icons.star_half, Colors.orange),
            _buildRatingOption('Thấp (<2.5⭐)', 'low', Icons.star_border, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = _selectedTimeFilter == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryBlue : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
      onTap: () {
        setState(() => _selectedTimeFilter = value);
        _applyFilters();
        Navigator.pop(context);
      },
    );
  }

  Widget _buildJobTypeOption(String label, String value, IconData icon) {
    final isSelected = _selectedJobTypeFilter == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryGreen : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
      onTap: () {
        setState(() => _selectedJobTypeFilter = value);
        _applyFilters();
        Navigator.pop(context);
      },
    );
  }

  Widget _buildRatingOption(String label, String value, IconData icon, [Color? color]) {
    final isSelected = _selectedRatingFilter == value;
    final iconColor = color ?? (isSelected ? Colors.amber : Colors.grey);
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.amber.shade700 : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: Colors.amber.shade700) : null,
      onTap: () {
        setState(() => _selectedRatingFilter = value);
        _applyFilters();
        Navigator.pop(context);
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final metadata = job['job_metadata'] as Map<String, dynamic>? ?? {};
    final jobTitle = metadata['title'] ?? 'Chưa có tiêu đề';
    final interviews = job['interviews'] as List;
    final jobType = job['job_type'] as String;

    return _JobCardWithExpansion(
      jobTitle: jobTitle,
      jobType: jobType,
      interviews: interviews,
      jobId: job['job_id'],
      onViewCV: _viewCV,
      onShowEvaluation: _showEvaluationDetail,
      onShowDecision: _showDecisionDialog,
      formatDateTime: _formatDateTime,
      isComparisonMode: _isComparisonMode,
      selectedCandidates: _selectedCandidatesForComparison,
      onToggleCandidateSelection: _toggleCandidateSelection,
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Chưa xác định';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  void _showEvaluationDetail(String candidateName, Map<String, dynamic> evaluation, dynamic interviewTime) {
    final rating = (evaluation['rating'] as num?)?.toDouble() ?? 0;
    final notes = evaluation['note'] as String? ?? '';
    final tags = (evaluation['tags'] as List?)?.cast<String>() ?? [];
    
    // Chi tiết các tiêu chí đánh giá
    final positionRating = (evaluation['position_rating'] as num?)?.toDouble() ?? 0;
    final environmentRating = (evaluation['environment_rating'] as num?)?.toDouble() ?? 0;
    final communicationRating = (evaluation['communication_rating'] as num?)?.toDouble() ?? 0;
    final potentialRating = (evaluation['potential_rating'] as num?)?.toDouble() ?? 0;
    
    // Yêu cầu đánh giá động từ job
    final requirementsEvaluation = evaluation['requirements_evaluation'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đánh giá phỏng vấn',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                candidateName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${rating.toStringAsFixed(1)}/5',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Interview Time
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Phỏng vấn: ${_formatDateTime(interviewTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating Display
                    const Text(
                      'Xếp hạng tổng thể',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Detailed Ratings
                    const Text(
                      'Đánh giá chi tiết',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildRatingBar('Phù hợp vị trí', positionRating, Icons.work_outline),
                    const SizedBox(height: 12),
                    _buildRatingBar('Môi trường/Văn hóa', environmentRating, Icons.group_outlined),
                    const SizedBox(height: 12),
                    _buildRatingBar('Kỹ năng giao tiếp', communicationRating, Icons.chat_bubble_outline),
                    const SizedBox(height: 12),
                    _buildRatingBar('Tiềm năng phát triển', potentialRating, Icons.trending_up),
                    const SizedBox(height: 24),

                    // Requirements Evaluation (Dynamic)
                    if (requirementsEvaluation.isNotEmpty) ...[
                      const Text(
                        'Đánh giá yêu cầu công việc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...requirementsEvaluation.entries.map((entry) {
                        final requirementName = entry.key;
                        final requirementRating = (entry.value as num?)?.toDouble() ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRatingBar(
                            requirementName,
                            requirementRating,
                            Icons.check_circle_outline,
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                    ],

                    // Tags
                    if (tags.isNotEmpty) ...[
                      const Text(
                        'Ghi chú đặc biệt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Notes
                    if (notes.isNotEmpty) ...[
                      const Text(
                        'Nhận xét chi tiết',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          notes,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa có nhận xét chi tiết',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Close Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String label, double rating, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${rating.toInt()}/10',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rating / 10,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                rating >= 8 ? AppColors.primaryGreen :
                rating >= 6 ? Colors.orange :
                Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCardWithExpansion extends StatefulWidget {
  final String jobTitle;
  final String jobType;
  final List interviews;
  final String jobId;
  final Function(String) onViewCV;
  final Function(String, Map<String, dynamic>, dynamic) onShowEvaluation;
  final Function({
    required String jobId,
    required String jobType,
    required String interviewId,
    required String candidateName,
  }) onShowDecision;
  final String Function(dynamic) formatDateTime;
  final bool isComparisonMode;
  final Set<String> selectedCandidates;
  final Function(String) onToggleCandidateSelection;

  const _JobCardWithExpansion({
    required this.jobTitle,
    required this.jobType,
    required this.interviews,
    required this.jobId,
    required this.onViewCV,
    required this.onShowEvaluation,
    required this.onShowDecision,
    required this.formatDateTime,
    required this.isComparisonMode,
    required this.selectedCandidates,
    required this.onToggleCandidateSelection,
  });

  @override
  State<_JobCardWithExpansion> createState() => _JobCardWithExpansionState();
}

class _JobCardWithExpansionState extends State<_JobCardWithExpansion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Header - Clickable
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.1),
                    AppColors.primaryGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.jobType == 'partnership'
                          ? Icons.handshake_outlined
                          : Icons.work_outline,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jobTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${widget.interviews.length} ứng viên chờ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                            if (widget.jobType == 'partnership') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Liên kết',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primaryBlue,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Candidates List - Collapsible
          if (_isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: widget.interviews.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final interview = widget.interviews[index];
                final candidate = interview['candidate'] as Map<String, dynamic>? ?? {};
                final candidateName = candidate['full_name'] ?? 'Ứng viên';
                final candidateEmail = candidate['email'] ?? '';
                final avatarUrl = candidate['avatar_url'];
                final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
                final cvId = interview['cv_id'];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Candidate Info
                      Row(
                        children: [
                          if (widget.isComparisonMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Checkbox(
                                value: widget.selectedCandidates.contains(interview['id']),
                                onChanged: (_) => widget.onToggleCandidateSelection(interview['id']),
                                activeColor: AppColors.primaryGreen,
                              ),
                            ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: avatarUrl == null
                                  ? const LinearGradient(
                                      colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                                    )
                                  : null,
                              image: avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarUrl == null
                                ? Center(
                                    child: Text(
                                      candidateName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidateName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  candidateEmail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Interview Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryBlue),
                                const SizedBox(width: 8),
                                Text(
                                  'Phỏng vấn: ${widget.formatDateTime(interview['interview_time'])}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            if (evaluation['note'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.note_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      evaluation['note'],
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (evaluation['rating'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Đánh giá: ${evaluation['rating']}/5',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: cvId != null ? () => widget.onViewCV(cvId) : null,
                                  icon: const Icon(Icons.description_outlined, size: 18),
                                  label: const Text('Xem CV'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    side: const BorderSide(color: AppColors.primaryBlue),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => widget.onShowEvaluation(candidateName, evaluation, interview['interview_time']),
                                  icon: const Icon(Icons.star_outline, size: 18),
                                  label: const Text('Đánh giá'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    widget.onShowDecision(
                                      jobId: widget.jobId,
                                      jobType: widget.jobType,
                                      interviewId: interview['id'],
                                      candidateName: candidateName,
                                    );
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Từ chối'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    widget.onShowDecision(
                                      jobId: widget.jobId,
                                      jobType: widget.jobType,
                                      interviewId: interview['id'],
                                      candidateName: candidateName,
                                    );
                                  },
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Chấp nhận'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Comparison Screen Widget
class _CandidateComparisonScreen extends StatefulWidget {
  final List<Map<String, dynamic>> interviews;
  final Function(String) onViewCV;

  const _CandidateComparisonScreen({
    required this.interviews,
    required this.onViewCV,
  });

  @override
  State<_CandidateComparisonScreen> createState() => _CandidateComparisonScreenState();
}

class _CandidateComparisonScreenState extends State<_CandidateComparisonScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'So sánh ứng viên',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Đánh giá', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('CV', 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildEvaluationComparison(),
          _buildCVComparison(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int page) {
    final isActive = _currentPage == page;
    return InkWell(
      onTap: () => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                )
              : null,
          color: isActive ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationComparison() {
    // Get all evaluation criteria
    Set<String> allCriteria = {};
    for (var interview in widget.interviews) {
      final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
      final requirements = evaluation['requirements_evaluation'] as Map<String, dynamic>? ?? {};
      allCriteria.addAll(requirements.keys);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Candidate Headers
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: widget.interviews.map((interview) {
                final candidate = interview['candidate'] as Map<String, dynamic>? ?? {};
                final candidateName = candidate['full_name'] ?? 'Ứng viên';
                final avatarUrl = candidate['avatar_url'];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: avatarUrl == null
                                ? const LinearGradient(
                                    colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                                  )
                                : null,
                            image: avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: avatarUrl == null
                              ? Center(
                                  child: Text(
                                    candidateName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          candidateName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Overall Rating Comparison
          _buildComparisonSection(
            title: 'Xếp hạng tổng thể',
            icon: Icons.star,
            builder: (interview) {
              final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
              final rating = (evaluation['rating'] as num?)?.toDouble() ?? 0;
              return Column(
                children: [
                  Text(
                    '${rating.toStringAsFixed(1)}/5',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                ],
              );
            },
          ),

          // Fixed Criteria Comparison
          _buildComparisonSection(
            title: 'Phù hợp vị trí',
            icon: Icons.work_outline,
            builder: (interview) {
              final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
              final rating = (evaluation['position_rating'] as num?)?.toDouble() ?? 0;
              return _buildRatingDisplay(rating);
            },
          ),

          _buildComparisonSection(
            title: 'Môi trường/Văn hóa',
            icon: Icons.group_outlined,
            builder: (interview) {
              final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
              final rating = (evaluation['environment_rating'] as num?)?.toDouble() ?? 0;
              return _buildRatingDisplay(rating);
            },
          ),

          _buildComparisonSection(
            title: 'Kỹ năng giao tiếp',
            icon: Icons.chat_bubble_outline,
            builder: (interview) {
              final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
              final rating = (evaluation['communication_rating'] as num?)?.toDouble() ?? 0;
              return _buildRatingDisplay(rating);
            },
          ),

          _buildComparisonSection(
            title: 'Tiềm năng phát triển',
            icon: Icons.trending_up,
            builder: (interview) {
              final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
              final rating = (evaluation['potential_rating'] as num?)?.toDouble() ?? 0;
              return _buildRatingDisplay(rating);
            },
          ),

          // Dynamic Requirements Comparison
          ...allCriteria.map((criterion) {
            return _buildComparisonSection(
              title: criterion,
              icon: Icons.check_circle_outline,
              builder: (interview) {
                final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
                final requirements = evaluation['requirements_evaluation'] as Map<String, dynamic>? ?? {};
                final rating = (requirements[criterion] as num?)?.toDouble() ?? 0;
                return _buildRatingDisplay(rating);
              },
            );
          }).toList(),

          // Tags Comparison
          _buildComparisonSection(
            title: 'Ghi chú đặc biệt',
            icon: Icons.label_outline,
            builder: (interview) {
              final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
              final tags = (evaluation['tags'] as List?)?.cast<String>() ?? [];
              if (tags.isEmpty) {
                return const Text(
                  'Chưa có',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )).toList(),
              );
            },
          ),

          // Notes Comparison
          _buildComparisonSection(
            title: 'Nhận xét chi tiết',
            icon: Icons.note_outlined,
            builder: (interview) {
              final evaluation = interview['evaluation'] as Map<String, dynamic>? ?? {};
              final notes = evaluation['note'] as String? ?? '';
              if (notes.isEmpty) {
                return const Text(
                  'Chưa có nhận xét',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildComparisonSection({
    required String title,
    required IconData icon,
    required Widget Function(Map<String, dynamic>) builder,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: widget.interviews.map((interview) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: builder(interview),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDisplay(double rating) {
    final color = rating >= 8
        ? AppColors.primaryGreen
        : rating >= 6
            ? Colors.orange
            : Colors.red;

    return Column(
      children: [
        Text(
          '${rating.toInt()}/10',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rating / 10,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCVComparison() {
    return Container(
      color: Colors.white,
      child: Row(
        children: widget.interviews.map((interview) {
          final candidate = interview['candidate'] as Map<String, dynamic>? ?? {};
          final candidateName = candidate['full_name'] ?? 'Ứng viên';
          final cvId = interview['cv_id'];

          return Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            candidateName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: cvId != null ? () => widget.onViewCV(cvId) : null,
                        icon: const Icon(Icons.description_outlined, size: 20),
                        label: const Text('Xem CV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
