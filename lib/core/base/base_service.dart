import 'package:flutter/foundation.dart';

abstract class BaseService {
  @protected
  Future<T> handleError<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('Service error: $e');
      rethrow;
    }
  }
} 