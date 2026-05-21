import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/company_repository.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/repositories/partnership_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/screens/candidate/job_detail_screen.dart';
import 'package:np_future_gate/screens/school/jobs/create_school_job_screen.dart';
import 'package:np_future_gate/widgets/animated_avatar.dart';
import 'package:np_future_gate/widgets/cards/job_card.dart';
import 'package:url_launcher/url_launcher.dart';


class CompanyDetailScreen extends StatefulWidget { // 'school', 'candidate', null

  const CompanyDetailScreen({
    super.key, 
    required this.company,
    this.userRole,
  });
  final Profile company;
  final String? userRole;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  final _companyRepository = CompanyRepository();
  final _jobRepository = JobRepository();
  final _partnershipRepository = PartnershipRepository();
  final _supabaseService = SupabaseService.instance;

  int _selectedTabIndex = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      final role = widget.userRole ?? 'candidate';
      final followedIds = await _companyRepository.getFollowedCompanyIds(userId, userRole: role);
      if (mounted) {
        setState(() {
          _isFollowing = followedIds.contains(widget.company.id);
        });
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
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
      final role = widget.userRole ?? 'candidate';
      if (_isFollowing) {
        await _companyRepository.unfollowCompany(userId, widget.company.id, userRole: role);
      } else {
        await _companyRepository.followCompany(userId, widget.company.id, userRole: role);
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _sendPartnershipRequest() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      // 1. Check if partnership already exists
      final existing = await _partnershipRepository.checkExistingPartnership(
        schoolId: userId,
        companyId: widget.company.id,
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

      // Confirmation Dialog
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gửi yêu cầu liên kết'),
          content: Text('Bạn có muốn gửi yêu cầu liên kết tới ${widget.company.fullName ?? 'doanh nghiệp này'} không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // 2. Insert new request
      await _partnershipRepository.sendPartnershipRequest(
        schoolId: userId,
        companyId: widget.company.id,
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

  @override
  Widget build(BuildContext context) {
    final companyName = widget.company.metadata['company_name'] ?? widget.company.fullName ?? 'Công ty';
    final fields = (widget.company.metadata['fields'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final address = widget.company.metadata['address'] as String?;
    final website = widget.company.metadata['website'] as String?;
    final facebook = widget.company.metadata['facebook'] as String?;
    final linkedin = widget.company.metadata['linkedin'] as String?;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar with Company Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
              // Create Partnership Job button for school
              if (widget.userRole == 'school') ...[
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _sendPartnershipRequest,
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    tooltip: 'Tạo tin liên kết',
                  ),
                ),
              ],
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF42A5F5),
                          Color(0xFF1E88E5),
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
                                color: Colors.black.withValues(alpha: 0.1),
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

          // Custom Tab Selector
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton('Giới thiệu', 0, Icons.info_outline),
                    ),
                    Expanded(
                      child: _buildTabButton('Tuyển dụng', 1, Icons.work_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Content
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _selectedTabIndex == 0
                  ? _buildAboutTab(fields, address, website, facebook, linkedin)
                  : _buildJobsTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppMainColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppMainColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(
    List<String> fields,
    String? address,
    String? website,
    String? facebook,
    String? linkedin,
  ) {
    return Container(
      key: const ValueKey('about'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fields.isNotEmpty) ...[
            _buildSectionTitle('Lĩnh vực hoạt động'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fields.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF42A5F5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  f,
                  style: const TextStyle(
                    color: Color(0xFF1E88E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
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
          
          if (widget.userRole == 'school') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _sendPartnershipRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.handshake, color: Colors.white),
                label: const Text(
                  'Yêu cầu liên kết', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
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
    );
  }

  Widget _buildJobsTab() {
    return Container(
      key: const ValueKey('jobs'),
      child: StreamBuilder<List<JobModel>>(
        stream: _jobRepository.getEmployerJobsStream(widget.company.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final activeJobs = snapshot.data ?? [];
          
          if (activeJobs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có tin tuyển dụng nào',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: activeJobs.length,
            itemBuilder: (context, index) {
              final job = activeJobs[index];
              
              // For school users, override JobCard tap to create partnership
              if (widget.userRole == 'school') {
                return GestureDetector(
                  onTap: () {
                    final companyName = widget.company.metadata['company_name'] ?? 
                                       widget.company.fullName ?? 
                                       'Công ty';
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateSchoolJobScreen(
                          isPartnership: true,
                          preselectedCompanyId: widget.company.id,
                          preselectedCompanyName: companyName,
                          job: job, // Pre-fill with job data
                        ),
                      ),
                    );
                  },
                  child: AbsorbPointer(
                    child: JobCard(job: job),
                  ),
                );
              }
              
              // For candidates, navigate to job detail screen
              return JobCard(
                job: job,
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
          );
        }
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
