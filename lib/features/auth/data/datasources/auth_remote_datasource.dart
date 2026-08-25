import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/api_exception.dart';
import '../../../../core/models/base_response.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<BaseResponse<UserCredential>> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return BaseResponse<UserCredential>.success(
        data: credential,
        message: 'Login successful',
        statusCode: 200,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      return BaseResponse<UserCredential>.error(
        error: _mapFirebaseAuthException(e, stackTrace),
        statusCode: 401,
      );
    } catch (e, stackTrace) {
      return BaseResponse<UserCredential>.error(
        error: ApiException.unknown(
          'An unexpected error occurred during login.',
          originalException: e is Exception ? e : null,
          stackTrace: stackTrace,
        ),
        statusCode: 500,
      );
    }
  }

  Future<BaseResponse<UserCredential>> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Set Firebase displayName after account creation
        await user.updateDisplayName(name.trim());
      }

      return BaseResponse<UserCredential>.success(
        data: credential,
        message: 'Account created successfully',
        statusCode: 201,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      return BaseResponse<UserCredential>.error(
        error: _mapFirebaseAuthException(e, stackTrace),
        statusCode: 400,
      );
    } catch (e, stackTrace) {
      return BaseResponse<UserCredential>.error(
        error: ApiException.unknown(
          'An unexpected error occurred during signup.',
          originalException: e is Exception ? e : null,
          stackTrace: stackTrace,
        ),
        statusCode: 500,
      );
    }
  }

  Future<BaseResponse<void>> logout() async {
    try {
      await _firebaseAuth.signOut();

      return BaseResponse<void>.success(
        data: null,
        message: 'Logout successful',
        statusCode: 200,
      );
    } catch (e, stackTrace) {
      return BaseResponse<void>.error(
        error: ApiException.auth(
          'Failed to logout. Please try again.',
          originalException: e is Exception ? e : null,
          stackTrace: stackTrace,
        ),
        statusCode: 400,
      );
    }
  }

  Future<BaseResponse<void>> resetPassword({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );

      return BaseResponse<void>.success(
        data: null,
        message: 'Password reset email sent',
        statusCode: 200,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      return BaseResponse<void>.error(
        error: _mapFirebaseAuthException(e, stackTrace),
        statusCode: 400,
      );
    } catch (e, stackTrace) {
      return BaseResponse<void>.error(
        error: ApiException.unknown(
          'An unexpected error occurred while resetting the password.',
          originalException: e is Exception ? e : null,
          stackTrace: stackTrace,
        ),
        statusCode: 500,
      );
    }
  }

  Future<BaseResponse<User?>> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;

      return BaseResponse<User?>.success(
        data: user,
        message: user == null
            ? 'No authenticated user'
            : 'Current user retrieved',
        statusCode: 200,
      );
    } catch (e, stackTrace) {
      return BaseResponse<User?>.error(
        error: ApiException.auth(
          'Unable to retrieve current user.',
          originalException: e is Exception ? e : null,
          stackTrace: stackTrace,
        ),
        statusCode: 400,
      );
    }
  }

  /// Listen to authentication state changes
  /// 
  /// Returns a stream that emits whenever the user logs in or out.
  /// Emits the User when authenticated, null when logged out.
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  ApiException _mapFirebaseAuthException(
    FirebaseAuthException exception,
    StackTrace stackTrace,
  ) {
    switch (exception.code) {
      case 'invalid-email':
        return ApiException.validation(
          'Please enter a valid email address.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      case 'user-not-found':
        return ApiException.auth(
          'No account found with this email address.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      case 'wrong-password':
      case 'invalid-credential':
        return ApiException.auth(
          'Invalid email or password.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      case 'email-already-in-use':
        return ApiException.validation(
          'An account already exists with this email address.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      case 'weak-password':
        return ApiException.validation(
          'Password is too weak. Please choose a stronger password.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      case 'user-disabled':
        return ApiException.auth(
          'This account has been disabled.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      case 'too-many-requests':
        return ApiException.auth(
          'Too many attempts. Please try again later.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      case 'network-request-failed':
        return ApiException.network(
          'Network error. Please check your internet connection.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );

      default:
        return ApiException.auth(
          exception.message ?? 'Authentication failed. Please try again.',
          code: exception.code,
          originalException: exception,
          stackTrace: stackTrace,
        );
    }
  }
}