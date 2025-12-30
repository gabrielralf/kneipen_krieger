// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kneipen_krieger/pages/login.dart';

void main() {
  testWidgets('Shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Willkommen!'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    bool isAssetImage(Widget w, String assetName) {
      return w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == assetName;
    }

    expect(
      find.byWidgetPredicate((w) => isAssetImage(w, 'lib/images/google_logo.png')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) => isAssetImage(w, 'lib/images/github-mark.png')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
