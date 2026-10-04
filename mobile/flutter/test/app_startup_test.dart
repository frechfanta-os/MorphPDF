import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:morphpdf/app/app.dart';
import 'package:morphpdf/shared/constants/app_constants.dart';

void main() {
  testWidgets('Application startup renders SplashScreen with app name', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MorphPdfApp(),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('PDF Intelligent • Local-First • IA'), findsOneWidget);

    // Advance past splash timer
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
  });
}
