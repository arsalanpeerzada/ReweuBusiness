import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Shown above content served from the offline cache.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD, vertical: 8),
        color: palette.severityMediumContainer,
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 16, color: palette.severityMedium),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'offline.banner'.tr(),
                style: AppTypography.caption(context).copyWith(color: palette.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
