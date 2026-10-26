import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/incident_feed_bloc.dart';
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
  String _searchQuery = '';
  int _currentBusinessId = 0;

  @override
  void initState() {
    super.initState();
    _currentBusinessId = widget.businessId;
    _initFeed();
  }

  Future<void> _initFeed() async {
    final storage = context.read<StorageService>();
    final authRepo = context.read<AuthRepository>();

    List<BusinessSummary> businesses = [];
    try {
      businesses = await authRepo.getUserBusinesses();
    } catch (_) {}

    if (businesses.isNotEmpty) {
      final validIds = businesses.map((b) => b.id).toSet();
      if (!validIds.contains(_currentBusinessId)) {
        _currentBusinessId = businesses.first.id;
        await storage.saveUserContext(
          userId: storage.getUserId() ?? 0,
          businessId: _currentBusinessId,
        );
      }
    } else {
      final storedId = storage.getBusinessId();
      if (storedId != null && storedId > 0 && _currentBusinessId <= 0) {
        _currentBusinessId = storedId;
      }
    }

    if (mounted) {
      context.read<IncidentFeedBloc>().add(
            FetchIncidentsEvent(
              businessId: _currentBusinessId,
              status: _selectedStatus,
            ),
          );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabSelected(String status) {
    if (_selectedStatus != status) {
      HapticFeedback.lightImpact();
      setState(() => _selectedStatus = status);
      context.read<IncidentFeedBloc>().add(FilterChangedEvent(status));
    }
  }

  List<IncidentListResponse> _filterBySearch(List<IncidentListResponse> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where((i) {
      final query = _searchQuery.toLowerCase();
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppLogo(
              height: 24,
              showBadge: true,
              badgeText: 'COMPANION',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<IncidentFeedBloc>().add(FilterChangedEvent(_selectedStatus));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile & Settings',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/profile');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'profile') {
                HapticFeedback.lightImpact();
                context.push('/profile');
              } else if (val == 'logout') {
                HapticFeedback.mediumImpact();
                await context.read<AuthRepository>().logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Profile & Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 10),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
            child: Column(
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search by incident code, metric, branch...',
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Status & Urgency Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('CRITICAL', 'Critical', Icons.crisis_alert_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('OPEN', 'New & Urgent', Icons.error_outline),
                      const SizedBox(width: 8),
                      _buildFilterChip('ACKNOWLEDGED', 'In Progress', Icons.pending_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('RESOLVED', 'Resolved', Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      _buildFilterChip('ALL', 'All', Icons.list_alt_rounded),
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
                if (state is IncidentFeedLoading) {
                  return _buildSkeletonLoader();
                } else if (state is IncidentFeedLoaded) {
                  final filtered = _filterBySearch(state.incidents);
                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    color: context.palette.primary,
                    onRefresh: () async {
                      context.read<IncidentFeedBloc>().add(FilterChangedEvent(_selectedStatus));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final incident = filtered[index];
                        return IncidentCard(
                          incident: incident,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/incidents/${incident.id}');
                          },
                          onQuickAcknowledge: incident.status == 'OPEN'
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  context.read<IncidentFeedBloc>().add(QuickAcknowledgeEvent(incident.id));
                                }
                              : null,
                        );
                      },
                    ),
                  );
                } else if (state is IncidentFeedError) {
                  final isAccessDenied = state.message.contains('403') ||
                      state.message.toLowerCase().contains('access denied') ||
                      state.message.toLowerCase().contains('not authorized');
                  return Center(
                    child: Padding(
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
                            isAccessDenied
                                ? 'Business Permission Required'
                                : 'Unable to Load Incidents',
                            style: AppTypography.h3(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message.replaceAll('Exception: ', ''),
                            style: AppTypography.bodySmall(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _initFeed(),
                                icon: const Icon(Icons.sync_rounded, size: 18),
                                label: const Text('Re-sync Businesses'),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.palette.primary,
                                  foregroundColor: context.palette.onPrimary,
                                ),
                                onPressed: () => context.push('/profile'),
                                icon: const Icon(Icons.person_outline_rounded, size: 18),
                                label: const Text('Profile & Settings'),
                              ),
                              if (isAccessDenied)
                                TextButton.icon(
                                  onPressed: () async {
                                    await context.read<AuthRepository>().logout();
                                    if (context.mounted) {
                                      context.go('/login');
                                    }
                                  },
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: const Text('Sign In Again'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
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
        iconColor = Colors.white;
        textColor = Colors.white;
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

    return InkWell(
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
            'All Clear!',
            style: AppTypography.h2(context),
          ),
          const SizedBox(height: 8),
          Text(
            'No ${_selectedStatus.toLowerCase()} incidents requiring attention.',
            style: AppTypography.bodySmall(context),
          ),
        ],
      ),
    );
  }
}
