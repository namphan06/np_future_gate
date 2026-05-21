import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class JobCard extends StatelessWidget {

  const JobCard({
    super.key,
    required this.job,
    this.isSaved = false,
    this.onToggleSave,
    this.isApplied = false,
    this.onTap,
    this.bottomAction,
    this.topRightBadge,
  });
  final JobModel job;
  final bool isSaved;
  final VoidCallback? onToggleSave;
  final bool isApplied;
  final VoidCallback? onTap;
  final Widget? bottomAction;
  final Widget? topRightBadge;

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Vừa xong';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String _formatSalary(JobSalary salary) {
    if (salary.isNegotiable) return 'Thỏa thuận';

    final min = salary.min ?? 0;
    final max = salary.max ?? 0;
    final currency = salary.currency;

    if (min > 0 && max <= 0) {
      return 'Từ $min $currency';
    }

    if (max > 0 && min <= 0) {
      return 'Đến $max $currency';
    }

    return '$min - $max $currency';
  }

  @override
  Widget build(BuildContext context) {
    final meta = job.metadata;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Logo, Title, Company, Save
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            image: job.creatorAvatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(job.creatorAvatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: job.creatorAvatarUrl == null
                              ? Center(
                                  child: Text(
                                    meta.title.isNotEmpty ? meta.title[0].toUpperCase() : 'J',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppMainColors.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (job.creatorName != null) ...[
                                Text(
                                  job.creatorName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppMainColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                meta.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (onToggleSave != null)
                          InkWell(
                            onTap: onToggleSave,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: isSaved ? AppMainColors.primary : Colors.grey.shade400,
                                size: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),

                    // Info Row: Salary, Region, Type
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildIconText(
                          Icons.monetization_on_outlined,
                          _formatSalary(meta.salary),
                          Colors.green.shade700,
                        ),
                        _buildIconText(
                          Icons.location_on_outlined,
                          meta.workingRegions.isNotEmpty
                              ? meta.workingRegions.first
                              : 'Toàn quốc',
                          Colors.grey.shade600,
                        ),
                        if (meta.employmentTypes.isNotEmpty)
                          _buildIconText(
                            Icons.business_center_outlined,
                            meta.employmentTypes.first,
                            Colors.orange.shade700,
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Footer: Applied Status (Left) & Date (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isApplied && bottomAction == null) // Only show default applied tag if no custom bottom action
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Đã nộp CV',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(), // Spacer if not applied

                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeAgo(job.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (bottomAction != null) ...[
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                bottomAction!,
              ],
            ],
          ),
          // Top right badge
          if (topRightBadge != null)
            Positioned(
              top: 8,
              right: 8,
              child: topRightBadge!,
            ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
