import 'package:flutter/foundation.dart';
import '../../../../core/base/base_viewmodel.dart';
import '../../../../core/base/base_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends BaseViewModel {
  final AuthService _authService;
  BaseState _state = InitialState();
  UserModel? _user;

  AuthViewModel(this._authService);

  BaseState get state => _state;
  UserModel? get user => _user;

  Future<void> login(String email, String password) async {
    setLoading(true);
    _state = LoadingState();
    notify();

    final result = await _authService.login(email, password);
    debugPrint('Login result: ${result.isSuccess}');
    debugPrint('Login error: ${result.error}');

    if (result.isSuccess) {
      _user = result.data;
      _state = SuccessState(_user);
    } else {
      _state = ErrorState(result.error ?? 'Ошибка авторизации');
      debugPrint('Login error state: ${_state.toString()}');
    }

    setLoading(false);
    notify();
  }

  Future<void> register(String email, String password) async {
    setLoading(true);
    _state = LoadingState();
    notify();

    final result = await _authService.register(email, password);

    if (result.isSuccess) {
      _user = result.data;
      _state = SuccessState(_user);
    } else {
      _state = ErrorState(result.error ?? 'Ошибка регистрации');
    }

    setLoading(false);
    notify();
  }

  Future<void> signInWithGoogle() async {
    setLoading(true);
    _state = LoadingState();
    notify();

    final result = await _authService.signInWithGoogle();

    if (result.isSuccess) {
      _user = result.data;
      _state = SuccessState(_user);
    } else {
      _state = ErrorState(result.error ?? 'Ошибка входа через Google');
    }

    setLoading(false);
    notify();
  }

  Future<void> logout() async {
    setLoading(true);
    _state = LoadingState();
    notify();

    final result = await _authService.logout();

    if (result.isSuccess) {
      _user = null;
      _state = InitialState();
    } else {
      _state = ErrorState(result.error ?? 'Ошибка выхода');
    }

    setLoading(false);
    notify();
  }
} 