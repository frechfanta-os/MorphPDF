import 'package:flutter/material.dart';
import '../../app/theme/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, danger, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = theme.colorScheme.primary;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = theme.colorScheme.secondary;
        fg = Colors.white;
        break;
      case AppButtonVariant.danger:
        bg = theme.colorScheme.error;
        fg = Colors.white;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = theme.colorScheme.primary;
        border = BorderSide(color: theme.colorScheme.primary, width: 1.5);
        break;
    }

    return SizedBox(
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppDimensions.iconSizeMedium),
                    const SizedBox(width: AppDimensions.space8),
                  ],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
