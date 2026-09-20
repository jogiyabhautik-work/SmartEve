import 'package:flutter_test/flutter_test.dart';
import 'package:smarteve_mobile/models/anchor_dashboard_models.dart';
import 'package:smarteve_mobile/providers/anchor_provider.dart';

void main() {
  group('AnchorProvider Tests', () {
    late AnchorProvider provider;

    setUp(() {
      provider = AnchorProvider();
    });

    test('Initial state contains invitations, upcoming events and history', () {
      expect(provider.invitations.length, 2);
      expect(provider.filteredUpcomingEvents.length, 4);
      expect(provider.displayedUpcomingEvents.length, 3); // Max 3 cards by default
      expect(provider.filteredCompletedEvents.length, 3);
      expect(provider.unreadAiAlertCount, 2);
    });

    test('Search filters across titles, dates, and organizers', () {
      provider.setSearchQuery('GDG');
      expect(provider.filteredInvitations.length, 1);
      expect(provider.filteredInvitations.first.title, contains('GDG'));

      provider.setSearchQuery('Alex Rivera');
      expect(provider.filteredUpcomingEvents.length, 1);
      expect(provider.filteredUpcomingEvents.first.organizerName, 'Alex Rivera');

      provider.setSearchQuery('NonExistentTerm123');
      expect(provider.filteredInvitations.isEmpty, isTrue);
      expect(provider.filteredUpcomingEvents.isEmpty, isTrue);
    });

    test('Accepting invitation transitions event to upcoming with accepted status', () {
      final initialInvCount = provider.invitations.length;
      final initialUpcomingCount = provider.filteredUpcomingEvents.length;
      final targetInv = provider.invitations.first;

      provider.acceptInvitation(targetInv.id);

      expect(provider.invitations.length, initialInvCount - 1);
      expect(provider.filteredUpcomingEvents.length, initialUpcomingCount + 1);

      final acceptedEvent = provider.filteredUpcomingEvents.first;
      expect(acceptedEvent.title, targetInv.title);
      expect(acceptedEvent.status, AnchorEventStatus.accepted);
    });

    test('Declining invitation removes it from sticky section', () {
      final initialInvCount = provider.invitations.length;
      final targetInv = provider.invitations.last;

      provider.declineInvitation(targetInv.id);

      expect(provider.invitations.length, initialInvCount - 1);
      expect(provider.invitations.any((it) => it.id == targetInv.id), isFalse);
    });

    test('Toggle view all expands and collapses upcoming events', () {
      expect(provider.displayedUpcomingEvents.length, 3);
      expect(provider.isViewAllUpcoming, isFalse);

      provider.toggleViewAllUpcoming();
      expect(provider.isViewAllUpcoming, isTrue);
      expect(provider.displayedUpcomingEvents.length, provider.filteredUpcomingEvents.length);

      provider.toggleViewAllUpcoming();
      expect(provider.isViewAllUpcoming, isFalse);
      expect(provider.displayedUpcomingEvents.length, 3);
    });
  });
}
