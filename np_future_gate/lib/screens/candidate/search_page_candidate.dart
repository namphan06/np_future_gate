import 'package:flutter/material.dart';
import 'package:np_future_gate/core/controllers/search_candidate_controller.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/screens/candidate/data/filter_data.dart';
import 'package:np_future_gate/screens/candidate/job_detail_screen.dart';
import 'package:np_future_gate/widgets/cards/job_card.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';

class SearchPageCandidate extends StatefulWidget {
  const SearchPageCandidate({super.key});

  @override
  State<SearchPageCandidate> createState() => _SearchPageCandidateState();
}

class _SearchPageCandidateState extends State<SearchPageCandidate> {
  late final SearchCandidateController _controller;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SearchCandidateController();
    _controller.addListener(_onControllerChanged);
    _controller.init();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
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
                _buildSearchHeader(),
                if (_controller.showFilters) _buildFilterPanel(),
                _buildJobResults(),
              ],
            ),
          ),
        ),
        _buildBottomGradient(),
      ],
    );
  }

  // ============================================================
  // UI COMPONENTS
  // ============================================================

  Widget _buildSearchHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.toggleFilterPanel(),
                    icon: Icon(
                      _controller.showFilters
                          ? Icons.filter_list_off
                          : Icons.filter_list,
                      size: 20,
                    ),
                    label: Text(_controller.showFilters
                        ? 'Ẩn bộ lọc'
                        : 'Bộ lọc nâng cao'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppMainColors.primary,
                      side: const BorderSide(color: AppMainColors.primary),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: AppMainColors.primary, size: 20),
                SizedBox(width: 8),
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
            _buildSalaryFilter(),
            const SizedBox(height: 20),
            _buildWorkTypeFilter(),
            const SizedBox(height: 20),
            _buildCityFilter(),
            const SizedBox(height: 20),
            _buildExperienceFilter(),
            const SizedBox(height: 20),
            _buildJobTypeFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildWorkTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final isSelected = _controller.selectedWorkType == workType;
            return FilterChip(
              label: Text(workType),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _controller.selectedWorkType = selected ? workType : null;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppMainColors.backgroundLightStart,
              checkmarkColor: AppMainColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppMainColors.primary
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? AppMainColors.primary
                      : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              value: _controller.selectedCity,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Chọn thành phố',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(10),
              items: cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _controller.selectedCity = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              value: _controller.selectedExperience,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Chọn kinh nghiệm',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(10),
              items: experiences.map((exp) {
                return DropdownMenuItem(value: exp, child: Text(exp));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _controller.selectedExperience = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              value: _controller.selectedJobType,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Chọn loại công việc',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(10),
              items: jobTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _controller.selectedJobType = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobResults() {
    return StreamBuilder<List<JobModel>>(
      stream: _controller.activeJobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allJobs = snapshot.data ?? [];
        final filteredJobs = _controller.filterJobs(
          allJobs,
          searchQuery: _searchController.text,
          minSalary: _minSalaryController.text,
          maxSalary: _maxSalaryController.text,
        );

        if (filteredJobs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy công việc phù hợp',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        final totalPages = _controller.getTotalPages(filteredJobs.length);
        final paginatedJobs = _controller.getPaginatedJobs(filteredJobs);

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < paginatedJobs.length) {
                  final job = paginatedJobs[index];
                  return JobCard(
                    job: job,
                    isSaved: _controller.isJobSaved(job.id!),
                    isApplied: _controller.isJobApplied(job.id!),
                    onToggleSave: () => _handleToggleSave(job.id!),
                    onTap: () => _navigateToJobDetail(job),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: _buildPaginationControls(totalPages),
                  );
                }
              },
              childCount: paginatedJobs.length + 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _controller.currentPage > 1
                  ? () => setState(() => _controller.currentPage--)
                  : null,
              icon: Icon(
                Icons.chevron_left,
                color: _controller.currentPage > 1
                    ? AppMainColors.primary
                    : Colors.grey.shade300,
              ),
            ),
            ..._buildPageNumbers(totalPages),
            IconButton(
              onPressed: _controller.currentPage < totalPages
                  ? () => setState(() => _controller.currentPage++)
                  : null,
              icon: Icon(
                Icons.chevron_right,
                color: _controller.currentPage < totalPages
                    ? AppMainColors.primary
                    : Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    final pages = <Widget>[];
    for (int i = 1; i <= totalPages; i++) {
      if (i == 1 ||
          i == totalPages ||
          (i >= _controller.currentPage - 1 &&
              i <= _controller.currentPage + 1)) {
        pages.add(
          GestureDetector(
            onTap: () => setState(() => _controller.currentPage = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _controller.currentPage == i
                    ? AppMainColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: _controller.currentPage == i
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: _controller.currentPage == i
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      } else if (i == _controller.currentPage - 2 ||
          i == _controller.currentPage + 2) {
        pages.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child:
                Text('...', style: TextStyle(color: Colors.grey.shade600)),
          ),
        );
      }
    }
    return pages;
  }

  Widget _buildBottomGradient() {
    return Positioned(
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
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.85),
                Colors.white,
              ],
              stops: const [0.0, 0.2, 0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _resetFilters() {
    _searchController.clear();
    _minSalaryController.clear();
    _maxSalaryController.clear();
    _controller.resetFilters();
  }

  void _navigateToJobDetail(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
    );
  }

  Future<void> _handleToggleSave(String jobId) async {
    try {
      await _controller.toggleSaveJob(jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    }
  }
}
