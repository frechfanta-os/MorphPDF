import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:morphpdf/app/app.dart';
import 'package:morphpdf/shared/constants/app_constants.dart';

void main() {
  testWidgets('Application startup renders official AppSplashScreen with app name', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MorphPdfApp(),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('ghdinteractivestudio'), findsOneWidget);

    // Let the animation advance
    await tester.pump(const Duration(milliseconds: 500));
  });
}
