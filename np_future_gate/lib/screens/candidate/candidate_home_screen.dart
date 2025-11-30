import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/screens/candidate/home_page_candidate.dart';
import 'package:np_future_gate/screens/candidate/search_page_candidate.dart';
import 'package:np_future_gate/screens/candidate/tools_page_candidate.dart';
import 'package:np_future_gate/screens/candidate/settings_page_candidate.dart';
import '../../widgets/navigation/custom_bottom_nav_bar.dart';

class CandidateHomeScreen extends StatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  State<CandidateHomeScreen> createState() => _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends State<CandidateHomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    HomePageCandidate(),
    SearchPageCandidate(),
    ToolsPageCandidate(),
    SettingsPageCandidate(),
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
