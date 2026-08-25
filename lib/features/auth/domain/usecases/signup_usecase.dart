import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/models/base_response.dart';

/// Use case for user signup
/// 
/// Handles signup business logic by delegating to AuthRepository.
/// Takes email, password, and name, returns newly created user.

class SignupUseCase {
  final AuthRepository _authRepository;

  SignupUseCase({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Execute signup with email, password, and name
  /// 
  /// Parameters:
  /// - [email] - User email address
  /// - [password] - User password (minimum 8 characters)
  /// - [name] - User display name
  /// 
  /// Returns:
  /// - [Future<BaseResponse<UserEntity>>] - Success returns created user
  /// 
  /// Example:
  /// ```dart
  /// final useCase = SignupUseCase(authRepository: repository);
  /// final response = await useCase(
  ///   email: 'newuser@example.com',
  ///   password: 'password123',
  ///   name: 'John Doe',
  /// );
  /// ```
  Future<BaseResponse<UserEntity>> call({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _authRepository.signup(
      email: email,
      password: password,
      name: name,
    );
  }
}