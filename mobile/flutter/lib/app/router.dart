import 'package:flutter/material.dart';
import '../features/ai/presentation/ai_screen.dart';
import '../features/clean_pdf/presentation/clean_pdf_screen.dart';
import '../features/conversion/presentation/conversion_screen.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/splash_screen.dart';
import '../features/merge_split/presentation/merge_split_screen.dart';
import '../features/ocr/presentation/ocr_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/pdf_editor/presentation/pdf_editor_screen.dart';
import '../features/pdf_viewer/presentation/pdf_viewer_screen.dart';
import '../features/scanner/presentation/scanner_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/templates/presentation/templates_screen.dart';
import '../shared/constants/app_constants.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeSplash:
        return _buildRoute(const MorphPdfSplashScreen(), settings);
      case AppConstants.routeOnboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case AppConstants.routeHome:
        return _buildRoute(const HomeScreen(), settings);
      case AppConstants.routeDocuments:
        return _buildRoute(const DocumentsScreen(), settings);
      case AppConstants.routePdfViewer:
        return _buildRoute(const PdfViewerScreen(), settings);
      case AppConstants.routePdfEditor:
        return _buildRoute(const PdfEditorScreen(), settings);
      case AppConstants.routeScanner:
        return _buildRoute(const ScannerScreen(), settings);
      case AppConstants.routeOcr:
        return _buildRoute(const OcrScreen(), settings);
      case AppConstants.routeAi:
        return _buildRoute(const AiScreen(), settings);
      case AppConstants.routeCleanPdf:
        return _buildRoute(const CleanPdfScreen(), settings);
      case AppConstants.routeMergeSplit:
        return _buildRoute(const MergeSplitScreen(), settings);
      case AppConstants.routeConversion:
        return _buildRoute(const ConversionScreen(), settings);
      case AppConstants.routeExport:
        return _buildRoute(const ExportScreen(), settings);
      case AppConstants.routeTemplates:
        return _buildRoute(const TemplatesScreen(), settings);
      case AppConstants.routeSettings:
        return _buildRoute(const SettingsScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
