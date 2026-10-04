import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/app/theme/app_colors.dart';
import 'package:morphpdf/app/theme/app_dimensions.dart';
import 'package:morphpdf/app/theme/app_theme.dart';

void main() {
  group('Theme & Design System Tests', () {
    test('Light theme properties', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.aiViolet);
      expect(theme.useMaterial3, isTrue);
    });

    test('Dark theme properties', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primaryDark);
      expect(theme.useMaterial3, isTrue);
    });

    test('AppDimensions accessible touch targets', () {
      expect(AppDimensions.minTouchTarget, greaterThanOrEqualTo(48.0));
      expect(AppDimensions.buttonHeight, greaterThanOrEqualTo(48.0));
    });
  });
}
