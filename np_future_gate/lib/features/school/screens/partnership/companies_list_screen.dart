import 'package:flutter/material.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _partnerships = [];
  Map<String, Map<String, dynamic>> _companies = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch approved partnerships
      final response = await Supabase.instance.client
          .from('school_company_partnerships')
          .select()
          .eq('school_id', userId)
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      // Get unique company IDs
      final companyIds = data
          .map((e) => e['company_id'] as String)
          .toSet()
          .toList();

      // Fetch company profiles
      if (companyIds.isNotEmpty) {
        final companiesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, avatar_url, email, phone')
            .filter('id', 'in', companyIds);
        
        final companiesMap = <String, Map<String, dynamic>>{};
        for (var c in companiesResponse) {
          companiesMap[c['id']] = c;
        }
        _companies = companiesMap;
      }

      setState(() {
        _partnerships = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        // Fallback for development if table not ready or empty
        // Mock data for demo if query fails (e.g. table doesn't exist yet/not deployed)
        // Or just show error
        debugPrint('Error loading partnerships: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRequestDialog(Map<String, dynamic> partnership) {
    final companyId = partnership['company_id'];
    final company = _companies[companyId] ?? {};
    final companyName = company['full_name'] ?? 'Doanh nghiệp';
    final currentLimit = partnership['post_limit_count'] ?? 0;
    final String currentPeriod = partnership['post_limit_period'] == 'year' ? 'năm' : 'tháng';

    final reasonController = TextEditingController();
    String selectedRequestType = 'increase_limit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gửi yêu cầu tới $companyName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Current Status Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hiện tại: $currentLimit tin / $currentPeriod',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Loại yêu cầu', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedRequestType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'increase_limit',
                  child: Text('Tăng giới hạn tin đăng'),
                ),
                DropdownMenuItem(
                  value: 'extend_contract',
                  child: Text('Gia hạn liên kết'),
                ),
                DropdownMenuItem(
                  value: 'other_privileges',
                  child: Text('Quyền lợi khác'),
                ),
              ],
              onChanged: (val) {
                selectedRequestType = val!;
              },
            ),
            const SizedBox(height: 20),

            const Text('Lý do / Mong muốn', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SpeechTextField(
              controller: reasonController,
              maxLines: 4,
              hint: 'Nhập nội dung yêu cầu...',
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // TODO: Implement actual database insert for request
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi yêu cầu thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _partnerships.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _partnerships.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) => _buildCompanyCard(_partnerships[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh sách đối tác',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Quản lý và yêu cầu quyền lợi',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> partnership) {
    final companyId = partnership['company_id'];
    final company = _companies[companyId] ?? {};
    final companyName = company['full_name'] ?? 'Chưa cập nhật tên';
    final avatarUrl = company['avatar_url'];
    final limit = partnership['post_limit_count'] ?? 0;
    final period = partnership['post_limit_period'] == 'year' ? 'năm' : 'tháng';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.business, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
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
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Đã liên kết',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạn mức tin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$limit tin / $period',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRequestDialog(partnership),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Yêu cầu quyền'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có doanh nghiệp liên kết',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy chủ động gửi lời mời liên kết tới các doanh nghiệp',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
