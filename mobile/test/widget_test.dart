import 'package:flutter_test/flutter_test.dart';
import 'package:smarteve_mobile/app.dart';

void main() {
  testWidgets('SmartEve app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartEveApp());
    expect(find.byType(SmartEveApp), findsOneWidget);
  });
}
