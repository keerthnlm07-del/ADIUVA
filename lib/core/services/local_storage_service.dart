import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_exception.dart';

/// Local device storage service wrapper
/// 
/// Provides simple key-value storage for non-sensitive app data.
/// Uses SharedPreferences for persistent local storage.
/// 
/// IMPORTANT: Do NOT store sensitive data like passwords or tokens here.
/// Firebase Authentication manages authentication tokens internally.
/// 
/// Use this for:
/// - App preferences (language, theme, etc.)
/// - Onboarding status
/// - User settings
/// - Cache data
/// 
/// Do NOT use this for:
/// - Firebase ID tokens (Firebase Auth handles internally)
/// - Passwords
/// - API keys
/// - Sensitive user data
/// 
/// Usage:
/// ```dart
/// final storage = LocalStorageService();
/// 
/// // Save preferences
/// await storage.saveBool('onboardingCompleted', true);
/// await storage.saveString('preferredLanguage', 'en');
/// await storage.saveInt('appLaunchCount', 5);
/// 
/// // Retrieve preferences
/// final completed = storage.getBool('onboardingCompleted') ?? false;
/// final language = storage.getString('preferredLanguage') ?? 'en';
/// final launches = storage.getInt('appLaunchCount') ?? 0;
/// 
/// // Check if key exists
/// final hasLanguage = storage.containsKey('preferredLanguage');
/// 
/// // Delete single key
/// await storage.remove('preferredLanguage');
/// 
/// // Clear all data
/// await storage.clearAll();
/// ```

class LocalStorageService {
  /// SharedPreferences instance (lazy loaded)
  static SharedPreferences? _prefs;

  /// Get SharedPreferences instance
  /// 
  /// Initializes SharedPreferences on first call.
  /// Subsequent calls return cached instance.
  /// 
  /// Throws:
  /// - [ApiException] - If initialization fails
  Future<SharedPreferences> _getPrefs() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!;
    } catch (e) {
      throw ApiException.unknown(
        'Failed to initialize local storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Save string value
  /// 
  /// Stores a string value with the given key.
  /// Overwrites existing value if key already exists.
  /// 
  /// Parameters:
  /// - [key] - Storage key (must be unique)
  /// - [value] - String value to store
  /// 
  /// Returns:
  /// - [Future<bool>] - true if save successful, false otherwise
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// await storage.saveString('preferredLanguage', 'en');
  /// ```
  Future<bool> saveString(String key, String value) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setString(key, value);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save string to storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get string value
  /// 
  /// Retrieves string value for the given key.
  /// Returns null if key doesn't exist.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// 
  /// Returns:
  /// - [String?] - Stored value or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// final language = storage.getString('preferredLanguage') ?? 'en';
  /// ```
  Future<String?> getString(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(key);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to read string from storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Save boolean value
  /// 
  /// Stores a boolean value with the given key.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// - [value] - Boolean value to store
  /// 
  /// Returns:
  /// - [Future<bool>] - true if save successful
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// await storage.saveBool('onboardingCompleted', true);
  /// ```
  Future<bool> saveBool(String key, bool value) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setBool(key, value);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save boolean to storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get boolean value
  /// 
  /// Retrieves boolean value for the given key.
  /// Returns null if key doesn't exist.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// 
  /// Returns:
  /// - [bool?] - Stored value or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// final completed = storage.getBool('onboardingCompleted') ?? false;
  /// ```
  Future<bool?> getBool(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(key);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to read boolean from storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Save integer value
  /// 
  /// Stores an integer value with the given key.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// - [value] - Integer value to store
  /// 
  /// Returns:
  /// - [Future<bool>] - true if save successful
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// await storage.saveInt('appLaunchCount', 5);
  /// ```
  Future<bool> saveInt(String key, int value) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setInt(key, value);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save integer to storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get integer value
  /// 
  /// Retrieves integer value for the given key.
  /// Returns null if key doesn't exist.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// 
  /// Returns:
  /// - [int?] - Stored value or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// final launches = storage.getInt('appLaunchCount') ?? 0;
  /// ```
  Future<int?> getInt(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getInt(key);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to read integer from storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Save double value
  /// 
  /// Stores a double value with the given key.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// - [value] - Double value to store
  /// 
  /// Returns:
  /// - [Future<bool>] - true if save successful
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// await storage.saveDouble('textSizeMultiplier', 1.2);
  /// ```
  Future<bool> saveDouble(String key, double value) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setDouble(key, value);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save double to storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get double value
  /// 
  /// Retrieves double value for the given key.
  /// Returns null if key doesn't exist.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// 
  /// Returns:
  /// - [double?] - Stored value or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// final sizeMultiplier = storage.getDouble('textSizeMultiplier') ?? 1.0;
  /// ```
  Future<double?> getDouble(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getDouble(key);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to read double from storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Save string list
  /// 
  /// Stores a list of strings with the given key.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// - [value] - List of strings to store
  /// 
  /// Returns:
  /// - [Future<bool>] - true if save successful
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// await storage.saveStringList('favoriteLanguages', ['en', 'es', 'fr']);
  /// ```
  Future<bool> saveStringList(String key, List<String> value) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setStringList(key, value);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to save string list to storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get string list
  /// 
  /// Retrieves list of strings for the given key.
  /// Returns null if key doesn't exist.
  /// 
  /// Parameters:
  /// - [key] - Storage key
  /// 
  /// Returns:
  /// - [List<String>?] - Stored list or null if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// final languages = storage.getStringList('favoriteLanguages') ?? [];
  /// ```
  Future<List<String>?> getStringList(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getStringList(key);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to read string list from storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Check if key exists in storage
  /// 
  /// Returns true if key exists, false otherwise.
  /// 
  /// Parameters:
  /// - [key] - Storage key to check
  /// 
  /// Returns:
  /// - [Future<bool>] - true if key exists, false otherwise
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// final hasLanguage = storage.containsKey('preferredLanguage');
  /// if (hasLanguage) {
  ///   print('Language preference exists');
  /// }
  /// ```
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.containsKey(key);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to check storage key',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Remove a value from storage
  /// 
  /// Deletes the value associated with the given key.
  /// Does nothing if key doesn't exist.
  /// 
  /// Parameters:
  /// - [key] - Storage key to remove
  /// 
  /// Returns:
  /// - [Future<bool>] - true if key was removed, false if not found
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// await storage.remove('preferredLanguage');
  /// ```
  Future<bool> remove(String key) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.remove(key);
    } catch (e) {
      throw ApiException.unknown(
        'Failed to remove value from storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Clear all data from storage
  /// 
  /// Deletes all stored key-value pairs.
  /// WARNING: This operation is irreversible.
  /// 
  /// Returns:
  /// - [Future<bool>] - true if all data cleared successfully
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// // Clear all local data (e.g., on logout)
  /// await storage.clearAll();
  /// ```
  Future<bool> clearAll() async {
    try {
      final prefs = await _getPrefs();
      return await prefs.clear();
    } catch (e) {
      throw ApiException.unknown(
        'Failed to clear storage',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get all keys in storage
  /// 
  /// Returns a set of all keys currently stored.
  /// Useful for debugging or migrating data.
  /// 
  /// Returns:
  /// - [Future<Set<String>>] - Set of all storage keys
  /// 
  /// Throws:
  /// - [ApiException] - If storage initialization fails
  /// 
  /// Example:
  /// ```dart
  /// final allKeys = await storage.getKeys();
  /// print('Stored keys: $allKeys');
  /// ```
  Future<Set<String>> getKeys() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getKeys();
    } catch (e) {
      throw ApiException.unknown(
        'Failed to get storage keys',
        originalException: e is Exception ? e : null,
      );
    }
  }
}