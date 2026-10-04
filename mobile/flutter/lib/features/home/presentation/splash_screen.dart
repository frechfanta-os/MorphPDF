import 'package:flutter/material.dart';
import 'package:splashscreen_ghdinteractivestudio/splashscreen_ghdinteractivestudio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/constants/app_constants.dart';
import '../../home/presentation/home_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class MorphPdfSplashScreen extends StatefulWidget {
  final StorageService? storageService;

  const MorphPdfSplashScreen({super.key, this.storageService});

  @override
  State<MorphPdfSplashScreen> createState() => _MorphPdfSplashScreenState();
}

class _MorphPdfSplashScreenState extends State<MorphPdfSplashScreen> {
  bool _isOnboardingCompleted = false;

  Future<void> _bootstrap() async {
    // Lightweight local initialization only
    final storage = widget.storageService ?? LocalStorageService();
    _isOnboardingCompleted = await storage.isOnboardingCompleted();
  }

  void _onFinish() {
    if (!mounted) return;

    final targetPage = _isOnboardingCompleted
        ? const HomeScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      AppSplashScreen.fadeRoute(
        page: targetPage,
        duration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSplashScreen(
      appName: AppConstants.appName,
      appLogo: null,
      appNameStyle: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      appNameFontFamily: 'sans-serif',
      appNameFontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
      companyPrefix: 'from',
      companyName: 'ghdinteractivestudio',
      companyNameGradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
      ),
      duration: const Duration(milliseconds: 2400),
      entranceDuration: const Duration(milliseconds: 850),
      exitDuration: const Duration(milliseconds: 380),
      showExitTransition: true,
      themeMode: ThemeMode.system,
      preloadFuture: _bootstrap(),
      onFinish: _onFinish,
    );
  }
}
