import 'api_exception.dart';

/// Generic response wrapper for all backend operations
/// 
/// Standardizes how data is returned from repositories and use cases.
/// Wraps successful data or error information in a consistent format.
/// 
/// Usage:
/// ```dart
/// // Successful response
/// final response = BaseResponse<UserEntity>.success(
///   data: user,
///   message: 'User logged in',
/// );
/// 
/// // Error response
/// final response = BaseResponse<UserEntity>.error(
///   error: ApiException.auth('Invalid credentials'),
/// );
/// 
/// // Check result
/// if (response.isSuccess) {
///   print('Success: ${response.data}');
/// } else {
///   print('Error: ${response.error?.userMessage}');
/// }
/// ```

class BaseResponse<T> {
  /// Whether the operation was successful
  final bool isSuccess;

  /// The returned data (non-null only if success is true)
  final T? data;

  /// Success message or additional information
  final String? message;

  /// Error information (non-null only if success is false)
  final ApiException? error;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Timestamp when response was created
  final DateTime timestamp;

  /// Private constructor - use named constructors instead
  BaseResponse._({
    required this.isSuccess,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a successful response with data
  /// 
  /// [data] - The returned data
  /// [message] - Optional success message
  /// [statusCode] - Optional HTTP status code (default: 200)
  factory BaseResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return BaseResponse<T>._(
      isSuccess: true,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
    );
  }

  /// Create an error response
  /// 
  /// [error] - The exception that occurred
  /// [statusCode] - Optional HTTP status code (default: 400)
  factory BaseResponse.error({
    required ApiException error,
    int? statusCode,
  }) {
    return BaseResponse<T>._(
      isSuccess: false,
      error: error,
      statusCode: statusCode ?? 400,
    );
  }

  /// Create a response from another response (mapping data type)
  /// 
  /// Useful for transforming one response type to another
  /// 
  /// Note: This is a static method (not a factory) to support generic type parameters.
  /// 
  /// Example:
  /// ```dart
  /// BaseResponse<UserModel> modelResponse = ...;
  /// BaseResponse<UserEntity> entityResponse = BaseResponse.from(
  ///   modelResponse,
  ///   (model) => model.toEntity(),
  /// );
  /// ```
  static BaseResponse<T> from<S, T>(
    BaseResponse<S> source,
    T Function(S) transform,
  ) {
    if (source.isSuccess && source.data != null) {
      return BaseResponse<T>._(
        isSuccess: true,
        data: transform(source.data as S),
        message: source.message,
        statusCode: source.statusCode,
      );
    } else {
      return BaseResponse<T>._(
        isSuccess: false,
        error: source.error!,
        statusCode: source.statusCode,
      );
    }
  }

  /// Check if operation was successful
  bool get isError => !isSuccess;

  /// Get data or default value if null
  /// 
  /// Example:
  /// ```dart
  /// final user = response.dataOrNull ?? UserEntity.empty();
  /// ```
  T? get dataOrNull => isSuccess ? data : null;

  /// Get error message or custom message
  /// 
  /// Returns error's user-friendly message or custom fallback
  String getErrorMessage({String fallback = 'An error occurred'}) {
    return error?.userMessage ?? fallback;
  }

  /// Check if response has data
  bool get hasData => data != null;

  /// Check if response has error
  bool get hasError => error != null;

  /// Convert response data to another type (if successful)
  /// 
  /// Returns new BaseResponse with transformed data
  /// 
  /// Example:
  /// ```dart
  /// final response = BaseResponse<UserModel>.success(data: userModel);
  /// final entityResponse = response.map((model) => model.toEntity());
  /// ```
  BaseResponse<R> map<R>(R Function(T) transform) {
    if (isSuccess && data != null) {
      return BaseResponse<R>._(
        isSuccess: true,
        data: transform(data as T),
        message: message,
        statusCode: statusCode,
      );
    } else {
      return BaseResponse<R>._(
        isSuccess: false,
        error: error!,
        statusCode: statusCode,
      );
    }
  }

  /// Execute a callback if response is successful
  /// 
  /// Returns this response for chaining
  /// 
  /// Example:
  /// ```dart
  /// response
  ///   .whenSuccess((data) => print('Success: $data'))
  ///   .whenError((error) => print('Error: $error'));
  /// ```
  BaseResponse<T> whenSuccess(void Function(T data) callback) {
    if (isSuccess && data != null) {
      callback(data as T);
    }
    return this;
  }

  /// Execute a callback if response is error
  /// 
  /// Returns this response for chaining
  BaseResponse<T> whenError(void Function(ApiException error) callback) {
    if (isError && error != null) {
      callback(error!);
    }
    return this;
  }

  /// Get response data or throw exception
  /// 
  /// Useful when you want exceptions instead of null checks
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final user = response.getOrThrow();
  /// } on ApiException catch (e) {
  ///   print('Error: ${e.userMessage}');
  /// }
  /// ```
  T getOrThrow() {
    if (isSuccess && data != null) {
      return data as T;
    }
    throw error ?? ApiException.unknown('No data available');
  }

  /// Get response data or return fallback value
  /// 
  /// Example:
  /// ```dart
  /// final user = response.getOrElse(UserEntity.empty());
  /// ```
  T getOrElse(T fallback) {
    return (isSuccess && data != null) ? data as T : fallback;
  }

  /// Convert to success response if condition is true
  /// 
  /// Useful for conditional success/error mapping
  factory BaseResponse.guard({
    required bool isValid,
    required T data,
    required String validationErrorMessage,
  }) {
    if (isValid) {
      return BaseResponse<T>.success(data: data);
    } else {
      return BaseResponse<T>.error(
        error: ApiException.validation(validationErrorMessage),
      );
    }
  }

  /// Convert response to string for logging
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('BaseResponse<$T> {');
    buffer.write('success: $isSuccess, ');
    buffer.write('data: ${data != null ? '$data' : 'null'}, ');
    buffer.write('message: ${message ?? 'null'}, ');
    buffer.write('error: ${error?.toString() ?? 'null'}');
    buffer.write('}');
    return buffer.toString();
  }

  /// Detailed string for logging with timestamp
  String toDetailedString() {
    return '$toString() [${timestamp.toIso8601String()}]';
  }
}

/// Extension to simplify BaseResponse usage in futures
extension FutureBaseResponseExt<T> on Future<BaseResponse<T>> {
  /// Handle response when it completes
  /// 
  /// Example:
  /// ```dart
  /// userRepository.getUser(userId)
  ///   .then((response) => response.whenSuccess((user) => print(user)))
  ///   .catchError((error) => print('Error: $error'));
  /// ```
  Future<BaseResponse<T>> whenSuccessDo(
    void Function(T data) onSuccess,
  ) async {
    final response = await this;
    response.whenSuccess(onSuccess);
    return response;
  }

  /// Handle error when response completes
  Future<BaseResponse<T>> whenErrorDo(
    void Function(ApiException error) onError,
  ) async {
    final response = await this;
    response.whenError(onError);
    return response;
  }
}