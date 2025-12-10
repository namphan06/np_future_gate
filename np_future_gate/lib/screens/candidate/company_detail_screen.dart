import 'package:flutter/material.dart';
import 'package:np_future_gate/widgets/cards/job_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/job_model.dart';
import '../../core/repositories/company_repository.dart';
import '../../core/repositories/job_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_main_colors.dart';
import '../../widgets/animated_avatar.dart';


class CompanyDetailScreen extends StatefulWidget {
  final Profile company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> with SingleTickerProviderStateMixin {
  final _companyRepository = CompanyRepository();
  final _jobRepository = JobRepository();
  final _supabaseService = SupabaseService.instance;

  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoadingJobs = true;
  List<JobModel> _activeJobs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFollowStatus();
    _loadCompanyJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFollowStatus() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      final followedIds = await _companyRepository.getFollowedCompanyIds(userId);
      if (mounted) {
        setState(() {
          _isFollowing = followedIds.contains(widget.company.id);
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _loadCompanyJobs() async {
    try {
      // Fetch all jobs created by this employer
      final jobs = await _jobRepository.getEmployerJobs(widget.company.id);
      // Filter only active jobs (approved and not expired)
      final now = DateTime.now();
      final activeJobs = jobs.where((job) {
        final isApproved = job.status == 'approved';
        final isNotExpired = job.deadline == null || job.deadline!.isAfter(now);
        return isApproved && isNotExpired;
      }).toList();
      
      if (mounted) {
        setState(() {
          _activeJobs = activeJobs;
          _isLoadingJobs = false;
        });
      }
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) {
        setState(() => _isLoadingJobs = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để theo dõi')),
      );
      return;
    }

    try {
      if (_isFollowing) {
        await _companyRepository.unfollowCompany(userId, widget.company.id);
      } else {
        await _companyRepository.followCompany(userId, widget.company.id);
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    final phone = widget.company.phone;
    if (phone == null || phone.isEmpty) return;
    
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMap() async {
    final address = widget.company.metadata['address'] as String?;
    if (address == null || address.isEmpty) return;

    final query = Uri.encodeComponent(address);
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.company.metadata['company_name'] ?? widget.company.fullName ?? 'Công ty';
    final fields = (widget.company.metadata['fields'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final address = widget.company.metadata['address'] as String?;
    final website = widget.company.metadata['website'] as String?;
    final facebook = widget.company.metadata['facebook'] as String?;
    final linkedin = widget.company.metadata['linkedin'] as String?;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _toggleFollow,
                    icon: Icon(
                      _isFollowing ? Icons.bookmark : Icons.bookmark_border,
                      color: _isFollowing ? AppMainColors.primary : Colors.black87,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Cover Image (Gradient placeholder)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppMainColors.primary.withOpacity(0.8),
                            AppMainColors.primaryDark,
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: AnimatedAvatar(
                              avatarUrl: widget.company.avatarUrl,
                              width: 100,
                              height: 100,
                              borderRadius: 16,
                              placeholderIcon: Icons.business,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppMainColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppMainColors.primary,
                  tabs: const [
                    Tab(text: 'Giới thiệu'),
                    Tab(text: 'Tuyển dụng'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Giới thiệu
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fields.isNotEmpty) ...[
                    _buildSectionTitle('Lĩnh vực hoạt động'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fields.map((f) => Chip(
                        label: Text(f),
                        backgroundColor: AppMainColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppMainColors.primary),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _buildSectionTitle('Thông tin liên hệ'),
                  const SizedBox(height: 16),
                  
                  // Map Preview
                  if (address != null && address.isNotEmpty)
                    GestureDetector(
                      onTap: _openMap,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Stack(
                          children: [
                            // Placeholder pattern if no image
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Xem trên bản đồ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  _buildContactItem(
                    icon: Icons.location_on,
                    text: address ?? 'Chưa cập nhật địa chỉ',
                    onTap: _openMap,
                    isLink: true,
                  ),
                  if (widget.company.phone != null)
                    _buildContactItem(
                      icon: Icons.phone,
                      text: widget.company.phone!,
                      onTap: _makePhoneCall,
                      isLink: true,
                    ),
                  
                  // Social Links
                  if (website != null || facebook != null || linkedin != null) ...[
                    const SizedBox(height: 12),
                    const Text('Liên kết:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (website != null && website.isNotEmpty)
                          _buildSocialButton(Icons.language, 'Website', () => _openUrl(website)),
                        if (facebook != null && facebook.isNotEmpty)
                          _buildSocialButton(Icons.facebook, 'Facebook', () => _openUrl(facebook)),
                        if (linkedin != null && linkedin.isNotEmpty)
                          _buildSocialButton(Icons.work, 'LinkedIn', () => _openUrl(linkedin)),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Giới thiệu công ty'),
                  const SizedBox(height: 8),
                  Text(
                    widget.company.metadata['description'] ?? 'Chưa có mô tả.',
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quy mô'),
                  const SizedBox(height: 8),
                  Text(
                    widget.company.metadata['company_size'] ?? 'Chưa cập nhật',
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Tab 2: Tuyển dụng
            _isLoadingJobs
                ? const Center(child: CircularProgressIndicator())
                : _activeJobs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_off_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Chưa có tin tuyển dụng nào đang mở'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activeJobs.length,
                        itemBuilder: (context, index) {
                          return JobCard(job: _activeJobs[index]);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppMainColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
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
        color: Colors.black87,
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppMainColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isLink ? Colors.blue.shade700 : Colors.black87,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ),
              if (isLink)
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
