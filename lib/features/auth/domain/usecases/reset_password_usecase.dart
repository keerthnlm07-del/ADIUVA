import '../repositories/auth_repository.dart';
import '../../../../core/models/base_response.dart';

/// Use case for password reset
/// 
/// Handles password reset business logic by delegating to AuthRepository.
/// Sends password reset email to user.

class ResetPasswordUseCase {
  final AuthRepository _authRepository;

  ResetPasswordUseCase({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Execute password reset
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// 
  /// Returns:
  /// - [Future<BaseResponse<void>>] - Success sends reset email
  /// 
  /// Example:
  /// ```dart
  /// final useCase = ResetPasswordUseCase(authRepository: repository);
  /// final response = await useCase(email: 'user@example.com');
  /// ```
  Future<BaseResponse<void>> call({
    required String email,
  }) async {
    return await _authRepository.resetPassword(email: email);
  }
}