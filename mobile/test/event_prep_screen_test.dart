import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smarteve_mobile/core/theme/app_theme.dart';
import 'package:smarteve_mobile/features/events/event_prep_screen.dart';
import 'package:smarteve_mobile/models/anchor_dashboard_models.dart';
import 'package:smarteve_mobile/providers/anchor_provider.dart';
import 'package:smarteve_mobile/providers/checklist_provider.dart';
import 'package:smarteve_mobile/providers/event_provider.dart';

void main() {
  late EventProvider eventProvider;
  late AnchorProvider anchorProvider;
  late ChecklistProvider checklistProvider;

  setUp(() {
    eventProvider = EventProvider();
    anchorProvider = AnchorProvider();
    checklistProvider = ChecklistProvider();
  });

  tearDown(() {
    eventProvider.dispose();
    anchorProvider.dispose();
    checklistProvider.dispose();
  });

  Widget harness(AnchorEventStatus status) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EventProvider>.value(value: eventProvider),
        ChangeNotifierProvider<AnchorProvider>.value(value: anchorProvider),
        ChangeNotifierProvider<ChecklistProvider>.value(
            value: checklistProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: EventPrepScreen(
          eventId: 'evt-prep-test',
          status: status,
          organizerName: 'Alex Rivera',
          collegeName: 'Stanford Engineering Concourse',
        ),
      ),
    );
  }

  /// Pumps the screen and lets the post-frame data load + fallback seed settle
  /// without using pumpAndSettle (EventProvider keeps a 1s periodic ticker).
  Future<void> pumpPrepScreen(WidgetTester tester,
      {AnchorEventStatus status = AnchorEventStatus.accepted}) async {
    await tester.pumpWidget(harness(status));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders sticky header, status badge and 4 tabs', (tester) async {
    await pumpPrepScreen(tester);

    // AppBar + event title from the loaded event payload
    expect(find.text('EVENT PREP'), findsOneWidget);
    expect(find.textContaining('TechNova'), findsWidgets);

    // Status indicator
    expect(find.text('ACCEPTED'), findsOneWidget);

    // Four section tabs
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('Speakers'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Prep ✓'), findsOneWidget);

    // Tab 1 content (default active)
    expect(find.text('DATE & TIME'), findsWidgets);
    expect(find.text('ORGANIZER'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsWidgets);
  });

  testWidgets('tablet layout renders checklist side-by-side and is interactive',
      (tester) async {
    // Default test surface is 800x600 -> tablet breakpoint (>= 600).
    await pumpPrepScreen(tester);

    // Checklist seeded with 8 items, 0 complete
    expect(find.text('Pre-Event Checklist'), findsWidgets);
    expect(find.text('0 of 8 complete'), findsWidgets);
    expect(find.text('Review all speakers & their details'), findsWidgets);
    expect(find.text('Notify organizer when ready'), findsWidgets);

    // Toggle the first item -> progress updates
    await tester.tap(find.text('Review all speakers & their details').first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1 of 8 complete'), findsWidgets);
  });

  testWidgets('bottom actions expose checklist gate, contact and script change',
      (tester) async {
    await pumpPrepScreen(tester);

    // Checklist not complete -> Go Live is gated
    expect(find.text('Complete checklist to Go Live'), findsWidgets);
    expect(find.text('Contact Organizer'), findsOneWidget);
    expect(find.text('Request Script Change'), findsOneWidget);

    // Completing every checklist item ungates the primary CTA when the
    // event window is reached, otherwise it stays time-gated.
    await checklistProvider.markAllComplete();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('All set! You\'re ready to go live.'), findsWidgets);
  });

  testWidgets('invited status shows Accept Event as the primary CTA',
      (tester) async {
    await pumpPrepScreen(tester, status: AnchorEventStatus.invited);

    expect(find.text('INVITED'), findsOneWidget);
    expect(find.text('Accept Event'), findsOneWidget);
  });

  testWidgets('mobile layout keeps all four top-level tabs reachable',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPrepScreen(tester);

    expect(find.text('Info'), findsOneWidget);
    expect(find.text('Speakers'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Prep ✓'), findsOneWidget);

    // Secondary CTAs remain pinned in the bottom action bar
    expect(find.text('Contact Organizer'), findsOneWidget);
    expect(find.text('Request Script Change'), findsOneWidget);
  });
}
