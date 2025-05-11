import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/base/base_service.dart';
import '../../../../core/utils/result.dart';
import '../models/user_model.dart';

class AuthService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Result<UserModel>> login(String email, String password) async {
    return handleError(() async {
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user != null) {
          final user = userCredential.user!;
          return Result.success(
            UserModel(
              id: user.uid,
              email: user.email!,
              name: user.displayName,
            ),
          );
        }
        return Result.error('Ошибка входа');
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        return Result.error(_getErrorMessage(e.code));
      }
    });
  }

  Future<Result<UserModel>> register(String email, String password) async {
    return handleError(() async {
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user != null) {
          final user = userCredential.user!;
          return Result.success(
            UserModel(
              id: user.uid,
              email: user.email!,
              name: user.displayName,
            ),
          );
        }
        return Result.error('Ошибка регистрации');
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        return Result.error(_getErrorMessage(e.code));
      }
    });
  }

  Future<Result<UserModel>> signInWithGoogle() async {
    return handleError(() async {
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return Result.error('Отменено пользователем');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          final user = userCredential.user!;
          return Result.success(
            UserModel(
              id: user.uid,
              email: user.email!,
              name: user.displayName,
            ),
          );
        }
        return Result.error('Ошибка входа через Google');
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        return Result.error(_getErrorMessage(e.code));
      }
    });
  }

  Future<Result<void>> logout() async {
    return handleError(() async {
      try {
        await _auth.signOut();
        await _googleSignIn.signOut();
        return Result.success(null);
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        return Result.error(_getErrorMessage(e.code));
      }
    });
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Слабый пароль';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'user-disabled':
        return 'Пользователь заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток входа. Попробуйте позже.';
      default:
        return 'Произошла ошибка';
    }
  }
}
