import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/core/services/notification/application_notification_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/candidate/screens/cv_selection_screen.dart';
import 'package:np_future_gate/features/candidate/screens/job_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnershipJobDetailScreen extends StatelessWidget {

  const PartnershipJobDetailScreen({super.key, required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    return _PartnershipJobDetailWrapper(job: job);
  }
}

class _PartnershipJobDetailWrapper extends StatefulWidget {

  const _PartnershipJobDetailWrapper({required this.job});
  final JobModel job;

  @override
  State<_PartnershipJobDetailWrapper> createState() => _PartnershipJobDetailWrapperState();
}

class _PartnershipJobDetailWrapperState extends State<_PartnershipJobDetailWrapper> {
  final JobRepository _jobRepository = JobRepository();
  final CVSupabaseService _cvService = CVSupabaseService();
  final ApplicationNotificationService _appNotificationService = ApplicationNotificationService();
  final AuthRepository _authRepository = AuthRepository();

  bool _hasApplied = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    if (_currentUserId == null || widget.job.id == null) return;
    final hasApplied = await _jobRepository.hasAppliedToPartnershipJob(_currentUserId!, widget.job.id!);
    if (mounted) {
      setState(() {
        _hasApplied = hasApplied;
      });
    }
  }

  Future<void> _showApplyDialog() async {
    if (_currentUserId == null) return;

    try {
      final cvs = await _cvService.getUserCVs(_currentUserId!);

      if (!mounted) return;

      if (cvs.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.description_outlined, size: 64, color: Colors.orange),
            title: const Text('Chưa có CV'),
            content: const Text('Bạn cần tạo CV trước khi ứng tuyển.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to CV creation
                },
                child: const Text('Tạo CV'),
              ),
            ],
          ),
        );
        return;
      }

      // Navigate to CV Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CVSelectionScreen(
            cvs: cvs,
            onCVSelected: (cvId) {
              Navigator.pop(context); // Close selection screen
              _applyForJob(cvId);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải CV: $e')),
      );
    }
  }

  Future<void> _applyForJob(String cvId) async {
    try {
      // 1. Ứng tuyển vào partnership job
      await _jobRepository.applyForPartnershipJob(widget.job.id!, _currentUserId!, cvId);
      
      // 2. Gửi notification đến nhà tuyển dụng
      // Lấy thông tin candidate
      final candidateProfile = await _authRepository.getCurrentUserProfile();
      final candidateName = candidateProfile?.fullName ?? 'Ứng viên';
      
      // Gửi notification (chạy background)
      _appNotificationService.notifyNewApplication(
        employerId: widget.job.creatorId,
        jobId: widget.job.id!,
        jobTitle: widget.job.metadata.title,
        candidateId: _currentUserId!,
        candidateName: candidateName,
        isPartnershipJob: true, // Đánh dấu đây là partnership job
      ).catchError((e) {
        debugPrint('⚠️ Failed to send partnership notification: $e');
      });
          
      if (mounted) {
        setState(() {
          _hasApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ứng tuyển thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi ứng tuyển: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the regular JobDetailScreen but override the apply button
    return Scaffold(
      body: JobDetailScreen(job: widget.job),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _hasApplied ? null : _showApplyDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppMainColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _hasApplied ? 'Đã ứng tuyển' : 'Ứng tuyển ngay',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
