import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_main_colors.dart';
import '../../candidate/company_detail_screen.dart'; // Using CompanyDetail reused for School view or similar profile view
import '../../../../core/models/profile_model.dart';

class SchoolPartnershipsScreen extends StatefulWidget {
  const SchoolPartnershipsScreen({super.key});

  @override
  State<SchoolPartnershipsScreen> createState() => _SchoolPartnershipsScreenState();
}

class _SchoolPartnershipsScreenState extends State<SchoolPartnershipsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _approvedPartners = [];
  Map<String, Map<String, dynamic>> _schools = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch all partnerships
      final response = await Supabase.instance.client
          .from('school_company_partnerships')
          .select()
          .eq('company_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      // Separate lists
      final allRequests = data.cast<Map<String, dynamic>>();
      _pendingRequests = allRequests.where((e) => e['status'] == 'pending').toList();
      _approvedPartners = allRequests.where((e) => e['status'] == 'accepted').toList();

      // Get unique school IDs to fetch profiles
      final schoolIds = allRequests
          .map((e) => e['school_id'] as String)
          .toSet()
          .toList();

      // Fetch school profiles
      if (schoolIds.isNotEmpty) {
        final schoolsResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, avatar_url, email, phone, metadata, role, is_active, created_at, updated_at')
            .filter('id', 'in', schoolIds);
        
        final schoolsMap = <String, Map<String, dynamic>>{};
        for (var s in schoolsResponse) {
          schoolsMap[s['id']] = s;
        }
        _schools = schoolsMap;
      }

      if (mounted) {
        setState(() {
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

  Future<void> _updateStatus(String id, String status, {int? limitCount, String? limitPeriod}) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final Map<String, dynamic> updateData = {'status': status};
      if (limitCount != null) updateData['post_limit_count'] = limitCount;
      if (limitPeriod != null) updateData['post_limit_period'] = limitPeriod;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await Supabase.instance.client
          .from('school_company_partnerships')
          .update(updateData)
          .eq('id', id);

      if (mounted) {
        Navigator.pop(context); // Hide loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'accepted' ? 'Đã chấp nhận liên kết' : 'Đã từ chối liên kết')),
        );
        _loadData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> request) {
    final schoolId = request['school_id'];
    final school = _schools[schoolId] ?? {};
    final schoolName = school['full_name'] ?? 'Nhà trường';

    int limitCount = 5;
    String limitPeriod = 'month';
    bool isUnlimited = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Chấp nhận liên kết với $schoolName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cài đặt giới hạn đăng tuyển:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Không giới hạn'),
                value: isUnlimited,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    isUnlimited = val ?? false;
                    if (isUnlimited) limitPeriod = 'unlimited';
                    else limitPeriod = 'month'; 
                  });
                },
              ),

              if (!isUnlimited) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng tin',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        controller: TextEditingController(text: limitCount.toString()),
                        onChanged: (val) => limitCount = int.tryParse(val) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: limitPeriod,
                        decoration: const InputDecoration(
                          labelText: 'Chu kỳ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'month', child: Text('Tháng')),
                          DropdownMenuItem(value: 'year', child: Text('Năm')),
                        ],
                        onChanged: (val) => setState(() => limitPeriod = val!),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final finalPeriod = isUnlimited ? 'unlimited' : limitPeriod;
                _updateStatus(request['id'], 'accepted', limitCount: limitCount, limitPeriod: finalPeriod);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppMainColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditLimitDialog(Map<String, dynamic> partnership) {
    final schoolId = partnership['school_id'];
    final school = _schools[schoolId] ?? {};
    final schoolName = school['full_name'] ?? 'Nhà trường';

    int limitCount = partnership['post_limit_count'] ?? 5;
    String limitPeriod = partnership['post_limit_period'] ?? 'month';
    bool isUnlimited = limitPeriod == 'unlimited';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cài đặt giới hạn cho $schoolName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Không giới hạn số tin đăng'),
                value: isUnlimited,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    isUnlimited = val ?? false;
                    if (isUnlimited) limitPeriod = 'unlimited';
                    else if (limitPeriod == 'unlimited') limitPeriod = 'month';
                  });
                },
              ),
              
              if (!isUnlimited) ...[
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng tin tối đa',
                    border: OutlineInputBorder(),
                    helperText: 'Số tin trường được phép đăng lên hệ thống của bạn',
                  ),
                  controller: TextEditingController(text: limitCount.toString()),
                  onChanged: (val) => limitCount = int.tryParse(val) ?? 0,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: limitPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Chu kỳ reset giới hạn',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'month', child: Text('Theo tháng')),
                    DropdownMenuItem(value: 'year', child: Text('Theo năm')),
                  ],
                  onChanged: (val) => setState(() => limitPeriod = val!),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final finalPeriod = isUnlimited ? 'unlimited' : limitPeriod;
                _updateStatus(partnership['id'], 'accepted', limitCount: limitCount, limitPeriod: finalPeriod);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppMainColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSchoolDetail(Map<String, dynamic> schoolData) {
    // Convert generic map to Profile model to reuse CompanyDetailScreen or similar
    // Since we don't have a dedicated SchoolDetailScreen, we can reuse CompanyDetailScreen (if suitable) 
    // or just show a bottom sheet with info. 
    // Ideally we should have a `SchoolDetailScreen`. For now, I'll use a info Dialog or reuse CompanyDetailScreen if Profile matches.
    
    final profile = Profile.fromJson(schoolData);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        // Reusing CompanyDetailScreen but passing school data. 
        // Note: You might want to rename CompanyDetailScreen to ProfileDetailScreen later for clarity.
        builder: (context) => CompanyDetailScreen(
          company: profile, 
          userRole: 'employer', // Viewing as Employer
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Liên kết trường học',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppMainColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppMainColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Yêu cầu mới (${_pendingRequests.length})'),
            const Tab(text: 'Đã liên kết'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(),
                _buildPartnersList(),
              ],
            ),
    );
  }

  Widget _buildRequestsList() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu nào', 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final school = _schools[request['school_id']] ?? {};
        
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _navigateToSchoolDetail(school),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade50,
                          backgroundImage: school['avatar_url'] != null ? NetworkImage(school['avatar_url']) : null,
                          child: school['avatar_url'] == null 
                              ? const Icon(Icons.school, color: Colors.grey) 
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              school['full_name'] ?? 'Nhà trường',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              school['email'] ?? 'Chưa cập nhật email',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Chờ duyệt',
                                style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(request['id'], 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showApprovalDialog(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppMainColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Chấp nhận', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPartnersList() {
    if (_approvedPartners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Chưa có trường nào liên kết', 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvedPartners.length,
      itemBuilder: (context, index) {
        final partner = _approvedPartners[index];
        final school = _schools[partner['school_id']] ?? {};
        final isUnlimited = partner['post_limit_period'] == 'unlimited';
        
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _navigateToSchoolDetail(school),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                   Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade50,
                        backgroundImage: school['avatar_url'] != null ? NetworkImage(school['avatar_url']) : null,
                        child: school['avatar_url'] == null 
                            ? const Icon(Icons.school, color: Colors.grey) 
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            school['full_name'] ?? 'Nhà trường',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUnlimited ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUnlimited ? Icons.all_inclusive : Icons.pie_chart_outline, 
                                  size: 14, 
                                  color: isUnlimited ? Colors.green : Colors.blue
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUnlimited 
                                      ? 'Không giới hạn tin'
                                      : '${partner['post_limit_count']} tin / ${partner['post_limit_period'] == 'year' ? 'năm' : 'tháng'}',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isUnlimited ? Colors.green : Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey),
                      tooltip: 'Cài đặt giới hạn',
                      onPressed: () => _showEditLimitDialog(partner),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
