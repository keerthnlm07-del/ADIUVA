import 'dart:convert';
import '../models/user_model.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/models/api_exception.dart';

/// Local data source for authentication
/// 
/// Stores non-sensitive user data locally using SharedPreferences.
/// Uses LocalStorageService for all storage operations.
/// 
/// IMPORTANT: This stores ONLY non-sensitive data.
/// Do NOT store: passwords, Firebase tokens, API keys, sensitive credentials
/// 
/// Stores:
/// - User ID
/// - User email
/// - User name
/// - User type
/// - Disability types
/// - Language preference
/// - Cached user data for offline access
/// - Onboarding completion status

class AuthLocalDataSource {
  /// Storage service instance
  final LocalStorageService _localStorageService;

  /// Storage keys
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUserType = 'auth_user_type';
  static const String _keyDisabilityTypes = 'auth_disability_types';
  static const String _keyUserLanguage = 'auth_language';
  static const String _keyCachedUser = 'auth_cached_user_json';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyUserLoggedIn = 'user_logged_in';

  AuthLocalDataSource({required LocalStorageService localStorageService})
      : _localStorageService = localStorageService;

  /// Save user data locally after successful authentication
  /// 
  /// Stores user profile data for quick access and offline support.
  /// Also stores JSON version for complete cached user data.
  /// 
  /// Parameters:
  /// - [user] - UserModel to save
  /// 
  /// Returns:
  /// - [Future<void>] completes when data is saved
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  /// 
  /// Example:
  /// ```dart
  /// final user = UserModel.fromFirestore(firestoreData);
  /// await localDataSource.saveUserLocally(user);
  /// ```
  Future<void> saveUserLocally(UserModel user) async {
    try {
      // Save individual fields for quick access
      await Future.wait([
        _localStorageService.saveString(_keyUserId, user.userId),
        _localStorageService.saveString(_keyUserEmail, user.email),
        _localStorageService.saveString(_keyUserName, user.name),
        _localStorageService.saveString(_keyUserType, user.userType),
        _localStorageService.saveStringList(
          _keyDisabilityTypes,
          user.disabilityTypes,
        ),
        _localStorageService.saveString(_keyUserLanguage, user.language),
        // Save complete user JSON for reconstruction
        _localStorageService.saveString(
          _keyCachedUser,
          jsonEncode(user.toJson()),
        ),
        // Mark user as logged in
        _localStorageService.saveBool(_keyUserLoggedIn, true),
      ]);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save user data locally',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Load cached user from local storage
  /// 
  /// Retrieves previously cached user data.
  /// Returns null if no user is cached.
  /// 
  /// Returns:
  /// - [UserModel?] - Cached user or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  /// 
  /// Example:
  /// ```dart
  /// final cachedUser = await localDataSource.getCachedUser();
  /// if (cachedUser != null) {
  ///   print('Loaded cached user: ${cachedUser.email}');
  /// }
  /// ```
  Future<UserModel?> getCachedUser() async {
    try {
      final cachedJson = await _localStorageService.getString(_keyCachedUser);
      if (cachedJson == null || cachedJson.isEmpty) {
        return null;
      }

      // Decode JSON and reconstruct UserModel
      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to load cached user',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get cached user ID
  /// 
  /// Quick access to user ID without loading full user object.
  /// 
  /// Returns:
  /// - [String?] - User ID or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  Future<String?> getCachedUserId() async {
    try {
      return await _localStorageService.getString(_keyUserId);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to get user ID',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get cached user email
  /// 
  /// Quick access to user email without loading full user object.
  /// 
  /// Returns:
  /// - [String?] - User email or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  Future<String?> getCachedUserEmail() async {
    try {
      return await _localStorageService.getString(_keyUserEmail);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to get user email',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Check if user is logged in locally
  /// 
  /// Returns true if user data is cached locally.
  /// This is a quick check; actual Firebase auth state may differ.
  /// 
  /// Returns:
  /// - [bool] - true if user is logged in locally, false otherwise
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  /// 
  /// Example:
  /// ```dart
  /// final isLoggedIn = await localDataSource.isUserLoggedIn();
  /// ```
  Future<bool> isUserLoggedIn() async {
    try {
      final isLoggedIn =
          await _localStorageService.getBool(_keyUserLoggedIn);
      return isLoggedIn ?? false;
    } catch (e) {
      throw ApiException.unknown(
        'Failed to check login status',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Check if onboarding is completed
  /// 
  /// Returns true if user has completed onboarding.
  /// 
  /// Returns:
  /// - [bool] - true if onboarding completed, false otherwise
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  Future<bool> isOnboardingCompleted() async {
    try {
      final completed =
          await _localStorageService.getBool(_keyOnboardingCompleted);
      return completed ?? false;
    } catch (e) {
      throw ApiException.unknown(
        'Failed to check onboarding status',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Mark onboarding as completed
  /// 
  /// Sets onboarding completion flag.
  /// 
  /// Returns:
  /// - [Future<void>] completes when flag is saved
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  Future<void> markOnboardingCompleted() async {
    try {
      await _localStorageService.saveBool(_keyOnboardingCompleted, true);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to mark onboarding completed',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Clear all user data from local storage
  /// 
  /// Removes all cached user data.
  /// Typically called on logout.
  /// 
  /// Returns:
  /// - [Future<void>] completes when data is cleared
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  /// 
  /// Example:
  /// ```dart
  /// await localDataSource.clearUserData();
  /// ```
  Future<void> clearUserData() async {
    try {
      await Future.wait([
        _localStorageService.remove(_keyUserId),
        _localStorageService.remove(_keyUserEmail),
        _localStorageService.remove(_keyUserName),
        _localStorageService.remove(_keyUserType),
        _localStorageService.remove(_keyDisabilityTypes),
        _localStorageService.remove(_keyUserLanguage),
        _localStorageService.remove(_keyCachedUser),
        _localStorageService.saveBool(_keyUserLoggedIn, false),
      ]);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to clear user data',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get user's preferred language
  /// 
  /// Returns language code or default 'en'.
  /// 
  /// Returns:
  /// - [String] - Language code (e.g., 'en', 'es')
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  Future<String> getUserLanguage() async {
    try {
      final language =
          await _localStorageService.getString(_keyUserLanguage);
      return language ?? 'en';
    } catch (e) {
      throw ApiException.unknown(
        'Failed to get user language',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Save user's preferred language
  /// 
  /// Parameters:
  /// - [language] - Language code (e.g., 'en', 'es')
  /// 
  /// Returns:
  /// - [Future<void>] completes when language is saved
  /// 
  /// Throws:
  /// - [ApiException] - If storage operation fails
  Future<void> saveUserLanguage(String language) async {
    try {
      await _localStorageService.saveString(_keyUserLanguage, language);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save user language',
        originalException: e is Exception ? e : null,
      );
    }
  }
}