import '../entities/user_entity.dart';
import '../../../../core/models/base_response.dart';

/// Abstract repository for authentication operations
/// 
/// Defines the contract for authentication business logic.
/// Implementation in data layer handles Firebase and Firestore.
/// 
/// This is the domain layer interface - independent of frameworks.

abstract class AuthRepository {
  /// Login user with email and password
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// - [password] - User password
  /// 
  /// Returns:
  /// - [Future<BaseResponse<UserEntity>>] - Success returns authenticated user
  /// 
  /// Response contains:
  /// - [data] - UserEntity with logged-in user info (on success)
  /// - [error] - ApiException with error details (on failure)
  /// 
  /// Possible errors:
  /// - validation error: invalid email format
  /// - auth error: wrong password, user not found
  /// - network error: connection failed
  Future<BaseResponse<UserEntity>> login({
    required String email,
    required String password,
  });

  /// Authenticate user via Google Sign-In
  Future<BaseResponse<UserEntity>> signInWithGoogle();

  /// Sign up new user with email, password, and name
  /// 
  /// Creates new user account in Firebase Authentication and Firestore.
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// - [password] - User password (minimum 8 characters)
  /// - [name] - User display name
  /// 
  /// Returns:
  /// - [Future<BaseResponse<UserEntity>>] - Success returns created user
  /// 
  /// Response contains:
  /// - [data] - UserEntity with new user info (on success)
  /// - [error] - ApiException with error details (on failure)
  /// 
  /// Possible errors:
  /// - validation error: invalid email, weak password
  /// - auth error: email already exists
  /// - firestore error: user document creation failed
  /// - network error: connection failed
  Future<BaseResponse<UserEntity>> signup({
    required String email,
    required String password,
    required String name,
  });

  /// Sign out current user
  /// 
  /// Clears authentication session and removes cached user data.
  /// 
  /// Returns:
  /// - [Future<BaseResponse<void>>] - Success returns empty response
  /// 
  /// Response contains:
  /// - [error] - ApiException with error details (on failure)
  /// 
  /// Possible errors:
  /// - auth error: no user logged in
  /// - network error: logout failed
  Future<BaseResponse<void>> logout();

  /// Send password reset email
  /// 
  /// Sends password reset link to user's email address.
  /// User clicks link in email to create new password.
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// 
  /// Returns:
  /// - [Future<BaseResponse<void>>] - Success returns empty response
  /// 
  /// Response contains:
  /// - [error] - ApiException with error details (on failure)
  /// 
  /// Possible errors:
  /// - validation error: invalid email format
  /// - auth error: user not found
  /// - network error: email send failed
  Future<BaseResponse<void>> resetPassword({
    required String email,
  });

  /// Get currently authenticated user
  /// 
  /// Retrieves the user currently logged in.
  /// Returns null if no user is authenticated.
  /// 
  /// This first checks Firebase Auth state, then loads user details from Firestore.
  /// 
  /// Returns:
  /// - [Future<BaseResponse<UserEntity?>>] - Success returns user or null
  /// 
  /// Response contains:
  /// - [data] - UserEntity with current user (if logged in), null otherwise
  /// - [error] - ApiException with error details (on failure)
  /// 
  /// Possible errors:
  /// - firestore error: failed to load user data
  /// - network error: connection failed
  Future<BaseResponse<UserEntity?>> getCurrentUser();

  /// Listen to authentication state changes
  /// 
  /// Returns a stream that emits whenever authentication state changes.
  /// Emits the current user when logged in, null when logged out.
  /// 
  /// Useful for:
  /// - Updating UI on login/logout
  /// - Initializing app with current auth state
  /// - Detecting session expiration
  /// 
  /// Returns:
  /// - [Stream<UserEntity?>] - Emits user on login, null on logout
  /// 
  /// Example:
  /// ```dart
  /// authRepository.authStateChanges().listen((user) {
  ///   if (user != null) {
  ///     print('User logged in: ${user.email}');
  ///   } else {
  ///     print('User logged out');
  ///   }
  /// });
  /// ```
  Stream<UserEntity?> authStateChanges();
}