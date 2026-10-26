import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';

/// AppLogo displays the official Reweu brand logo adapted for dark/light themes.
class AppLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final Alignment alignment;
  final bool showBadge;
  final String badgeText;

  const AppLogo({
    super.key,
    this.height = 26,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.centerLeft,
    this.showBadge = false,
    this.badgeText = 'COMPANION',
  });

  /// Styled logo mark inside a rounded container, ideal for avatars, icons, or compact headers.
  static Widget mark({
    Key? key,
    double size = 32,
    double padding = 4,
    BorderRadius? borderRadius,
  }) {
    return Builder(
      builder: (context) {
        final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusXS);
        return Container(
          key: key,
          width: size,
          height: size,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: radius,
            border: Border.all(
              color: context.palette.primary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: const AppLogo(
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark
        ? 'assets/images/reweu_logo.png'
        : 'assets/images/reweu_logo_light.png';

    final logoWidget = Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to original asset
        return Image.asset(
          'assets/images/reweu_logo_new.png',
          height: height,
          width: width,
          fit: fit,
          alignment: alignment,
        );
      },
    );

    if (!showBadge) {
      return logoWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.palette.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
            border: Border.all(
              color: context.palette.primary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: context.palette.primary,
            ),
          ),
        ),
      ],
    );
  }
}
