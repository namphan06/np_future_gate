/// Utility class for date/time formatting and calculations.
/// Centralizes all time-related helper methods that were previously
/// duplicated across multiple screen files.
class DateTimeUtils {
  DateTimeUtils._();

  /// Returns a human-readable "time ago" string from a DateTime.
  /// Example: "2 ngày trước", "3 giờ trước", "Vừa xong"
  static String getTimeAgo(DateTime dateTime) {
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

  /// Returns deadline text relative to now.
  /// Example: "Còn 5 ngày", "Còn 3 giờ", "Đã hết hạn"
  static String getDeadlineText(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    } else if (difference.inDays > 0) {
      return 'Còn ${difference.inDays} ngày';
    } else if (difference.inHours > 0) {
      return 'Còn ${difference.inHours} giờ';
    } else {
      return 'Sắp hết hạn';
    }
  }

  /// Checks if a DateTime is within the last [hours] hours.
  static bool isWithinHours(DateTime dateTime, int hours) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return difference.inHours <= hours;
  }
}
