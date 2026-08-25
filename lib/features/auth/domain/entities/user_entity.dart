import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated user
/// 
/// This is the pure domain model - framework-independent.
/// Immutable and uses Equatable for value comparison.

class UserEntity extends Equatable {
  /// Unique user identifier (Firebase UID)
  final String userId;

  /// User's email address
  final String email;

  /// User's display name
  final String name;

  /// User's selected disability type
  /// Valid values: visually_impaired, deaf, speech_impaired,
  /// cognitively_impaired, physically_disabled, normal
  final String userType;

  /// List of disability types user experiences
  /// At least one should be selected
  final List<String> disabilityTypes;

  /// User's preferred language code (e.g., 'en', 'es')
  final String language;

  /// Whether user account is active
  final bool isActive;

  /// User's phone number (optional)
  final String? phone;

  /// User's profile photo URL (optional)
  final String? photoUrl;

  /// When user was created (Unix milliseconds)
  final int createdAt;

  /// When user profile was last updated (Unix milliseconds)
  final int updatedAt;

  /// When user last logged in (optional, Unix milliseconds)
  final int? lastLoginAt;

  const UserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.userType,
    required this.disabilityTypes,
    required this.language,
    required this.isActive,
    this.phone,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  /// Create an empty user (useful for initial state)
  factory UserEntity.empty() {
    return UserEntity(
      userId: '',
      email: '',
      name: '',
      userType: 'normal',
      disabilityTypes: [],
      language: 'en',
      isActive: false,
      createdAt: 0,
      updatedAt: 0,
    );
  }

  /// Copy with new values
  UserEntity copyWith({
    String? userId,
    String? email,
    String? name,
    String? userType,
    List<String>? disabilityTypes,
    String? language,
    bool? isActive,
    String? phone,
    String? photoUrl,
    int? createdAt,
    int? updatedAt,
    int? lastLoginAt,
  }) {
    return UserEntity(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      disabilityTypes: disabilityTypes ?? this.disabilityTypes,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Check if user is valid (has required fields)
  bool get isValid {
    return userId.isNotEmpty &&
        email.isNotEmpty &&
        name.isNotEmpty &&
        disabilityTypes.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        userId,
        email,
        name,
        userType,
        disabilityTypes,
        language,
        isActive,
        phone,
        photoUrl,
        createdAt,
        updatedAt,
        lastLoginAt,
      ];
}