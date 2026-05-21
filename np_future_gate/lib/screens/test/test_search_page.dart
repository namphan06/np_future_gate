import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class TestSearchPage extends StatelessWidget {
  const TestSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppMainColors.lightGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 100,
              color: AppMainColors.primaryLight,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tìm Kiếm',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Search Page',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
