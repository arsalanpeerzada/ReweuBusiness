import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/support_config.dart';
import '../../../data/repositories/support_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/support_chat_cubit.dart';
import '../widgets/support_contact_sheet.dart';

class SupportChatScreen extends StatefulWidget {
  final int? incidentId;
  final String? incidentCode;

  const SupportChatScreen({
    super.key,
    this.incidentId,
    this.incidentCode,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final SupportChatCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SupportChatCubit(
      repository: context.read<SupportRepository>(),
      incidentId: widget.incidentId,
    )..load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _messageController.clear();
    final sent = await _cubit.sendMessage(text);
    if (sent && mounted && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SupportChatCubit, SupportChatState>(
        builder: (context, state) {
          final SupportConfig? config = state is SupportChatLoaded
              ? state.config
              : (state is SupportChatLoading ? state.config : null);

          return Scaffold(
            backgroundColor: palette.background,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('support.chat_title'.tr(), style: AppTypography.h2(context)),
                  Text(
                    'support.chat_24_7'.tr(),
                    style: AppTypography.caption(context).copyWith(color: palette.brandText),
                  ),
                ],
              ),
              actions: [
                if (config?.hasPhone == true)
                  IconButton(
                    icon: Icon(Icons.call_rounded, color: palette.primary),
                    tooltip: config!.supportHours.isNotEmpty
                        ? 'support.call_with_hours'.tr(args: [config.supportHours])
                        : 'support.call_title'.tr(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      launchSupportCall(context, config.phone);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'common.refresh'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _cubit.load(showSpinner: false);
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                if (widget.incidentCode != null && widget.incidentCode!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spaceMD,
                      vertical: 10,
                    ),
                    color: palette.surfaceContainer,
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 16, color: palette.brandText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'support.escalating_incident'.tr(args: [widget.incidentCode!]),
                            style: AppTypography.caption(context).copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (config?.hasPhone == true && config!.supportHours.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spaceMD,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border(bottom: BorderSide(color: palette.borderSubtle)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: palette.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'support.phone_hours_banner'.tr(args: [config.supportHours]),
                            style: AppTypography.caption(context),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => launchSupportCall(context, config.phone),
                          child: Text(
                            'support.call_now'.tr(),
                            style: AppTypography.caption(context).copyWith(
                              color: palette.brandText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildBody(context, state)),
                _buildComposer(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SupportChatState state) {
    final palette = context.palette;

    if (state is SupportChatLoading || state is SupportChatInitial) {
      return Center(child: CircularProgressIndicator(color: palette.primary));
    }

    if (state is SupportChatLoaded) {
      if (state.chatUnavailable) {
        return _buildChatUnavailableFallback(context, state.config);
      }

      if (state.messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spaceXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent_rounded, size: 48, color: palette.brandText),
                const SizedBox(height: 12),
                Text(
                  'support.chat_empty_title'.tr(),
                  style: AppTypography.h3(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'support.chat_empty_subtitle'.tr(),
                  style: AppTypography.bodySmall(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          if (state.errorBanner != null)
            MaterialBanner(
              backgroundColor: palette.severityCritical.withValues(alpha: 0.12),
              content: Text(
                state.errorBanner!,
                style: AppTypography.caption(context).copyWith(color: palette.severityCritical),
              ),
              actions: [
                TextButton(
                  onPressed: () => _cubit.load(showSpinner: false),
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          Expanded(
            child: RefreshIndicator(
              color: palette.primary,
              onRefresh: () => _cubit.load(showSpinner: false),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                itemCount: state.messages.length,
                itemBuilder: (context, index) => _MessageBubble(
                  message: state.messages[index],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChatUnavailableFallback(BuildContext context, SupportConfig? config) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: palette.brandText),
            const SizedBox(height: 12),
            Text(
              'support.chat_unavailable_title'.tr(),
              style: AppTypography.h3(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'support.chat_unavailable_body'.tr(),
              style: AppTypography.bodySmall(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (config?.hasWhatsapp == true) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  final prefill = widget.incidentCode != null && widget.incidentCode!.isNotEmpty
                      ? 'support.whatsapp_prefill_incident'.tr(args: [widget.incidentCode!])
                      : 'support.whatsapp_prefill'.tr();
                  launchSupportWhatsApp(context, config!.whatsapp!, prefill: prefill);
                },
                icon: const Icon(Icons.forum_outlined),
                label: Text('support.whatsapp_title'.tr()),
              ),
              const SizedBox(height: 10),
            ],
            if (config != null && config.hasPhone)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => launchSupportCall(context, config.phone),
                icon: const Icon(Icons.call_rounded),
                label: Text(
                  config.supportHours.isNotEmpty
                      ? 'support.call_with_hours'.tr(args: [config.supportHours])
                      : 'support.call_title'.tr(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context, SupportChatState state) {
    final palette = context.palette;
    final disabled = state is SupportChatLoaded && (state.isSending || state.chatUnavailable);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !disabled,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'support.chat_hint'.tr(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
              ),
              icon: state is SupportChatLoaded && state.isSending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              onPressed: disabled ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fromAdmin = message.isFromSuperAdmin;

    return Align(
      alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromAdmin ? palette.surface : palette.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: fromAdmin ? Border.all(color: palette.border) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fromAdmin
                  ? (message.senderName.isNotEmpty ? message.senderName : 'support.super_admin'.tr())
                  : 'support.you'.tr(),
              style: AppTypography.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: fromAdmin ? palette.brandText : palette.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: AppTypography.body(context).copyWith(
                color: fromAdmin ? palette.textPrimary : palette.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.createdAt.toLocal()),
              style: AppTypography.caption(context).copyWith(
                fontSize: 10,
                color: fromAdmin ? palette.textHint : palette.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
