import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/biometrics/biometric_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ProfileScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthRepository authRepository;
  final BiometricService biometricService;

  const ProfileScreen({
    super.key,
    required this.storageService,
    required this.authRepository,
    required this.biometricService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  Map<String, dynamic> _userProfile = {};
  List<BusinessSummary> _businesses = [];
  int? _activeBusinessId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final bioAvailable = await widget.biometricService.isBiometricsAvailable();
    final bioEnabled = widget.storageService.isBiometricsEnabled();
    final currentBusinessId = widget.storageService.getBusinessId();

    Map<String, dynamic> profile = {};
    List<BusinessSummary> businesses = [];

    try {
      profile = await widget.authRepository.getUserProfile();
    } catch (_) {}

    try {
      businesses = await widget.authRepository.getUserBusinesses();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _biometricsAvailable = bioAvailable;
        _biometricsEnabled = bioEnabled;
        _userProfile = profile;
        _businesses = businesses;
        _activeBusinessId = currentBusinessId;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    HapticFeedback.selectionClick();
    if (value) {
      final authenticated = await widget.biometricService.authenticate(
        reason: 'Scan your face to enable biometric unlock for Reweu Companion',
      );
      if (authenticated) {
        await widget.storageService.setBiometricsEnabled(true);
        setState(() => _biometricsEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face scan authentication enabled.')),
          );
        }
      }
    } else {
      await widget.storageService.setBiometricsEnabled(false);
      setState(() => _biometricsEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face scan authentication disabled.')),
        );
      }
    }
  }

  Future<void> _handleSwitchBusiness(BusinessSummary business) async {
    HapticFeedback.mediumImpact();
    await widget.authRepository.switchBusiness(business.id);
    setState(() => _activeBusinessId = business.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${business.name}')),
      );
    }
  }

  void _showBusinessSelector() {
    if (_businesses.isEmpty) return;
    final palette = context.palette;

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                Text('Select Active Business', style: AppTypography.h3(context)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _businesses.length,
                    separatorBuilder: (_, _) => Divider(color: palette.borderSubtle),
                    itemBuilder: (_, index) {
                      final b = _businesses[index];
                      final isSelected = b.id == _activeBusinessId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? palette.primary : palette.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                          ),
                          child: Center(
                            child: Text(
                              b.name.isNotEmpty ? b.name[0].toUpperCase() : 'B',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? palette.onPrimary : palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          b.name,
                          style: AppTypography.body(context).copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${b.categoryName ?? 'Business'} • ID: ${b.id}',
                          style: AppTypography.caption(context),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: palette.primary, size: 20)
                            : null,
                        onTap: () => _handleSwitchBusiness(b),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        ),
        title: Text('Sign Out', style: AppTypography.h3(context)),
        content: Text(
          'Are you sure you want to sign out of Reweu Business?',
          style: AppTypography.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: palette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.severityCritical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      await widget.authRepository.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final displayName = _userProfile['firstName'] != null
        ? '${_userProfile['firstName']} ${_userProfile['lastName'] ?? ''}'.trim()
        : widget.storageService.getUserName() ?? 'Business Partner';

    final email = _userProfile['email']?.toString() ??
        widget.storageService.getUserEmail() ??
        'account@reweu.app';

    final activeBusiness = _businesses.cast<BusinessSummary?>().firstWhere(
          (b) => b?.id == _activeBusinessId,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text('Profile & Settings', style: AppTypography.h2(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: palette.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: palette.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Identity Header Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceLG),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: palette.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.primary, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: palette.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: AppTypography.h2(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: AppTypography.bodySmall(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: palette.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                              border: Border.all(color: palette.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 14, color: palette.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Partner Admin',
                                  style: AppTypography.caption(context).copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Active Business Section
                    Text('Active Business', style: AppTypography.h3(context)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: palette.surfaceContainer,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                                ),
                                child: Icon(Icons.storefront_rounded, color: palette.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeBusiness?.name ?? 'Reweu Partner Franchise',
                                      style: AppTypography.body(context).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activeBusiness?.locationName ?? 'Operational Branch',
                                      style: AppTypography.caption(context),
                                    ),
                                  ],
                                ),
                              ),
                              if (_businesses.length > 1)
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: palette.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onPressed: _showBusinessSelector,
                                  child: Text('Switch', style: TextStyle(color: palette.primary)),
                                ),
                            ],
                          ),
                          if (activeBusiness != null && activeBusiness.overAllRating > 0) ...[
                            const SizedBox(height: 12),
                            Divider(color: palette.borderSubtle),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 18, color: palette.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Rating: ${activeBusiness.overAllRating.toStringAsFixed(1)} / 5.0',
                                  style: AppTypography.caption(context),
                                ),
                                const Spacer(),
                                Text(
                                  'ID: #${activeBusiness.id}',
                                  style: AppTypography.caption(context).copyWith(
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security & Preferences Section
                    Text('Security & Preferences', style: AppTypography.h3(context)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        children: [
                          if (_biometricsAvailable)
                            SwitchListTile(
                              activeThumbColor: palette.primary,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.spaceMD,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.face_retouching_natural_rounded,
                                color: palette.primary,
                              ),
                              title: Text(
                                'Face Scan & Biometrics',
                                style: AppTypography.body(context),
                              ),
                              subtitle: Text(
                                'Unlock Reweu Companion with Face Scan',
                                style: AppTypography.caption(context),
                              ),
                              value: _biometricsEnabled,
                              onChanged: _toggleBiometrics,
                            )
                          else
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.spaceMD,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.face_retouching_natural_rounded,
                                color: palette.textSecondary,
                              ),
                              title: Text(
                                'Face Scan & Biometrics',
                                style: AppTypography.body(context),
                              ),
                              subtitle: Text(
                                'Biometrics not enrolled on this device',
                                style: AppTypography.caption(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Out Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: palette.severityCritical),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        ),
                      ),
                      onPressed: _handleSignOut,
                      icon: Icon(Icons.logout, color: palette.severityCritical),
                      label: Text(
                        'Sign Out',
                        style: AppTypography.button(context).copyWith(
                          color: palette.severityCritical,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Version & branding footer
                    Center(
                      child: Opacity(
                        opacity: 0.7,
                        child: const AppLogo(height: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Reweu Business Companion • v1.0.0+1',
                        style: AppTypography.caption(context).copyWith(
                          color: palette.textHint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
