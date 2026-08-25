import '../repositories/auth_repository.dart';
import '../../../../core/models/base_response.dart';

/// Use case for user logout
/// 
/// Handles logout business logic by delegating to AuthRepository.
/// Signs out user and clears session.

class LogoutUseCase {
  final AuthRepository _authRepository;

  LogoutUseCase({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Execute logout
  /// 
  /// Returns:
  /// - [Future<BaseResponse<void>>] - Success clears session
  /// 
  /// Example:
  /// ```dart
  /// final useCase = LogoutUseCase(authRepository: repository);
  /// final response = await useCase();
  /// ```
  Future<BaseResponse<void>> call() async {
    return await _authRepository.logout();
  }
}
