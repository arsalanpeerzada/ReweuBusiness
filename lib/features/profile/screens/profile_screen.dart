import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/biometrics/biometric_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../auth/sign_out.dart';

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
  String _version = '';

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
    String version = '';

    try {
      profile = await widget.authRepository.getUserProfile();
    } catch (_) {
      // Shown from the stored session details instead.
    }

    try {
      businesses = await widget.authRepository.getUserBusinesses();
    } catch (_) {}

    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {}

    if (mounted) {
      setState(() {
        _biometricsAvailable = bioAvailable;
        _biometricsEnabled = bioEnabled;
        _userProfile = profile;
        _businesses = businesses;
        _activeBusinessId = currentBusinessId;
        _version = version;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final authenticated = await widget.biometricService.authenticate(
        reason: 'biometrics.reason_enable'.tr(),
        biometricOnly: true,
      );
      if (authenticated) {
        await widget.storageService.setBiometricsEnabled(true);
        if (!mounted) return;
        setState(() => _biometricsEnabled = true);
        messenger.showSnackBar(SnackBar(content: Text('profile.biometrics_enabled'.tr())));
      }
    } else {
      await widget.storageService.setBiometricsEnabled(false);
      if (!mounted) return;
      setState(() => _biometricsEnabled = false);
      messenger.showSnackBar(SnackBar(content: Text('profile.biometrics_disabled'.tr())));
    }
  }

  Future<void> _handleSwitchBusiness(BusinessSummary business) async {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    await widget.authRepository.switchBusiness(business.id);
    if (!mounted) return;
    setState(() => _activeBusinessId = business.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('profile.switched_to'.tr(args: [business.name]))),
    );
    context.go('/incidents?businessId=${business.id}');
  }

  Future<void> _changeLanguage(Locale locale) async {
    HapticFeedback.selectionClick();
    await context.setLocale(locale);
    if (mounted) setState(() {});
  }

  void _showBusinessSelector() {
    if (_businesses.isEmpty) return;
    final palette = context.palette;

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
      ),
      builder: (ctx) {
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
                  Text('profile.select_business'.tr(), style: AppTypography.h3(context)),
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
                          selected: isSelected,
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
                            b.categoryName ?? 'profile.business_fallback'.tr(),
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
        title: Text('auth.logout'.tr(), style: AppTypography.h3(context)),
        content: Text(
          'profile.sign_out_confirm'.tr(),
          style: AppTypography.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.severityCritical,
              foregroundColor: palette.onSeverity,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('auth.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      await signOut(context);
    }
  }

  String _roleLabel() {
    final roles = widget.storageService.getRoles();
    for (final role in const ['SUPER_ADMIN', 'BUSINESS_OWNER', 'ADMIN', 'BRANCH_ADMIN', 'BRANCH_MANAGER']) {
      if (roles.contains(role)) return 'roles.${role.toLowerCase()}'.tr();
    }
    return 'roles.member'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final profileName = '${_userProfile['firstName'] ?? ''} ${_userProfile['lastName'] ?? ''}'.trim();
    final displayName = profileName.isNotEmpty
        ? profileName
        : (widget.storageService.getUserName()?.isNotEmpty == true
            ? widget.storageService.getUserName()!
            : 'profile.name_fallback'.tr());

    final email = _userProfile['email']?.toString() ?? widget.storageService.getUserEmail() ?? '';

    final activeBusiness = _businesses.cast<BusinessSummary?>().firstWhere(
          (b) => b?.id == _activeBusinessId,
          orElse: () => null,
        );

    final isUrdu = context.locale.languageCode == 'ur';

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text('profile.title'.tr(), style: AppTypography.h2(context)),
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: 'common.back'.tr(),
          onPressed: () => context.canPop() ? context.pop() : context.go('/incidents'),
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
                          ExcludeSemantics(
                            child: Container(
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
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: AppTypography.h2(context),
                            textAlign: TextAlign.center,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: AppTypography.bodySmall(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                                Icon(Icons.verified, size: 14, color: palette.brandText),
                                const SizedBox(width: 6),
                                Text(
                                  _roleLabel(),
                                  style: AppTypography.caption(context).copyWith(
                                    color: palette.brandText,
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
                    Semantics(header: true, child: Text('profile.active_business'.tr(), style: AppTypography.h3(context))),
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
                                      activeBusiness?.name ?? 'profile.no_business'.tr(),
                                      style: AppTypography.body(context).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (activeBusiness?.locationName?.isNotEmpty ?? false) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        activeBusiness!.locationName!,
                                        style: AppTypography.caption(context),
                                      ),
                                    ],
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
                                  child: Text('profile.switch'.tr(), style: TextStyle(color: palette.brandText)),
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
                                  'profile.rating'.tr(args: [activeBusiness.overAllRating.toStringAsFixed(1)]),
                                  style: AppTypography.caption(context),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security & Preferences Section
                    Semantics(header: true, child: Text('profile.security'.tr(), style: AppTypography.h3(context))),
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
                                Icons.fingerprint,
                                color: palette.primary,
                              ),
                              title: Text(
                                'profile.biometrics_title'.tr(),
                                style: AppTypography.body(context),
                              ),
                              subtitle: Text(
                                'profile.biometrics_subtitle'.tr(),
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
                                Icons.fingerprint,
                                color: palette.textSecondary,
                              ),
                              title: Text(
                                'profile.biometrics_title'.tr(),
                                style: AppTypography.body(context),
                              ),
                              subtitle: Text(
                                'profile.biometrics_unavailable'.tr(),
                                style: AppTypography.caption(context),
                              ),
                            ),
                          Divider(height: 1, color: palette.borderSubtle),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spaceMD,
                              vertical: 4,
                            ),
                            leading: Icon(Icons.translate, color: palette.primary),
                            title: Text('profile.language'.tr(), style: AppTypography.body(context)),
                            trailing: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 'en', label: Text('English')),
                                ButtonSegment(value: 'ur', label: Text('اردو')),
                              ],
                              selected: {isUrdu ? 'ur' : 'en'},
                              onSelectionChanged: (val) => _changeLanguage(
                                val.first == 'ur' ? const Locale('ur', 'PK') : const Locale('en', 'US'),
                              ),
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
                        'auth.logout'.tr(),
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
                        child: const AppLogo(height: 18, alignment: Alignment.center),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _version.isNotEmpty
                            ? 'profile.version'.tr(args: [_version])
                            : 'auth.title'.tr(),
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
