import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/support_config.dart';
import '../../../data/repositories/support_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

Future<void> launchSupportUri(
  BuildContext context,
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  var launched = false;
  try {
    launched = await launchUrl(uri, mode: mode);
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('incident_detail.launch_failed'.tr())),
    );
  }
}

Future<void> launchSupportCall(BuildContext context, String phone) {
  final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
  return launchSupportUri(context, Uri(scheme: 'tel', path: clean));
}

Future<void> launchSupportWhatsApp(
  BuildContext context,
  String whatsapp, {
  String? prefill,
}) {
  final clean = whatsapp.replaceAll(RegExp(r'\D'), '');
  final uri = Uri(
    scheme: 'https',
    host: 'wa.me',
    path: '/$clean',
    queryParameters: prefill != null && prefill.isNotEmpty ? {'text': prefill} : null,
  );
  return launchSupportUri(context, uri, mode: LaunchMode.externalApplication);
}

Future<void> launchSupportEmail(BuildContext context, String email) {
  return launchSupportUri(
    context,
    Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'support.email_subject'.tr()},
    ),
  );
}

class SupportContactSheet extends StatefulWidget {
  final SupportRepository supportRepository;
  final bool allowInAppChat;
  final int? incidentId;
  final String? incidentCode;

  const SupportContactSheet({
    super.key,
    required this.supportRepository,
    this.allowInAppChat = true,
    this.incidentId,
    this.incidentCode,
  });

  static Future<void> show(
    BuildContext context, {
    required SupportRepository supportRepository,
    bool allowInAppChat = true,
    int? incidentId,
    String? incidentCode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
      ),
      builder: (_) => SupportContactSheet(
        supportRepository: supportRepository,
        allowInAppChat: allowInAppChat,
        incidentId: incidentId,
        incidentCode: incidentCode,
      ),
    );
  }

  @override
  State<SupportContactSheet> createState() => _SupportContactSheetState();
}

class _SupportContactSheetState extends State<SupportContactSheet> {
  SupportConfig? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _config = widget.supportRepository.getCachedSupportConfig();
    _refresh();
  }

  Future<void> _refresh() async {
    final fresh = await widget.supportRepository.getSupportConfig(forceRefresh: true);
    if (mounted) {
      setState(() {
        _config = fresh;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final config = _config;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.support_agent_rounded, color: palette.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('support.title'.tr(), style: AppTypography.h2(context)),
                ),
                if (_loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('support.subtitle'.tr(), style: AppTypography.bodySmall(context)),
            const SizedBox(height: 20),

            // Call Super Admin
            _SupportActionTile(
              icon: Icons.call_rounded,
              iconColor: palette.primary,
              title: 'support.call_title'.tr(),
              subtitle: config != null && config.supportHours.isNotEmpty
                  ? 'support.hours_format'.tr(args: [config.supportHours])
                  : (config?.hasPhone == true
                      ? config!.phone
                      : 'support.phone_unavailable'.tr()),
              badgeText: config?.hasPhone == true ? config!.phone : null,
              enabled: config?.hasPhone == true,
              onTap: config?.hasPhone == true
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      launchSupportCall(context, config!.phone);
                    }
                  : null,
            ),
            const SizedBox(height: 10),

            // 24/7 Chat with Super Admin
            if (widget.allowInAppChat) ...[
              _SupportActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: palette.brandText,
                title: 'support.chat_title'.tr(),
                subtitle: 'support.chat_24_7'.tr(),
                enabled: config?.isChatEnabled ?? true,
                onTap: (config?.isChatEnabled ?? true)
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        final uri = Uri(
                          path: '/support/chat',
                          queryParameters: {
                            if (widget.incidentId != null && widget.incidentId! > 0)
                              'incidentId': '${widget.incidentId}',
                            if (widget.incidentCode != null && widget.incidentCode!.isNotEmpty)
                              'incidentCode': widget.incidentCode!,
                          },
                        );
                        context.push(uri.toString());
                      }
                    : null,
              ),
              const SizedBox(height: 10),
            ],

            // WhatsApp fallback (if configured by Super Admin)
            if (config?.hasWhatsapp == true) ...[
              _SupportActionTile(
                icon: Icons.forum_outlined,
                iconColor: const Color(0xFF25D366),
                title: 'support.whatsapp_title'.tr(),
                subtitle: 'support.whatsapp_subtitle'.tr(),
                enabled: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  final prefill = widget.incidentCode != null && widget.incidentCode!.isNotEmpty
                      ? 'support.whatsapp_prefill_incident'.tr(args: [widget.incidentCode!])
                      : 'support.whatsapp_prefill'.tr();
                  launchSupportWhatsApp(context, config!.whatsapp!, prefill: prefill);
                },
              ),
              const SizedBox(height: 10),
            ],

            // Email support (if configured by Super Admin)
            if (config?.hasEmail == true)
              _SupportActionTile(
                icon: Icons.email_outlined,
                iconColor: palette.textSecondary,
                title: 'support.email_title'.tr(),
                subtitle: config!.email!,
                enabled: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  launchSupportEmail(context, config.email!);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool enabled;
  final VoidCallback? onTap;

  const _SupportActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption(context)),
                      if (badgeText != null && badgeText!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          badgeText!,
                          style: AppTypography.caption(context).copyWith(
                            color: palette.brandText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
