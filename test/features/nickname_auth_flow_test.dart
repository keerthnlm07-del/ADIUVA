import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/auth/domain/entities/user_entity.dart';
import 'package:adiuva/features/auth/data/models/user_model.dart';
import 'package:adiuva/core/services/voice_response_localizer.dart';

void main() {
  group('Preferred Name Domain & Data Model Tests', () {
    test('UserEntity stores preferredName correctly', () {
      final user = UserEntity(
        userId: 'uid_123',
        email: 'test@example.com',
        name: 'Keerthan',
        preferredName: 'Keerth',
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(user.preferredName, equals('Keerth'));
      expect(user.props, contains('Keerth'));

      final updated = user.copyWith(preferredName: 'Kiki');
      expect(updated.preferredName, equals('Kiki'));
    });

    test('UserModel serializes and deserializes preferredName correctly', () {
      final json = {
        'userId': 'uid_456',
        'email': 'kiki@example.com',
        'name': 'Keerthan Kumar',
        'preferredName': 'Keeru',
        'userType': 'normal',
        'disabilityTypes': ['normal'],
        'language': 'en',
        'isActive': true,
        'createdAt': 1000,
        'updatedAt': 1000,
      };

      final model = UserModel.fromJson(json);
      expect(model.preferredName, equals('Keeru'));

      final jsonOutput = model.toJson();
      expect(jsonOutput['preferredName'], equals('Keeru'));

      final firestoreOutput = model.toFirestore();
      expect(firestoreOutput['preferredName'], equals('Keeru'));
    });
  });

  group('VoiceResponseLocalizer Returning Welcome Tests', () {
    test('Returns personalized greeting when preferredName is provided', () {
      final greetingEn = VoiceResponseLocalizer.returningWelcome('en', 'Keerth');
      expect(greetingEn, equals('Welcome back, Keerth. Voice Control is active.'));

      final greetingTe = VoiceResponseLocalizer.returningWelcome('en-IN', 'Keerth');
      expect(greetingTe, contains('Keerth'));

      final greetingTa = VoiceResponseLocalizer.returningWelcome('ta', 'Keerth');
      expect(greetingTa, contains('Keerth'));
    });

    test('Returns standard greeting when preferredName is null or empty', () {
      final greetingNull = VoiceResponseLocalizer.returningWelcome('en', null);
      expect(greetingNull, equals('Welcome back. Voice Control is active.'));

      final greetingEmpty = VoiceResponseLocalizer.returningWelcome('en', '  ');
      expect(greetingEmpty, equals('Welcome back. Voice Control is active.'));
    });
  });

  group('UID-Scoped User Profile Isolation Tests', () {
    test('User A and User B entities retain distinct preferredNames', () {
      final userA = UserEntity(
        userId: 'uid_user_a',
        email: 'usera@example.com',
        name: 'User A',
        preferredName: 'Kitty',
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final userB = UserEntity(
        userId: 'uid_user_b',
        email: 'userb@example.com',
        name: 'User B',
        preferredName: 'Rahul',
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 2000,
        updatedAt: 2000,
      );

      expect(userA.userId, isNot(equals(userB.userId)));
      expect(userA.preferredName, equals('Kitty'));
      expect(userB.preferredName, equals('Rahul'));
      expect(userA.preferredName, isNot(equals(userB.preferredName)));
    });
  });
}
