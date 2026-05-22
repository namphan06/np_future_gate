import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/candidate/screens/data/filter_data.dart';
import 'package:np_future_gate/features/candidate/screens/job_detail_screen.dart';
import 'package:np_future_gate/shared/widgets/cards/job_card.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final _jobRepo = JobRepository();
  // List<Map<String, dynamic>> _allSavedJobs = []; // Removed
  // List<Map<String, dynamic>> _filteredJobs = []; // Removed
  // bool _isLoading = true; // Removed

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  
  String? _selectedCity;
  String? _selectedExperience;
  String? _selectedJobType;
  String? _selectedWorkType;
  
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // _loadSavedJobs(); // Removed
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterJobs(List<Map<String, dynamic>> jobs) {
    return jobs.where((item) {
        final jobData = item['jobs'];
        if (jobData == null) return false;
        
        try {
          final job = JobModel.fromJson(Map<String, dynamic>.from(jobData as Map));
          final meta = job.metadata;

          // Search Text
          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            final titleMatch = meta.title.toLowerCase().contains(query);
            final tagMatch = meta.requirementsTags.any((tag) => tag.toLowerCase().contains(query));
            if (!titleMatch && !tagMatch) return false;
          }

          // Filter by City (Working Regions)
          if (_selectedCity != null && !meta.workingRegions.contains(_selectedCity)) {
            return false;
          }

          // Filter by Experience
          if (_selectedExperience != null && meta.experienceRequired != _selectedExperience) {
            return false;
          }

          // Filter by Job Type (Fields)
          if (_selectedJobType != null && !meta.fields.contains(_selectedJobType)) {
            return false;
          }

          // Filter by Work Type (Employment Types)
          if (_selectedWorkType != null && !meta.employmentTypes.contains(_selectedWorkType)) {
            return false;
          }

          // Salary Filter (Simplified)
          if (_minSalaryController.text.isNotEmpty) {
            final minFilter = double.tryParse(_minSalaryController.text);
            if (minFilter != null && (meta.salary.max ?? 0) < minFilter) return false;
          }
          
          if (_maxSalaryController.text.isNotEmpty) {
            final maxFilter = double.tryParse(_maxSalaryController.text);
            if (maxFilter != null && (meta.salary.min ?? 0) > maxFilter) return false;
          }

          return true;
        } catch (e) {
          return false;
        }
      }).toList();
  }

  Future<void> _unSaveJob(String jobId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _jobRepo.toggleSaveJob(userId, jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bỏ lưu công việc')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {});
  }

  Future<void> _loadSavedJobs() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMainColors.backgroundLightStart,
      appBar: AppBar(
        title: const Text(
          'Việc làm đã lưu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                SpeechTextField(
                  controller: _searchController,
                  hint: 'Tìm kiếm việc làm đã lưu... (hoặc nói)',
                  prefixIcon: Icons.search,
                  maxLines: 1,
                ),
                
                // Filter Toggle
                if (_showFilters) ...[
                  const SizedBox(height: 16),
                  
                  // Khu vực
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: InputDecoration(
                      labelText: 'Khu vực',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: cities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) {
                      _selectedCity = val;
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Kinh nghiệm
                  DropdownButtonFormField<String>(
                    initialValue: _selectedExperience,
                    decoration: InputDecoration(
                      labelText: 'Kinh nghiệm',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: experiences.map((exp) {
                      return DropdownMenuItem(value: exp, child: Text(exp));
                    }).toList(),
                    onChanged: (val) {
                      _selectedExperience = val;
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Loại công việc
                  DropdownButtonFormField<String>(
                    initialValue: _selectedJobType,
                    decoration: InputDecoration(
                      labelText: 'Loại công việc',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: jobTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      _selectedJobType = val;
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        _selectedCity = null;
                        _selectedExperience = null;
                        _selectedJobType = null;
                        _selectedWorkType = null;
                        _searchController.clear();
                        _minSalaryController.clear();
                        _maxSalaryController.clear();
                        _applyFilters();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Đặt lại'),
                    ),
                  ),
                ],
                
                TextButton(
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_showFilters ? Icons.keyboard_arrow_up : Icons.filter_list),
                      const SizedBox(width: 8),
                      Text(_showFilters ? 'Ẩn bộ lọc' : 'Hiện bộ lọc'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _jobRepo.getSavedJobsStream(Supabase.instance.client.auth.currentUser?.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allSavedJobs = snapshot.data ?? [];
                final filteredJobs = _filterJobs(allSavedJobs);
                
                if (filteredJobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy công việc nào',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadSavedJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final item = filteredJobs[index];
                      final jobData = item['jobs'];
                      if (jobData == null) return const SizedBox.shrink();
                      
                      final job = JobModel.fromJson(Map<String, dynamic>.from(jobData as Map));
                      final isApplied = item['is_applied'] == true;

                      return JobCard(
                        job: job,
                        isSaved: true,
                        isApplied: isApplied,
                        onToggleSave: () => _unSaveJob(job.id!),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailScreen(job: job),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
