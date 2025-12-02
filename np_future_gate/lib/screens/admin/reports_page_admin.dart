import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';

class ReportsPageAdmin extends StatelessWidget {
  const ReportsPageAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo cáo & Phân tích',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reports & Analytics',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Time Range Selector
          Row(
            children: [
              Expanded(
                child: _buildTimeRangeButton('7 ngày', true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeRangeButton('30 ngày', false),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeRangeButton('90 ngày', false),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeRangeButton('1 năm', false),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Charts Placeholder
          _buildReportCard(
            title: 'Người dùng mới',
            icon: Icons.trending_up,
            color: Colors.blue,
            value: '+245',
            description: 'So với tuần trước',
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Việc làm đăng',
            icon: Icons.work,
            color: Colors.orange,
            value: '+89',
            description: 'So với tuần trước',
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Ứng tuyển',
            icon: Icons.description,
            color: Colors.green,
            value: '+1,234',
            description: 'So với tuần trước',
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Tỷ lệ thành công',
            icon: Icons.check_circle,
            color: Colors.purple,
            value: '68%',
            description: 'Ứng tuyển được duyệt',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppMainColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppMainColors.primary : Colors.grey.shade300,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppMainColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Icon(Icons.more_vert, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Chart Placeholder',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
