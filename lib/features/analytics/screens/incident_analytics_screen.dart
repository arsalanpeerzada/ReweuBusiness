import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/incident_analytics.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/incident_analytics_cubit.dart';

class IncidentAnalyticsScreen extends StatelessWidget {
  final int businessId;

  const IncidentAnalyticsScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IncidentAnalyticsCubit(
        context.read<IncidentRepository>(),
        businessId: businessId,
      )..load(),
      child: const _AnalyticsView(),
    );
  }
}

/// Formats a duration in minutes as "45m", "3h 20m" or "2d 4h".
String formatMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return 'time.short_minutes'.tr(args: ['$minutes']);
  final hours = minutes ~/ 60;
  if (hours < 24) {
    final rem = minutes % 60;
    return rem == 0
        ? 'time.short_hours'.tr(args: ['$hours'])
        : 'time.short_hours_minutes'.tr(args: ['$hours', '$rem']);
  }
  final days = hours ~/ 24;
  final remHours = hours % 24;
  return remHours == 0
      ? 'time.short_days'.tr(args: ['$days'])
      : 'time.short_days_hours'.tr(args: ['$days', '$remHours']);
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text('analytics.title'.tr(), style: AppTypography.h2(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'common.refresh'.tr(),
            onPressed: () => context.read<IncidentAnalyticsCubit>().load(),
          ),
        ],
      ),
      body: BlocBuilder<IncidentAnalyticsCubit, IncidentAnalyticsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: palette.primary,
            onRefresh: () => context.read<IncidentAnalyticsCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.spaceMD),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _PeriodSelector(selected: state.period),
                const SizedBox(height: 16),
                if (state.isLoading && state.data == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: palette.primary)),
                  )
                else if (state.error != null)
                  _ErrorView(message: state.error!)
                else if (state.data != null) ...[
                  if (state.isLoading)
                    LinearProgressIndicator(color: palette.primary, minHeight: 2),
                  _KpiGrid(data: state.data!),
                  const SizedBox(height: 20),
                  _SeverityTrend(points: state.data!.severityTrend),
                  const SizedBox(height: 20),
                  _PerformanceTable(
                    title: 'analytics.by_branch'.tr(),
                    nameHeader: 'common.branch'.tr(),
                    rows: state.data!.locationPerformance,
                  ),
                  const SizedBox(height: 20),
                  _PerformanceTable(
                    title: 'analytics.by_staff'.tr(),
                    nameHeader: 'analytics.staff'.tr(),
                    rows: state.data!.staffPerformance,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selected;

  const _PeriodSelector({required this.selected});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SegmentedButton<AnalyticsPeriod>(
      showSelectedIcon: false,
      segments: [
        for (final p in AnalyticsPeriod.values)
          ButtonSegment(value: p, label: Text('analytics.last_days'.tr(args: ['${p.days}']))),
      ],
      selected: {selected},
      onSelectionChanged: (val) {
        HapticFeedback.selectionClick();
        context.read<IncidentAnalyticsCubit>().load(val.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? palette.primary : palette.surfaceContainer),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? palette.onPrimary : palette.textPrimary),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final IncidentAnalytics data;

  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final percent = NumberFormat.percentPattern(Localizations.localeOf(context).toString()).format(data.resolutionRate);
    final tiles = [
      _KpiTile(label: 'analytics.total_incidents'.tr(), value: '${data.totalIncidents}', icon: Icons.report_outlined),
      _KpiTile(label: 'analytics.resolution_rate'.tr(), value: percent, icon: Icons.task_alt_outlined),
      _KpiTile(label: 'analytics.mtta'.tr(), value: formatMinutes(data.avgReviewTimeMinutes), icon: Icons.visibility_outlined),
      _KpiTile(label: 'analytics.mttr'.tr(), value: formatMinutes(data.avgResolveTimeMinutes), icon: Icons.timer_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: palette.brandText),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value, style: AppTypography.metricValue(context).copyWith(fontSize: 26)),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.caption(context), maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _SeverityTrend extends StatelessWidget {
  final List<SeverityTrendPoint> points;

  const _SeverityTrend({required this.points});

  static const _order = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final maxTotal = points.fold<int>(0, (m, p) => p.total > m ? p.total : m);
    final locale = Localizations.localeOf(context).toString();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('analytics.trend'.tr(), style: AppTypography.h3(context))),
          const SizedBox(height: 12),
          if (points.isEmpty || maxTotal == 0)
            Text('analytics.no_data'.tr(), style: AppTypography.bodySmall(context))
          else ...[
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final p in points)
                    Expanded(
                      child: Tooltip(
                        message: '${DateFormat('MMM d', locale).format(p.date)}: ${p.total}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (final sev in _order)
                                if ((p.countsBySeverity[sev] ?? 0) > 0)
                                  Container(
                                    height: 140 * (p.countsBySeverity[sev]! / maxTotal),
                                    color: palette.colorForSeverity(sev),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMM d', locale).format(points.first.date), style: AppTypography.caption(context)),
                Text(DateFormat('MMM d', locale).format(points.last.date), style: AppTypography.caption(context)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final sev in _order)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, color: palette.colorForSeverity(sev)),
                      const SizedBox(width: 4),
                      Text('severity.${sev.toLowerCase()}'.tr(), style: AppTypography.caption(context)),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceTable extends StatelessWidget {
  final String title;
  final String nameHeader;
  final List<PerformanceRow> rows;

  const _PerformanceTable({required this.title, required this.nameHeader, required this.rows});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final percent = NumberFormat.percentPattern(Localizations.localeOf(context).toString());
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: AppTypography.h3(context))),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text('analytics.no_data'.tr(), style: AppTypography.bodySmall(context))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
                dataTextStyle: AppTypography.bodySmall(context).copyWith(color: palette.textPrimary),
                columnSpacing: 20,
                horizontalMargin: 0,
                columns: [
                  DataColumn(label: Text(nameHeader)),
                  DataColumn(label: Text('analytics.col_incidents'.tr()), numeric: true),
                  DataColumn(label: Text('analytics.col_resolved'.tr()), numeric: true),
                  DataColumn(label: Text('analytics.mtta_short'.tr()), numeric: true),
                  DataColumn(label: Text('analytics.mttr_short'.tr()), numeric: true),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(cells: [
                      DataCell(Text(r.name.isNotEmpty ? r.name : '-')),
                      DataCell(Text('${r.incidents}')),
                      DataCell(Text(percent.format(r.percentResolved > 1 ? r.percentResolved / 100 : r.percentResolved))),
                      DataCell(Text(formatMinutes(r.avgReviewMinutes))),
                      DataCell(Text(formatMinutes(r.avgResolveMinutes))),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 48, color: palette.textSecondary),
          const SizedBox(height: 16),
          Text('analytics.load_error'.tr(), style: AppTypography.h3(context), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.bodySmall(context), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
            ),
            onPressed: () => context.read<IncidentAnalyticsCubit>().load(),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }
}
