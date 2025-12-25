import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/models/job_model.dart';
import '../../core/repositories/job_repository.dart';
import 'job_detail_screen.dart';
import 'data/filter_data.dart';
import '../../widgets/cards/job_card.dart';
import '../../widgets/speech_text_field.dart';


class SearchPageCandidate extends StatefulWidget {
  const SearchPageCandidate({super.key});

  @override
  State<SearchPageCandidate> createState() => _SearchPageCandidateState();
}

class _SearchPageCandidateState extends State<SearchPageCandidate> {
  final JobRepository _jobRepo = JobRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  
  String? _selectedCity;
  String? _selectedExperience;
  String? _selectedJobType;
  String? _selectedWorkType;
  
  bool _showFilters = false;
  // List<JobModel> _allJobs = []; // Removed
  // List<JobModel> _filteredJobs = []; // Removed
  // bool _isLoading = true; // Removed
  List<String> _savedJobIds = [];
  List<String> _appliedJobIds = [];

  @override
  void initState() {
    super.initState();
    // _loadJobs(); // Removed
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final savedIds = await _jobRepo.getSavedJobIds(user.id);
      final appliedIds = await _jobRepo.getAppliedJobIds(user.id);
      if (mounted) {
        setState(() {
          _savedJobIds = savedIds;
          _appliedJobIds = appliedIds;
        });
      }
    }
  }

  Future<void> _toggleSaveJob(String jobId) async {


    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        if (_savedJobIds.contains(jobId)) {
          _savedJobIds.remove(jobId);
        } else {
          _savedJobIds.add(jobId);
        }
      });

      await _jobRepo.toggleSaveJob(user.id, jobId);
    } catch (e) {
      _loadSavedJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    }
  }

  List<JobModel> _filterJobs(List<JobModel> jobs) {
    return jobs.where((job) {
        final meta = job.metadata;
        
        // Search by Title OR Tags
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
      }).toList();
  }

  void _applyFilters() {
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minSalaryController.clear();
      _maxSalaryController.clear();
      _selectedCity = null;
      _selectedExperience = null;
      _selectedJobType = null;
      _selectedWorkType = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppMainColors.backgroundLightStart,
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header với thanh tìm kiếm
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Tiêu đề
                        Row(
                          children: [
                            Text(
                              'Tìm kiếm việc làm',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppMainColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Thanh tìm kiếm
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SpeechTextField(
                            controller: _searchController,
                            hint: 'Tìm tên công việc, công ty... (hoặc nói)',
                            prefixIcon: Icons.search,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Nút hiện/ẩn bộ lọc
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showFilters = !_showFilters;
                                  });
                                },
                                icon: Icon(
                                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                  size: 20,
                                ),
                                label: Text(_showFilters ? 'Ẩn bộ lọc' : 'Bộ lọc nâng cao'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppMainColors.primary,
                                  side: BorderSide(color: AppMainColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: _resetFilters,
                              icon: const Icon(Icons.refresh, size: 20),
                              label: const Text('Đặt lại'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Phần bộ lọc (có thể ẩn/hiện)
                if (_showFilters)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề bộ lọc
                          Row(
                            children: [
                              Icon(Icons.tune, color: AppMainColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Bộ lọc tìm kiếm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppMainColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Mức lương
                          Text(
                            'Mức lương (triệu VNĐ)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SpeechTextField(
                                  controller: _minSalaryController,
                                  hint: 'Từ (triệu)',
                                  maxLines: 1,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('-', style: TextStyle(fontSize: 18)),
                              ),
                              Expanded(
                                child: SpeechTextField(
                                  controller: _maxSalaryController,
                                  hint: 'Đến (triệu)',
                                  maxLines: 1,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Loại hình công việc
                          Text(
                            'Loại hình công việc',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: jobWorkTypes.map((workType) {
                              final isSelected = _selectedWorkType == workType;
                              return FilterChip(
                                label: Text(workType),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedWorkType = selected ? workType : null;
                                    _applyFilters();
                                  });
                                },
                                backgroundColor: Colors.grey.shade100,
                                selectedColor: AppMainColors.backgroundLightStart,
                                checkmarkColor: AppMainColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppMainColors.primary : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppMainColors.primary : Colors.grey.shade300,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Thành phố
                          Text(
                            'Thành phố',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCity,
                                isExpanded: true,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Chọn thành phố', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: BorderRadius.circular(10),
                                items: cities.map((city) {
                                  return DropdownMenuItem(
                                    value: city,
                                    child: Text(city),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCity = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Kinh nghiệm
                          Text(
                            'Kinh nghiệm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedExperience,
                                isExpanded: true,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Chọn kinh nghiệm', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: BorderRadius.circular(10),
                                items: experiences.map((exp) {
                                  return DropdownMenuItem(
                                    value: exp,
                                    child: Text(exp),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedExperience = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Loại công việc
                          Text(
                            'Loại công việc',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedJobType,
                                isExpanded: true,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Chọn loại công việc', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: BorderRadius.circular(10),
                                items: jobTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedJobType = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Kết quả tìm kiếm
                StreamBuilder<List<JobModel>>(
                  stream: _jobRepo.activeJobsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final allJobs = snapshot.data ?? [];
                    final filteredJobs = _filterJobs(allJobs);
                    
                    if (filteredJobs.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không tìm thấy công việc phù hợp',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final job = filteredJobs[index];
                            final isSaved = _savedJobIds.contains(job.id);
                            final isApplied = _appliedJobIds.contains(job.id);
                            
                            return JobCard(
                              job: job,
                              isSaved: isSaved,
                              isApplied: isApplied,
                              onToggleSave: () => _toggleSaveJob(job.id!),
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
                          childCount: filteredJobs.length,
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ),
        // Gradient overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                   colors: [
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.85),
                Colors.white,
              ],
              stops: const [0.0, 0.2, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
