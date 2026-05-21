import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';

class PartnershipRequestsEmployerScreen extends StatefulWidget {
  const PartnershipRequestsEmployerScreen({super.key});

  @override
  State<PartnershipRequestsEmployerScreen> createState() => _PartnershipRequestsEmployerScreenState();
}

class _PartnershipRequestsEmployerScreenState extends State<PartnershipRequestsEmployerScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, pending, accepted, rejected

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      var query = SupabaseService.instance.client
          .from('school_partnership_jobs')
          .select()
          .eq('company_id', userId);

      if (_filterStatus != 'all') {
        query = query.eq('company_status', _filterStatus);
      }

      final jobsData = await query.order('created_at', ascending: false);
      
      // Get unique school IDs
      final schoolIds = <String>{};
      for (var job in jobsData) {
        schoolIds.add(job['school_id']);
      }

      // Fetch school profiles
      final profilesData = await SupabaseService.instance.client
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('id', schoolIds.toList());

      // Create a map for quick lookup
      final profilesMap = <String, Map<String, dynamic>>{};
      for (var profile in profilesData) {
        profilesMap[profile['id']] = profile;
      }

      // Merge data
      final mergedData = jobsData.map((job) {
        final schoolId = job['school_id'];
        return {
          ...job,
          'school': profilesMap[schoolId] ?? {},
        };
      }).toList();

      setState(() {
        _requests = mergedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải yêu cầu: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String jobId, String status, String? reason) async {
    try {
      await SupabaseService.instance.client
          .from('school_partnership_jobs')
          .update({
            'company_status': status,
            'company_rejection_reason': reason,
            'company_reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' 
              ? 'Đã chấp nhận yêu cầu. Tin sẽ được gửi đến admin để duyệt.' 
              : 'Đã từ chối yêu cầu'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String jobId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cho biết lý do từ chối:'),
            const SizedBox(height: 16),
            SpeechTextField(
              controller: reasonController,
              hint: 'Nhập lý do...',
              maxLines: 3,
            ),
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
              _updateStatus(jobId, 'rejected', reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showJobDetail(Map<String, dynamic> job) {
    final metadata = job['metadata'] as Map<String, dynamic>? ?? {};
    final schoolInfo = job['school'] as Map<String, dynamic>? ?? {};
    final status = job['company_status'] as String;
    final salary = metadata['salary'] as Map<String, dynamic>? ?? {};
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // School Info Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.school, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Yêu cầu từ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  schoolInfo['full_name'] ?? 'Không rõ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (schoolInfo['email'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.email, color: Colors.white70, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          schoolInfo['email'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Job Title
                    Text(
                      metadata['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    // Intern Badge
                    if (metadata['is_intern'] == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'VỊ TRÍ THỰC TẬP SINH',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Salary & Employment Type
                    _buildInfoSection(
                      icon: Icons.monetization_on_outlined,
                      title: 'Lương & Hình thức',
                      color: Colors.green,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Mức lương',
                            _getSalaryText(salary),
                            icon: Icons.payments_outlined,
                          ),
                          if ((metadata['employment_types'] as List?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Hình thức',
                              (metadata['employment_types'] as List).join(', '),
                              icon: Icons.work_outline,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Location & Experience
                    _buildInfoSection(
                      icon: Icons.location_on_outlined,
                      title: 'Địa điểm & Kinh nghiệm',
                      color: Colors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((metadata['working_regions'] as List?)?.isNotEmpty == true)
                            _buildDetailRow(
                              'Khu vực',
                              (metadata['working_regions'] as List).join(', '),
                              icon: Icons.map_outlined,
                            ),
                          if ((metadata['work_locations'] as List?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            const Text('Địa chỉ cụ thể:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            ...(metadata['work_locations'] as List).map((loc) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: Colors.blue)),
                                  Expanded(child: Text(loc.toString())),
                                ],
                              ),
                            )),
                          ],
                          if (metadata['experience_required'] != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Kinh nghiệm',
                              metadata['experience_required'].toString(),
                              icon: Icons.business_center_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fields & Tags
                    if ((metadata['fields'] as List?)?.isNotEmpty == true ||
                        (metadata['requirements_tags'] as List?)?.isNotEmpty == true)
                      _buildInfoSection(
                        icon: Icons.sell_outlined,
                        title: 'Lĩnh vực & Tags',
                        color: Colors.orange,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((metadata['fields'] as List?)?.isNotEmpty == true) ...[
                              const Text('Lĩnh vực:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (metadata['fields'] as List).map((field) => Chip(
                                  label: Text(field.toString()),
                                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                  side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                                )).toList(),
                              ),
                            ],
                            if ((metadata['requirements_tags'] as List?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 16),
                              const Text('Tags:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (metadata['requirements_tags'] as List).map((tag) => Chip(
                                  label: Text(tag.toString()),
                                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                                  side: BorderSide(color: Colors.purple.withValues(alpha: 0.5)),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    
                    if ((metadata['fields'] as List?)?.isNotEmpty == true ||
                        (metadata['requirements_tags'] as List?)?.isNotEmpty == true)
                      const SizedBox(height: 16),
                    
                    // Job Description
                    if ((metadata['job_description'] as List?)?.isNotEmpty == true)
                      _buildInfoSection(
                        icon: Icons.description_outlined,
                        title: 'Mô tả công việc',
                        color: Colors.indigo,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (metadata['job_description'] as List).map((desc) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.indigo,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(desc.toString(), style: const TextStyle(height: 1.6))),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    
                    if ((metadata['job_description'] as List?)?.isNotEmpty == true)
                      const SizedBox(height: 16),
                    
                    // Requirements
                    if ((metadata['candidate_requirements'] as List?)?.isNotEmpty == true)
                      _buildInfoSection(
                        icon: Icons.check_circle_outline,
                        title: 'Yêu cầu ứng viên',
                        color: Colors.teal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (metadata['candidate_requirements'] as List).map((req) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check, color: Colors.teal, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(req.toString(), style: const TextStyle(height: 1.6))),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    
                    if ((metadata['candidate_requirements'] as List?)?.isNotEmpty == true)
                      const SizedBox(height: 16),
                    
                    // Benefits
                    if ((metadata['benefits'] as List?)?.isNotEmpty == true)
                      _buildInfoSection(
                        icon: Icons.star_outline,
                        title: 'Quyền lợi',
                        color: Colors.amber,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (metadata['benefits'] as List).map((benefit) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(benefit.toString(), style: const TextStyle(height: 1.6))),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    if (status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showRejectDialog(job['id']);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 20),
                              label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateStatus(job['id'], 'accepted', null);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.check, size: 20),
                              label: const Text('Chấp nhận', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getSalaryText(Map<String, dynamic> salary) {
    if (salary['is_negotiable'] == true) return 'Thỏa thuận';
    final min = salary['min'];
    final max = salary['max'];
    if (min != null && max != null) return '$min - $max triệu VND';
    if (min != null) return 'Từ $min triệu VND';
    if (max != null) return 'Đến $max triệu VND';
    return 'Thỏa thuận';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9C27B0),
              Color(0xFFBA68C8),
              Color(0xFFF5F7FA),
            ],
            stops: [0.0, 0.3, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yêu cầu từ nhà trường',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Xem và duyệt tin liên kết',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                      ),
                      onSelected: (value) {
                        setState(() => _filterStatus = value);
                        _loadRequests();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'all', child: Text('Tất cả')),
                        const PopupMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                        const PopupMenuItem(value: 'accepted', child: Text('Đã chấp nhận')),
                        const PopupMenuItem(value: 'rejected', child: Text('Đã từ chối')),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 80, color: Colors.white.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  _filterStatus == 'all'
                                      ? 'Chưa có yêu cầu nào'
                                      : 'Không có yêu cầu nào',
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRequests,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _requests.length,
                              itemBuilder: (context, index) {
                                final request = _requests[index];
                                return _buildRequestCard(request);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final metadata = request['metadata'] as Map<String, dynamic>? ?? {};
    final schoolInfo = request['school'] as Map<String, dynamic>? ?? {};
    final status = request['company_status'] as String;
    final createdAt = DateTime.parse(request['created_at']);
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Chờ duyệt';
        statusIcon = Icons.pending_outlined;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Đã chấp nhận';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Đã từ chối';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không rõ';
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showJobDetail(request),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schoolInfo['full_name'] ?? 'Không rõ',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metadata['title'] ?? 'Không có tiêu đề',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (metadata['is_intern'] == true) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'THỰC TẬP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(request['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(request['id'], 'accepted', null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Chấp nhận'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
