import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_main_colors.dart';

class PartnershipRequestsScreen extends StatefulWidget {
  const PartnershipRequestsScreen({super.key});

  @override
  State<PartnershipRequestsScreen> createState() => _PartnershipRequestsScreenState();
}

class _PartnershipRequestsScreenState extends State<PartnershipRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];
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

      // 1. Fetch partnership requests
      final response = await Supabase.instance.client
          .from('school_partnership_jobs')
          .select()
          .eq('school_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      // 2. Get unique company IDs
      final companyIds = data
          .map((e) => e['company_id'] as String)
          .toSet()
          .toList();

      // 3. Fetch company profiles
      if (companyIds.isNotEmpty) {
        final companiesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, avatar_url, email')
            .filter('id', 'in', companyIds);
        
        final companiesMap = <String, Map<String, dynamic>>{};
        for (var c in companiesResponse) {
          companiesMap[c['id']] = c;
        }
        _companies = companiesMap;
      }

      setState(() {
        _requests = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildCustomHeader(),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _requests.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu cầu liên kết',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Theo dõi tiến độ xét duyệt',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show job detail modal
  void _showJobDetail(Map<String, dynamic> request) {
    final metadata = request['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] ?? 'Chi tiết';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('Thông tin chung', [
                      _buildDetailRow(Icons.work_outline, 'Tiêu đề', title),
                      _buildDetailRow(Icons.category_outlined, 'Ngành nghề', (metadata['fields'] as List?)?.join(', ') ?? '-'),
                      _buildDetailRow(Icons.location_on_outlined, 'Địa điểm', (metadata['work_locations'] as List?)?.join(', ') ?? '-'),
                      _buildDetailRow(Icons.timer_outlined, 'Hạn nộp', request['deadline'] != null 
                          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(request['deadline'])) 
                          : '-'),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Mô tả công việc', [
                      Text(
                        (metadata['job_description'] as List?)?.join('\n') ?? 'Không có mô tả',
                        style: const TextStyle(height: 1.5, color: Colors.black87),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Yêu cầu ứng viên', [
                      Text(
                        (metadata['candidate_requirements'] as List?)?.join('\n') ?? 'Không có yêu cầu',
                        style: const TextStyle(height: 1.5, color: Colors.black87),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Quyền lợi', [
                      Text(
                        (metadata['benefits'] as List?)?.join('\n') ?? 'Không có thông tin',
                        style: const TextStyle(height: 1.5, color: Colors.black87),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppMainColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
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
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có yêu cầu liên kết nào',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final metadata = request['metadata'] as Map<String, dynamic>?;
    final title = metadata?['title'] ?? 'Không có tiêu đề';
    final companyId = request['company_id'];
    final company = _companies[companyId] ?? {};
    final companyName = company['full_name'] ?? 'Doanh nghiệp';
    final createdAt = DateTime.tryParse(request['created_at'] ?? '');

    final companyStatus = request['company_status'] ?? 'pending';
    final adminStatus = request['admin_status'] ?? 'pending';
    
    // Logic for overall status
    // If company rejected -> Failed
    // If company pending -> Pending Company
    // If company accepted -> Check Admin
    // If admin pending -> Pending Admin
    // If admin rejected -> Failed
    // If admin approved -> Approved

    return GestureDetector(
      onTap: () => _showJobDetail(request),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Job Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Doanh nghiệp: $companyName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            'Tạo ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),

              // Status Stepper
              const Text(
                'Tiến độ xét duyệt:',
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              
              // Step 1: Company
              _buildStatusStep(
                title: 'Doanh nghiệp xác thực',
                status: companyStatus, 
                rejectionReason: request['company_rejection_reason'],
                isFirst: true,
              ),
              
              // Connector line
              Container(
                margin: const EdgeInsets.only(left: 15), // Align with icon center
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),

              // Step 2: Admin
              _buildStatusStep(
                title: 'Admin phê duyệt',
                status: adminStatus,
                rejectionReason: request['admin_rejection_reason'],
                isDependentOnPrevious: companyStatus != 'accepted',
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStep({
    required String title,
    required String status,
    String? rejectionReason,
    bool isFirst = false,
    bool isLast = false,
    bool isDependentOnPrevious = false,
  }) {
    Color color;
    IconData icon;
    String statusText;

    if (isDependentOnPrevious) {
      color = Colors.grey;
      icon = Icons.radio_button_unchecked;
      statusText = 'Chờ bước trước';
    } else {
      switch (status) {
        case 'approved':
        case 'accepted':
          color = Colors.green;
          icon = Icons.check_circle;
          statusText = 'Đã chấp nhận';
          break;
        case 'rejected':
          color = Colors.red;
          icon = Icons.cancel;
          statusText = 'Từ chối';
          break;
        default: // pending
          color = Colors.orange;
          icon = Icons.pending;
          statusText = 'Đang chờ';
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (status == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Lý do: $rejectionReason',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
