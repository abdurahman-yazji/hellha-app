import 'package:flutter_test/flutter_test.dart';
import 'package:hellha/app.dart';

void main() {
  testWidgets('shows the home page', (WidgetTester tester) async {
    await tester.pumpWidget(const HellhaApp());

    expect(find.text('Hellha'), findsOneWidget);
  });
}