import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/api_constants.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ResolutionModal extends StatefulWidget {
  final int incidentId;
  final Function(
    String status,
    String? summary,
    bool sendVoucher,
    double? amount,
  )
  onConfirm;

  const ResolutionModal({
    super.key,
    required this.incidentId,
    required this.onConfirm,
  });

  /// Returns an error message key, or null when [text] is a valid voucher amount.
  static String? validateVoucherAmount(String text) {
    final normalised = text.trim().replaceAll(',', '');
    if (normalised.isEmpty) return 'resolution.voucher_required';
    final value = double.tryParse(normalised);
    if (value == null || value.isNaN || value.isInfinite) {
      return 'resolution.voucher_invalid';
    }
    if (value <= 0) return 'resolution.voucher_positive';
    if (value > AppConfig.maxVoucherAmount) {
      return 'resolution.voucher_too_high';
    }
    return null;
  }

  /// Returns an error message key, or null when [summary] is acceptable for [status].
  static String? validateSummary(String status, String summary) {
    if (status == 'RESOLVED' &&
        summary.trim().length < AppConfig.minResolutionSummaryLength) {
      return 'resolution.summary_required';
    }
    return null;
  }

  @override
  State<ResolutionModal> createState() => _ResolutionModalState();
}

class _ResolutionModalState extends State<ResolutionModal> {
  final _summaryController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedStatus = 'RESOLVED';
  bool _sendVoucher = false;
  String? _summaryError;
  String? _amountError;

  @override
  void dispose() {
    _summaryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final summaryError = ResolutionModal.validateSummary(
      _selectedStatus,
      _summaryController.text,
    );
    final amountError = _sendVoucher
        ? ResolutionModal.validateVoucherAmount(_amountController.text)
        : null;
    setState(() {
      _summaryError = summaryError;
      _amountError = amountError;
    });
    if (summaryError != null || amountError != null) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.heavyImpact();
    final double? amount = _sendVoucher
        ? double.parse(_amountController.text.trim().replaceAll(',', ''))
        : null;
    widget.onConfirm(
      _selectedStatus,
      _summaryController.text.trim().isNotEmpty
          ? _summaryController.text.trim()
          : null,
      _sendVoucher,
      amount,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.spaceLG,
        right: AppSpacing.spaceLG,
        top: AppSpacing.spaceLG,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.spaceLG,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('resolution.title'.tr(), style: AppTypography.h2(context)),
            const SizedBox(height: 16),

            // Status selector
            Text(
              'resolution.target_status'.tr(),
              style: AppTypography.bodySmall(context),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'ACKNOWLEDGED',
                  label: Text('status.acknowledged'.tr()),
                ),
                ButtonSegment(
                  value: 'RESOLVED',
                  label: Text('status.resolved'.tr()),
                ),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedStatus = val.first;
                  _summaryError = null;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return context.palette.primary;
                  }
                  return context.palette.surfaceContainer;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return context.palette.onPrimary;
                  }
                  return context.palette.textPrimary;
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Summary Note
            TextField(
              key: const Key('resolution-summary'),
              controller: _summaryController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: _selectedStatus == 'RESOLVED'
                    ? 'resolution.summary_label_required'.tr()
                    : 'resolution.summary_label'.tr(),
                hintText: 'resolution.summary_hint'.tr(),
                errorText: _summaryError?.tr(
                  args: ['${AppConfig.minResolutionSummaryLength}'],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Service Recovery Voucher Toggle (Material so the switch tile's
            // ink is visible on the coloured background)
            Material(
              color: context.palette.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                side: BorderSide(color: context.palette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('resolution-voucher-switch'),
                      contentPadding: EdgeInsets.zero,
                      value: _sendVoucher,
                      activeThumbColor: context.palette.primary,
                      secondary: Icon(
                        Icons.confirmation_num_outlined,
                        color: context.palette.brandText,
                      ),
                      title: Text(
                        'resolution.voucher_title'.tr(),
                        style: AppTypography.bodyMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'resolution.voucher_subtitle'.tr(),
                        style: AppTypography.caption(context),
                      ),
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _sendVoucher = val;
                          _amountError = null;
                        });
                      },
                    ),
                    if (_sendVoucher) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('resolution-voucher-amount'),
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'resolution.voucher_amount'.tr(
                            args: [AppConfig.voucherCurrency],
                          ),
                          prefixText: '${AppConfig.voucherCurrency} ',
                          helperText: 'resolution.voucher_max'.tr(
                            args: [
                              NumberFormat.decimalPattern(
                                Localizations.localeOf(context).toString(),
                              ).format(AppConfig.maxVoucherAmount),
                              AppConfig.voucherCurrency,
                            ],
                          ),
                          errorText: _amountError?.tr(
                            args: [
                              NumberFormat.decimalPattern(
                                Localizations.localeOf(context).toString(),
                              ).format(AppConfig.maxVoucherAmount),
                              AppConfig.voucherCurrency,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              key: const Key('resolution-submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.onPrimary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
              ),
              onPressed: _handleSubmit,
              child: Text(
                'resolution.confirm'.tr(),
                style: AppTypography.button(
                  context,
                ).copyWith(color: context.palette.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
