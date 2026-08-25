import 'package:firebase_auth/firebase_auth.dart';
import '../models/api_exception.dart';
import '../utils/validators.dart';

/// Firebase Authentication service wrapper
/// 
/// Provides clean interface for Firebase Authentication operations.
/// Handles Firebase exceptions and converts them to ApiException.
/// Validates input before operations.
/// 
/// Usage:
/// ```dart
/// final authService = FirebaseAuthService();
/// 
/// // Signup
/// await authService.signUp(
///   email: 'user@example.com',
///   password: 'Password123',
///   name: 'John Doe',
/// );
/// 
/// // Login
/// final user = await authService.login(
///   email: 'user@example.com',
///   password: 'Password123',
/// );
/// 
/// // Get current user
/// final currentUser = authService.getCurrentUser();
/// 
/// // Logout
/// await authService.logout();
/// ```

class FirebaseAuthService {
  /// Firebase Authentication instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Get current Firebase user
  User? get _currentUser => _firebaseAuth.currentUser;

  /// Sign up new user with email and password
  /// 
  /// Validates email and password format before attempting signup.
  /// Creates user account in Firebase Authentication.
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// - [password] - User password (minimum 8 characters)
  /// - [name] - User display name (optional, for future use)
  /// 
  /// Returns:
  /// - [User] object if signup successful
  /// 
  /// Throws:
  /// - [ApiException.validation] - If email or password format is invalid
  /// - [ApiException.auth] - If Firebase Auth operation fails
  ///   - 'email-already-in-use' - User with this email already exists
  ///   - 'weak-password' - Password doesn't meet Firebase requirements
  ///   - Other Firebase errors
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await authService.signUp(
  ///     email: 'newuser@example.com',
  ///     password: 'SecurePass123',
  ///     name: 'John Doe',
  ///   );
  ///   print('User created: ${user.email}');
  /// } on ApiException catch (e) {
  ///   print('Signup failed: ${e.userMessage}');
  /// }
  /// ```
  Future<User> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    // Validate email format
    if (!isValidEmail(email)) {
      throw ApiException.validation(
        'Invalid email format',
        code: 'INVALID_EMAIL',
      );
    }

    // Validate password strength
    if (!isValidPassword(password)) {
      throw ApiException.validation(
        'Password must be at least 8 characters',
        code: 'WEAK_PASSWORD',
      );
    }

    try {
      // Create user in Firebase Authentication
      final userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw ApiException.auth(
          'User creation failed',
          code: 'USER_NULL',
        );
      }

      // Update user display name if provided
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name.trim());
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific exceptions
      String message = 'Signup failed';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already registered';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'operation-not-allowed':
          message = 'Email/password signup is disabled';
          break;
        case 'network-request-failed':
          throw ApiException.network(
            'Network error during signup',
            code: e.code,
          );
        default:
          message = 'Signup failed: ${e.message}';
      }

      throw ApiException.auth(
        message,
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error during signup',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Login user with email and password
  /// 
  /// Validates email format before attempting login.
  /// Signs in user to Firebase Authentication.
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// - [password] - User password
  /// 
  /// Returns:
  /// - [User] object if login successful
  /// 
  /// Throws:
  /// - [ApiException.validation] - If email format is invalid
  /// - [ApiException.auth] - If Firebase Auth operation fails
  ///   - 'user-not-found' - No account with this email
  ///   - 'wrong-password' - Incorrect password
  ///   - Other Firebase errors
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await authService.login(
  ///     email: 'user@example.com',
  ///     password: 'Password123',
  ///   );
  ///   print('Logged in: ${user.email}');
  /// } on ApiException catch (e) {
  ///   if (e.isAuthError) {
  ///     print('Invalid credentials');
  ///   }
  /// }
  /// ```
  Future<User> login({
    required String email,
    required String password,
  }) async {
    // Validate email format
    if (!isValidEmail(email)) {
      throw ApiException.validation(
        'Invalid email format',
        code: 'INVALID_EMAIL',
      );
    }

    // Validate password is not empty
    if (password.isEmpty) {
      throw ApiException.validation(
        'Password cannot be empty',
        code: 'EMPTY_PASSWORD',
      );
    }

    try {
      // Sign in user to Firebase Authentication
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw ApiException.auth(
          'Login failed',
          code: 'USER_NULL',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific exceptions
      String message = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Try again later';
          break;
        case 'network-request-failed':
          throw ApiException.network(
            'Network error during login',
            code: e.code,
          );
        default:
          message = 'Login failed: ${e.message}';
      }

      throw ApiException.auth(
        message,
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error during login',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Sign out current user
  /// 
  /// Clears Firebase Authentication session.
  /// User will be logged out and [getCurrentUser] will return null.
  /// 
  /// Returns:
  /// - [Future<void>] completes when logout is successful
  /// 
  /// Throws:
  /// - [ApiException.auth] - If logout operation fails
  /// 
  /// Example:
  /// ```dart
  /// await authService.logout();
  /// final user = authService.getCurrentUser();
  /// assert(user == null);
  /// ```
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw ApiException.auth(
        'Logout failed',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error during logout',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Send password reset email
  /// 
  /// Sends password reset link to user's email.
  /// User clicks link in email to reset password.
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// 
  /// Returns:
  /// - [Future<void>] completes when email is sent
  /// 
  /// Throws:
  /// - [ApiException.validation] - If email format is invalid
  /// - [ApiException.auth] - If operation fails
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await authService.resetPassword(email: 'user@example.com');
  ///   print('Password reset email sent');
  /// } on ApiException catch (e) {
  ///   print('Error: ${e.userMessage}');
  /// }
  /// ```
  Future<void> resetPassword({required String email}) async {
    // Validate email format
    if (!isValidEmail(email)) {
      throw ApiException.validation(
        'Invalid email format',
        code: 'INVALID_EMAIL',
      );
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Password reset failed';
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'network-request-failed':
          throw ApiException.network(
            'Network error during password reset',
            code: e.code,
          );
        default:
          message = 'Password reset failed: ${e.message}';
      }

      throw ApiException.auth(
        message,
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error during password reset',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get current authenticated user
  /// 
  /// Returns currently logged-in Firebase user.
  /// Returns null if no user is logged in.
  /// 
  /// Returns:
  /// - [User?] - Currently logged-in user or null
  /// 
  /// Example:
  /// ```dart
  /// final user = authService.getCurrentUser();
  /// if (user != null) {
  ///   print('Logged in as: ${user.email}');
  /// } else {
  ///   print('Not logged in');
  /// }
  /// ```
  User? getCurrentUser() {
    return _currentUser;
  }

  /// Check if user is currently logged in
  /// 
  /// Returns true if a user is authenticated, false otherwise.
  /// 
  /// Returns:
  /// - [bool] - true if user is logged in, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// if (authService.isUserLoggedIn()) {
  ///   print('User is authenticated');
  /// } else {
  ///   print('User needs to login');
  /// }
  /// ```
  bool isUserLoggedIn() {
    return _currentUser != null;
  }

  /// Listen to authentication state changes
  /// 
  /// Returns a stream that emits whenever authentication state changes.
  /// Useful for updating UI when user logs in/out.
  /// 
  /// Returns:
  /// - [Stream<User?>] - Emits User when logged in, null when logged out
  /// 
  /// Example:
  /// ```dart
  /// authService.authStateChanges().listen((User? user) {
  ///   if (user != null) {
  ///     print('User logged in: ${user.email}');
  ///   } else {
  ///     print('User logged out');
  ///   }
  /// });
  /// ```
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}