import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/security/secure_screen.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/incident_detail_bloc.dart';
import '../bloc/incident_feed_bloc.dart';
import '../widgets/resolution_modal.dart';
import '../widgets/severity_badge.dart';

class IncidentDetailScreen extends StatelessWidget {
  final int incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IncidentDetailBloc(context.read<IncidentRepository>())
        ..add(FetchIncidentDetailEvent(incidentId)),
      child: _IncidentDetailView(incidentId: incidentId),
    );
  }
}

class _IncidentDetailView extends StatefulWidget {
  final int incidentId;

  const _IncidentDetailView({required this.incidentId});

  @override
  State<_IncidentDetailView> createState() => _IncidentDetailViewState();
}

class _IncidentDetailViewState extends State<_IncidentDetailView> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Customer contact details are on this screen.
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _commentController.dispose();
    super.dispose();
  }

  void _openResolutionModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    final bloc = context.read<IncidentDetailBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surfaceElevated,
      builder: (ctx) => ResolutionModal(
        incidentId: widget.incidentId,
        onConfirm: (status, summary, sendVoucher, amount) {
          bloc.add(
            ResolveIncidentEvent(
              incidentId: widget.incidentId,
              status: status,
              summary: summary,
              sendVoucher: sendVoucher,
              voucherAmount: amount,
            ),
          );
        },
      ),
    );
  }

  void _postComment() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;
    HapticFeedback.lightImpact();
    context.read<IncidentDetailBloc>().add(PostCommentEvent(widget.incidentId, comment));
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _launch(Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: mode);
    } catch (_) {
      launched = false;
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('incident_detail.launch_failed'.tr())),
      );
    }
  }

  Future<void> _makePhoneCall(String phone) =>
      _launch(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));

  Future<void> _openWhatsApp(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return _launch(Uri.parse('https://wa.me/$cleanPhone'), mode: LaunchMode.externalApplication);
  }

  Future<void> _sendEmail(String email) => _launch(Uri(scheme: 'mailto', path: email));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text('incident_detail.title'.tr(), style: AppTypography.h2(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'common.refresh'.tr(),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<IncidentDetailBloc>().add(FetchIncidentDetailEvent(widget.incidentId));
            },
          ),
        ],
      ),
      body: BlocConsumer<IncidentDetailBloc, IncidentDetailState>(
        listenWhen: (prev, curr) =>
            curr is IncidentDetailLoaded &&
            curr.notice != null &&
            (prev is! IncidentDetailLoaded || prev.notice != curr.notice),
        listener: (context, state) {
          final notice = (state as IncidentDetailLoaded).notice!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: notice.isError ? context.palette.severityCritical : null,
                content: Text(notice.message),
              ),
            );
          if (!notice.isError) {
            // Keep the feed in step with status changes made here.
            context.read<IncidentFeedBloc>().add(const RefreshIncidentsEvent());
          }
        },
        builder: (context, state) {
          if (state is IncidentDetailLoading || state is IncidentDetailInitial) {
            return _buildSkeleton(context);
          } else if (state is IncidentDetailLoaded) {
            return _buildDetailContent(context, state.incident, busy: state.actionInProgress);
          } else if (state is IncidentDetailError) {
            return _buildError(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, IncidentDetailError state) {
    final icon = switch (state.kind) {
      ApiErrorKind.forbidden => Icons.lock_outline,
      ApiErrorKind.notFound => Icons.search_off_rounded,
      _ => Icons.wifi_off_outlined,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.palette.textSecondary),
            const SizedBox(height: 16),
            Text('incident_detail.load_error_title'.tr(), style: AppTypography.h3(context), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(state.message, style: AppTypography.bodySmall(context), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.onPrimary,
              ),
              onPressed: () =>
                  context.read<IncidentDetailBloc>().add(FetchIncidentDetailEvent(widget.incidentId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, IncidentDetailResponse incident, {required bool busy}) {
    final locale = Localizations.localeOf(context).toString();
    final readOnly = incident.fromCache;

    return Column(
      children: [
        if (incident.fromCache) const OfflineBanner(),
        if (busy) LinearProgressIndicator(color: context.palette.primary, minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(color: context.palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            incident.code.isNotEmpty ? incident.code : '#${incident.id}',
                            style: AppTypography.incidentCode(context).copyWith(fontSize: 16),
                          ),
                        ),
                        SeverityBadge(severity: incident.severity),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'incident_detail.reported'.tr(args: [
                        DateFormat('EEE, MMM d, yyyy • h:mm a', locale).format(incident.createdAt),
                      ]),
                      style: AppTypography.caption(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'incident_detail.status_line'.tr(args: [_statusLabel(incident.status)]),
                      style: AppTypography.caption(context).copyWith(color: context.palette.brandText),
                    ),
                    if (incident.branchName != null && incident.branchName!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 16, color: context.palette.brandText),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              incident.branchName!,
                              style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer Review Context Card
              Semantics(header: true, child: Text('incident_detail.customer_feedback'.tr(), style: AppTypography.h3(context))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(color: context.palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            incident.customerName?.isNotEmpty == true
                                ? incident.customerName!
                                : 'incident_detail.guest_reviewer'.tr(),
                            style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (incident.rating != null)
                          Semantics(
                            label: 'incident_detail.rating_semantics'
                                .tr(args: [incident.rating!.toStringAsFixed(1)]),
                            excludeSemantics: true,
                            child: Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < incident.rating!.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 18,
                                  color: context.palette.colorForRating(incident.rating!),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      incident.reviewComment ?? 'incident_detail.no_comment'.tr(),
                      style: AppTypography.reviewContent(
                        context,
                        isUrdu: RegExp(r'[؀-ۿ]').hasMatch(incident.reviewComment ?? ''),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Contact Actions
                    if ((incident.customerPhone?.isNotEmpty ?? false) ||
                        (incident.customerEmail?.isNotEmpty ?? false)) ...[
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (incident.customerPhone?.isNotEmpty ?? false) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.palette.border),
                                minimumSize: const Size(48, 44),
                              ),
                              onPressed: () => _makePhoneCall(incident.customerPhone!),
                              icon: const Icon(Icons.phone, size: 16),
                              label: Text('incident_detail.call'.tr()),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.palette.whatsApp,
                                foregroundColor: context.palette.onWhatsApp,
                                minimumSize: const Size(48, 44),
                              ),
                              onPressed: () => _openWhatsApp(incident.customerPhone!),
                              icon: const Icon(Icons.chat, size: 16),
                              label: Text('incident_detail.whatsapp'.tr()),
                            ),
                          ],
                          if (incident.customerEmail?.isNotEmpty ?? false)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.palette.border),
                                minimumSize: const Size(48, 44),
                              ),
                              onPressed: () => _sendEmail(incident.customerEmail!),
                              icon: const Icon(Icons.email_outlined, size: 16),
                              label: Text('incident_detail.email'.tr()),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trigger Metrics
              if (incident.metrics.isNotEmpty) ...[
                Semantics(header: true, child: Text('incident_detail.trigger_dimensions'.tr(), style: AppTypography.h3(context))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: incident.metrics.entries.map((entry) {
                    final ratingVal = entry.value > 0 ? ' (${entry.value.toStringAsFixed(1)}★)' : '';
                    return Chip(
                      label: Text('${entry.key.replaceAll('_', ' ')}$ratingVal'),
                      backgroundColor: context.palette.surfaceContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (incident.resolutionSummary?.isNotEmpty ?? false) ...[
                Semantics(header: true, child: Text('incident_detail.resolution_summary'.tr(), style: AppTypography.h3(context))),
                const SizedBox(height: 8),
                Text(incident.resolutionSummary!, style: AppTypography.bodyMedium(context)),
                const SizedBox(height: 16),
              ],

              // Activity Stream & Notes
              Semantics(header: true, child: Text('incident_detail.activity'.tr(), style: AppTypography.h3(context))),
              const SizedBox(height: 8),
              if (incident.activities.isEmpty)
                Text('incident_detail.no_activity'.tr(), style: AppTypography.caption(context))
              else
                ...incident.activities.map((act) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                act.performedBy?.name ?? 'incident_detail.system'.tr(),
                                style: AppTypography.caption(context).copyWith(
                                  color: context.palette.brandText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, h:mm a', locale).format(act.createdAt),
                              style: AppTypography.caption(context),
                            ),
                          ],
                        ),
                        if (act.message != null) ...[
                          const SizedBox(height: 4),
                          Text(act.message!, style: AppTypography.bodySmall(context)),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        // Sticky Bottom Bar: Add Comment + Resolve
        if (!readOnly)
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            decoration: BoxDecoration(
              color: context.palette.surfaceElevated,
              border: Border(top: BorderSide(color: context.palette.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          enabled: !busy,
                          maxLength: 1000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _postComment(),
                          decoration: InputDecoration(
                            hintText: 'incident_detail.note_hint'.tr(),
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: context.palette.primary,
                          foregroundColor: context.palette.onPrimary,
                        ),
                        tooltip: 'incident_detail.send_note'.tr(),
                        icon: const Icon(Icons.send_rounded, size: 20),
                        onPressed: busy ? null : _postComment,
                      ),
                    ],
                  ),
                  if (!incident.isClosed) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.palette.primary,
                        foregroundColor: context.palette.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        ),
                      ),
                      onPressed: busy ? null : () => _openResolutionModal(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('incident_detail.resolve_button'.tr(), style: AppTypography.button(context)),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _statusLabel(String status) {
    final key = 'status.${status.toLowerCase()}';
    final label = key.tr();
    return label == key ? status : label;
  }

  Widget _buildSkeleton(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
          ),
        ],
      ),
    );
  }
}
