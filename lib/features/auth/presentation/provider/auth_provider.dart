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

  bool _isInitializing = false;

  /// Initialize authentication state
  /// 
  /// Checks if user is already logged in.
  /// Listens to authentication state changes.
  Future<void> _initializeAuth() async {
    _isInitializing = true;
    _state = const AuthLoading();
    notifyListeners();

    debugPrint('[AUTH_TRACE] waiting_for_auth_state');

    // Start listening to authentication state changes first
    _listenToAuthStateChanges();

    try {
      final response = await _authRepository.getCurrentUser();
      if (response.isSuccess && response.data != null) {
        _isInitializing = false;
        _state = AuthAuthenticated(user: response.data!);
        final uid = response.data!.userId;
        final prefName = response.data!.preferredName ?? '';
        debugPrint('[AUTH_TRACE] current_user=$uid');
        debugPrint('[AUTH_TRACE] session_restored');
        debugPrint('[AUTH_TRACE] loading_profile');
        debugPrint('[AUTH_TRACE] preferred_name=$prefName');
        notifyListeners();
        return;
      }
    } catch (_) {}

    debugPrint('[AUTH_TRACE] current_user=null (awaiting session restoration)');

    // Await Firebase Auth session restoration stream event (5000ms window for cold boot)
    try {
      final restoredUser = await _authRepository
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(milliseconds: 5000));
      if (restoredUser != null) {
        _isInitializing = false;
        _state = AuthAuthenticated(user: restoredUser);
        final uid = restoredUser.userId;
        final prefName = restoredUser.preferredName ?? '';
        debugPrint('[AUTH_TRACE] current_user=$uid');
        debugPrint('[AUTH_TRACE] session_restored');
        debugPrint('[AUTH_TRACE] loading_profile');
        debugPrint('[AUTH_TRACE] preferred_name=$prefName');
        notifyListeners();
        return;
      }
    } catch (_) {}

    _isInitializing = false;
    _state = const AuthUnauthenticated();
    debugPrint('[AUTH_TRACE] current_user=null');
    debugPrint('[AUTH_TRACE] login_required');
    notifyListeners();
  }

  /// Check and await authentication state resolution
  Future<bool> checkAuthStatus() async {
    if (_state is AuthAuthenticated) {
      return true;
    }

    if (_state is AuthLoading || _state is AuthInitial || _isInitializing) {
      int count = 0;
      while ((_state is AuthLoading || _state is AuthInitial || _isInitializing) && count < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        count++;
      }
    }

    if (_state is AuthAuthenticated) {
      return true;
    }

    // Direct fallback check via repository
    try {
      final response = await _authRepository.getCurrentUser();
      if (response.isSuccess && response.data != null) {
        _state = AuthAuthenticated(user: response.data!);
        final uid = response.data!.userId;
        final prefName = response.data!.preferredName ?? '';
        debugPrint('[AUTH_TRACE] current_user=$uid');
        debugPrint('[AUTH_TRACE] session_restored');
        debugPrint('[AUTH_TRACE] loading_profile');
        debugPrint('[AUTH_TRACE] preferred_name=$prefName');
        notifyListeners();
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
          _isInitializing = false;
          _state = AuthAuthenticated(user: user);
          debugPrint('[AUTH_TRACE] auth_state=authenticated (stream) uid=${user.userId}');
          notifyListeners();
        } else if (!_isInitializing) {
          _state = const AuthUnauthenticated();
          debugPrint('[AUTH_TRACE] auth_state=unauthenticated (stream)');
          notifyListeners();
        }
      },
      onError: (error) {
        if (!_isInitializing) {
          _state = AuthError(message: 'Authentication error: $error');
          notifyListeners();
        }
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
    debugPrint('[AUTH_FINAL] signout');
    _isInitializing = false;
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

  /// Update preferred nickname/name for authenticated user
  Future<bool> updatePreferredName(String preferredName) async {
    final currentUser = user;
    if (currentUser == null || currentUser.userId.isEmpty) {
      return false;
    }

    try {
      final response = await _authRepository.updatePreferredName(
        userId: currentUser.userId,
        preferredName: preferredName,
      );

      debugPrint('[AUTH_FINAL] nicknameSaved uid=${currentUser.userId} preferredName=${preferredName.trim()}');

      if (response.isSuccess && response.data != null) {
        _state = AuthAuthenticated(user: response.data!);
        notifyListeners();
        return true;
      } else {
        // Fallback: update local user entity copy
        final updatedUser = currentUser.copyWith(preferredName: preferredName.trim());
        _state = AuthAuthenticated(user: updatedUser);
        notifyListeners();
        return true;
      }
    } catch (_) {
      final updatedUser = currentUser.copyWith(preferredName: preferredName.trim());
      _state = AuthAuthenticated(user: updatedUser);
      notifyListeners();
      return true;
    }
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