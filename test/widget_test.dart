import 'package:flutter_test/flutter_test.dart';

import 'package:omr_scanner/main.dart';

void main() {
  testWidgets('Home screen shows both scan options', (WidgetTester tester) async {
    await tester.pumpWidget(const OmrScannerApp());
    await tester.pumpAndSettle();

    expect(find.text('Scan Answer Key'), findsOneWidget);
    expect(find.text('Scan OMR'), findsOneWidget);
  });
}
