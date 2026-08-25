import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Data model for User - maps Firestore ↔ Domain
/// 
/// Handles serialization/deserialization with Firestore.
/// Converts to UserEntity for domain layer.

class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.email,
    required super.name,
    required super.userType,
    required super.disabilityTypes,
    required super.language,
    required super.isActive,
    super.phone,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
    super.lastLoginAt,
  });

  /// Create UserModel from Firestore document
  /// 
  /// Handles Firestore Timestamp conversion to milliseconds.
  factory UserModel.fromFirestore(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: json['userType'] as String,
      disabilityTypes:
          List<String>.from(json['disabilityTypes'] as List<dynamic>),
      language: json['language'] as String,
      isActive: json['isActive'] as bool,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: _timestampToMillis(json['createdAt']),
      updatedAt: _timestampToMillis(json['updatedAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? _timestampToMillis(json['lastLoginAt'])
          : null,
    );
  }

  /// Create UserModel from JSON (generic Map)
  /// 
  /// Used for JSON deserialization.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: json['userType'] as String,
      disabilityTypes:
          List<String>.from(json['disabilityTypes'] as List<dynamic>),
      language: json['language'] as String,
      isActive: json['isActive'] as bool,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      lastLoginAt: json['lastLoginAt'] as int?,
    );
  }

  /// Convert to Firestore JSON
  /// 
  /// Converts timestamps to Firestore Timestamp objects.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'userType': userType,
      'disabilityTypes': disabilityTypes,
      'language': language,
      'isActive': isActive,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(createdAt),
      'updatedAt': Timestamp.fromMillisecondsSinceEpoch(updatedAt),
      if (lastLoginAt != null)
        'lastLoginAt': Timestamp.fromMillisecondsSinceEpoch(lastLoginAt!),
    };
  }

  /// Convert to generic JSON (for API responses)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'userType': userType,
      'disabilityTypes': disabilityTypes,
      'language': language,
      'isActive': isActive,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt,
    };
  }

  /// Convert to domain entity
  /// 
  /// UserModel extends UserEntity, so this just returns self.
  /// Exists for consistency and clarity.
  UserEntity toEntity() {
    return UserEntity(
      userId: userId,
      email: email,
      name: name,
      userType: userType,
      disabilityTypes: disabilityTypes,
      language: language,
      isActive: isActive,
      phone: phone,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Helper: Convert Firestore Timestamp to milliseconds
  /// 
  /// Handles both Timestamp objects and raw int values.
  static int _timestampToMillis(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is int) {
      return value;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}