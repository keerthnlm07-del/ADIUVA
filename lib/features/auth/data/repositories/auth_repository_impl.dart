import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/models/api_exception.dart';
import '../../../../core/models/base_response.dart';
import '../../../../core/services/firebase_service.dart';

/// Implementation of AuthRepository
/// 
/// Coordinates authentication between Firebase Auth, Firestore, and local storage.
/// Converts Firebase objects to domain entities.

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authRemoteDataSource;
  final AuthLocalDataSource _authLocalDataSource;
  final FirebaseService _firebaseService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authRemoteDataSource,
    required AuthLocalDataSource authLocalDataSource,
    required FirebaseService firebaseService,
  })  : _authRemoteDataSource = authRemoteDataSource,
        _authLocalDataSource = authLocalDataSource,
        _firebaseService = firebaseService;

  @override
  Future<BaseResponse<UserEntity>> signInWithGoogle() async {
    try {
      final authResponse = await _authRemoteDataSource.signInWithGoogle();

      if (!authResponse.isSuccess || authResponse.data == null) {
        return BaseResponse<UserEntity>.error(
          error: authResponse.error ?? ApiException.auth('Google sign-in failed'),
        );
      }

      final firebaseUser = authResponse.data!.user;
      if (firebaseUser == null) {
        return BaseResponse<UserEntity>.error(
          error: ApiException.auth('User UID not available after Google sign-in'),
        );
      }

      final userModel = await _getOrCreateFirestoreUser(
        userId: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );

      final userEntity = userModel?.toEntity() ??
          UserEntity(
            userId: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'Google User',
            userType: 'normal',
            disabilityTypes: const <String>[],
            language: 'en',
            isActive: true,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );

      if (userModel != null) {
        await _authLocalDataSource.saveUserLocally(userModel);
      }

      return BaseResponse<UserEntity>.success(
        data: userEntity,
        message: 'Google sign-in successful',
        statusCode: 200,
      );
    } catch (e) {
      return BaseResponse<UserEntity>.error(
        error: ApiException.unknown('Google sign-in failed: $e'),
      );
    }
  }

  @override
  Future<BaseResponse<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Authenticate with Firebase
      final authResponse = await _authRemoteDataSource.login(
        email: email,
        password: password,
      );

      if (!authResponse.isSuccess || authResponse.data == null) {
        return BaseResponse<UserEntity>.error(
          error: authResponse.error ??
              ApiException.auth('Login failed'),
        );
      }

      // 2. Get userId from credential
      final userId = authResponse.data!.user?.uid;
      if (userId == null) {
        return BaseResponse<UserEntity>.error(
          error: ApiException.auth('User UID not available after login'),
        );
      }

      // 3. Fetch or create Firestore user document
      final userModel = await _getOrCreateFirestoreUser(
        userId: userId,
        email: email,
      );

      if (userModel == null) {
        return BaseResponse<UserEntity>.error(
          error: ApiException.firestore('Failed to get user profile'),
        );
      }

      // 4. Save to local storage (fire and forget)
      try {
        await _authLocalDataSource.saveUserLocally(userModel);
      } catch (e) {
        // Local storage failure doesn't fail the login
      }

      return BaseResponse<UserEntity>.success(
        data: userModel.toEntity(),
        message: 'Login successful',
      );
    } catch (e) {
      return BaseResponse<UserEntity>.error(
        error: ApiException.unknown(
          'Unexpected error during login',
          originalException: e is Exception ? e : null,
        ),
      );
    }
  }

  @override
  Future<BaseResponse<UserEntity>> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Create Firebase Authentication account with displayName
      final authResponse = await _authRemoteDataSource.signup(
        email: email,
        password: password,
        name: name,
      );

      if (!authResponse.isSuccess || authResponse.data == null) {
        return BaseResponse<UserEntity>.error(
          error: authResponse.error ??
              ApiException.auth('Signup failed'),
        );
      }

      // 2. Get userId from credential
      final userId = authResponse.data!.user?.uid;
      if (userId == null) {
        return BaseResponse<UserEntity>.error(
          error: ApiException.auth('User UID not available after signup'),
        );
      }

      // 3. Create Firestore user document with server timestamps
      try {
        await _firebaseService.createDocument(
          'users/$userId',
          {
            'userId': userId,
            'email': email.trim(),
            'name': name.trim(),
            'userType': 'normal',
            'disabilityTypes': <String>[],
            'language': 'en',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      } catch (e) {
        return BaseResponse<UserEntity>.error(
          error: ApiException.firestore(
            'Failed to create user profile in database',
            originalException: e is Exception ? e : null,
          ),
        );
      }

      // 4. Read the created document to get actual timestamps
      final userModel = await _getUserModelFromFirestore(userId);
      if (userModel == null) {
        return BaseResponse<UserEntity>.error(
          error: ApiException.firestore('Failed to retrieve created user profile'),
        );
      }

      // 5. Save to local storage (fire and forget)
      try {
        await _authLocalDataSource.saveUserLocally(userModel);
      } catch (e) {
        // Local storage failure doesn't fail the signup
      }

      return BaseResponse<UserEntity>.success(
        data: userModel.toEntity(),
        message: 'Account created successfully',
        statusCode: 201,
      );
    } catch (e) {
      return BaseResponse<UserEntity>.error(
        error: ApiException.unknown(
          'Unexpected error during signup',
          originalException: e is Exception ? e : null,
        ),
      );
    }
  }

  @override
  Future<BaseResponse<void>> logout() async {
    try {
      // 1. Sign out from Firebase
      final logoutResponse = await _authRemoteDataSource.logout();

      if (!logoutResponse.isSuccess) {
        return BaseResponse<void>.error(
          error: logoutResponse.error ?? ApiException.auth('Logout failed'),
        );
      }

      // 2. Clear local storage (fire and forget)
      try {
        await _authLocalDataSource.clearUserData();
      } catch (e) {
        // Local storage clear failure doesn't fail the logout
      }

      return BaseResponse<void>.success(
        data: null,
        message: 'Logout successful',
      );
    } catch (e) {
      return BaseResponse<void>.error(
        error: ApiException.unknown(
          'Unexpected error during logout',
          originalException: e is Exception ? e : null,
        ),
      );
    }
  }

  @override
  Future<BaseResponse<void>> resetPassword({
    required String email,
  }) async {
    try {
      final response = await _authRemoteDataSource.resetPassword(
        email: email,
      );

      if (!response.isSuccess) {
        return BaseResponse<void>.error(
          error: response.error ??
              ApiException.auth('Password reset failed'),
        );
      }

      return BaseResponse<void>.success(
        data: null,
        message: 'Password reset email sent',
      );
    } catch (e) {
      return BaseResponse<void>.error(
        error: ApiException.unknown(
          'Unexpected error during password reset',
          originalException: e is Exception ? e : null,
        ),
      );
    }
  }

  @override
  Future<BaseResponse<UserEntity?>> getCurrentUser() async {
    try {
      // 1. Get Firebase current user
      final authResponse = await _authRemoteDataSource.getCurrentUser();

      if (!authResponse.isSuccess) {
        return BaseResponse<UserEntity?>.error(
          error: authResponse.error ?? ApiException.auth('Failed to get current user'),
        );
      }

      // If no user is logged in, return success with null
      if (authResponse.data == null) {
        return BaseResponse<UserEntity?>.success(
          data: null,
          message: 'No authenticated user',
        );
      }

      // 2. User exists, fetch their Firestore profile
      final userId = authResponse.data!.uid;
      final userModel = await _getOrCreateFirestoreUser(userId: userId);

      return BaseResponse<UserEntity?>.success(
        data: userModel?.toEntity(),
        message: 'Current user retrieved',
      );
    } catch (e) {
      return BaseResponse<UserEntity?>.error(
        error: ApiException.unknown(
          'Unexpected error getting current user',
          originalException: e is Exception ? e : null,
        ),
      );
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _authRemoteDataSource.authStateChanges().asyncMap(
      (firebaseUser) async {
        if (firebaseUser == null) {
          return null;
        }

        try {
          final userModel = await _getUserModelFromFirestore(firebaseUser.uid);
          return userModel?.toEntity();
        } catch (e) {
          // If we can't get the profile, return minimal entity from Firebase user
          return UserEntity(
            userId: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'User',
            userType: 'normal',
            disabilityTypes: const <String>[],
            language: 'en',
            isActive: true,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
      },
    );
  }

  // ==================== PRIVATE HELPERS ====================

  /// Get or create Firestore user document
  /// 
  /// Tries to read existing user document.
  /// If doesn't exist, creates a default one.
  /// 
  /// Returns UserModel if successful, null if creation fails.
  Future<UserModel?> _getOrCreateFirestoreUser({
    required String userId,
    String? email,
  }) async {
    try {
      // Try to read existing document
      final userModel = await _getUserModelFromFirestore(userId);

      if (userModel != null) {
        return userModel;
      }

      // User document doesn't exist, create default one
      try {
        await _firebaseService.createDocument(
          'users/$userId',
          {
            'userId': userId,
            'email': email ?? '',
            'name': 'User',
            'userType': 'normal',
            'disabilityTypes': <String>[],
            'language': 'en',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Read it back to get timestamps
        return await _getUserModelFromFirestore(userId);
      } catch (e) {
        // Creation failed, return null
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get UserModel from Firestore by userId
  /// 
  /// Returns null if document doesn't exist.
  /// Throws ApiException if read fails.
  Future<UserModel?> _getUserModelFromFirestore(String userId) async {
    try {
      final doc = await _firebaseService.readDocument('users/$userId');

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromFirestore(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.firestore(
        'Failed to read user profile',
        originalException: e is Exception ? e : null,
      );
    }
  }
}