import 'package:flutter_test/flutter_test.dart';
import 'package:vitals_pro/main.dart';

void main() {
  testWidgets('Vitals Pro app loads without crash',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const VitalsProApp());

    // Just verify app builds
    expect(find.text('Vitals Pro'), findsWidgets);
  });
}
