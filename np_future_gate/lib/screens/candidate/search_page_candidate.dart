import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../test/data/job_data.dart';
import 'data/filter_data.dart';

class SearchPageCandidate extends StatefulWidget {
  const SearchPageCandidate({super.key});

  @override
  State<SearchPageCandidate> createState() => _SearchPageCandidateState();
}

class _SearchPageCandidateState extends State<SearchPageCandidate> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  
  String? _selectedCity;
  String? _selectedExperience;
  String? _selectedJobType;
  String? _selectedWorkType;
  
  bool _showFilters = false;
  List<JobPosting> _filteredJobs = mockJobPostings;

  @override
  void dispose() {
    _searchController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = mockJobPostings.where((job) {
        // Lọc theo tên công việc
        if (_searchController.text.isNotEmpty &&
            !job.title.toLowerCase().contains(_searchController.text.toLowerCase()) &&
            !job.company.toLowerCase().contains(_searchController.text.toLowerCase())) {
          return false;
        }

        // Lọc theo thành phố
        if (_selectedCity != null && job.location != _selectedCity) {
          return false;
        }

        // Lọc theo kinh nghiệm
        if (_selectedExperience != null && job.level != _selectedExperience) {
          return false;
        }

        // Lọc theo loại công việc
        if (_selectedJobType != null && !job.tags.contains(_selectedJobType)) {
          return false;
        }

        // Lọc theo loại hình công việc
        if (_selectedWorkType != null && job.type != _selectedWorkType) {
          return false;
        }

        // Lọc theo mức lương (giả sử salary có format "XX - YY triệu")
        if (_minSalaryController.text.isNotEmpty || _maxSalaryController.text.isNotEmpty) {
          // Parse salary from job (simplified - thực tế cần parse chính xác hơn)
          final salaryText = job.salary.replaceAll(RegExp(r'[^0-9-]'), '');
          // Đơn giản hóa - trong thực tế cần xử lý phức tạp hơn
        }

        return true;
      }).toList();
    });
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
      _filteredJobs = mockJobPostings;
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
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
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => _applyFilters(),
                            decoration: InputDecoration(
                              hintText: 'Tên công việc, công ty...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.search, color: AppMainColors.primary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
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
                                child: TextField(
                                  controller: _minSalaryController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => _applyFilters(),
                                  decoration: InputDecoration(
                                    hintText: 'Từ',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: AppMainColors.primary),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('-', style: TextStyle(fontSize: 18)),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _maxSalaryController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => _applyFilters(),
                                  decoration: InputDecoration(
                                    hintText: 'Đến',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: AppMainColors.primary),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
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
                if (_filteredJobs.isEmpty)
                  SliverFillRemaining(
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
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final job = _filteredJobs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  // TODO: Navigate to job detail
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppMainColors.backgroundLightStart,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                job.company[0],
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppMainColors.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  job.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  job.company,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.bookmark_border,
                                            color: AppMainColors.primary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: job.tags.map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppMainColors.backgroundLightStart,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppMainColors.primary,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            job.location,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            job.type,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.stars, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            job.level,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            job.salary,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          Text(
                                            _getTimeAgo(job.postedDate),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _filteredJobs.length,
                      ),
                    ),
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
