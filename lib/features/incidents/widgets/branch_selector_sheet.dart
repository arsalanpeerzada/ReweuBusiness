import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/models/auth_models.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Bottom sheet listing the business's branches. Resolves to the chosen
/// branch id, `-1` for "All branches", or null when dismissed.
Future<int?> showBranchSelector(
  BuildContext context, {
  required List<BranchSummary> branches,
  required int? selectedBranchId,
}) {
  final palette = context.palette;
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: palette.surfaceElevated,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
    ),
    builder: (ctx) {
      Widget tile({required int value, required String title, String? subtitle}) {
        final isSelected = value == -1 ? selectedBranchId == null : value == selectedBranchId;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            value == -1 ? Icons.store_mall_directory_outlined : Icons.storefront_outlined,
            color: isSelected ? palette.primary : palette.textSecondary,
          ),
          title: Text(
            title,
            style: AppTypography.body(ctx).copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: subtitle != null && subtitle.isNotEmpty
              ? Text(subtitle, style: AppTypography.caption(ctx))
              : null,
          trailing: isSelected ? Icon(Icons.check_circle, color: palette.primary, size: 20) : null,
          selected: isSelected,
          onTap: () => Navigator.pop(ctx, value),
        );
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text('branches.select_title'.tr(), style: AppTypography.h3(ctx)),
                const SizedBox(height: 8),
                tile(value: -1, title: 'common.all_branches'.tr()),
                Divider(color: palette.borderSubtle),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: branches.length,
                    separatorBuilder: (_, _) => Divider(color: palette.borderSubtle),
                    itemBuilder: (_, index) {
                      final b = branches[index];
                      return tile(
                        value: b.id,
                        title: b.name.isNotEmpty ? b.name : '#${b.id}',
                        subtitle: b.locationName,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
