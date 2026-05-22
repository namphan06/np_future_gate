import 'package:np_future_gate/core/controllers/base_controller.dart';

/// A mixin that provides reusable pagination logic for controllers.
///
/// Usage:
/// ```dart
/// class MyController extends BaseController with PaginationMixin<MyModel> {
///   @override
///   Future<List<MyModel>> fetchPage(int offset, int limit) async {
///     return await repository.getItems(offset: offset, limit: limit);
///   }
/// }
/// ```
mixin PaginationMixin<T> on BaseController {
  List<T> _items = [];
  int _currentPage = 0;
  bool _hasMore = true;

  /// Number of items to fetch per page. Override to customize.
  int get pageSize => 10;

  /// The accumulated list of items loaded across all pages.
  List<T> get items => _items;

  /// Whether there are more pages available to load.
  bool get hasMore => _hasMore;

  /// The current page index (zero-based).
  int get currentPage => _currentPage;

  /// Fetches a page of items from the data source.
  ///
  /// Subclasses must implement this to provide the actual data fetching logic.
  /// [offset] is the starting index, [limit] is the maximum number of items.
  Future<List<T>> fetchPage(int offset, int limit);

  /// Loads the next page of items.
  ///
  /// Does nothing if already loading or if there are no more pages.
  /// On success, appends new items and increments the page counter.
  /// On failure, sets the error state.
  Future<void> loadNextPage() async {
    if (isLoading || !_hasMore) return;
    isLoading = true;
    try {
      final newItems = await fetchPage(_currentPage * pageSize, pageSize);
      _items.addAll(newItems);
      _hasMore = newItems.length >= pageSize;
      _currentPage++;
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      isLoading = false;
    }
  }

  /// Resets pagination state, clearing all items and resetting the page counter.
  ///
  /// Call this when filters change or a fresh load is needed.
  void resetPagination() {
    _items = [];
    _currentPage = 0;
    _hasMore = true;
    safeNotifyListeners();
  }
}
