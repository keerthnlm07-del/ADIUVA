import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/auth/domain/entities/user_entity.dart';
import 'package:adiuva/features/auth/data/models/user_model.dart';
import 'package:adiuva/core/services/voice_response_localizer.dart';

void main() {
  group('Auth Flow Reliability & Nickname Persistence Tests', () {
    test('Unauthenticated user entity is empty/invalid', () {
      final emptyUser = UserEntity.empty();
      expect(emptyUser.userId, isEmpty);
      expect(emptyUser.isValid, isFalse);
    });

    test('New user without preferredName identifies requirement for Nickname Prompt', () {
      final newAccount = UserEntity(
        userId: 'uid_new_1',
        email: 'newuser@example.com',
        name: 'Keerthan Kumar',
        preferredName: null,
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final hasPreferredName = newAccount.preferredName?.trim().isNotEmpty ?? false;
      expect(hasPreferredName, isFalse);
    });

    test('Skip action sets preferredName to user existing full name', () {
      final userBeforeSkip = UserEntity(
        userId: 'uid_skip_1',
        email: 'skipuser@example.com',
        name: 'Keerthan Kumar',
        preferredName: null,
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      // On Skip, preferredName is saved using the user's full name
      final userAfterSkip = userBeforeSkip.copyWith(preferredName: userBeforeSkip.name);
      expect(userAfterSkip.preferredName, equals('Keerthan Kumar'));
      expect(userAfterSkip.preferredName?.trim().isNotEmpty, isTrue);
    });

    test('Returning user with preferredName skips Nickname Prompt and Login', () {
      final returningUser = UserEntity(
        userId: 'uid_returning_1',
        email: 'returning@example.com',
        name: 'Keerthan Kumar',
        preferredName: 'Keerth',
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final hasPreferredName = returningUser.preferredName?.trim().isNotEmpty ?? false;
      expect(hasPreferredName, isTrue);

      final greeting = VoiceResponseLocalizer.returningWelcome('en', returningUser.preferredName);
      expect(greeting, equals('Welcome back, Keerth. Voice Control is active.'));
    });

    test('Returning user with full name as preferredName generates valid greeting', () {
      final returningUserFull = UserEntity(
        userId: 'uid_returning_2',
        email: 'returning2@example.com',
        name: 'Keerthan Kumar',
        preferredName: 'Keerthan Kumar',
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final greeting = VoiceResponseLocalizer.returningWelcome('en', returningUserFull.preferredName);
      expect(greeting, equals('Welcome back, Keerthan Kumar. Voice Control is active.'));
    });

    test('UserModel round-trip preserves preferredName correctly', () {
      final model = UserModel(
        userId: 'uid_model_1',
        email: 'model@example.com',
        name: 'Keerthan Kumar',
        preferredName: 'Kiki',
        userType: 'normal',
        disabilityTypes: const ['normal'],
        language: 'en',
        isActive: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final json = model.toJson();
      final recreated = UserModel.fromJson(json);

      expect(recreated.preferredName, equals('Kiki'));
      expect(recreated.name, equals('Keerthan Kumar'));
    });
  });
}
