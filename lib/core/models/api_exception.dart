// Custom exception types for ADIUVA backend operations.
//
// This exception hierarchy provides structured error handling
// across authentication, Firestore, validation, and network operations.
//
// Usage:
// throw ApiException.auth('Invalid credentials');
// throw ApiException.firestore('Document not found');
// throw ApiException.validation('Email format invalid');

enum ExceptionType {
  // Authentication-related errors
  authentication,

  // Firestore database operation errors
  firestore,

  // Input validation errors
  validation,

  // Network/connectivity errors
  network,

  // Unknown or unclassified errors
  unknown,
}

class ApiException implements Exception {
  // Exception type classification
  final ExceptionType type;

  // Human-readable error message
  final String message;

  // Optional error code
  final String? code;

  // Optional original exception for debugging
  final Exception? originalException;

  // Stack trace for debugging
  final StackTrace? stackTrace;

  // Private constructor
  ApiException._({
    required this.type,
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  // Authentication error
  factory ApiException.auth(
    String message, {
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ApiException._(
      type: ExceptionType.authentication,
      message: message,
      code: code,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  // Firestore operation error
  factory ApiException.firestore(
    String message, {
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ApiException._(
      type: ExceptionType.firestore,
      message: message,
      code: code,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  // Input validation error
  factory ApiException.validation(
    String message, {
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ApiException._(
      type: ExceptionType.validation,
      message: message,
      code: code,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  // Network/connectivity error
  factory ApiException.network(
    String message, {
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ApiException._(
      type: ExceptionType.network,
      message: message,
      code: code,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  // Unknown error
  factory ApiException.unknown(
    String message, {
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ApiException._(
      type: ExceptionType.unknown,
      message: message,
      code: code,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  // Check authentication error
  bool get isAuthError => type == ExceptionType.authentication;

  // Check Firestore error
  bool get isFirestoreError => type == ExceptionType.firestore;

  // Check validation error
  bool get isValidationError => type == ExceptionType.validation;

  // Check network error
  bool get isNetworkError => type == ExceptionType.network;

  // User-friendly error message
  String get userMessage {
    switch (type) {
      case ExceptionType.authentication:
        return message.isEmpty
            ? 'Authentication failed. Please try again.'
            : message;

      case ExceptionType.firestore:
        return message.isEmpty
            ? 'A database error occurred. Please try again.'
            : message;

      case ExceptionType.validation:
        return message.isEmpty
            ? 'Please check your input.'
            : message;

      case ExceptionType.network:
        return message.isEmpty
            ? 'Network error. Please check your connection.'
            : message;

      case ExceptionType.unknown:
        return message.isEmpty
            ? 'An unexpected error occurred.'
            : message;
    }
  }

  // Detailed error string for logging/debugging
  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write(
      'ApiException [${type.toString().split('.').last}]: ',
    );

    buffer.write(message);

    if (code != null) {
      buffer.write(' (Code: $code)');
    }

    return buffer.toString();
  }

  // Log-friendly format with stack trace
  String toDetailedString() {
    final buffer = StringBuffer();

    buffer.writeln(toString());

    if (stackTrace != null) {
      buffer.writeln('StackTrace:');
      buffer.writeln(stackTrace);
    }

    if (originalException != null) {
      buffer.writeln(
        'Original Exception: $originalException',
      );
    }

    return buffer.toString();
  }
}