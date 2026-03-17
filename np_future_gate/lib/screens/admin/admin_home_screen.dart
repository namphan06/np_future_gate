import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../auth/login_screen.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/demo_mode_service.dart';
import '../../core/repositories/auth_repository.dart';
import 'dashboard_page_admin.dart';
import 'users_management_page_admin.dart';
import 'content_management_page_admin.dart';
import 'reports_page_admin.dart';
import 'test_page_admin.dart';
import 'settings_page_admin.dart';
import '../chat/chat_list_screen.dart';
import '../candidate/candidate_home_screen.dart';
import '../demo/demo_candidate_home.dart';
import '../demo/demo_employer_home.dart';
import '../demo/demo_school_home.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final supabaseService = SupabaseService.instance;

  final List<Widget> _pages = const [
    DashboardPageAdmin(),
    UsersManagementPageAdmin(),
    ContentManagementPageAdmin(),
    ReportsPageAdmin(),
    const ChatListScreen(),
    TestPageAdmin(),
    SettingsPageAdmin(),
  ];

   final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard,
      'title': 'Dashboard',
      'subtitle': 'Tổng quan hệ thống',
    },
    {
      'icon': Icons.people_outline,
      'activeIcon': Icons.people,
      'title': 'Quản lý người dùng',
      'subtitle': 'Candidates, Employers, Schools',
    },
    {
      'icon': Icons.work_outline,
      'activeIcon': Icons.work,
      'title': 'Quản lý nội dung',
      'subtitle': 'Jobs, Companies, Applications',
    },
    {
      'icon': Icons.analytics_outlined,
      'activeIcon': Icons.analytics,
      'title': 'Báo cáo',
      'subtitle': 'Reports & Analytics',
    },
    {
      'icon': Icons.chat_outlined,
      'activeIcon': Icons.chat,
      'title': 'Tin nhắn',
      'subtitle': 'Quản lý tin nhắn & Hỗ trợ',
    },
    {
      'icon': Icons.science_outlined,
      'activeIcon': Icons.science,
      'title': 'Test',
      'subtitle': 'Testing & Debugging',
    },
    {
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings,
      'title': 'Cài đặt',
      'subtitle': 'System settings',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = supabaseService.currentUser;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppMainColors.primary, AppMainColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'NP Future Gate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_outlined, color: Colors.grey.shade700),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('5 thông báo mới')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppMainColors.primary, AppMainColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 3),
                          gradient: currentUser?.userMetadata?['avatar_url'] == null
                              ? LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                )
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: currentUser?.userMetadata?['avatar_url'] != null
                              ? Image.network(
                                  currentUser!.userMetadata!['avatar_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.admin_panel_settings,
                                      size: 35,
                                      color: Colors.white,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.admin_panel_settings,
                                  size: 35,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentUser?.userMetadata?['full_name'] ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final isActive = _currentIndex == index;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? AppMainColors.primary.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isActive ? item['activeIcon'] : item['icon'],
                          color: isActive ? AppMainColors.primary : Colors.grey.shade600,
                          size: 24,
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? AppMainColors.primary : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          item['subtitle'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Divider
              Divider(height: 1, color: Colors.grey.shade300),

              // Preview Views Section
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'Xem giao diện',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    _buildPreviewTile(
                      icon: Icons.person_outline,
                      title: 'Candidate View',
                      color: Colors.blue,
                      onTap: () => _enterDemoMode(context, 'candidate'),
                    ),
                    _buildPreviewTile(
                      icon: Icons.business_outlined,
                      title: 'Employer View',
                      color: Colors.orange,
                      onTap: () => _enterDemoMode(context, 'employer'),
                    ),
                    _buildPreviewTile(
                      icon: Icons.school_outlined,
                      title: 'School View',
                      color: Colors.green,
                      onTap: () => _enterDemoMode(context, 'school'),
                    ),
                  ],
                ),
              ),

              // Logout
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade600),
                  title: Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _pages[_currentIndex],
      ),
    );
  }

  Widget _buildPreviewTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  // Navigate to demo/preview screens
  void _enterDemoMode(BuildContext context, String role) {
    Widget demoScreen;
    
    switch (role) {
      case 'candidate':
        demoScreen = const DemoCandidateHome();
        break;
      case 'employer':
        demoScreen = const DemoEmployerHome();
        break;
      case 'school':
        demoScreen = const DemoSchoolHome();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => demoScreen),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi Admin Panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirm
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );

              try {
                await AuthRepository().signOut();
              } catch (e) {
                print('Logout error: $e');
              }
              if (context.mounted) {
                Navigator.pop(context); // Pop loading
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
