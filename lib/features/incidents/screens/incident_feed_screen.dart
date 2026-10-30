import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../auth/sign_out.dart';
import '../bloc/incident_feed_bloc.dart';
import '../widgets/branch_selector_sheet.dart';
import '../widgets/incident_card.dart';

class IncidentFeedScreen extends StatefulWidget {
  final int businessId;

  const IncidentFeedScreen({super.key, required this.businessId});

  @override
  State<IncidentFeedScreen> createState() => _IncidentFeedScreenState();
}

class _IncidentFeedScreenState extends State<IncidentFeedScreen> {
  String _selectedStatus = 'OPEN';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  int _currentBusinessId = 0;
  int? _selectedBranchId;
  List<BranchSummary> _branches = [];

  @override
  void initState() {
    super.initState();
    _currentBusinessId = widget.businessId;
    _selectedBranchId = context.read<StorageService>().getBranchId();
    _scrollController.addListener(_onScroll);
    _initFeed();
  }

  @override
  void didUpdateWidget(covariant IncidentFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching business on the profile screen navigates back here with a
    // new id; reload for it.
    if (oldWidget.businessId != widget.businessId && widget.businessId > 0) {
      _currentBusinessId = widget.businessId;
      _selectedBranchId = null;
      _branches = [];
      _initFeed();
    }
  }

  Future<void> _initFeed() async {
    final storage = context.read<StorageService>();
    final authRepo = context.read<AuthRepository>();
    final feedBloc = context.read<IncidentFeedBloc>();

    List<BusinessSummary> businesses = [];
    try {
      businesses = await authRepo.getUserBusinesses();
    } catch (_) {
      // Offline: fall back to the stored business and the cached feed.
    }

    if (businesses.isNotEmpty) {
      final validIds = businesses.map((b) => b.id).toSet();
      if (!validIds.contains(_currentBusinessId)) {
        _currentBusinessId = businesses.first.id;
        _selectedBranchId = null;
        await authRepo.switchBusiness(_currentBusinessId);
      }
    } else {
      final storedId = storage.getBusinessId();
      if (storedId != null && storedId > 0 && _currentBusinessId <= 0) {
        _currentBusinessId = storedId;
      }
    }

    feedBloc.add(
      FetchIncidentsEvent(
        businessId: _currentBusinessId,
        branchId: _selectedBranchId,
        status: _selectedStatus,
      ),
    );

    _loadBranches();
  }

  Future<void> _loadBranches() async {
    if (_currentBusinessId <= 0) return;
    try {
      final branches = await context.read<AuthRepository>().getBranches(_currentBusinessId);
      if (!mounted) return;
      setState(() => _branches = branches);
      if (_selectedBranchId != null && !branches.any((b) => b.id == _selectedBranchId)) {
        _onBranchSelected(null);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<IncidentFeedBloc>().add(const LoadMoreIncidentsEvent());
    }
  }

  void _onTabSelected(String status) {
    if (_selectedStatus != status) {
      HapticFeedback.lightImpact();
      setState(() => _selectedStatus = status);
      context.read<IncidentFeedBloc>().add(FilterChangedEvent(status));
    }
  }

  Future<void> _openBranchSelector() async {
    HapticFeedback.lightImpact();
    final result = await showBranchSelector(
      context,
      branches: _branches,
      selectedBranchId: _selectedBranchId,
    );
    if (result == null) return;
    _onBranchSelected(result == -1 ? null : result);
  }

  void _onBranchSelected(int? branchId) {
    if (branchId == _selectedBranchId) return;
    setState(() => _selectedBranchId = branchId);
    context.read<StorageService>().saveBranchId(branchId);
    context.read<IncidentFeedBloc>().add(BranchChangedEvent(branchId));
  }

  String get _branchLabel {
    if (_selectedBranchId == null) return 'common.all_branches'.tr();
    final match = _branches.where((b) => b.id == _selectedBranchId);
    return match.isNotEmpty && match.first.name.isNotEmpty
        ? match.first.name
        : 'common.branch'.tr();
  }

  List<IncidentListResponse> _filterBySearch(List<IncidentListResponse> items) {
    if (_searchQuery.isEmpty) return items;
    final query = _searchQuery.toLowerCase();
    return items.where((i) {
      final codeMatch = i.code.toLowerCase().contains(query);
      final locationMatch = i.location?.toLowerCase().contains(query) ?? false;
      final metricMatch = i.metrics.any((m) => m.toLowerCase().contains(query));
      return codeMatch || locationMatch || metricMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.spaceMD,
        title: Semantics(
          header: true,
          label: 'auth.title'.tr(),
          child: AppLogo(
            height: 24,
            showBadge: true,
            badgeText: 'common.badge'.tr(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'analytics.title'.tr(),
            onPressed: _currentBusinessId > 0
                ? () {
                    HapticFeedback.lightImpact();
                    context.push('/analytics?businessId=$_currentBusinessId');
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'common.refresh'.tr(),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<IncidentFeedBloc>().add(const RefreshIncidentsEvent());
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'common.more'.tr(),
            onSelected: (val) async {
              if (val == 'profile') {
                HapticFeedback.lightImpact();
                context.push('/profile');
              } else if (val == 'logout') {
                HapticFeedback.mediumImpact();
                await signOut(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text('profile.title'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18),
                    const SizedBox(width: 10),
                    Text('auth.logout'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<IncidentFeedBloc, IncidentFeedState>(
        listenWhen: (prev, curr) =>
            curr is IncidentFeedLoaded &&
            curr.notice != null &&
            (prev is! IncidentFeedLoaded || prev.notice != curr.notice),
        listener: (context, state) {
          final notice = (state as IncidentFeedLoaded).notice!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: notice.isError ? context.palette.severityCritical : null,
                content: Text(notice.message),
              ),
            );
        },
        child: Column(
          children: [
            // Search & Filter header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: 'incidents.search_hint'.tr(),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    tooltip: 'common.clear'.tr(),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Branch filter + status tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_branches.length > 1) ...[
                          _buildBranchChip(),
                          const SizedBox(width: 8),
                        ],
                        _buildFilterChip('CRITICAL', 'incidents.tab_critical'.tr(), Icons.crisis_alert_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip('OPEN', 'incidents.tab_open'.tr(), Icons.error_outline),
                        const SizedBox(width: 8),
                        _buildFilterChip('ACKNOWLEDGED', 'incidents.tab_acknowledged'.tr(), Icons.pending_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip('RESOLVED', 'incidents.tab_resolved'.tr(), Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        _buildFilterChip('ALL', 'incidents.tab_all'.tr(), Icons.list_alt_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Incident List
            Expanded(
              child: BlocBuilder<IncidentFeedBloc, IncidentFeedState>(
                builder: (context, state) {
                  if (state is IncidentFeedLoading || state is IncidentFeedInitial) {
                    return _buildSkeletonLoader();
                  } else if (state is IncidentFeedLoaded) {
                    return _buildList(context, state);
                  } else if (state is IncidentFeedError) {
                    return _buildError(context, state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, IncidentFeedLoaded state) {
    final filtered = _filterBySearch(state.incidents);
    final showFooter = state.hasMore || state.isLoadingMore;

    return Column(
      children: [
        if (state.fromCache) const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            color: context.palette.primary,
            onRefresh: () async {
              final done = Completer<void>();
              context.read<IncidentFeedBloc>().add(RefreshIncidentsEvent(completer: done));
              await done.future;
            },
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _buildEmptyState(),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    itemCount: filtered.length + (showFooter ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filtered.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceMD),
                          child: Center(
                            child: state.isLoadingMore
                                ? CircularProgressIndicator(color: context.palette.primary)
                                : TextButton(
                                    onPressed: () => context
                                        .read<IncidentFeedBloc>()
                                        .add(const LoadMoreIncidentsEvent()),
                                    child: Text('incidents.load_more'.tr()),
                                  ),
                          ),
                        );
                      }
                      final incident = filtered[index];
                      return IncidentCard(
                        incident: incident,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/incidents/${incident.id}');
                        },
                        onQuickAcknowledge: incident.status == 'OPEN' && !state.fromCache
                            ? () {
                                HapticFeedback.mediumImpact();
                                context.read<IncidentFeedBloc>().add(QuickAcknowledgeEvent(incident.id));
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, IncidentFeedError state) {
    final isAccessDenied = state.isAccessDenied;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAccessDenied ? Icons.store_outlined : Icons.wifi_off_outlined,
              size: 48,
              color: isAccessDenied ? context.palette.primary : context.palette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isAccessDenied ? 'incidents.permission_title'.tr() : 'incidents.load_error_title'.tr(),
              style: AppTypography.h3(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTypography.bodySmall(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                  ),
                  onPressed: () => _initFeed(),
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text('common.retry'.tr()),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/profile'),
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text('profile.title'.tr()),
                ),
                if (isAccessDenied)
                  TextButton.icon(
                    onPressed: () => signOut(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text('auth.sign_in_again'.tr()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchChip() {
    final palette = context.palette;
    final isFiltered = _selectedBranchId != null;
    return Semantics(
      button: true,
      label: 'branches.filter_semantics'.tr(args: [_branchLabel]),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: _openBranchSelector,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isFiltered ? palette.primary.withValues(alpha: 0.15) : palette.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: isFiltered ? palette.primary : palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined, size: 16, color: isFiltered ? palette.primary : palette.textSecondary),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  _branchLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 18, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label, IconData icon) {
    final isSelected = _selectedStatus == status;
    final isCritical = status == 'CRITICAL';

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final Color textColor;

    if (isCritical) {
      if (isSelected) {
        bgColor = context.palette.severityCritical;
        borderColor = context.palette.severityCritical;
        iconColor = context.palette.onSeverity;
        textColor = context.palette.onSeverity;
      } else {
        bgColor = context.palette.severityCritical.withValues(alpha: 0.12);
        borderColor = context.palette.severityCritical.withValues(alpha: 0.35);
        iconColor = context.palette.severityCritical;
        textColor = context.palette.severityCritical;
      }
    } else {
      if (isSelected) {
        bgColor = context.palette.primary;
        borderColor = context.palette.primary;
        iconColor = context.palette.onPrimary;
        textColor = context.palette.onPrimary;
      } else {
        bgColor = context.palette.surfaceContainer;
        borderColor = context.palette.border;
        iconColor = context.palette.textSecondary;
        textColor = context.palette.textPrimary;
      }
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: () => _onTabSelected(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: borderColor,
              width: isSelected || isCritical ? 1.5 : 1,
            ),
            boxShadow: isCritical && isSelected
                ? [
                    BoxShadow(
                      color: context.palette.severityCritical.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
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
                children: const [
                  Bone.text(words: 2),
                  Bone.square(size: 24),
                ],
              ),
              const SizedBox(height: 12),
              const Bone.text(words: 3),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Bone.button(width: 80, height: 24),
                  SizedBox(width: 8),
                  Bone.button(width: 90, height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final statusLabel = 'incidents.status_word_${_selectedStatus.toLowerCase()}'.tr();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.palette.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_outlined,
              size: 48,
              color: context.palette.brandText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'incidents.no_matches_title'.tr() : 'incidents.empty_title'.tr(),
            style: AppTypography.h2(context),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'incidents.no_matches_body'.tr()
                  : statusLabel.isEmpty
                      ? 'incidents.empty_body_all'.tr()
                      : 'incidents.empty_body'.tr(args: [statusLabel]),
              style: AppTypography.bodySmall(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
