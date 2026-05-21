import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/auth_models.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/admin_user_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/screens/admin/user_detail_screen.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';

class UsersManagementPageAdmin extends StatefulWidget {
  const UsersManagementPageAdmin({super.key});

  @override
  State<UsersManagementPageAdmin> createState() => _UsersManagementPageAdminState();
}

class _UsersManagementPageAdminState extends State<UsersManagementPageAdmin> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminUserRepository _adminRepo = AdminUserRepository();
  
  List<Profile> _candidates = [];
  List<Profile> _employers = [];
  List<Profile> _schools = [];
  
  bool _isLoadingCandidates = false;
  bool _isLoadingEmployers = false;
  bool _isLoadingSchools = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
    _loadAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    _loadCandidates();
    _loadEmployers();
    _loadSchools();
  }

  Future<void> _loadCandidates() async {
    setState(() => _isLoadingCandidates = true);
    try {
      final users = await _adminRepo.getUsersByRole(UserRole.candidate);
      setState(() => _candidates = users);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải candidates: $e')),
      );
    } finally {
      setState(() => _isLoadingCandidates = false);
    }
  }

  Future<void> _loadEmployers() async {
    setState(() => _isLoadingEmployers = true);
    try {
      final users = await _adminRepo.getUsersByRole(UserRole.employer);
      setState(() => _employers = users);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải employers: $e')),
      );
    } finally {
      setState(() => _isLoadingEmployers = false);
    }
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final users = await _adminRepo.getUsersByRole(UserRole.school);
      setState(() => _schools = users);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải schools: $e')),
      );
    } finally {
      setState(() => _isLoadingSchools = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _loadAllUsers();
      return;
    }

    UserRole? role;
    switch (_tabController.index) {
      case 0:
        role = UserRole.candidate;
        setState(() => _isLoadingCandidates = true);
        break;
      case 1:
        role = UserRole.employer;
        setState(() => _isLoadingEmployers = true);
        break;
      case 2:
        role = UserRole.school;
        setState(() => _isLoadingSchools = true);
        break;
    }

    try {
      final results = await _adminRepo.searchUsers(query, role);
      
      setState(() {
        switch (_tabController.index) {
          case 0:
            _candidates = results;
            _isLoadingCandidates = false;
            break;
          case 1:
            _employers = results;
            _isLoadingEmployers = false;
            break;
          case 2:
            _schools = results;
            _isLoadingSchools = false;
            break;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
      );
      setState(() {
        _isLoadingCandidates = false;
        _isLoadingEmployers = false;
        _isLoadingSchools = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý người dùng',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Candidates, Employers, Schools',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SpeechTextField(
                  controller: _searchController,
                  hint: 'Tìm kiếm theo email hoặc tên...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (value == _searchQuery) {
                        _performSearch(value);
                      }
                    });
                  },
                ),
              ),
              
              TabBar(
                controller: _tabController,
                labelColor: AppMainColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppMainColors.primary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'UV (${_candidates.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'NTD (${_employers.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Trường (${_schools.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(_candidates, _isLoadingCandidates, UserRole.candidate, _loadCandidates),
              _buildUserList(_employers, _isLoadingEmployers, UserRole.employer, _loadEmployers),
              _buildUserList(_schools, _isLoadingSchools, UserRole.school, _loadSchools),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(
    List<Profile> users,
    bool isLoading,
    UserRole role,
    Future<void> Function() onRefresh,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Chưa có người dùng'
                  : 'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final roleColor = _getRoleColor(role);
    final roleIcon = _getRoleIcon(role);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: user.isActive ? Colors.transparent : Colors.red.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _navigateToUserDetail(user, onRefresh),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: user.avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(roleIcon, color: roleColor, size: 24);
                                  },
                                ),
                              )
                            : Icon(roleIcon, color: roleColor, size: 24),
                      ),
                      if (!user.isActive)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.fullName ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!user.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ngừng',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Show limits for employer and school
                        if (role == UserRole.employer && user.metadata['limit_post'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, size: 12, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Giới hạn: ${user.metadata['limit_post']} tin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // School: show both limits
                        if (role == UserRole.school && 
                            (user.metadata['limit_post'] != null || user.metadata['limit_partnership'] != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 2,
                              children: [
                                if (user.metadata['limit_post'] != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.description, size: 12, color: Colors.green.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tin: ${user.metadata['limit_post']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (user.metadata['limit_partnership'] != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.link, size: 12, color: Colors.purple.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Liên kết: ${user.metadata['limit_partnership']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.purple.shade700,
                                          fontWeight: FontWeight.w500,
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
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) => _handleUserAction(value, user, onRefresh),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('Xem chi tiết'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_active',
                        child: Row(
                          children: [
                            Icon(
                              user.isActive ? Icons.block : Icons.check_circle,
                              size: 20,
                              color: user.isActive ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(user.isActive ? 'Ngừng hoạt động' : 'Kích hoạt'),
                          ],
                        ),
                      ),
                      if (role == UserRole.employer || role == UserRole.school)
                        PopupMenuItem(
                          value: 'set_limit',
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, size: 20),
                              const SizedBox(width: 8),
                              Text(role == UserRole.school 
                                ? 'Cài đặt giới hạn' 
                                : 'Giới hạn tin đăng'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
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

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
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

  Future<void> _navigateToUserDetail(Profile user, Future<void> Function() onRefresh) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
    
    // Refresh if needed
    if (result == true || result is Profile) {
      onRefresh();
    }
  }

  void _handleUserAction(String action, Profile user, Future<void> Function() onRefresh) {
    switch (action) {
      case 'view':
        _navigateToUserDetail(user, onRefresh);
        break;
      case 'toggle_active':
        _quickToggleActive(user, onRefresh);
        break;
      case 'set_limit':
        _showQuickSetLimit(user, onRefresh);
        break;
      case 'delete':
        _showQuickDeleteConfirmation(user, onRefresh);
        break;
    }
  }

  Future<void> _quickToggleActive(Profile user, Future<void> Function() onRefresh) async {
    final newStatus = !user.isActive;
    
    try {
      await _adminRepo.toggleUserActiveStatus(user.id, newStatus);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Đã kích hoạt tài khoản' : 'Đã ngừng hoạt động tài khoản',
          ),
        ),
      );
      onRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _showQuickSetLimit(Profile user, Future<void> Function() onRefresh) {
    // For school, show dialog with 2 inputs
    if (user.role == UserRole.school) {
      _showSchoolQuickSetLimit(user, onRefresh);
      return;
    }
    
    // For employer, show dialog with 1 input
    final controller = TextEditingController(
      text: user.metadata['limit_post']?.toString() ?? '',
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
              'Nhập số lượng tin tối đa:',
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
                final updatedMetadata = Map<String, dynamic>.from(user.metadata);
                updatedMetadata.remove('limit_post');
                await _adminRepo.updateUserMetadata(user.id, updatedMetadata);
                
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa giới hạn')),
                );
                onRefresh();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
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
                await _adminRepo.setPostLimit(user.id, limit);
                
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã cập nhật: $limit tin')),
                );
                onRefresh();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
  
  void _showSchoolQuickSetLimit(Profile user, Future<void> Function() onRefresh) {
    final postController = TextEditingController(
      text: user.metadata['limit_post']?.toString() ?? '',
    );
    final partnershipController = TextEditingController(
      text: user.metadata['limit_partnership']?.toString() ?? '',
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
                final updatedMetadata = Map<String, dynamic>.from(user.metadata);
                updatedMetadata.remove('limit_post');
                updatedMetadata.remove('limit_partnership');
                await _adminRepo.updateUserMetadata(user.id, updatedMetadata);
                
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tất cả giới hạn')),
                );
                onRefresh();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
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
                final updatedMetadata = Map<String, dynamic>.from(user.metadata);
                
                if (postLimit != null) {
                  updatedMetadata['limit_post'] = postLimit;
                } else {
                  updatedMetadata.remove('limit_post');
                }
                
                if (partnershipLimit != null) {
                  updatedMetadata['limit_partnership'] = partnershipLimit;
                } else {
                  updatedMetadata.remove('limit_partnership');
                }
                
                await _adminRepo.updateUserMetadata(user.id, updatedMetadata);
                
                final messages = <String>[];
                if (postLimit != null) messages.add('Tin: $postLimit');
                if (partnershipLimit != null) messages.add('Liên kết: $partnershipLimit');
                
                if (mounted) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        messages.isEmpty
                          ? 'Đã xóa tất cả giới hạn'
                          : 'Đã cập nhật: ${messages.join(', ')}',
                      ),
                    ),
                  );
                  onRefresh();
                }
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showQuickDeleteConfirmation(Profile user, Future<void> Function() onRefresh) {
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
          'Bạn có chắc chắn muốn xóa tài khoản "${user.fullName}"?\n\n'
          'Hành động này KHÔNG THỂ HOÀN TÁC!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                await _adminRepo.deleteUserAccount(user.id);
                
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tài khoản')),
                );
                onRefresh();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi xóa tài khoản: $e')),
                );
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
}
