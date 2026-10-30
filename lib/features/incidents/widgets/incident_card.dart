import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/incident.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'severity_badge.dart';

class IncidentCard extends StatelessWidget {
  final IncidentListResponse incident;
  final VoidCallback onTap;
  final VoidCallback? onQuickAcknowledge;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.onQuickAcknowledge,
  });

  static String formatTimeAgo(BuildContext context, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'time.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'time.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    } else if (diff.inHours < 24) {
      return 'time.hours_ago'.tr(args: ['${diff.inHours}']);
    }
    return DateFormat('MMM d, h:mm a', Localizations.localeOf(context).toString()).format(dateTime);
  }

  bool get _canAcknowledge => incident.status == 'OPEN' && onQuickAcknowledge != null;

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    if (!_canAcknowledge) return card;

    // Swipe right to acknowledge. The card stays in place; the feed refreshes
    // once the backend confirms.
    return Dismissible(
      key: ValueKey('incident-${incident.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        onQuickAcknowledge!();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: context.palette.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: context.palette.onPrimary),
            const SizedBox(width: 8),
            Text(
              'incidents.acknowledge_action'.tr(),
              style: AppTypography.button(context).copyWith(color: context.palette.onPrimary),
            ),
          ],
        ),
      ),
      child: card,
    );
  }

  Widget _buildCard(BuildContext context) {
    final isCritical = incident.severity.toUpperCase() == 'CRITICAL';
    final location = incident.location?.isNotEmpty == true
        ? incident.location!
        : 'incidents.unknown_branch'.tr();

    return Semantics(
      button: true,
      label: 'incidents.card_semantics'.tr(args: [
        incident.code.isNotEmpty ? incident.code : '#${incident.id}',
        SeverityBadge.labelFor(incident.severity),
        location,
      ]),
      hint: _canAcknowledge ? 'incidents.swipe_hint'.tr() : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(
            color: isCritical
                ? context.palette.severityCritical.withValues(alpha: 0.5)
                : context.palette.border,
            width: isCritical ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Code & Severity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                incident.code.isNotEmpty ? incident.code : '#${incident.id}',
                                style: AppTypography.incidentCode(context),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${formatTimeAgo(context, incident.createdAt)}',
                              style: AppTypography.caption(context),
                            ),
                          ],
                        ),
                      ),
                      SeverityBadge(severity: incident.severity),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location / Branch
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 16,
                        color: context.palette.brandText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTypography.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (incident.rating != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.palette.colorForRating(incident.rating!).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: context.palette.colorForRating(incident.rating!),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                incident.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.palette.colorForRating(incident.rating!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Metrics / Trigger Tags
                  if (incident.metrics.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: incident.metrics.take(3).map((metric) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
                            border: Border.all(color: context.palette.border, width: 0.5),
                          ),
                          child: Text(
                            metric.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.palette.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Bottom Footer: Review & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'incidents.review_id'.tr(args: ['${incident.reviewId}']),
                        style: AppTypography.caption(context),
                      ),
                      if (_canAcknowledge)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(48, 40),
                            backgroundColor: context.palette.primary.withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                            ),
                          ),
                          onPressed: onQuickAcknowledge,
                          icon: Icon(Icons.check_circle_outline, size: 16, color: context.palette.brandText),
                          label: Text(
                            'incidents.acknowledge_action'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.palette.brandText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
