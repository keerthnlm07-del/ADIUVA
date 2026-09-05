import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/entities/emergency_event_entity.dart';

/// Firestore Remote Data Source for Emergency Contacts & SOS Events
class EmergencyRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all emergency contacts for an authenticated user
  Future<List<EmergencyContactEntity>> fetchEmergencyContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('emergency_contacts')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContactEntity.fromFirestoreMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch emergency contacts: $e');
    }
  }

  /// Create a new emergency contact document
  Future<void> addEmergencyContact(EmergencyContactEntity contact) async {
    try {
      await _firestore
          .collection('emergency_contacts')
          .doc(contact.contactId)
          .set(contact.toFirestoreMap());
    } catch (e) {
      throw Exception('Failed to save emergency contact: $e');
    }
  }

  /// Delete an emergency contact document
  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      await _firestore.collection('emergency_contacts').doc(contactId).delete();
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }

  /// Trigger a new SOS emergency event
  Future<void> triggerSosAlert(EmergencyEventEntity event) async {
    try {
      await _firestore
          .collection('emergency_events')
          .doc(event.eventId)
          .set(event.toFirestoreMap());
    } catch (e) {
      throw Exception('Failed to trigger emergency alert: $e');
    }
  }

  /// Update an active SOS event status (e.g. resolved or cancelled)
  Future<void> updateSosStatus(String eventId, String status, [DateTime? resolvedAt]) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt),
      };

      await _firestore.collection('emergency_events').doc(eventId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update emergency event status: $e');
    }
  }
}
