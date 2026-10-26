import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/incident.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/incident_detail_bloc.dart';
import '../widgets/resolution_modal.dart';
import '../widgets/severity_badge.dart';

class IncidentDetailScreen extends StatefulWidget {
  final int incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<IncidentDetailBloc>().add(FetchIncidentDetailEvent(widget.incidentId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _openResolutionModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surfaceElevated,
      builder: (ctx) => ResolutionModal(
        incidentId: widget.incidentId,
        onConfirm: (status, summary, sendVoucher, amount) {
          context.read<IncidentDetailBloc>().add(
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
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text('Incident Triage', style: AppTypography.h2(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<IncidentDetailBloc>().add(FetchIncidentDetailEvent(widget.incidentId));
            },
          ),
        ],
      ),
      body: BlocBuilder<IncidentDetailBloc, IncidentDetailState>(
        builder: (context, state) {
          if (state is IncidentDetailLoading) {
            return _buildSkeleton(context);
          } else if (state is IncidentDetailLoaded || state is IncidentDetailActionInProgress) {
            final incident = (state as dynamic).incident as IncidentDetailResponse;
            return _buildDetailContent(context, incident);
          } else if (state is IncidentDetailError) {
            return Center(
              child: Text(state.message, style: AppTypography.bodyMedium(context)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, IncidentDetailResponse incident) {
    return Column(
      children: [
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
                        Text(
                          incident.code.isNotEmpty ? incident.code : '#${incident.id}',
                          style: AppTypography.incidentCode(context).copyWith(fontSize: 16),
                        ),
                        SeverityBadge(severity: incident.severity),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reported: ${DateFormat('EEE, MMM d, yyyy • h:mm a').format(incident.createdAt)}',
                      style: AppTypography.caption(context),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (incident.branchName != null && incident.branchName!.isNotEmpty) ...[
                          Icon(Icons.storefront, size: 16, color: context.palette.brandText),
                          const SizedBox(width: 6),
                          Text(
                            incident.branchName!,
                            style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer Review Context Card
              Text('Customer Feedback', style: AppTypography.h3(context)),
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
                        Text(
                          incident.customerName?.isNotEmpty == true ? incident.customerName! : 'Guest Reviewer',
                          style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (incident.rating != null)
                          Row(
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      incident.reviewComment ?? 'No written comment left by customer.',
                      style: AppTypography.reviewContent(context),
                    ),
                    const SizedBox(height: 16),

                    // Customer Contact Actions
                    if (incident.customerPhone != null && incident.customerPhone!.isNotEmpty) ...[
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.palette.border),
                              ),
                              onPressed: () => _makePhoneCall(incident.customerPhone!),
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text('Call'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _openWhatsApp(incident.customerPhone!),
                              icon: const Icon(Icons.chat, size: 16),
                              label: const Text('WhatsApp'),
                            ),
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
                Text('Trigger Dimensions', style: AppTypography.h3(context)),
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

              // Activity Stream & Notes
              Text('Team Notes & Activity', style: AppTypography.h3(context)),
              const SizedBox(height: 8),
              if (incident.activities.isEmpty)
                Text('No activity recorded yet.', style: AppTypography.caption(context))
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
                            Text(
                              act.performedBy?.name ?? 'System',
                              style: AppTypography.caption(context).copyWith(
                                color: context.palette.brandText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, h:mm a').format(act.createdAt),
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
        Container(
          padding: const EdgeInsets.all(AppSpacing.spaceMD),
          decoration: BoxDecoration(
            color: context.palette.surfaceElevated,
            border: Border(top: BorderSide(color: context.palette.border)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add internal team note...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: context.palette.primary,
                        foregroundColor: context.palette.onPrimary,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 20),
                      onPressed: _postComment,
                    ),
                  ],
                ),
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
                  onPressed: () => _openResolutionModal(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Resolve Incident & Recovery', style: AppTypography.button(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
