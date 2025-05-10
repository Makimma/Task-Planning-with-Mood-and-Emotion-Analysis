import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/base/base_viewmodel.dart';
import '../../../../core/base/base_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../../../core/services/notification_service.dart';
import 'dart:io';

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
    _state = InitialState();
    notify();
  }

  String _getDetailedErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Неверный формат email адреса';
      case 'user-disabled':
        return 'Этот аккаунт был отключен';
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется другим аккаунтом';
      case 'operation-not-allowed':
        return 'Операция не разрешена. Пожалуйста, обратитесь в поддержку';
      case 'weak-password':
        return 'Пароль слишком слабый. Используйте минимум 6 символов';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету';
      case 'too-many-requests':
        return 'Слишком много попыток входа. Попробуйте позже';
      case 'invalid-credential':
        return 'Неверные учетные данные';
      case 'account-exists-with-different-credential':
        return 'Аккаунт уже существует с другим способом входа';
      case 'requires-recent-login':
        return 'Требуется повторная авторизация. Пожалуйста, выйдите и войдите снова';
      case 'popup-closed-by-user':
        return 'Окно авторизации было закрыто';
      default:
        return 'Произошла ошибка: $code';
    }
  }

  Future<void> authenticate(String email, String password) async {
    setLoading(true);
    _state = LoadingState();
    notify();

    try {
      if (!await _checkInternetConnection()) {
        _state = ErrorState('Отсутствует подключение к интернету');
        setLoading(false);
        notify();
        return;
      }

      final result = _isLogin
          ? await _authService.login(email, password)
          : await _authService.register(email, password);

      if (result.isSuccess) {
        _userModel = result.data;
        _firebaseUser = FirebaseAuth.instance.currentUser;
        _state = SuccessState(_userModel);
        
        // Initialize notifications after successful login
        await NotificationService.toggleNotifications(true);
      } else {
        String errorMessage = result.error ?? 'Неизвестная ошибка';
        if (result.error != null && result.error!.contains('firebase_auth')) {
          final parts = result.error!.split('/');
          if (parts.length >= 2) {
            final code = parts[1].trim();
            errorMessage = _getDetailedErrorMessage(code);
          }
        }
        _state = ErrorState(errorMessage);
      }
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        errorMessage = _getDetailedErrorMessage(e.code);
      } else {
        errorMessage = e.toString();
        if (errorMessage.contains('firebase_auth')) {
          final parts = errorMessage.split('/');
          if (parts.length >= 2) {
            final code = parts[1].trim();
            errorMessage = _getDetailedErrorMessage(code);
          }
        }
      }
      _state = ErrorState(errorMessage);
    }

    setLoading(false);
    notify();
  }

  Future<void> signInWithGoogle() async {
    setLoading(true);
    _state = LoadingState();
    notify();

    try {
      if (!await _checkInternetConnection()) {
        _state = ErrorState('Отсутствует подключение к интернету');
        setLoading(false);
        notify();
        return;
      }

      final result = await _authService.signInWithGoogle();

      if (result.isSuccess) {
        _userModel = result.data;
        _firebaseUser = FirebaseAuth.instance.currentUser;
        _state = SuccessState(_userModel);
        
        // Initialize notifications after successful Google sign in
        await NotificationService.toggleNotifications(true);
      } else {
        String errorMessage = result.error ?? 'Ошибка входа через Google';
        if (result.error != null && result.error!.contains('firebase_auth')) {
          final parts = result.error!.split('/');
          if (parts.length >= 2) {
            final code = parts[1].trim();
            errorMessage = _getDetailedErrorMessage(code);
          }
        }
        _state = ErrorState(errorMessage);
      }
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        errorMessage = _getDetailedErrorMessage(e.code);
      } else {
        errorMessage = e.toString();
        if (errorMessage.contains('firebase_auth')) {
          final parts = errorMessage.split('/');
          if (parts.length >= 2) {
            final code = parts[1].trim();
            errorMessage = _getDetailedErrorMessage(code);
          }
        }
      }
      _state = ErrorState(errorMessage);
    }

    setLoading(false);
    notify();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    setLoading(true);
    _state = LoadingState();
    notify();

    try {
      // Отключаем уведомления в любом случае
      print('🔕 Отключение уведомлений при выходе из аккаунта...');
      await NotificationService.toggleNotifications(false);
      print('✅ Уведомления успешно отключены');

      // Пытаемся выйти из аккаунта
      final result = await _authService.logout();

      if (result.isSuccess) {
        _userModel = null;
        _firebaseUser = null;
        _state = InitialState();
        
        if (_context != null && _context!.mounted) {
          Navigator.of(_context!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => AuthScreen()),
            (route) => false,
          );
        }
      } else {
        if (result.error != null) {
          String errorMessage = result.error!;
          if (errorMessage.contains('firebase_auth')) {
            final code = errorMessage.split('/').last.trim();
            errorMessage = _getDetailedErrorMessage(code);
          }
          _state = ErrorState(errorMessage);
        }
      }
    } catch (e) {
      // Даже если произошла ошибка при выходе, очищаем локальное состояние
      _userModel = null;
      _firebaseUser = null;
      _state = InitialState();
      
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen()),
          (route) => false,
        );
      }
    }

    setLoading(false);
    notify();
  }
} 