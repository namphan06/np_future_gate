import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/company_repository.dart';
import 'package:np_future_gate/core/repositories/partnership_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/screens/candidate/company_detail_screen.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPageSchool extends StatefulWidget {
  const SearchPageSchool({super.key});

  @override
  State<SearchPageSchool> createState() => _SearchPageSchoolState();
}

class _SearchPageSchoolState extends State<SearchPageSchool> {
  final TextEditingController _searchController = TextEditingController();
  // ignore: unused_field
  final AuthRepository _authRepository = AuthRepository();
  final CompanyRepository _companyRepository = CompanyRepository();
  final PartnershipRepository _partnershipRepository = PartnershipRepository();
  
  List<Profile> _allEmployers = [];
  List<Profile> _filteredEmployers = [];
  Set<String> _followedCompanyIds = {};
  Set<String> _partnerCompanyIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    _loadEmployers();
    _loadFollowedCompanies();
    _loadPartnerCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployers() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all profiles with role 'employer'
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'employer')
          .order('full_name', ascending: true);
      
      final employers = (response as List)
          .map((e) => Profile.fromJson(e))
          .toList();
      
      setState(() {
        _allEmployers = employers;
        _filteredEmployers = employers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _loadFollowedCompanies() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final followedIds = await _companyRepository.getFollowedCompanyIds(userId, userRole: 'school');
      if (mounted) {
        setState(() {
          _followedCompanyIds = followedIds.toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading followed companies: $e');
    }
  }

  Future<void> _loadPartnerCompanies() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      // Get all approved partnerships
      final response = await Supabase.instance.client
          .from('school_company_partnerships')
          .select('company_id')
          .eq('school_id', userId)
          .eq('status', 'accepted');
      
      final partnerIds = (response as List)
          .map((e) => e['company_id'] as String)
          .toSet();
      
      if (mounted) {
        setState(() {
          _partnerCompanyIds = partnerIds;
        });
      }
    } catch (e) {
      debugPrint('Error loading partner companies: $e');
    }
  }

  Future<void> _toggleFollowCompany(String companyId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập')),
        );
        return;
      }
      
      final isFollowing = _followedCompanyIds.contains(companyId);
      
      if (isFollowing) {
        await _companyRepository.unfollowCompany(userId, companyId, userRole: 'school');
        setState(() {
          _followedCompanyIds.remove(companyId);
        });
      } else {
        await _companyRepository.followCompany(userId, companyId, userRole: 'school');
        setState(() {
          _followedCompanyIds.add(companyId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _filterEmployers(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset to first page when filtering
      if (query.isEmpty) {
        _filteredEmployers = _allEmployers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredEmployers = _allEmployers.where((employer) {
          final name = employer.fullName?.toLowerCase() ?? '';
          final email = employer.email?.toLowerCase() ?? '';
          final metadata = employer.metadata;
          final companyName = metadata['company_name']?.toString().toLowerCase() ?? '';
          
          return name.contains(lowerQuery) || 
                 email.contains(lowerQuery) ||
                 companyName.contains(lowerQuery);
        }).toList();
      }
    });
  }
  
  Widget _buildPaginationControls() {
    final totalPages = (_filteredEmployers.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 40, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
    final List<Widget> pages = [];
    
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Tìm kiếm nhà tuyển dụng',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_filteredEmployers.length} nhà tuyển dụng',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Search Bar
              SpeechTextField(
                controller: _searchController,
                hint: 'Tìm kiếm công ty, nhà tuyển dụng...',
                prefixIcon: Icons.search,
                onChanged: _filterEmployers,
              ),
              const SizedBox(height: 24),
              
              // Employer List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _filteredEmployers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty 
                                      ? Icons.business_outlined 
                                      : Icons.search_off_outlined,
                                  size: 80,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Chưa có nhà tuyển dụng nào'
                                      : 'Không tìm thấy kết quả',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _loadEmployers,
                                  color: AppMainColors.primary,
                                  child: Builder(
                                    builder: (context) {
                                      final totalPages = (_filteredEmployers.length / _itemsPerPage).ceil();
                                      if (_currentPage > totalPages && totalPages > 0) {
                                        _currentPage = totalPages;
                                      }
                                      final startIndex = (_currentPage - 1) * _itemsPerPage;
                                      final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredEmployers.length);
                                      final paginatedEmployers = _filteredEmployers.sublist(startIndex, endIndex);
                                      
                                      return ListView.builder(
                                        itemCount: paginatedEmployers.length,
                                        itemBuilder: (context, index) {
                                          final employer = paginatedEmployers[index];
                                          return _buildEmployerCard(employer);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              _buildPaginationControls(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployerCard(Profile employer) {
    final metadata = employer.metadata;
    final companyName = metadata['company_name']?.toString() ?? 'Công ty';
    final industry = metadata['industry']?.toString();
    final companySize = metadata['company_size']?.toString();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to employer detail or show dialog
          _showEmployerDetails(employer);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: employer.avatarUrl != null
                    ? NetworkImage(employer.avatarUrl!)
                    : null,
                backgroundColor: AppMainColors.primary.withValues(alpha: 0.1),
                child: employer.avatarUrl == null
                    ? const Icon(
                        Icons.business,
                        size: 30,
                        color: AppMainColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (employer.fullName != null)
                      Text(
                        employer.fullName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (employer.email != null)
                      Text(
                        employer.email!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (industry != null || companySize != null)
                      const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (industry != null)
                          _buildInfoChip(Icons.business_center, industry),
                        if (companySize != null)
                          _buildInfoChip(Icons.people, companySize),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bookmark button
              Column(
                children: [
                   IconButton(
                    onPressed: () => _toggleFollowCompany(employer.id),
                    icon: Icon(
                      _followedCompanyIds.contains(employer.id) 
                          ? Icons.bookmark 
                          : Icons.bookmark_border,
                      color: _followedCompanyIds.contains(employer.id)
                          ? AppMainColors.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _createPartnershipRequest(employer),
                    tooltip: _partnerCompanyIds.contains(employer.id) 
                        ? 'Đã liên kết' 
                        : 'Yêu cầu liên kết',
                    icon: Icon(
                      _partnerCompanyIds.contains(employer.id)
                          ? Icons.handshake
                          : Icons.handshake_outlined,
                      color: _partnerCompanyIds.contains(employer.id)
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createPartnershipRequest(Profile employer) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Check if partnership already exists
      final existing = await _partnershipRepository.checkExistingPartnership(
        schoolId: userId,
        companyId: employer.id,
      );

      if (existing != null) {
        if (!mounted) return;
        final String status = existing['status'];
        final String msg = status == 'approved' 
            ? 'Đã là đối tác của nhau' 
            : status == 'pending' 
                ? 'Đã gửi yêu cầu, vui lòng chờ phản hồi' 
                : 'Yêu cầu trước đó đã bị từ chối';
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      // 2. Insert new request
      await _partnershipRepository.sendPartnershipRequest(
        schoolId: userId,
        companyId: employer.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu liên kết thành công!'), 
            backgroundColor: Colors.green,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppMainColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppMainColors.primary),
          const SizedBox(width:4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppMainColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployerDetails(Profile employer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(
          company: employer,
          userRole: 'school',
        ),
      ),
    );
    
    // Reload followed companies when coming back
    _loadFollowedCompanies();
    _loadPartnerCompanies();
  }
}
