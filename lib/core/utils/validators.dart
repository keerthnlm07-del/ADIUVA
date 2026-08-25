// Input validation utilities for ADIUVA backend
//
// Provides validation functions for email, password, phone, name, and other fields.
// All functions return true if input is valid, false otherwise.
//
// Used by auth services, data sources, and repositories to validate input
// before operations.

/// Regular expressions for validation
class _ValidationRegex {
  /// Email validation regex (RFC 5322 simplified)
  static final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Phone number validation (supports multiple formats)
  /// Allows: +country-code, parentheses, hyphens, spaces, and digits
  static final phoneRegex = RegExp(
    r'^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,4}[-\s.]?[0-9]{1,9}$',
  );

  /// URL validation
  static final urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );
}

/// Validate email address format
/// 
/// Checks:
/// - Email format matches pattern
/// - Contains @ symbol
/// - Has domain with extension
/// 
/// Parameters:
/// - [email] - Email string to validate
/// 
/// Returns:
/// - `true` if email is valid
/// - `false` if email is invalid or empty
/// 
/// Example:
/// ```dart
/// if (isValidEmail('user@example.com')) {
///   print('Valid email');
/// }
/// ```
bool isValidEmail(String? email) {
  if (email == null || email.isEmpty) {
    return false;
  }

  final trimmed = email.trim();

  // Check length
  if (trimmed.length > 254) {
    return false;
  }

  // Check format using regex
  if (!_ValidationRegex.emailRegex.hasMatch(trimmed)) {
    return false;
  }

  return true;
}

/// Validate password strength
/// 
/// Checks:
/// - Minimum length of 8 characters
/// - Not empty
/// 
/// Note: Does not check for specific character types (uppercase, lowercase, numbers)
/// to allow flexibility. Consider updating if stricter requirements needed.
/// 
/// Parameters:
/// - [password] - Password string to validate
/// 
/// Returns:
/// - `true` if password is valid
/// - `false` if password is invalid or too short
/// 
/// Example:
/// ```dart
/// if (isValidPassword('MyPassword123')) {
///   print('Password is strong enough');
/// }
/// ```
bool isValidPassword(String? password) {
  if (password == null || password.isEmpty) {
    return false;
  }

  // Minimum 8 characters per ADIUVA requirements
  if (password.length < 8) {
    return false;
  }

  // Maximum 128 characters (reasonable limit)
  if (password.length > 128) {
    return false;
  }

  return true;
}

/// Validate phone number format
/// 
/// Checks:
/// - Valid phone format (international or local)
/// - Contains digits
/// - Optional country code (+)
/// - Optional formatting (parentheses, hyphens, spaces)
/// 
/// Parameters:
/// - [phone] - Phone string to validate
/// 
/// Returns:
/// - `true` if phone is valid
/// - `false` if phone is invalid or empty
/// 
/// Example:
/// ```dart
/// if (isValidPhone('+919876543210')) {
///   print('Valid phone number');
/// }
/// ```
bool isValidPhone(String? phone) {
  if (phone == null || phone.isEmpty) {
    return false;
  }

  final trimmed = phone.trim();

  // Remove common formatting characters for length check
  final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d+]'), '');

  // Should have at least 7 digits
  if (digitsOnly.replaceAll('+', '').length < 7) {
    return false;
  }

  // Should have at most 15 digits (ITU-T E.164 standard)
  if (digitsOnly.replaceAll('+', '').length > 15) {
    return false;
  }

  // Check format using regex
  if (!_ValidationRegex.phoneRegex.hasMatch(trimmed)) {
    return false;
  }

  return true;
}

/// Validate user name
/// 
/// Checks:
/// - Minimum length of 2 characters
/// - Maximum length of 50 characters
/// - Only contains letters, spaces, hyphens, and apostrophes
/// 
/// Parameters:
/// - [name] - Name string to validate
/// 
/// Returns:
/// - `true` if name is valid
/// - `false` if name is invalid or empty
/// 
/// Example:
/// ```dart
/// if (isValidName('John Doe')) {
///   print('Valid name');
/// }
/// ```
bool isValidName(String? name) {
  if (name == null || name.isEmpty) {
    return false;
  }

  final trimmed = name.trim();

  // Check length constraints (2-50 characters per ADIUVA requirements)
  if (trimmed.length < 2) {
    return false;
  }

  if (trimmed.length > 50) {
    return false;
  }

  // Allow: letters (a-z, A-Z), spaces, hyphens, apostrophes
  final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
  if (!nameRegex.hasMatch(trimmed)) {
    return false;
  }

  return true;
}

/// Validate URL format
/// 
/// Checks:
/// - Valid HTTP or HTTPS protocol
/// - Proper domain structure
/// - Optional www prefix
/// 
/// Parameters:
/// - [url] - URL string to validate
/// 
/// Returns:
/// - `true` if URL is valid
/// - `false` if URL is invalid or empty
/// 
/// Example:
/// ```dart
/// if (isValidUrl('https://example.com')) {
///   print('Valid URL');
/// }
/// ```
bool isValidUrl(String? url) {
  if (url == null || url.isEmpty) {
    return false;
  }

  final trimmed = url.trim();

  // Check format using regex
  if (!_ValidationRegex.urlRegex.hasMatch(trimmed)) {
    return false;
  }

  return true;
}

/// Validate that a string is not empty or whitespace
/// 
/// Parameters:
/// - [value] - String to check
/// - [minLength] - Optional minimum length (default: 1)
/// - [maxLength] - Optional maximum length
/// 
/// Returns:
/// - `true` if string is not empty and meets length requirements
/// - `false` otherwise
/// 
/// Example:
/// ```dart
/// if (isNotEmpty(taskTitle)) {
///   print('Title is valid');
/// }
/// ```
bool isNotEmpty(
  String? value, {
  int minLength = 1,
  int? maxLength,
}) {
  if (value == null) {
    return false;
  }

  final trimmed = value.trim();

  if (trimmed.length < minLength) {
    return false;
  }

  if (maxLength != null && trimmed.length > maxLength) {
    return false;
  }

  return true;
}

/// Validate string length is within range
/// 
/// Parameters:
/// - [value] - String to validate
/// - [min] - Minimum length (inclusive)
/// - [max] - Maximum length (inclusive)
/// 
/// Returns:
/// - `true` if string length is within [min] and [max]
/// - `false` otherwise
/// 
/// Example:
/// ```dart
/// if (isWithinLength(description, 10, 500)) {
///   print('Description length is valid');
/// }
/// ```
bool isWithinLength(
  String? value,
  int min,
  int max,
) {
  if (value == null) {
    return false;
  }

  final trimmed = value.trim();
  return trimmed.length >= min && trimmed.length <= max;
}

/// Validate that value matches a pattern
/// 
/// Parameters:
/// - [value] - String to validate
/// - [pattern] - Regular expression pattern to match
/// 
/// Returns:
/// - `true` if value matches pattern
/// - `false` otherwise
/// 
/// Example:
/// ```dart
/// final pattern = RegExp(r'^\d{5}$'); // 5 digits
/// if (matchesPattern(zipCode, pattern)) {
///   print('Valid zip code');
/// }
/// ```
bool matchesPattern(String? value, RegExp pattern) {
  if (value == null || value.isEmpty) {
    return false;
  }

  return pattern.hasMatch(value);
}

/// Validate list is not empty
/// 
/// Parameters:
/// - [list] - List to check
/// 
/// Returns:
/// - `true` if list is not empty
/// - `false` if list is null or empty
/// 
/// Example:
/// ```dart
/// if (isNotEmptyList(disabilityTypes)) {
///   print('At least one disability type selected');
/// }
/// ```
bool isNotEmptyList<T>(List<T>? list) {
  return list != null && list.isNotEmpty;
}

/// Validate list length is within range
/// 
/// Parameters:
/// - [list] - List to validate
/// - [min] - Minimum length (inclusive)
/// - [max] - Maximum length (inclusive)
/// 
/// Returns:
/// - `true` if list length is within [min] and [max]
/// - `false` otherwise
/// 
/// Example:
/// ```dart
/// if (isListWithinLength(emergencyContacts, 1, 5)) {
///   print('Valid number of emergency contacts');
/// }
/// ```
bool isListWithinLength<T>(
  List<T>? list,
  int min,
  int max,
) {
  if (list == null) {
    return false;
  }

  return list.length >= min && list.length <= max;
}

/// Validate that value is in allowed list
/// 
/// Parameters:
/// - [value] - Value to check
/// - [allowedValues] - List of allowed values
/// 
/// Returns:
/// - `true` if value is in allowedValues
/// - `false` otherwise
/// 
/// Example:
/// ```dart
/// final validPriorities = ['low', 'medium', 'high'];
/// if (isInList(taskPriority, validPriorities)) {
///   print('Valid priority');
/// }
/// ```
bool isInList<T>(T? value, List<T> allowedValues) {
  if (value == null) {
    return false;
  }

  return allowedValues.contains(value);
}