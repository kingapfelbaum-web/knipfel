import 'package:flutter_test/flutter_test.dart';
import 'package:testkni/main.dart';

void main() {
  testWidgets('Kniffel App startet', (WidgetTester tester) async {
    await tester.pumpWidget(const KniffelApp());
    expect(find.text('Kniffel'), findsOneWidget);
  });
}