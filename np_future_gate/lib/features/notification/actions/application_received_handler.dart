import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/features/employer/screens/jobs/employer_jobs_screen.dart';
import 'package:np_future_gate/features/employer/screens/jobs/job_applicants_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handler để xử lý các action từ notification
/// Đặc biệt xử lý navigation đến job applicants screen
class ApplicationReceivedHandler {
  final JobRepository _jobRepository = JobRepository();

  /// Navigate đến job applicants screen với jobId và userId
  /// Tự động phát hiện job thường hay partnership job
  Future<void> navigateToJobApplicants({
    required BuildContext context,
    required String jobId,
    String? userId, // Optional - nếu có thì scroll đến applicant cụ thể
  }) async {
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Step 1: Detect job type (regular or partnership)
      final isPartnershipJob = await _isPartnershipJob(jobId);
      
      // Step 2: Load job model to get applicants
      final job = await _loadJob(jobId, isPartnershipJob);

      if (!context.mounted) return;

      // Hide loading
      Navigator.pop(context);

      if (job == null) {
        _showErrorDialog(context, 'Không tìm thấy công việc');
        return;
      }

      if (job.applicants.isEmpty) {
        _showNoApplicantsDialog(context);
        return;
      }

      // Step 3: Navigate to JobApplicantsScreen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobApplicantsScreen(
            jobId: jobId,
            applicants: job.applicants,
            isPartnershipJob: isPartnershipJob,
            isReadOnly: false,
          ),
        ),
      );

      // TODO: If userId provided, scroll to specific applicant after navigation
      // This would require modifying JobApplicantsScreen to accept initial scroll position
      
    } catch (e) {
      if (!context.mounted) return;
      
      // Hide loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showErrorDialog(context, e.toString());
    }
  }

  /// Navigate đến employer jobs screen (danh sách tất cả jobs)
  Future<void> navigateToEmployerJobs({
    required BuildContext context,
  }) async {
    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployerJobsScreen(),
      ),
    );
  }

  /// Kiểm tra xem job có phải là partnership job không
  Future<bool> _isPartnershipJob(String jobId) async {
    try {
      // Check if job exists in school_partnership_jobs table
      final result = await Supabase.instance.client
          .from('school_partnership_jobs')
          .select('id')
          .eq('id', jobId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('Error checking partnership job: $e');
      return false;
    }
  }

  /// Load job model (regular hoặc partnership)
  Future<JobModel?> _loadJob(
    String jobId,
    bool isPartnershipJob,
  ) async {
    try {
      if (isPartnershipJob) {
        // Load partnership job
        return await _jobRepository.getPartnershipJobById(jobId);
      } else {
        // Load regular job
        return await _jobRepository.getJobById(jobId);
      }
    } catch (e) {
      debugPrint('Error loading job: $e');
      rethrow;
    }
  }

  /// Show dialog when no applicants found
  void _showNoApplicantsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không có ứng viên'),
        content: const Text('Công việc này chưa có ứng viên nào ứng tuyển.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text('Không thể tải danh sách ứng viên:\n$error'),
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
