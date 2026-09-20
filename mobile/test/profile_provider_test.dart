import 'package:flutter_test/flutter_test.dart';
import 'package:smarteve_mobile/providers/profile_provider.dart';

void main() {
  group('ProfileProvider Tests', () {
    late ProfileProvider provider;

  setUp(() {
    provider = ProfileProvider();
  });

  test('Initial state contains default profile and stats', () {
    expect(provider.profile.fullName, 'Jordan Hayes');
    expect(provider.profile.designation, contains('Stage Host'));
    expect(provider.profile.stats.eventsAnchored, 24);
    expect(provider.profile.stats.hoursOnStage, 96);
    expect(provider.profile.stats.averageRating, 4.9);
    expect(provider.profile.stats.completionRate, 98);
    expect(provider.profile.languages, contains('English'));
    expect(provider.profile.specializations, contains('Hackathons'));
    expect(provider.isDirty, isFalse);
    expect(provider.isEditing, isFalse);
  });

  test('Editing mode and dirty state tracking', () {
    provider.toggleEditMode(true);
    expect(provider.isEditing, isTrue);
    expect(provider.isDirty, isFalse);

    provider.updateFullName('Jordan Hayes (Senior Emcee)');
    expect(provider.isDirty, isTrue);
    expect(provider.profile.fullName, 'Jordan Hayes (Senior Emcee)');

    provider.discardChanges();
    expect(provider.isEditing, isFalse);
    expect(provider.isDirty, isFalse);
    expect(provider.profile.fullName, 'Jordan Hayes');
  });

  test('Adding and removing languages and specializations', () {
    provider.toggleEditMode(true);
    provider.addLanguage('Spanish');
    expect(provider.profile.languages, contains('Spanish'));

    provider.removeLanguage('Spanish');
    expect(provider.profile.languages.contains('Spanish'), isFalse);

    provider.addSpecialization('AI Summit');
    expect(provider.profile.specializations, contains('AI Summit'));

    provider.removeSpecialization('AI Summit');
    expect(provider.profile.specializations.contains('AI Summit'), isFalse);
  });

  test('Updating notification and app preferences', () {
    provider.toggleEditMode(true);
    final initialPrefs = provider.profile.notificationPreferences;
    provider.updateNotificationPreferences(initialPrefs.copyWith(sound: false, vibration: false));

    expect(provider.profile.notificationPreferences.sound, isFalse);
    expect(provider.profile.notificationPreferences.vibration, isFalse);

    final initialAppPrefs = provider.profile.appPreferences;
    provider.updateAppPreferences(initialAppPrefs.copyWith(themeMode: 'dark', fontSize: 'Large'));

    expect(provider.profile.appPreferences.themeMode, 'dark');
    expect(provider.profile.appPreferences.fontSize, 'Large');
  });

  test('Masked phone number formats correctly', () {
    final profile = provider.profile;
    expect(profile.maskedPhoneNumber, contains('•••••'));
  });
  });
}
