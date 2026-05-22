import 'package:flutter/foundation.dart';

/// Abstract base class for all controllers providing common state management.
///
/// Provides:
/// - Loading state management via [isLoading]
/// - Error state management via [error] and [hasError]
/// - Safe notification via [safeNotifyListeners] that checks disposal state
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;

  /// Whether the controller is currently performing an async operation.
  bool get isLoading => _isLoading;

  /// Whether the controller has an active error.
  bool get hasError => _error != null;

  /// The current error message, or null if no error.
  String? get error => _error;

  /// Sets the loading state and notifies listeners.
  @protected
  set isLoading(bool value) {
    _isLoading = value;
    safeNotifyListeners();
  }

  /// Sets the error state and notifies listeners.
  @protected
  void setError(String? error) {
    _error = error;
    safeNotifyListeners();
  }

  /// Calls [notifyListeners] only if the controller has not been disposed.
  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
