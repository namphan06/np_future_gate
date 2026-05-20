import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/auth_models.dart';
import '../../core/repositories/admin_user_repository.dart';
import '../../core/services/chat_service.dart';
import '../chat/chat_detail_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final Profile user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AdminUserRepository _adminRepo = AdminUserRepository();
  late Profile _user;
  bool _isLoading = false;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _userActivities = [];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load statistics
      final stats = await _adminRepo.getUserStatistics(_user.id, _user.role);
      
      // Load activities based on role
      List<Map<String, dynamic>> activities = [];
      switch (_user.role) {
        case UserRole.candidate:
          activities = await _adminRepo.getUserApplications(_user.id);
          break;
        case UserRole.employer:
          activities = await _adminRepo.getUserPostedJobs(_user.id);
          break;
        case UserRole.school:
          // For schools, load both regular jobs AND partnership jobs
          final regularJobs = await _adminRepo.getUserPostedJobs(_user.id);
          final partnershipJobs = await _adminRepo.getSchoolPartnershipJobs(_user.id);
          
          // Mark each job with its type
          final markedRegularJobs = regularJobs.map((job) {
            return {...job, 'job_type': 'regular'};
          }).toList();
          
          final markedPartnershipJobs = partnershipJobs.map((job) {
            return {...job, 'job_type': 'partnership'};
          }).toList();
          
          // Combine both lists
          activities = [...markedRegularJobs, ...markedPartnershipJobs];
          
          // Sort by created_at descending
          activities.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
            final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
          break;
        default:
          break;
      }
      
      setState(() {
        _statistics = stats;
        _userActivities = activities;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getRoleColor() {
    switch (_user.role) {
      case UserRole.candidate:
        return Colors.blue;
      case UserRole.employer:
        return Colors.orange;
      case UserRole.school:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon() {
    switch (_user.role) {
      case UserRole.candidate:
        return Icons.person;
      case UserRole.employer:
        return Icons.business;
      case UserRole.school:
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, _user),
        ),
        title: const Text(
          'Thông tin người dùng',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_active',
                child: Row(
                  children: [
                    Icon(
                      _user.isActive ? Icons.block : Icons.check_circle,
                      size: 20,
                      color: _user.isActive ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(_user.isActive ? 'Ngừng hoạt động' : 'Kích hoạt'),
                  ],
                ),
              ),
              if (_user.role == UserRole.employer || _user.role == UserRole.school)
                const PopupMenuItem(
                  value: 'set_limit',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 20),
                      SizedBox(width: 8),
                      Text('Giới hạn tin đăng'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(roleColor),
                    const SizedBox(height: 16),
                    _buildStatisticsCards(),
                    const SizedBox(height: 16),
                    _buildInfoSection(),
                    const SizedBox(height: 16),
                    _buildActivitiesSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Color roleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: roleColor, width: 3),
                ),
                child: _user.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(_getRoleIcon(), size: 50, color: roleColor);
                          },
                        ),
                      )
                    : Icon(_getRoleIcon(), size: 50, color: roleColor),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _user.isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _user.isActive ? Icons.check : Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user.fullName ?? 'N/A',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user.email ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(_getRoleIcon(), size: 16, color: roleColor),
                    const SizedBox(width: 6),
                    Text(
                      _user.role.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: (_user.isActive ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _user.isActive ? 'HOẠT ĐỘNG' : 'NGỪNG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _user.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openChatWithUser(context),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text('Nhắn tin cho người dùng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_statistics.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _statistics.entries.map((entry) {
              return _buildStatCard(
                _getStatLabel(entry.key),
                entry.value.toString(),
                _getStatIcon(entry.key),
                _getRoleColor(),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email, 'Email', _user.email ?? 'N/A'),
          _buildInfoRow(Icons.phone, 'Số điện thoại', _user.phone ?? 'N/A'),
          _buildInfoRow(
            Icons.calendar_today,
            'Ngày tạo',
            DateFormat('dd/MM/yyyy HH:mm').format(_user.createdAt),
          ),
          if (_user.role == UserRole.employer)
            _buildInfoRow(
              Icons.trending_up,
              'Giới hạn tin đăng',
              (_user.metadata['limit_post']?.toString() ?? 'Không giới hạn'),
            ),
          if (_user.role == UserRole.school) ...[
            _buildInfoRow(
              Icons.trending_up,
              'Giới hạn tin thông thường',
              (_user.metadata['limit_post']?.toString() ?? 'Không giới hạn'),
            ),
            _buildInfoRow(
              Icons.link,
              'Giới hạn việc liên kết',
              (_user.metadata['limit_partnership']?.toString() ?? 'Không giới hạn'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade700),
          ),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    if (_userActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    String title = '';
    switch (_user.role) {
      case UserRole.candidate:
        title = 'Đơn ứng tuyển';
        break;
      case UserRole.employer:
        title = 'Tin tuyển dụng';
        break;
      case UserRole.school:
        title = 'Việc từ trường';
        break;
      default:
        title = 'Hoạt động';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
          ..._userActivities.take(5).map((activity) {
            return _buildActivityItem(activity);
          }).toList(),
          if (_userActivities.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Show all activities
                  },
                  child: const Text('Xem tất cả'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    String title = '';
    String subtitle = '';
    bool isPartnership = false;
    
    switch (_user.role) {
      case UserRole.candidate:
        // For candidates, job data is nested in 'jobs' key
        title = activity['jobs']?['title'] ?? 'N/A';
        subtitle = activity['jobs']?['company_name'] ?? 'N/A';
        break;
      case UserRole.employer:
        // For employers, job data has title in metadata
        final metadata = activity['metadata'] as Map<String, dynamic>?;
        title = metadata?['title'] ?? activity['title'] ?? 'N/A';
        
        // Get work type from employment_types or work_locations
        final employmentTypes = metadata?['employment_types'] as List?;
        final workLocations = metadata?['work_locations'] as List?;
        subtitle = employmentTypes?.first?.toString() ?? 
                   workLocations?.first?.toString() ?? 
                   'N/A';
        break;
      case UserRole.school:
        // For schools, check if it's partnership or regular job
        isPartnership = activity['job_type'] == 'partnership';
        final metadata = activity['metadata'] as Map<String, dynamic>?;
        title = metadata?['title'] ?? activity['title'] ?? 'N/A';
        
        final employmentTypes = metadata?['employment_types'] as List?;
        subtitle = employmentTypes?.first?.toString() ?? 'N/A';
        break;
      case UserRole.admin:
        title = 'Admin Activity';
        subtitle = 'N/A';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _user.role == UserRole.candidate ? Icons.work : Icons.description,
              color: _getRoleColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPartnership)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Liên kết',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
        ],
      ),
    );
  }

  String _getStatLabel(String key) {
    switch (key) {
      case 'total_applications':
        return 'Tổng đơn';
      case 'pending_applications':
        return 'Chờ duyệt';
      case 'accepted_applications':
        return 'Được nhận';
      case 'total_jobs':
        return 'Tin tuyển dụng';
      case 'active_jobs':
        return 'Đang hoạt động';
      case 'active_regular_jobs':
        return 'Tin đang hoạt động';
      case 'total_applicants':
        return 'Ứng viên';
      case 'total_partnership_jobs':
        return 'Việc liên kết';
      default:
        return key;
    }
  }

  IconData _getStatIcon(String key) {
    switch (key) {
      case 'total_applications':
      case 'total_jobs':
      case 'total_partnership_jobs':
        return Icons.description;
      case 'pending_applications':
        return Icons.hourglass_empty;
      case 'accepted_applications':
        return Icons.check_circle;
      case 'active_jobs':
        return Icons.trending_up;
      case 'total_applicants':
        return Icons.people;
      default:
        return Icons.analytics;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_active':
        _toggleActiveStatus();
        break;
      case 'set_limit':
        _showSetLimitDialog();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _toggleActiveStatus() async {
    final newStatus = !_user.isActive;
    
    try {
      await _adminRepo.toggleUserActiveStatus(_user.id, newStatus);
      setState(() {
        _user = _user.copyWith(isActive: newStatus);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus 
                  ? 'Đã kích hoạt tài khoản' 
                  : 'Đã ngừng hoạt động tài khoản',
            ),
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

  void _showSetLimitDialog() {
    // For school, show 2 input fields
    if (_user.role == UserRole.school) {
      _showSchoolLimitDialog();
      return;
    }
    
    // For employer, show 1 input field
    final controller = TextEditingController(
      text: _user.metadata['limit_post']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giới hạn tin đăng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số lượng tin tối đa có thể đăng:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng tin',
                hintText: 'Để trống = không giới hạn',
                border: OutlineInputBorder(),
                helperText: 'Ví dụ: 10',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Clear limit
              try {
                final newMetadata = Map<String, dynamic>.from(_user.metadata);
                newMetadata.remove('limit_post');
                await _adminRepo.updateUserMetadata(_user.id, newMetadata);
                
                setState(() {
                  _user = _user.copyWith(metadata: newMetadata);
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa giới hạn tin đăng')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Xóa giới hạn', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () async {
              final limitText = controller.text.trim();
              if (limitText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập số hoặc nhấn "Xóa giới hạn"')),
                );
                return;
              }
              
              final limit = int.tryParse(limitText);
              if (limit == null || limit <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Số lượng phải là số dương')),
                );
                return;
              }
              
              try {
                await _adminRepo.setPostLimit(_user.id, limit);
                final newMetadata = Map<String, dynamic>.from(_user.metadata);
                newMetadata['limit_post'] = limit;
                
                setState(() {
                  _user = _user.copyWith(metadata: newMetadata);
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật giới hạn: $limit tin')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
  
  void _showSchoolLimitDialog() {
    final postController = TextEditingController(
      text: _user.metadata['limit_post']?.toString() ?? '',
    );
    final partnershipController = TextEditingController(
      text: _user.metadata['limit_partnership']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giới hạn tin đăng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giới hạn tin tuyển dụng thông thường:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: postController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tin thông thường',
                  hintText: 'Để trống = không giới hạn',
                  border: OutlineInputBorder(),
                  helperText: 'Ví dụ: 10',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Giới hạn việc liên kết:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: partnershipController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng việc liên kết',
                  hintText: 'Để trống = không giới hạn',
                  border: OutlineInputBorder(),
                  helperText: 'Ví dụ: 20',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Clear all limits
              try {
                final newMetadata = Map<String, dynamic>.from(_user.metadata);
                newMetadata.remove('limit_post');
                newMetadata.remove('limit_partnership');
                await _adminRepo.updateUserMetadata(_user.id, newMetadata);
                
                setState(() {
                  _user = _user.copyWith(metadata: newMetadata);
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa tất cả giới hạn')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Xóa tất cả', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () async {
              final postText = postController.text.trim();
              final partnershipText = partnershipController.text.trim();
              
              final postLimit = postText.isEmpty ? null : int.tryParse(postText);
              final partnershipLimit = partnershipText.isEmpty ? null : int.tryParse(partnershipText);
              
              if (postLimit != null && postLimit <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giới hạn tin thông thường phải là số dương')),
                );
                return;
              }
              
              if (partnershipLimit != null && partnershipLimit <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giới hạn việc liên kết phải là số dương')),
                );
                return;
              }
              
              try {
                final newMetadata = Map<String, dynamic>.from(_user.metadata);
                
                if (postLimit != null) {
                  newMetadata['limit_post'] = postLimit;
                } else {
                  newMetadata.remove('limit_post');
                }
                
                if (partnershipLimit != null) {
                  newMetadata['limit_partnership'] = partnershipLimit;
                } else {
                  newMetadata.remove('limit_partnership');
                }
                
                await _adminRepo.updateUserMetadata(_user.id, newMetadata);
                
                setState(() {
                  _user = _user.copyWith(metadata: newMetadata);
                });
                
                final messages = <String>[];
                if (postLimit != null) messages.add('Tin thông thường: $postLimit');
                if (partnershipLimit != null) messages.add('Việc liên kết: $partnershipLimit');
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        messages.isEmpty 
                          ? 'Đã xóa tất cả giới hạn'
                          : 'Đã cập nhật: ${messages.join(', ')}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa tài khoản "${_user.fullName}"?\n\n'
          'Hành động này KHÔNG THỂ HOÀN TÁC!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                await _adminRepo.deleteUserAccount(_user.id);
                
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  Navigator.pop(context, true); // Return to list with refresh flag
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa tài khoản')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi xóa tài khoản: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithUser(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final chatService = ChatService();
      String otherUserType = _user.role.value;
      // Map 'company' to 'employer' if needed for chat constraints
      if (otherUserType == 'company') otherUserType = 'employer';

      final conversation = await chatService.getOrCreateConversation(
        otherUserId: _user.id,
        otherUserType: otherUserType,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (conversation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversation: conversation,
              otherUserName: _user.fullName ?? 'Người dùng',
              otherUserAvatar: _user.avatarUrl ?? '',
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo cuộc trò chuyện. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
