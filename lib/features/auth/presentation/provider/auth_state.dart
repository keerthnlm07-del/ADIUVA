import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Base class for authentication states
/// 
/// Represents all possible authentication states in the app.
/// Uses Equatable for value comparison.

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - app just started
/// 
/// Used when the app is checking if user is already authenticated.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - operation in progress
/// 
/// Used during login, signup, logout, or checking auth state.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is logged in
/// 
/// Holds the authenticated user data.
class AuthAuthenticated extends AuthState {
  /// The authenticated user
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state - user is logged out
/// 
/// No user is currently logged in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state - an error occurred
/// 
/// Holds error information from failed operations.
class AuthError extends AuthState {
  /// Human-readable error message
  final String message;

  /// Optional error code (e.g., 'invalid-email')
  final String? code;

  const AuthError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}