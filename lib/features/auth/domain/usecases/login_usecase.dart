import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/models/base_response.dart';

/// Use case for user login
/// 
/// Handles login business logic by delegating to AuthRepository.
/// Takes email and password, returns authenticated user.

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Execute login with email and password
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// - [password] - User password
  /// 
  /// Returns:
  /// - [Future<BaseResponse<UserEntity>>] - Success returns logged-in user
  /// 
  /// Example:
  /// ```dart
  /// final useCase = LoginUseCase(authRepository: repository);
  /// final response = await useCase(
  ///   email: 'user@example.com',
  ///   password: 'password123',
  /// );
  /// ```
  Future<BaseResponse<UserEntity>> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.login(
      email: email,
      password: password,
    );
  }
}