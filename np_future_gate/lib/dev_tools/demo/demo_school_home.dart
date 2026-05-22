import 'package:flutter/material.dart';

/// Demo School Home - Preview cho admin
class DemoSchoolHome extends StatelessWidget {
  const DemoSchoolHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview: School View'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Demo banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Text(
                  'Chế độ xem trước - Dữ liệu mẫu',
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Giao diện School',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dữ liệu mẫu để xem trước',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
