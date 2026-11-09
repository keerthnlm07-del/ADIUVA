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
  static const String _keyActiveUserId = 'auth_active_user_id';
  static const String _keyUserLoggedIn = 'user_logged_in';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  /// UID-scoped key generators
  String _keyUserId(String uid) => 'auth_user_id_$uid';
  String _keyUserEmail(String uid) => 'auth_user_email_$uid';
  String _keyUserName(String uid) => 'auth_user_name_$uid';
  String _keyPreferredName(String uid) => 'auth_preferred_name_$uid';
  String _keyUserType(String uid) => 'auth_user_type_$uid';
  String _keyDisabilityTypes(String uid) => 'auth_disability_types_$uid';
  String _keyUserLanguage(String uid) => 'auth_language_$uid';
  String _keyCachedUser(String uid) => 'auth_cached_user_json_$uid';

  AuthLocalDataSource({required LocalStorageService localStorageService})
      : _localStorageService = localStorageService;

  /// Save user data locally after successful authentication
  /// 
  /// Stores user profile data for quick access and offline support.
  /// Keys are strictly UID-scoped to prevent user profile leakage.
  Future<void> saveUserLocally(UserModel user) async {
    try {
      final uid = user.userId;
      if (uid.isEmpty) return;

      String? prefName = user.preferredName;
      if (prefName == null || prefName.trim().isEmpty) {
        final existingPrefName = await _localStorageService.getString(_keyPreferredName(uid));
        if (existingPrefName != null && existingPrefName.trim().isNotEmpty) {
          prefName = existingPrefName.trim();
        }
      }

      final effectiveUser = (prefName != null && prefName != user.preferredName)
          ? UserModel.fromEntity(user.copyWith(preferredName: prefName))
          : user;

      // Save pointer to active user
      await _localStorageService.saveString(_keyActiveUserId, uid);

      // Save individual fields for quick access, UID-scoped
      await Future.wait([
        _localStorageService.saveString(_keyUserId(uid), effectiveUser.userId),
        _localStorageService.saveString(_keyUserEmail(uid), effectiveUser.email),
        _localStorageService.saveString(_keyUserName(uid), effectiveUser.name),
        if (effectiveUser.preferredName != null && effectiveUser.preferredName!.trim().isNotEmpty)
          _localStorageService.saveString(_keyPreferredName(uid), effectiveUser.preferredName!.trim()),
        _localStorageService.saveString(_keyUserType(uid), effectiveUser.userType),
        _localStorageService.saveStringList(
          _keyDisabilityTypes(uid),
          effectiveUser.disabilityTypes,
        ),
        _localStorageService.saveString(_keyUserLanguage(uid), effectiveUser.language),
        // Save complete user JSON for reconstruction
        _localStorageService.saveString(
          _keyCachedUser(uid),
          jsonEncode(effectiveUser.toJson()),
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

  /// Load cached user from local storage for active user or specified UID
  Future<UserModel?> getCachedUser({String? targetUid}) async {
    try {
      final uid = targetUid ?? await getCachedUserId();
      if (uid == null || uid.isEmpty) {
        return null;
      }

      final cachedJson = await _localStorageService.getString(_keyCachedUser(uid));
      final storedPrefName = await _localStorageService.getString(_keyPreferredName(uid));

      if (cachedJson == null || cachedJson.isEmpty) {
        if (storedPrefName != null && storedPrefName.trim().isNotEmpty) {
          final email = await getCachedUserEmail(targetUid: uid) ?? '';
          final name = await _localStorageService.getString(_keyUserName(uid)) ?? 'User';
          return UserModel(
            userId: uid,
            email: email,
            name: name,
            preferredName: storedPrefName.trim(),
            userType: 'normal',
            disabilityTypes: const <String>[],
            language: 'en',
            isActive: true,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
        return null;
      }

      // Decode JSON and reconstruct UserModel
      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      final model = UserModel.fromJson(json);

      if ((model.preferredName == null || model.preferredName!.trim().isEmpty) &&
          storedPrefName != null &&
          storedPrefName.trim().isNotEmpty) {
        return UserModel.fromEntity(model.copyWith(preferredName: storedPrefName.trim()));
      }

      return model;
    } catch (e) {
      throw ApiException.unknown(
        'Failed to load cached user',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get active cached user ID
  Future<String?> getCachedUserId() async {
    try {
      return await _localStorageService.getString(_keyActiveUserId);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to get user ID',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get cached user email for active user or specified UID
  Future<String?> getCachedUserEmail({String? targetUid}) async {
    try {
      final uid = targetUid ?? await getCachedUserId();
      if (uid == null || uid.isEmpty) return null;
      return await _localStorageService.getString(_keyUserEmail(uid));
    } catch (e) {
      throw ApiException.unknown(
        'Failed to get user email',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Check if user is logged in locally
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

  /// Clear active session pointers from local storage
  Future<void> clearUserData() async {
    try {
      final activeUid = await getCachedUserId();
      await Future.wait([
        _localStorageService.remove(_keyActiveUserId),
        _localStorageService.saveBool(_keyUserLoggedIn, false),
        if (activeUid != null && activeUid.isNotEmpty) ...[
          _localStorageService.remove(_keyUserId(activeUid)),
          _localStorageService.remove(_keyUserEmail(activeUid)),
          _localStorageService.remove(_keyUserName(activeUid)),
          _localStorageService.remove(_keyUserType(activeUid)),
          _localStorageService.remove(_keyDisabilityTypes(activeUid)),
          _localStorageService.remove(_keyUserLanguage(activeUid)),
        ],
      ]);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to clear user data',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get user's preferred language for active user or specified UID
  Future<String> getUserLanguage({String? targetUid}) async {
    try {
      final uid = targetUid ?? await getCachedUserId();
      if (uid == null || uid.isEmpty) return 'en';
      final language =
          await _localStorageService.getString(_keyUserLanguage(uid));
      return language ?? 'en';
    } catch (e) {
      throw ApiException.unknown(
        'Failed to get user language',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Save user's preferred language for active user or specified UID
  Future<void> saveUserLanguage(String language, {String? targetUid}) async {
    try {
      final uid = targetUid ?? await getCachedUserId();
      if (uid == null || uid.isEmpty) return;
      await _localStorageService.saveString(_keyUserLanguage(uid), language);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save user language',
        originalException: e is Exception ? e : null,
      );
    }
  }
}