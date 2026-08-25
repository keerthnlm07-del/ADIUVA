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
      final userResponse = await _getOrCreateFirestoreUser(
        userId: userId,
        email: email,
      );

      if (!userResponse.isSuccess) {
        return BaseResponse<UserEntity>.error(
          error: userResponse.error ?? ApiException.firestore('Failed to load user profile'),
        );
      }

      final userEntity = userResponse.data;
      if (userEntity == null) {
        return BaseResponse<UserEntity>.error(
          error: ApiException.firestore('User profile is empty'),
        );
      }

      // 4. Save to local storage
      try {
        final userModel = UserModel(
          userId: userEntity.userId,
          email: userEntity.email,
          name: userEntity.name,
          userType: userEntity.userType,
          disabilityTypes: userEntity.disabilityTypes,
          language: userEntity.language,
          isActive: userEntity.isActive,
          phone: userEntity.phone,
          photoUrl: userEntity.photoUrl,
          createdAt: userEntity.createdAt,
          updatedAt: userEntity.updatedAt,
          lastLoginAt: userEntity.lastLoginAt,
        );
        await _authLocalDataSource.saveUserLocally(userModel);
      } catch (e) {
        // Log to local storage failed, but don't fail the login
      }

      return BaseResponse<UserEntity>.success(
        data: userEntity,
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
            'disabilityTypes': [],
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

      // 5. Save to local storage
      try {
        await _authLocalDataSource.saveUserLocally(userModel);
      } catch (e) {
        // Log to local storage failed, but don't fail the signup
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

      // 2. Clear local storage
      try {
        await _authLocalDataSource.clearUserData();
      } catch (e) {
        // Log clear failed, but logout was successful
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
      final userModel = await _getUserModelFromFirestore(userId);

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
    return _authRemoteDataSource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        final userModel = await _getUserModelFromFirestore(firebaseUser.uid);
        return userModel?.toEntity();
      } catch (e) {
        // If we can't get the profile, still emit the auth state change
        // but with minimal info from Firebase
        return UserEntity(
          userId: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'User',
          userType: 'normal',
          disabilityTypes: [],
          language: 'en',
          isActive: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
    });
  }

  // ==================== PRIVATE HELPERS ====================

  /// Get or create Firestore user document
  /// 
  /// Tries to read existing user document.
  /// If doesn't exist, creates a default one.
  Future<BaseResponse<UserEntity?>> _getOrCreateFirestoreUser({
    required String userId,
    required String email,
  }) async {
    try {
      final userModel = await _getUserModelFromFirestore(userId);

      if (userModel != null) {
        return BaseResponse<UserEntity?>.success(data: userModel.toEntity());
      }

      // User document doesn't exist, create default one
      try {
        await _firebaseService.createDocument(
          'users/$userId',
          {
            'userId': userId,
            'email': email.trim(),
            'name': 'User', // Fallback name
            'userType': 'normal',
            'disabilityTypes': [],
            'language': 'en',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Read it back to get timestamps
        final createdModel = await _getUserModelFromFirestore(userId);
        return BaseResponse<UserEntity?>.success(data: createdModel?.toEntity());
      } catch (e) {
        return BaseResponse<UserEntity?>.error(
          error: ApiException.firestore(
            'Failed to create user profile',
            originalException: e is Exception ? e : null,
          ),
        );
      }
    } catch (e) {
      return BaseResponse<UserEntity?>.error(
        error: ApiException.unknown(
          'Unexpected error accessing user profile',
          originalException: e is Exception ? e : null,
        ),
      );
    }
  }

  /// Get UserModel from Firestore by userId
  /// 
  /// Returns null if document doesn't exist.
  Future<UserModel?> _getUserModelFromFirestore(String userId) async {
    try {
      final doc = await _firebaseService.readDocument('users/$userId');

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromFirestore(data);
    } catch (e) {
      throw ApiException.firestore(
        'Failed to read user profile',
        originalException: e is Exception ? e : null,
      );
    }
  }
}