import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/screens/candidate/job_detail_screen.dart';

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

    debugPrint('🔍 ========== APPLICATION STATUS HANDLER ==========');
    debugPrint('📋 Navigate to job detail');
    debugPrint('   jobId: $jobId');
    debugPrint('   userId: $userId');
    debugPrint('   isApproved: $isApproved');

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
        debugPrint('📋 Job not found in regular jobs, trying partnership...');
        job = await _jobRepository.getPartnershipJobById(jobId);
        isPartnershipJob = true;
      }

      if (!context.mounted) return;

      // Hide loading
      Navigator.pop(context);

      if (job == null) {
        debugPrint('❌ Job not found in both regular and partnership jobs');
        _showErrorDialog(context, 'Không tìm thấy công việc');
        return;
      }

      debugPrint('✅ Job found: ${job.metadata.title}');
      debugPrint('📋 Job type: ${isPartnershipJob ? "Partnership" : "Regular"}');

      // Navigate to job detail screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailScreen(job: job!),
        ),
      );

      debugPrint('✅ Navigation completed');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in navigateToJobDetail: $e');
      debugPrint('❌ Stack trace: $stackTrace');

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
