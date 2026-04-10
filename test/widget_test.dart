import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nonvoyxona/core/constants/app_constants.dart';

void main() {
  testWidgets('Ilova nomi TAQSIM', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text(AppConstants.appName)),
        ),
      ),
    );
    expect(find.text('TAQSIM'), findsOneWidget);
  });
}
