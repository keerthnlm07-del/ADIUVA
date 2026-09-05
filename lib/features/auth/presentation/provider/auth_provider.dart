import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import 'auth_state.dart';

/// Provider for authentication state management
/// 
/// Manages user authentication state and provides methods for:
/// - Login
/// - Signup
/// - Logout
/// - Password reset
/// - Checking authentication status
/// - Listening to auth state changes

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final SignupUseCase _signupUseCase;
  final LogoutUseCase _logoutUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final AuthRepository _authRepository;

  /// Current authentication state
  AuthState _state = const AuthInitial();

  /// Subscription to auth state changes stream
  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthProvider({
    required LoginUseCase loginUseCase,
    required SignupUseCase signupUseCase,
    required LogoutUseCase logoutUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _signupUseCase = signupUseCase,
        _logoutUseCase = logoutUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _authRepository = authRepository {
    // Initialize authentication state when provider is created
    _initializeAuth();
  }

  /// Get current authentication state
  AuthState get state => _state;

  /// Get current authenticated user (if any)
  UserEntity? get user {
    if (_state is AuthAuthenticated) {
      return (_state as AuthAuthenticated).user;
    }
    return null;
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _state is AuthAuthenticated;

  /// Check if an operation is in progress
  bool get isLoading => _state is AuthLoading;

  /// Get current error message (if any)
  String? get errorMessage {
    if (_state is AuthError) {
      return (_state as AuthError).message;
    }
    return null;
  }

  /// Get current error code (if any)
  String? get errorCode {
    if (_state is AuthError) {
      return (_state as AuthError).code;
    }
    return null;
  }

  /// Initialize authentication state
  /// 
  /// Checks if user is already logged in.
  /// Listens to authentication state changes.
  Future<void> _initializeAuth() async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      // Check current authentication status
      final response = await _authRepository.getCurrentUser();

      if (response.isSuccess && response.data != null) {
        // User is already logged in
        _state = AuthAuthenticated(user: response.data!);
      } else {
        // No user logged in
        _state = const AuthUnauthenticated();
      }
    } catch (e) {
      _state = const AuthUnauthenticated();
    }

    notifyListeners();

    // Listen to authentication state changes
    _listenToAuthStateChanges();
  }

  /// Check and await authentication state resolution
  Future<bool> checkAuthStatus() async {
    if (_state is AuthLoading || _state is AuthInitial) {
      int count = 0;
      while ((_state is AuthLoading || _state is AuthInitial) && count < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        count++;
      }
    }

    // Direct fallback check via repository
    try {
      final response = await _authRepository.getCurrentUser();
      if (response.isSuccess && response.data != null) {
        if (_state is! AuthAuthenticated) {
          _state = AuthAuthenticated(user: response.data!);
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}

    return isAuthenticated;
  }

  /// Listen to authentication state changes stream
  /// 
  /// Updates provider state whenever user logs in/out.
  void _listenToAuthStateChanges() {
    _authStateSubscription?.cancel();

    _authStateSubscription = _authRepository.authStateChanges().listen(
      (user) {
        if (user != null) {
          _state = AuthAuthenticated(user: user);
        } else {
          _state = const AuthUnauthenticated();
        }
        notifyListeners();
      },
      onError: (error) {
        _state = AuthError(message: 'Authentication error: $error');
        notifyListeners();
      },
    );
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final response = await _loginUseCase(
        email: email,
        password: password,
      );

      if (response.isSuccess && response.data != null) {
        _state = AuthAuthenticated(user: response.data!);
      } else {
        _state = AuthError(
          message: response.error?.userMessage ?? 'Login failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      _state = AuthError(message: 'Unexpected error during login: $e');
    }

    notifyListeners();
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final response = await _authRepository.signInWithGoogle();

      if (response.isSuccess && response.data != null) {
        _state = AuthAuthenticated(user: response.data!);
      } else {
        _state = AuthError(
          message: response.error?.userMessage ?? 'Google sign-in failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      _state = AuthError(message: 'Unexpected error during Google sign-in: $e');
    }

    notifyListeners();
  }

  /// Signup with user details
  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final response = await _signupUseCase(
        email: email,
        password: password,
        name: name,
      );

      if (response.isSuccess && response.data != null) {
        _state = AuthAuthenticated(user: response.data!);
      } else {
        _state = AuthError(
          message: response.error?.userMessage ?? 'Signup failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      _state = AuthError(message: 'Unexpected error during signup: $e');
    }

    notifyListeners();
  }

  /// Logout current user
  Future<void> logout() async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final response = await _logoutUseCase();

      if (response.isSuccess) {
        _state = const AuthUnauthenticated();
      } else {
        _state = AuthError(
          message: response.error?.userMessage ?? 'Logout failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      _state = AuthError(message: 'Unexpected error during logout: $e');
    }

    notifyListeners();
  }

  /// Send password reset email
  Future<void> resetPassword({
    required String email,
  }) async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final response = await _resetPasswordUseCase(email: email);

      if (response.isSuccess) {
        _state = const AuthUnauthenticated();
      } else {
        _state = AuthError(
          message: response.error?.userMessage ?? 'Password reset failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      _state = AuthError(message: 'Unexpected error during password reset: $e');
    }

    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    if (_state is AuthError) {
      _state = const AuthUnauthenticated();
      notifyListeners();
    }
  }

  /// Clear all state and reset to initial
  void reset() {
    _state = const AuthInitial();
    _authStateSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}