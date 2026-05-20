import 'package:flutter/material.dart';
import '../../core/models/job_model.dart';
import '../../core/repositories/job_repository.dart';
import '../../screens/candidate/job_detail_screen.dart';

/// Handler để xử lý navigation khi application được approved/rejected
/// Điều hướng candidate đến job detail screen để xem thông tin công việc
class ApplicationStatusHandler {
  final JobRepository _jobRepository = JobRepository();

  /// Navigate đến job detail screen khi application được approve/reject
  /// 
  /// [context] - BuildContext để navigate
  /// [jobId] - ID của job
  /// [userId] - ID của candidate (optional, để hiển thị thông tin phù hợp)
  /// [isApproved] - true nếu approved, false nếu rejected
  Future<void> navigateToJobDetail({
    required BuildContext context,
    required String jobId,
    String? userId,
    bool? isApproved,
  }) async {
    if (!context.mounted) return;

    print('🔍 ========== APPLICATION STATUS HANDLER ==========');
    print('📋 Navigate to job detail');
    print('   jobId: $jobId');
    print('   userId: $userId');
    print('   isApproved: $isApproved');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Step 1: Try to load regular job first
      JobModel? job = await _jobRepository.getJobById(jobId);
      bool isPartnershipJob = false;

      // Step 2: If not found, try partnership job
      if (job == null) {
        print('📋 Job not found in regular jobs, trying partnership...');
        job = await _jobRepository.getPartnershipJobById(jobId);
        isPartnershipJob = true;
      }

      if (!context.mounted) return;

      // Hide loading
      Navigator.pop(context);

      if (job == null) {
        print('❌ Job not found in both regular and partnership jobs');
        _showErrorDialog(context, 'Không tìm thấy công việc');
        return;
      }

      print('✅ Job found: ${job.metadata.title}');
      print('📋 Job type: ${isPartnershipJob ? "Partnership" : "Regular"}');

      // Navigate to job detail screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailScreen(job: job!),
        ),
      );

      print('✅ Navigation completed');
    } catch (e, stackTrace) {
      print('❌ Error in navigateToJobDetail: $e');
      print('❌ Stack trace: $stackTrace');

      if (!context.mounted) return;

      // Hide loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showErrorDialog(context, 'Lỗi: ${e.toString()}');
    }
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
