import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../../widgets/navigation/custom_bottom_nav_bar.dart';
import 'home_page_school.dart';
import 'search_page_school.dart';
import 'tools_page_school.dart';
import 'settings_page_school.dart';

class SchoolHomeScreen extends StatefulWidget {
  const SchoolHomeScreen({super.key});

  @override
  State<SchoolHomeScreen> createState() => _SchoolHomeScreenState();
}

class _SchoolHomeScreenState extends State<SchoolHomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    HomePageSchool(),
    SearchPageSchool(),
    ToolsPageSchool(),
    SettingsPageSchool(),
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
