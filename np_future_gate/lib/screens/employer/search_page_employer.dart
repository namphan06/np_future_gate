import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/job_model.dart';
import '../../core/enums/vietnam_provinces.dart';
import '../../core/enums/job_fields.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/services/cv_supabase_service.dart';
import '../../screens/cv/cv_setting/cv_display_manager.dart';
import '../../widgets/speech_text_field.dart';
import 'widgets/job_selection_dialog.dart';
import '../../core/repositories/candidate_repository.dart';
import '../../core/services/supabase_service.dart';

class SearchPageEmployer extends StatefulWidget {
  const SearchPageEmployer({super.key});

  @override
  State<SearchPageEmployer> createState() => _SearchPageEmployerState();
}

class _SearchPageEmployerState extends State<SearchPageEmployer> {
  final CVSupabaseService _cvService = CVSupabaseService();
  final _candidateRepository = CandidateRepository();
  final _supabaseService = SupabaseService.instance;
  List<String> _followedCandidateIds = [];

  // Filter values
  List<String> _selectedFields = [];
  String _selectedEducation = 'Tất cả';
  String _selectedLocation = 'Tất cả';
  RangeValues _ageRange = const RangeValues(18, 60);
  String _selectedGender = 'Tất cả';

  bool _showFilters = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 3;
  
  @override
  void initState() {
    super.initState();
    _loadFollowedCandidates();
  }

  Future<void> _loadFollowedCandidates() async {
    final userId = _supabaseService.currentUserId;
    if (userId != null) {
      final ids = await _candidateRepository.getFollowedCandidateIds(userId);
      if (mounted) {
        setState(() {
          _followedCandidateIds = ids;
        });
      }
    }
  }

  Future<void> _toggleFollow(String candidateId) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      if (_followedCandidateIds.contains(candidateId)) {
        await _candidateRepository.unfollowCandidate(userId, candidateId);
        setState(() {
          _followedCandidateIds.remove(candidateId);
        });
      } else {
        await _candidateRepository.followCandidate(userId, candidateId);
        setState(() {
          _followedCandidateIds.add(candidateId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật theo dõi: $e')),
      );
    }
  }

  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 20, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 1 ? AppMainColors.primary : Colors.grey.shade300,
            ),
          ),
          
          // Page numbers
          ..._buildPageNumbers(totalPages),
          
          // Next button
          IconButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < totalPages ? AppMainColors.primary : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildPageNumbers(int totalPages) {
    List<Widget> pages = [];
    
    for (int i = 1; i <= totalPages; i++) {
      if (i == 1 || i == totalPages || (i >= _currentPage - 1 && i <= _currentPage + 1)) {
        pages.add(
          GestureDetector(
            onTap: () {
              setState(() {
                _currentPage = i;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _currentPage == i ? AppMainColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: _currentPage == i ? Colors.white : Colors.black87,
                  fontWeight: _currentPage == i ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      } else if (i == _currentPage - 2 || i == _currentPage + 2) {
        pages.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey.shade600)),
          ),
        );
      }
    }
    
    return pages;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _checkFilter(Profile profile) {
    final meta = profile.metadata;
    
    // 1. Security Check (Must be true)
    if (meta['security'] != true) return false;

    // 2. Search Query (Fields or Tags)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final fields = (meta['interested_fields'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      final tags = (meta['tags'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      
      bool matchField = fields.any((f) => f.contains(query));
      bool matchTag = tags.any((t) => t.contains(query));
      
      if (!matchField && !matchTag) return false;
    }

    // 3. Dropdown Filters
    if (_selectedFields.isNotEmpty) {
      final fields = (meta['interested_fields'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      // Check if any selected field matches candidate's fields
      bool match = _selectedFields.any((selected) => fields.contains(selected));
      if (!match) return false;
    }

    if (_selectedEducation != 'Tất cả') {
      if (meta['education'] != _selectedEducation) return false;
    }

    if (_selectedLocation != 'Tất cả') {
      final locations = (meta['work_locations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      // Simple check if selected location is in their preferred locations
      // Or check address? Let's check work_locations
      bool matchLoc = locations.any((l) => l.toString().contains(_selectedLocation));
      if (!matchLoc) return false;
    }

    if (_selectedGender != 'Tất cả') {
      // Assuming gender is in metadata or profile? Profile model doesn't have gender explicitly in top level usually
      // Let's check metadata['gender'] if it exists, otherwise skip
      if (meta['gender'] != null && meta['gender'] != _selectedGender) return false;
    }

    // 4. Age Filter
    if (profile.dateOfBirth != null) {
      final age = DateTime.now().year - profile.dateOfBirth!.year;
      if (age < _ageRange.start || age > _ageRange.end) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tìm kiếm ứng viên',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SpeechTextField(
                      controller: _searchController,
                      hint: 'Tìm theo lĩnh vực, tags...',
                      prefixIcon: Icons.search,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Filters Panel
            if (_showFilters)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.49
                  ,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bộ lọc tìm kiếm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMultiSelectFilter(
                        'Lĩnh vực',
                        _selectedFields,
                        JobField.valuesList,
                        (values) => setState(() => _selectedFields = values),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownFilter(
                        'Bằng cấp',
                        _selectedEducation,
                        ['Tất cả', 'Trung học phổ thông', 'Cao đẳng', 'Đại học', 'Thạc sĩ', 'Tiến sĩ', 'Khác'],
                        (value) => setState(() => _selectedEducation = value!),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownFilter(
                        'Địa điểm',
                        _selectedLocation,
                        ['Tất cả', ...VietnamProvince.valuesList],
                        (value) => setState(() => _selectedLocation = value!),
                      ),
                      const SizedBox(height: 16),
                      _buildRangeFilter(
                        'Độ tuổi',
                        _ageRange,
                        18,
                        60,
                        (values) => setState(() => _ageRange = values),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownFilter(
                        'Giới tính',
                        _selectedGender,
                        ['Tất cả', 'Nam', 'Nữ', 'Khác'],
                        (value) => setState(() => _selectedGender = value!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFields = [];
                                  _selectedEducation = 'Tất cả';
                                  _selectedLocation = 'Tất cả';
                                  _ageRange = const RangeValues(18, 60);
                                  _selectedGender = 'Tất cả';
                                });
                              },
                              child: const Text('Xóa bộ lọc'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showFilters = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppMainColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Áp dụng'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Results
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('profiles')
                    .stream(primaryKey: ['id'])
                    .eq('role', 'candidate'),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final profiles = snapshot.data!.map((e) => Profile.fromJson(e)).where(_checkFilter).toList();
                  
                  if (profiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Không tìm thấy ứng viên phù hợp',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  // Calculate pagination
                  final totalPages = (profiles.length / _itemsPerPage).ceil();
                  if (_currentPage > totalPages && totalPages > 0) {
                    _currentPage = totalPages;
                  }
                  final startIndex = (_currentPage - 1) * _itemsPerPage;
                  final endIndex = (startIndex + _itemsPerPage).clamp(0, profiles.length);
                  final paginatedProfiles = profiles.sublist(startIndex, endIndex);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          itemCount: paginatedProfiles.length,
                          itemBuilder: (context, index) {
                            final profile = paginatedProfiles[index];
                            return _buildCandidateCard(profile);
                          },
                        ),
                      ),
                      _buildPaginationControls(totalPages),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(Profile profile) {
    final meta = profile.metadata;
    final fields = (meta['interested_fields'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final tags = (meta['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final isFollowing = _followedCandidateIds.contains(profile.id);

    return GestureDetector(
      onTap: () {
        _showCandidateDetail(profile);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                        ? Image.network(
                            profile.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, color: Colors.grey, size: 30);
                            },
                          )
                        : const Icon(Icons.person, color: Colors.grey, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName ?? 'Ứng viên',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            profile.phone ?? 'Chưa cập nhật SĐT',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFollowing ? Icons.bookmark : Icons.bookmark_border,
                    color: isFollowing ? AppMainColors.primary : Colors.grey.shade400,
                  ),
                  onPressed: () => _toggleFollow(profile.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (fields.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, size: 16, color: AppMainColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fields.join(', '),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (tags.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.label_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tags.join(', '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool isField = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isField ? AppMainColors.primary.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: isField ? Border.all(color: AppMainColors.primary.withOpacity(0.2)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isField ? Icons.work : Icons.label,
            size: 12,
            color: isField ? AppMainColors.primary : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isField ? AppMainColors.primary : Colors.black87,
              fontWeight: isField ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showCandidateDetail(Profile profile) {
    final meta = profile.metadata;
    final fields = (meta['interested_fields'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final tags = (meta['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final workLocations = (meta['work_locations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final experience = (meta['experience'] as List<dynamic>?) ?? [];
    final cvIds = (meta['cv_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
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
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Header Profile
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        profile.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, color: Colors.grey, size: 50);
                                        },
                                      )
                                    : const Icon(Icons.person, color: Colors.grey, size: 50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profile.fullName ?? 'Ứng viên',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (meta['bio'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                meta['bio'],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Info Sections
                      _buildDetailSection('Thông tin cơ bản', [
                        _buildDetailRow(Icons.email, 'Email', profile.email ?? 'Chưa cập nhật'),
                        if (profile.phone != null) _buildDetailRow(Icons.phone, 'Số điện thoại', profile.phone!),
                        if (profile.dateOfBirth != null) 
                          _buildDetailRow(Icons.cake, 'Tuổi', '${DateTime.now().year - profile.dateOfBirth!.year} tuổi'),
                        if (meta['education'] != null)
                          _buildDetailRow(Icons.school, 'Học vấn', meta['education']),
                        if (workLocations.isNotEmpty)
                          _buildDetailRow(Icons.location_on, 'Khu vực làm việc', workLocations.join(', ')),
                      ],),

                      if (fields.isNotEmpty || tags.isNotEmpty)
                        _buildDetailSection('Kỹ năng & Lĩnh vực', [
                          if (fields.isNotEmpty) ...[
                            const Text('Lĩnh vực quan tâm:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: fields.map((f) => _buildTag(f, isField: true)).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (tags.isNotEmpty) ...[
                            const Text('Tags:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((t) => _buildTag(t)).toList(),
                            ),
                          ],
                        ]),

                      if (experience.isNotEmpty)
                        _buildDetailSection('Kinh nghiệm làm việc', [
                          ...experience.map((exp) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp['company'] ?? 'Công ty',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exp['position'] ?? 'Vị trí',
                                  style: TextStyle(color: AppMainColors.primary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exp['date'] ?? '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                if (exp['description'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(exp['description'], style: const TextStyle(height: 1.4)),
                                ],
                              ],
                            ),
                          )),
                        ]),

                      // CV Section
                      if (cvIds.isNotEmpty)
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: Future.wait(cvIds.map((id) async {
                            try {
                              final data = await _cvService.getCVData(id);
                              return data ?? {};
                            } catch (e) {
                              return {};
                            }
                          })),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final cvs = snapshot.data!.where((e) => e.isNotEmpty).toList();
                            if (cvs.isEmpty) return const SizedBox.shrink();

                            return _buildDetailSection('Hồ sơ đính kèm (CV)', [
                              ...cvs.map((cvData) {
                                final personalInfo = cvData['personal_info'] as Map<String, dynamic>?;
                                final title = personalInfo?['full_name'] ?? 'CV Ứng viên';
                                final summary = cvData['summary'] ?? 'Không có mô tả';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.description, color: Colors.blue),
                                    ),
                                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      summary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: TextButton(
                                      onPressed: () {
                                        // TODO: Navigate to CV View
                                        _showCVContent(context, cvData);
                                      },
                                      child: const Text('Xem'),
                                    ),
                                  ),
                                );
                              }),
                            ]);
                          },
                        ),
                      
                      const SizedBox(height: 80), // Space for bottom buttons
                    ],
                  ),
                ),
                
                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _toggleFollow(profile.id);
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            _followedCandidateIds.contains(profile.id)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          label: Text(
                            _followedCandidateIds.contains(profile.id)
                                ? 'Bỏ lưu'
                                : 'Lưu hồ sơ',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppMainColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showJobSelectionDialog(context, profile);
                          },
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Gửi Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppMainColors.primary,
                            foregroundColor: Colors.white,
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
      ),
    );
  }

  void _showJobSelectionDialog(BuildContext context, Profile candidate) {
    showDialog(
      context: context,
      builder: (context) => JobSelectionDialog(candidate: candidate),
    );
  }

  void _showCVContent(BuildContext context, Map<String, dynamic> cvData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CVDisplayManager.buildViewWidget(context, cvData),
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
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppMainColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppMainColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectFilter(
    String label,
    List<String> selectedValues,
    List<String> items,
    void Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showMultiSelectDialog(label, selectedValues, items, onChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedValues.isEmpty ? 'Tất cả' : selectedValues.join(', '),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMultiSelectDialog(
    String title,
    List<String> selectedValues,
    List<String> items,
    void Function(List<String>) onChanged,
  ) {
    final tempSelected = List<String>.from(selectedValues);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Chọn $title'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = tempSelected.contains(item);
                  return CheckboxListTile(
                    title: Text(item),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          tempSelected.add(item);
                        } else {
                          tempSelected.remove(item);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  onChanged(tempSelected);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeFilter(
    String label,
    RangeValues values,
    double min,
    double max,
    void Function(RangeValues) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${values.start.round()} - ${values.end.round()}',
              style: TextStyle(
                fontSize: 12,
                color: AppMainColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppMainColors.primary,
          inactiveColor: Colors.grey.shade300,
          onChanged: onChanged,
        ),
      ],
    );
  }
}


