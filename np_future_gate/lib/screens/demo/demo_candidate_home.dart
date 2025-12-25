import 'package:flutter/material.dart';
import 'mock_data/mock_jobs.dart';
import '../../core/models/job_model.dart';
import '../../widgets/cards/job_card.dart';

/// Demo Candidate Home - Màn hình preview cho admin
/// Không cần login, chỉ hiển thị mock data
class DemoCandidateHome extends StatelessWidget {
  const DemoCandidateHome({super.key});

  @override
  Widget build(BuildContext context) {
    final mockJobs = MockJobs.getSampleJobs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview: Candidate View'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Demo banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chế độ xem trước - Dữ liệu mẫu',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Job list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockJobs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DemoJobCard(job: mockJobs[index]),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom navigation (disabled in demo)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Đã lưu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
        onTap: (index) {
          // Disabled in demo mode
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chức năng chỉ khả dụng khi đăng nhập'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

/// Demo job card - simplified version
class _DemoJobCard extends StatelessWidget {
  final JobModel job;

  const _DemoJobCard({required this.job});

  String _formatSalary(JobSalary salary) {
    if (salary.min != null && salary.max != null) {
      return '${(salary.min! / 1000000).toStringAsFixed(0)}-${(salary.max! / 1000000).toStringAsFixed(0)} triệu VNĐ';
    }
    return 'Thỏa thuận';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chi tiết công việc - chỉ khả dụng khi đăng nhập'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company name
              Text(
                job.creatorName ?? 'Company',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),

              // Job title
              Text(
                job.metadata.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Salary & Location
              Row(
                children: [
                  Icon(Icons.payments, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatSalary(job.metadata.salary),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.metadata.workingRegions.isNotEmpty 
                          ? job.metadata.workingRegions.first
                          : 'N/A',
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tags
              Wrap(
                spacing: 8,
                children: [
if (job.metadata.employmentTypes.isNotEmpty)
                    Chip(
                      label: Text(
                        job.metadata.employmentTypes.first == 'full-time'
                            ? 'Full-time'
                            : 'Part-time',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  const Chip(
                    label: Text('Demo', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
