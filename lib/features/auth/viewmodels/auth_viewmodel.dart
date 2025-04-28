import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/base/base_viewmodel.dart';
import '../../../../core/base/base_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';

class AuthViewModel extends BaseViewModel {
  final AuthService _authService;
  BaseState _state = InitialState();
  UserModel? _userModel;
  User? _firebaseUser;
  bool _isLogin = true;
  BuildContext? _context;

  AuthViewModel(this._authService);

  void setContext(BuildContext context) {
    _context = context;
  }

  BaseState get state => _state;
  UserModel? get userModel => _userModel;
  User? get firebaseUser => _firebaseUser;
  bool get isLogin => _isLogin;

  void toggleAuthMode() {
    _isLogin = !_isLogin;
    notify();
  }

  Future<void> authenticate(String email, String password) async {
    setLoading(true);
    _state = LoadingState();
    notify();

    final result = _isLogin
        ? await _authService.login(email, password)
        : await _authService.register(email, password);

    if (result.isSuccess) {
      _userModel = result.data;
      _firebaseUser = FirebaseAuth.instance.currentUser;
      _state = SuccessState(_userModel);
    } else {
      _state = ErrorState(result.error ?? 'Ошибка ${_isLogin ? 'входа' : 'регистрации'}');
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
      _userModel = result.data;
      _firebaseUser = FirebaseAuth.instance.currentUser;
      _state = SuccessState(_userModel);
    } else {
      _state = ErrorState(result.error ?? 'Ошибка входа через Google');
    }

    setLoading(false);
    notify();
  }

  Future<void> logout(BuildContext context) async {
    setLoading(true);
    _state = LoadingState();
    notify();

    final result = await _authService.logout();

    if (result.isSuccess) {
      _userModel = null;
      _firebaseUser = null;
      _state = InitialState();
      
      // Перенаправляем на экран авторизации
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthScreen()),
        (route) => false,
      );
    } else {
      _state = ErrorState(result.error ?? 'Ошибка выхода');
    }

    setLoading(false);
    notify();
  }
} 