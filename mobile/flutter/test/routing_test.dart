import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/app/router.dart';
import 'package:morphpdf/features/home/presentation/home_screen.dart';
import 'package:morphpdf/shared/constants/app_constants.dart';

void main() {
  test('AppRouter generates expected routes', () {
    final homeRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppConstants.routeHome),
    );
    expect(homeRoute, isA<MaterialPageRoute>());

    final docsRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppConstants.routeDocuments),
    );
    expect(docsRoute, isA<MaterialPageRoute>());

    final aiRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppConstants.routeAi),
    );
    expect(aiRoute, isA<MaterialPageRoute>());

    final settingsRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppConstants.routeSettings),
    );
    expect(settingsRoute, isA<MaterialPageRoute>());
  });

  testWidgets('Routing to Home renders HomeDashboardView', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    expect(find.text('Bienvenue sur MorphPDF'), findsOneWidget);
    expect(find.text('Ouvrir un PDF'), findsOneWidget);
    expect(find.text('Scanner OCR'), findsOneWidget);
  });
}
