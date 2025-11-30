import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../../widgets/navigation/custom_bottom_nav_bar.dart';
import '../test/test_home_page.dart';
import '../test/test_search_page.dart';
import '../test/test_tools_page.dart';
import '../test/test_settings_page.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    TestHomePage(),
    TestSearchPage(),
    TestToolsPage(),
    TestSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppMainColors.primaryGradient,
        ),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        primaryColor: AppMainColors.primary,
      ),
    );
  }
}
