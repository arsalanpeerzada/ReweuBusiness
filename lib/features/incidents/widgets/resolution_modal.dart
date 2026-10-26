import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ResolutionModal extends StatefulWidget {
  final int incidentId;
  final Function(String status, String? summary, bool sendVoucher, double? amount) onConfirm;

  const ResolutionModal({
    super.key,
    required this.incidentId,
    required this.onConfirm,
  });

  @override
  State<ResolutionModal> createState() => _ResolutionModalState();
}

class _ResolutionModalState extends State<ResolutionModal> {
  final _summaryController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedStatus = 'RESOLVED';
  bool _sendVoucher = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    HapticFeedback.heavyImpact();
    final double? amount = _sendVoucher ? double.tryParse(_amountController.text) : null;
    widget.onConfirm(
      _selectedStatus,
      _summaryController.text.trim().isNotEmpty ? _summaryController.text.trim() : null,
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
          Text(
            'Incident Resolution & Recovery',
            style: AppTypography.h2(context),
          ),
          const SizedBox(height: 16),

          // Status selector
          Text('Target Status', style: AppTypography.bodySmall(context)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ACKNOWLEDGED', label: Text('In Progress')),
              ButtonSegment(value: 'RESOLVED', label: Text('Resolved')),
            ],
            selected: {_selectedStatus},
            onSelectionChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _selectedStatus = val.first);
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
            controller: _summaryController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Resolution Summary',
              hintText: 'e.g. Table manager apologized, dish replaced, guest satisfied.',
            ),
          ),
          const SizedBox(height: 16),

          // Service Recovery Voucher Toggle
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            decoration: BoxDecoration(
              color: context.palette.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
              border: Border.all(color: context.palette.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.confirmation_num_outlined,
                          color: context.palette.brandText,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Recovery Voucher',
                              style: AppTypography.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Send instant credit to customer app',
                              style: AppTypography.caption(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _sendVoucher,
                      activeThumbColor: context.palette.primary,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _sendVoucher = val);
                      },
                    ),
                  ],
                ),
                if (_sendVoucher) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Voucher Value (\$ / PKR)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
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
              'Confirm Resolution',
              style: AppTypography.button(context).copyWith(
                color: context.palette.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
