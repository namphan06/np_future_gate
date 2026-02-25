import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/interview_model.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/job_model.dart';
import '../../core/theme/app_main_colors.dart';

class InterviewDetailCandidateScreen extends StatelessWidget {
  final InterviewModel interview;
  final Profile? employer;
  final JobModel? job;

  const InterviewDetailCandidateScreen({
    super.key,
    required this.interview,
    this.employer,
    this.job,
  });

  @override
  Widget build(BuildContext context) {
    final eval = interview.evaluation;
    final bool isShared = interview.share;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employer Info Card
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
                    backgroundImage: employer?.avatarUrl != null
                        ? NetworkImage(employer!.avatarUrl!)
                        : null,
                    child: employer?.avatarUrl == null
                        ? const Icon(Icons.business, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employer?.fullName ?? 'Nhà tuyển dụng',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          interview.jobTitle,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
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
                        DateFormat('EEEE, dd/MM/yyyy - HH:mm', 'vi').format(interview.interviewTime),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trạng thái:', style: TextStyle(color: Colors.grey)),
                      _buildStatusBadge(interview.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Evaluation Section
            if (isShared && interview.status.toLowerCase() == 'completed') ...[
              const Text(
                'Đánh giá từ nhà tuyển dụng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Đánh giá chung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        _buildStarRating((eval['rating'] as num?)?.toDouble() ?? 0),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Detailed Ratings if they exist
                    _buildRatingItem('Môi trường/Văn hóa', (eval['environment_rating'] as num?)?.toDouble() ?? 0),
                    _buildRatingItem('Phù hợp vị trí', (eval['position_rating'] as num?)?.toDouble() ?? 0),
                    _buildRatingItem('Tiềm năng phát triển', (eval['potential_rating'] as num?)?.toDouble() ?? 0),
                    _buildRatingItem('Kỹ năng giao tiếp', (eval['communication_rating'] as num?)?.toDouble() ?? 0),

                    const Divider(height: 32),
                    
                    // Note
                    const Text('Nhận xét:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      eval['note'] ?? 'Không có nhận xét chi tiết.',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    
                    if ((eval['tags'] as List?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (eval['tags'] as List).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppMainColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag.toString(),
                            style: TextStyle(color: AppMainColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (!isShared && interview.status.toLowerCase() == 'completed') ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Nhà tuyển dụng chưa chia sẻ kết quả đánh giá',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
               Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Kết quả sẽ được hiển thị sau khi buổi phỏng vấn kết thúc',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
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
      case 'postponed':
        color = Colors.amber;
        text = 'Tạm hoãn';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return const Icon(Icons.star, color: Colors.amber, size: 20);
          } else if (index < rating.ceil() && rating % 1 != 0) {
            return const Icon(Icons.star_half, color: Colors.amber, size: 20);
          } else {
            return const Icon(Icons.star_border, color: Colors.amber, size: 20);
          }
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRatingItem(String label, double rating) {
    if (rating == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text('${rating.toStringAsFixed(1)}/5.0', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rating / 5.0,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(AppMainColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
