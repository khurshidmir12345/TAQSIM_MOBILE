import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonvoyxona/main.dart';

void main() {
  testWidgets('App renders splash screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NonvoyxonaApp()),
    );
    expect(find.text('Nonvoyxona'), findsOneWidget);
  });
}
