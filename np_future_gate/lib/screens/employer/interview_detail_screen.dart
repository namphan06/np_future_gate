import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/interview_model.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/job_model.dart';
import '../../core/repositories/interview_repository.dart';
import '../../core/services/cv_supabase_service.dart';
import '../../core/theme/app_main_colors.dart';
import '../../widgets/speech_text_field.dart';
import '../cv/cv_setting/cv_display_manager.dart';

class InterviewDetailScreen extends StatefulWidget {
  final InterviewModel interview;
  final Profile? candidate;
  final JobModel? job;

  const InterviewDetailScreen({
    super.key,
    required this.interview,
    this.candidate,
    this.job,
  });

  @override
  State<InterviewDetailScreen> createState() => _InterviewDetailScreenState();
}

class _InterviewDetailScreenState extends State<InterviewDetailScreen> {
  final InterviewRepository _interviewRepository = InterviewRepository();
  final CVSupabaseService _cvService = CVSupabaseService();
  
  late TextEditingController _noteController;
  double _rating = 0;
  double _environmentRating = 0;
  double _positionRating = 0;
  double _potentialRating = 0;
  double _communicationRating = 0;
  Map<String, double> _requirementsEvaluation = {};
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  bool _isSaving = false;
  bool _share = false;
  late String _currentStatus;
  late DateTime _displayTime;

  @override
  void initState() {
    super.initState();
    final eval = widget.interview.evaluation;
    _noteController = TextEditingController(text: eval['note'] ?? '');
    _rating = (eval['rating'] as num?)?.toDouble() ?? 0;
    _environmentRating = (eval['environment_rating'] as num?)?.toDouble() ?? 0;
    _positionRating = (eval['position_rating'] as num?)?.toDouble() ?? 0;
    _potentialRating = (eval['potential_rating'] as num?)?.toDouble() ?? 0;
    _communicationRating = (eval['communication_rating'] as num?)?.toDouble() ?? 0;
    
    // Load requirements evaluation
    final reqEval = eval['requirements_evaluation'] as Map<String, dynamic>? ?? {};
    if (widget.job != null) {
      for (var req in widget.job!.metadata.candidateRequirements) {
        _requirementsEvaluation[req] = (reqEval[req] as num?)?.toDouble() ?? 0.0;
      }
    }

    _tags = (eval['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    
    // Load share status from dedicated column (not from evaluation JSON)
    _share = widget.interview.share;
    
    _currentStatus = widget.interview.status;
    _displayTime = widget.interview.interviewTime;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    await _saveData(isDraft: true);
  }

  Future<void> _completeInterview() async {
    await _saveData(isDraft: false);
  }

  Future<void> _saveData({required bool isDraft}) async {
    setState(() => _isSaving = true);
    try {
      final evaluation = {
        'note': _noteController.text,
        'rating': _rating,
        'environment_rating': _environmentRating,
        'position_rating': _positionRating,
        'potential_rating': _potentialRating,
        'communication_rating': _communicationRating,
        'requirements_evaluation': _requirementsEvaluation,
        'tags': _tags,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _interviewRepository.updateEvaluation(widget.interview.id, evaluation);
      
      // Update share status separately (it's a column, not in evaluation JSON)
      await _interviewRepository.updateShare(widget.interview.id, _share);
      
      if (!isDraft) {
        await _interviewRepository.updateStatus(widget.interview.id, 'completed');
        setState(() => _currentStatus = 'completed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isDraft ? 'Đã lưu nháp' : 'Đã hoàn thành phỏng vấn')),
        );
        if (!isDraft) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _postponeInterview() async {
    try {
      await _interviewRepository.updateStatus(widget.interview.id, 'postponed');
      setState(() => _currentStatus = 'postponed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạm hoãn phỏng vấn')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _rescheduleInterview() async {
    // Ensure firstDate is not after initialDate
    final now = DateTime.now();
    final initialDate = _displayTime.isBefore(now) ? now : _displayTime;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_displayTime),
      );
      
      if (pickedTime != null && mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        try {
          await _interviewRepository.rescheduleInterview(widget.interview.id, newDateTime);
          setState(() {
             _displayTime = newDateTime;
             _currentStatus = 'scheduled';
          });
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã đặt lại lịch phỏng vấn')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _deleteInterview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch phỏng vấn này? Dữ liệu sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _interviewRepository.deleteInterview(widget.interview.id);
        if (mounted) {
          Navigator.pop(context); // Close screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy lịch phỏng vấn')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi hủy lịch: $e')),
          );
        }
      }
    }
  }

  Future<void> _viewCV() async {
    if (widget.interview.cvId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy CV')),
      );
      return;
    }

    try {
      final cvData = await _cvService.getCVFullDataForEmployer(widget.interview.cvId!);
      if (cvData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CVDisplayManager.buildViewWidget(context, cvData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải CV: $e')),
        );
      }
    }
  }

  Future<void> _updateShareStatus(bool newValue) async {
    final String confirmMessage = widget.interview.isPartnership
        ? (newValue
            ? 'Bạn có chắc chắn muốn chia sẻ đánh giá này với trường đối tác?'
            : 'Bạn có chắc chắn muốn ngừng chia sẻ đánh giá này với trường đối tác?')
        : (newValue
            ? 'Bạn có chắc chắn muốn bật chia sẻ đánh giá này?'
            : 'Bạn có chắc chắn muốn tắt chia sẻ đánh giá này?');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _share = newValue);
        
        // Update share status in database (separate column)
        await _interviewRepository.updateShare(widget.interview.id, _share);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newValue
                    ? 'Đã bật chia sẻ đánh giá'
                    : 'Đã tắt chia sẻ đánh giá',
              ),
            ),
          );
        }
      } catch (e) {
        // Revert on error
        setState(() => _share = !newValue);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateEvaluation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận cập nhật'),
        content: const Text('Bạn có chắc chắn muốn cập nhật lại đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _saveData(isDraft: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết phỏng vấn',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Candidate Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: widget.candidate?.avatarUrl != null
                              ? NetworkImage(widget.candidate!.avatarUrl!)
                              : null,
                          child: widget.candidate?.avatarUrl == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.candidate?.fullName ?? 'Unknown Candidate',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.interview.jobTitle,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.description, color: Colors.blue),
                          onPressed: _viewCV,
                          tooltip: 'Xem CV',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time & Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, dd/MM/yyyy - HH:mm', 'vi').format(_displayTime),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Trạng thái:', style: TextStyle(color: Colors.grey)),
                            _buildStatusBadge(_currentStatus),
                          ],
                        ),
                        if (_currentStatus != 'completed') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _postponeInterview,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Tạm hoãn'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _rescheduleInterview,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Đặt lại lịch'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _deleteInterview,
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              label: const Text('Hủy lịch phỏng vấn', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Evaluation Section
                  const Text(
                    'Đánh giá ứng viên',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _share ? AppMainColors.primary.withOpacity(0.3) : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          color: _share ? AppMainColors.primary : Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.interview.isPartnership 
                                    ? 'Chia sẻ đánh giá cho trường'
                                    : 'Chia sẻ đánh giá',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.interview.isPartnership
                                    ? 'Trường đối tác sẽ nhận được kết quả đánh giá'
                                    : 'Cho phép chia sẻ đánh giá này với bên thứ ba',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _share,
                          onChanged: _updateShareStatus,
                          activeColor: AppMainColors.primary,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Requirements Evaluation
                        if (widget.job != null && widget.job!.metadata.candidateRequirements.isNotEmpty) ...[
                          const Text('Yêu cầu công việc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...widget.job!.metadata.candidateRequirements.map((req) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(req, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: _requirementsEvaluation[req] ?? 0,
                                        min: 0,
                                        max: 10,
                                        divisions: 10,
                                        label: (_requirementsEvaluation[req] ?? 0).toStringAsFixed(0),
                                        activeColor: AppMainColors.primary,
                                        onChanged: (val) {
                                          setState(() {
                                            _requirementsEvaluation[req] = val;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        (_requirementsEvaluation[req] ?? 0).toStringAsFixed(0),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }),
                          const Divider(height: 32),
                        ],

                        // Detailed Ratings
                        const Text('Đánh giá chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        _buildRatingRow('Phù hợp vị trí', _positionRating, (v) => setState(() => _positionRating = v)),
                        _buildRatingRow('Môi trường/Văn hóa', _environmentRating, (v) => setState(() => _environmentRating = v)),
                        _buildRatingRow('Kỹ năng giao tiếp', _communicationRating, (v) => setState(() => _communicationRating = v)),
                        _buildRatingRow('Tiềm năng phát triển', _potentialRating, (v) => setState(() => _potentialRating = v)),
                        
                        const Divider(height: 24),
                        
                        // Overall Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Đánh giá chung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${_rating.toStringAsFixed(1)}/5.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                          ],
                        ),
                        Slider(
                          value: _rating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: _rating.toString(),
                          activeColor: Colors.amber,
                          onChanged: (v) => setState(() => _rating = v),
                        ),
                        const SizedBox(height: 24),

                        // Note
                        const Text('Ghi chú / Nhận xét', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        SpeechTextField(
                          controller: _noteController,
                          maxLines: 5,
                          hint: 'Nhập nhận xét chi tiết về ứng viên...',
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        const Text('Tags', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppMainColors.primary.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppMainColors.primary.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tag,
                                    style: TextStyle(
                                      color: AppMainColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => setState(() => _tags.remove(tag)),
                                    child: Icon(Icons.close, size: 16, color: AppMainColors.primary),
                                  ),
                                ],
                              ),
                            )),
                            InkWell(
                              onTap: _showAddTagDialog,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add, size: 16, color: Colors.black54),
                                    SizedBox(width: 4),
                                    Text(
                                      'Thêm Tag',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: _currentStatus == 'completed'
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateEvaluation,
                      icon: const Icon(Icons.update, color: Colors.white),
                      label: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Cập nhật đánh giá',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppMainColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _saveDraft,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: AppMainColors.primary),
                          ),
                          child: Text(
                            'Lưu nháp',
                            style: TextStyle(
                              color: AppMainColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _completeInterview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppMainColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Hoàn thành',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Tag'),
        content: SpeechTextField(
          controller: _tagController,
          hint: 'Ví dụ: Có kinh nghiệm, Tiếng Anh tốt...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (_tagController.text.isNotEmpty) {
                setState(() => _tags.add(_tagController.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'scheduled':
        color = Colors.orange;
        text = 'Sắp tới';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Hoàn thành';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      case 'postponed':
        color = Colors.orange;
        text = 'Tạm hoãn';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, double rating, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: rating,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: rating.toStringAsFixed(0),
                  activeColor: AppMainColors.primary,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  rating.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
