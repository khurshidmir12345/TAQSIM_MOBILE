import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/constants/app_constants.dart';

void main() {
  testWidgets('App name renders TAQSEEM', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text(AppConstants.appName)),
        ),
      ),
    );
    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
