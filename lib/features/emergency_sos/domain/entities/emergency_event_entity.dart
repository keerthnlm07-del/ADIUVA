import 'package:equatable/equatable.dart';

/// Entity representing an Emergency SOS Event stored in Cloud Firestore
class EmergencyEventEntity extends Equatable {
  final String eventId;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status; // triggered, resolved, cancelled
  final List<String> contactsAttempted;
  final DateTime? resolvedAt;
  final String? notes;

  const EmergencyEventEntity({
    required this.eventId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.status = 'triggered',
    this.contactsAttempted = const [],
    this.resolvedAt,
    this.notes,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'status': status,
      'contactsAttempted': contactsAttempted,
      if (resolvedAt != null) 'resolvedAt': resolvedAt,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  factory EmergencyEventEntity.fromFirestoreMap(Map<String, dynamic> map, String id) {
    return EmergencyEventEntity(
      eventId: map['eventId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as dynamic).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? 'triggered',
      contactsAttempted: List<String>.from(map['contactsAttempted'] as List? ?? []),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as dynamic).toDate()
          : null,
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        userId,
        latitude,
        longitude,
        timestamp,
        status,
        contactsAttempted,
        resolvedAt,
        notes,
      ];
}
