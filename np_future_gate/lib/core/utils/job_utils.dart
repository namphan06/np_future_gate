import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';

/// Utility class for job-related formatting and calculations.
/// Centralizes helper methods previously duplicated in employer/candidate screens.
class JobUtils {
  JobUtils._();

  /// Returns the display status of a job based on its deadline.
  static String getJobStatus(JobModel job) {
    if (job.deadline != null && job.deadline!.isBefore(DateTime.now())) {
      return 'Hết hạn';
    }
    return 'Đang tuyển';
  }

  /// Returns a formatted salary string from JobSalary.
  static String getSalaryString(JobSalary salary) {
    if (salary.isNegotiable) {
      return 'Thỏa thuận';
    }
    if (salary.min != null && salary.max != null) {
      return '${_formatNumber(salary.min!)} - ${_formatNumber(salary.max!)} triệu';
    }
    if (salary.min != null) {
      return 'Từ ${_formatNumber(salary.min!)} triệu';
    }
    if (salary.max != null) {
      return 'Đến ${_formatNumber(salary.max!)} triệu';
    }
    return 'Thỏa thuận';
  }

  /// Returns the color for deadline display based on urgency.
  static Color getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inDays <= 3) {
      return Colors.orange.shade700;
    } else {
      return Colors.green.shade600;
    }
  }

  static String _formatNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toString();
  }
}
