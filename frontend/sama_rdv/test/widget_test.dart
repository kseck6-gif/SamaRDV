
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sama_rdv/screens/home_screen.dart';

void main() {
  testWidgets('SamaRDV affiche son écran d’accueil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    expect(find.text('♥ SamaRDV'), findsOneWidget);
    expect(find.text('Votre santé, notre priorité'), findsOneWidget);
  });
}
