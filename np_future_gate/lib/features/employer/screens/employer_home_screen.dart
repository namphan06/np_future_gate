import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/employer/screens/home_page_employer.dart';
import 'package:np_future_gate/features/employer/screens/profile_page_employer.dart';
import 'package:np_future_gate/features/employer/screens/search_page_employer.dart';
import 'package:np_future_gate/features/employer/screens/tools_page_employer.dart';
import 'package:np_future_gate/shared/widgets/layouts/custom_bottom_nav_bar.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePageEmployer(),
    SearchPageEmployer(),
    ToolsPageEmployer(),
    ProfilePageEmployer(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppMainColors.lightGradient,
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
