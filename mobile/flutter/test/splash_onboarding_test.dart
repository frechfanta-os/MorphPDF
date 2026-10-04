import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/storage/storage_service.dart';
import 'package:morphpdf/features/home/presentation/home_screen.dart';
import 'package:morphpdf/features/home/presentation/splash_screen.dart';
import 'package:morphpdf/features/onboarding/presentation/onboarding_screen.dart';

class MockStorageService implements StorageService {
  bool completed;
  MockStorageService({this.completed = false});

  @override
  Future<bool> isOnboardingCompleted() async => completed;

  @override
  Future<void> setOnboardingCompleted(bool val) async {
    completed = val;
  }

  @override
  Future<File> saveTemp(String fileName, List<int> bytes) async => File(fileName);
  @override
  Future<File?> getTemp(String fileName) async => null;
  @override
  Future<void> deleteTemp(String fileName) async {}
  @override
  Future<File> saveExport(String fileName, List<int> bytes) async => File(fileName);
  @override
  Future<List<File>> listExports() async => [];
}

void main() {
  group('Splash and Onboarding Tests', () {
    testWidgets('First launch: Splash transitions to Onboarding', (tester) async {
      final mockStorage = MockStorageService(completed: false);

      await tester.pumpWidget(
        MaterialApp(
          home: MorphPdfSplashScreen(storageService: mockStorage),
        ),
      );

      expect(find.text('MorphPDF'), findsOneWidget);
      expect(find.text('ghdinteractivestudio'), findsOneWidget);

      // Finish splash duration & transitions
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Bienvenue sur\nMorphPDF'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('Returning user: Splash transitions directly to Home', (tester) async {
      final mockStorage = MockStorageService(completed: true);

      await tester.pumpWidget(
        MaterialApp(
          home: MorphPdfSplashScreen(storageService: mockStorage),
        ),
      );

      // Finish splash duration & transitions
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Bienvenue sur MorphPDF'), findsOneWidget);
    });

    testWidgets('Onboarding "Commencer" saves flag', (tester) async {
      final mockStorage = MockStorageService(completed: false);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home Target')),
          },
          home: OnboardingScreen(storageService: mockStorage),
        ),
      );

      expect(find.text('Commencer'), findsOneWidget);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      expect(mockStorage.completed, isTrue);
      expect(find.text('Home Target'), findsOneWidget);
    });
  });
}
