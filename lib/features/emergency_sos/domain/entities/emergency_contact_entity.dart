import 'package:equatable/equatable.dart';

/// Entity representing an Emergency Contact stored in Cloud Firestore
class EmergencyContactEntity extends Equatable {
  final String contactId;
  final String userId;
  final String name;
  final String phone;
  final String relationship; // family, friend, emergency_services, caregiver, other
  final bool isPrimary;
  final String? email;
  final DateTime createdAt;

  const EmergencyContactEntity({
    required this.contactId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
    this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'contactId': contactId,
      'userId': userId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isPrimary': isPrimary,
      if (email != null && email!.isNotEmpty) 'email': email,
      'createdAt': createdAt,
    };
  }

  factory EmergencyContactEntity.fromFirestoreMap(Map<String, dynamic> map, String id) {
    return EmergencyContactEntity(
      contactId: map['contactId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Contact',
      phone: map['phone'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'friend',
      isPrimary: map['isPrimary'] as bool? ?? false,
      email: map['email'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [contactId, userId, name, phone, relationship, isPrimary, email, createdAt];
}
