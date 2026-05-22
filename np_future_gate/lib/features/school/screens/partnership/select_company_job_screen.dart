import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';

class SelectCompanyJobScreen extends StatefulWidget {

  const SelectCompanyJobScreen({super.key, required this.companyId});
  final String companyId;

  @override
  State<SelectCompanyJobScreen> createState() => _SelectCompanyJobScreenState();
}

class _SelectCompanyJobScreenState extends State<SelectCompanyJobScreen> {
  final JobRepository _jobRepository = JobRepository();
  List<JobModel> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _jobRepository.getEmployerJobs(widget.companyId);
      setState(() {
        _jobs = jobs.where((job) => job.status == 'approved').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách tin: $e')),
        );
      }
    }
  }

  String _getSalaryString(JobSalary salary) {
    if (salary.isNegotiable) return 'Thỏa thuận';
    if (salary.min != null && salary.max != null) {
      return '${salary.min}-${salary.max} triệu';
    }
    if (salary.min != null) return 'Từ ${salary.min} triệu';
    if (salary.max != null) return 'Đến ${salary.max} triệu';
    return 'Thỏa thuận';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chọn tin để sao chép'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _jobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Công ty chưa có tin tuyển dụng nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    return _buildJobCard(job);
                  },
                ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context, job);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.metadata.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.monetization_on_outlined,
                      _getSalaryString(job.metadata.salary),
                    ),
                    if (job.metadata.experienceRequired.isNotEmpty)
                      _buildInfoChip(
                        Icons.work_outline,
                        job.metadata.experienceRequired,
                      ),
                    if (job.metadata.workingRegions.isNotEmpty)
                      _buildInfoChip(
                        Icons.location_on_outlined,
                        job.metadata.workingRegions.first,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.copy, size: 16, color: Colors.purple),
                    SizedBox(width: 4),
                    Text(
                      'Nhấn để sao chép thông tin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.purple),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
