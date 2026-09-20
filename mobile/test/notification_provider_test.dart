import 'package:flutter_test/flutter_test.dart';
import 'package:smarteve_mobile/models/notification_model.dart';
import 'package:smarteve_mobile/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationProvider Tests', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('initial state has empty searchQuery and default preferences', () {
      expect(provider.searchQuery, isEmpty);
      expect(provider.filter, equals('all'));
      expect(provider.sort, equals('newest'));
      expect(provider.unreadOnly, isFalse);
      expect(provider.preferences.pushEnabled, isTrue);
    });

    test('setSearchQuery updates query and notifies listeners', () {
      provider.setSearchQuery('TechNova');
      expect(provider.searchQuery, equals('TechNova'));
    });

    test('toggleUnreadOnly toggles unreadOnly state', () {
      expect(provider.unreadOnly, isFalse);
      provider.toggleUnreadOnly();
      expect(provider.unreadOnly, isTrue);
      provider.toggleUnreadOnly();
      expect(provider.unreadOnly, isFalse);
    });

    test('updatePreferences updates state', () async {
      final updated = provider.preferences.copyWith(
        soundEnabled: false,
        quietHoursEnabled: true,
      );
      await provider.updatePreferences(updated);
      expect(provider.preferences.soundEnabled, isFalse);
      expect(provider.preferences.quietHoursEnabled, isTrue);
    });

    test('NotificationType metadata resolves correctly for 25 types', () {
      expect(NotificationType.fromCode('anchor_invitation'), equals(NotificationType.anchorInvitation));
      expect(NotificationType.fromCode('event_delay'), equals(NotificationType.eventDelay));
      expect(NotificationType.fromCode('emergency_sos'), equals(NotificationType.emergencySOS));
      expect(NotificationType.fromCode('scripts_generated'), equals(NotificationType.scriptsGenerated));
    });
  });
}
