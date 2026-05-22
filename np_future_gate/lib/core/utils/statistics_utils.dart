import 'package:fl_chart/fl_chart.dart';

/// Utility functions for statistics data transformation.
/// These are pure functions used by controllers to prepare chart data.
class StatisticsUtils {
  StatisticsUtils._();

  /// Groups items by day within a period.
  ///
  /// Returns a list of `{'day': 'M/D', 'count': int}` maps, one entry per day
  /// in the period. Days with no matching items have a count of 0.
  ///
  /// [items] - list of data items (maps or objects with a parseable date field).
  /// [dateField] - the key name containing the date string in each item.
  /// [periodStart] - the start of the period (items before this are excluded).
  /// [periodDays] - number of days in the period.
  static List<Map<String, dynamic>> groupByDay(
    List<dynamic> items,
    String dateField,
    DateTime periodStart,
    int periodDays,
  ) {
    final grouped = <String, int>{};

    // Initialize all days in the period with 0
    for (var i = 0; i < periodDays; i++) {
      final date = periodStart.add(Duration(days: i + 1));
      final key = '${date.month}/${date.day}';
      grouped[key] = 0;
    }

    // Count items by day
    for (var item in items) {
      final dateValue = item is Map ? item[dateField] : null;
      final date = DateTime.tryParse(dateValue?.toString() ?? '');
      if (date != null && date.isAfter(periodStart)) {
        final key = '${date.month}/${date.day}';
        if (grouped.containsKey(key)) {
          grouped[key] = (grouped[key] ?? 0) + 1;
        }
      }
    }

    return grouped.entries
        .map((e) => {'day': e.key, 'count': e.value})
        .toList();
  }

  /// Converts a day-count list to [FlSpot] list for fl_chart line charts.
  ///
  /// Each entry's index becomes the x-value, and its 'count' becomes the y-value.
  /// Returns an empty list if [dayCountList] is empty.
  static List<FlSpot> buildLineChartSpots(
    List<Map<String, dynamic>> dayCountList,
  ) {
    return dayCountList.asMap().entries.map((entry) {
      final count = (entry.value['count'] as int?) ?? 0;
      return FlSpot(entry.key.toDouble(), count.toDouble());
    }).toList();
  }
}
