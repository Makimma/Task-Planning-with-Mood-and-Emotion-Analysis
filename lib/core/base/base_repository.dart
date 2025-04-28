import 'package:flutter/foundation.dart';

abstract class BaseRepository {
  @protected
  Future<T> handleError<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('Repository error: $e');
      rethrow;
    }
  }
} 