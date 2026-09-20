import 'package:flutter_test/flutter_test.dart';
import 'package:smarteve_mobile/providers/checklist_provider.dart';

void main() {
  group('ChecklistProvider Tests', () {
    late ChecklistProvider provider;

    setUp(() {
      provider = ChecklistProvider();
      provider.loadForEvent('evt-test-1');
    });

    test('seeds 8 canonical pre-event checklist items', () {
      expect(provider.items.length, 8);
      expect(provider.totalCount, 8);
      expect(provider.completedCount, 0);
      expect(provider.completionPercent, 0);
      expect(provider.isAllComplete, isFalse);
    });

    test('items match required checklist labels', () {
      final labels = provider.items.map((i) => i.label).toList();
      expect(labels, contains('Review all speakers & their details'));
      expect(labels, contains('Memorize opening script'));
      expect(labels, contains('Check audio setup (mic working)'));
      expect(labels, contains('Check video setup (camera working)'));
      expect(labels, contains('Review all generated scripts'));
      expect(labels, contains('Familiarize with agenda flow'));
      expect(labels, contains('Check internet connection'));
      expect(labels, contains('Notify organizer when ready'));
    });

    test('toggling an item updates completion stats', () async {
      final first = provider.items.first;
      await provider.toggleItem(first.id, true);

      expect(provider.completedCount, 1);
      expect(provider.completionPercent, 13); // 1/8 = 12.5% -> 13
      expect(provider.isAllComplete, isFalse);
      expect(first.isCompleted, isTrue);
      expect(first.completedAt, isNotNull);

      await provider.toggleItem(first.id, false);
      expect(provider.completedCount, 0);
      expect(first.completedAt, isNull);
    });

    test('markAllComplete sets every item complete', () async {
      await provider.markAllComplete();

      expect(provider.isAllComplete, isTrue);
      expect(provider.completedCount, provider.totalCount);
      expect(provider.completionPercent, 100);
      expect(provider.completionFraction, 1.0);
    });

    test('toggling unknown item id is a no-op', () async {
      await provider.toggleItem('non-existent-id', true);
      expect(provider.completedCount, 0);
    });
  });
}
