import 'package:flutter/foundation.dart';

/// Base of the view models: an immutable state that the page listens to with a ListenableBuilder,
/// as HomeViewModel and HomeState do in the course project.
///
/// Every change goes through [emit], which replaces the state and notifies the page. A request that
/// finishes after the member left the screen does not notify a disposed notifier.
abstract class ViewModel<S> extends ChangeNotifier {
  ViewModel(this._state);

  S _state;
  bool _disposed = false;

  S get state => _state;

  bool get isDisposed => _disposed;

  @protected
  void emit(S state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
