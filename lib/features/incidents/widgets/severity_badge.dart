import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  static String labelFor(String severity) {
    final key = 'severity.${severity.toLowerCase()}';
    final label = key.tr();
    return label == key ? severity.toUpperCase() : label;
  }

  @override
  Widget build(BuildContext context) {
    final color = context.palette.colorForSeverity(severity);
    final containerColor = context.palette.containerForSeverity(severity);
    final label = labelFor(severity);

    return Semantics(
      label: 'severity.semantics'.tr(args: [label]),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
