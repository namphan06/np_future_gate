import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/profile_model.dart';
import '../../core/repositories/company_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_main_colors.dart';
import '../../widgets/animated_avatar.dart';
import 'company_detail_screen.dart';

class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  final _companyRepository = CompanyRepository();
  final _supabaseService = SupabaseService.instance;
  final _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Profile> _allCompanies = [];
  List<Profile> _filteredCompanies = [];
  List<String> _followedCompanyIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCompanies = _allCompanies.where((company) {
        final name = (company.metadata['company_name'] ?? company.fullName ?? '').toLowerCase();
        final fields = (company.metadata['fields'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        
        return name.contains(query) || fields.any((f) => f.contains(query));
      }).toList();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final companies = await _companyRepository.getAllCompanies();
      final userId = _supabaseService.currentUserId;
      List<String> followedIds = [];
      
      if (userId != null) {
        followedIds = await _companyRepository.getFollowedCompanyIds(userId);
      }

      if (mounted) {
        setState(() {
          _allCompanies = companies;
          _filteredCompanies = companies;
          _followedCompanyIds = followedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow(String companyId) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      if (_followedCompanyIds.contains(companyId)) {
        await _companyRepository.unfollowCompany(userId, companyId);
        setState(() {
          _followedCompanyIds.remove(companyId);
        });
      } else {
        await _companyRepository.followCompany(userId, companyId);
        setState(() {
          _followedCompanyIds.add(companyId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật theo dõi: $e')),
      );
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có số điện thoại')),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện cuộc gọi')),
        );
      }
    }
  }

  Future<void> _openMap(String? address) async {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có địa chỉ')),
      );
      return;
    }
    final query = Uri.encodeComponent(address);
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ')),
        );
      }
    }
  }

  void _navigateToDetail(Profile company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(company: company),
      ),
    ).then((_) => _loadData()); // Reload data when returning (in case follow status changed)
  }

  @override
  Widget build(BuildContext context) {
    final followedCompanies = _filteredCompanies.where((c) => _followedCompanyIds.contains(c.id)).toList();
    final otherCompanies = _filteredCompanies.where((c) => !_followedCompanyIds.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Danh sách công ty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm công ty, lĩnh vực...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (followedCompanies.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildSectionTitle('Công ty đang theo dõi (${followedCompanies.length})'),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: followedCompanies.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) => _buildCompanyCardHorizontal(followedCompanies[index], true),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildSectionTitle('Gợi ý công ty (${otherCompanies.length})'),
                            ),
                            const SizedBox(height: 12),
                            if (otherCompanies.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Không tìm thấy công ty nào.'),
                              )
                            else
                              SizedBox(
                                height: 180,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: otherCompanies.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) => _buildCompanyCardHorizontal(otherCompanies[index], false),
                                ),
                              ),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppMainColors.primary,
      ),
    );
  }

  Widget _buildCompanyCardHorizontal(Profile company, bool isFollowing) {
    final companyName = company.metadata['company_name'] ?? company.fullName ?? 'Công ty';
    final address = company.metadata['address'] as String?;
    final fields = (company.metadata['fields'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(company),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedAvatar(
                      avatarUrl: company.avatarUrl,
                      width: 50,
                      height: 50,
                      borderRadius: 10,
                      placeholderIcon: Icons.business,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (fields.isNotEmpty)
                            Text(
                              fields.first,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggleFollow(company.id),
                      icon: Icon(
                        isFollowing ? Icons.bookmark : Icons.bookmark_border,
                        color: isFollowing ? AppMainColors.primary : Colors.grey,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Spacer(),
                if (fields.length > 1) ...[
                   Wrap(
                     spacing: 4,
                     runSpacing: 4,
                     children: fields.skip(1).take(2).map((f) => Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.grey.shade100,
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(
                         f,
                         style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                       ),
                     )).toList(),
                   ),
                   const SizedBox(height: 12),
                ],
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openMap(address),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address ?? 'Chưa cập nhật địa chỉ',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _makePhoneCall(company.phone),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone, size: 16, color: Colors.green.shade700),
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
  }
}
