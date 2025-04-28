import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  bool get isDisposed => _isDisposed;

  @protected
  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @protected
  void notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
} 