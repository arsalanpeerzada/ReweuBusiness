import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/biometrics/biometric_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/security/app_lock.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../widgets/password_text_field.dart';

class LoginScreen extends StatefulWidget {
  final StorageService storageService;
  final BiometricService biometricService;
  final AuthRepository authRepository;

  const LoginScreen({
    super.key,
    required this.storageService,
    required this.biometricService,
    required this.authRepository,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Offers biometric unlock once after the first password sign-in. It is
  /// only switched on if the user agrees and passes a biometric check.
  Future<void> _offerBiometrics() async {
    if (widget.storageService.wasBiometricsPrompted()) return;
    final available = await widget.biometricService.isBiometricsAvailable();
    if (!available || !mounted) return;

    final palette = context.palette;
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceElevated,
        title: Text('biometrics.offer_title'.tr(), style: AppTypography.h3(ctx)),
        content: Text('biometrics.offer_body'.tr(), style: AppTypography.body(ctx)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('biometrics.offer_decline'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('biometrics.offer_accept'.tr()),
          ),
        ],
      ),
    );

    if (accept == true) {
      final ok = await widget.biometricService.authenticate(
        reason: 'biometrics.reason_enable'.tr(),
        biometricOnly: true,
      );
      await widget.storageService.setBiometricsEnabled(ok);
    } else {
      await widget.storageService.markBiometricsPrompted();
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('auth.error_missing'.tr());
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('auth.error_email'.tr());
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    TextInput.finishAutofillContext();

    try {
      final user = await widget.authRepository.login(
        email: email,
        password: password,
      );
      if (user.token.isEmpty) {
        await widget.authRepository.logout();
        throw ApiException(ApiErrorKind.server, 'errors.server'.tr());
      }

      if (!mounted) return;
      context.read<AppLockController>().reset();
      await _offerBiometrics();

      if (mounted) {
        setState(() => _isLoading = false);
        final businessId = widget.storageService.getBusinessId();
        if (businessId != null && businessId > 0) {
          context.go('/incidents?businessId=$businessId');
        } else {
          context.go('/incidents');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e is ApiException ? e.message : 'errors.unknown'.tr());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: context.palette.severityCritical,
          content: Text(
            message,
            style: TextStyle(color: context.palette.onSeverity),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spaceLG),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  Center(
                    child: AppLogo.mark(
                      size: 76,
                      padding: 12,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'auth.title'.tr(),
                        style: AppTypography.h1(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'auth.subtitle'.tr(),
                      style: AppTypography.bodySmall(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 36),

                  AutofillGroup(
                    child: Column(
                      children: [
                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          enableSuggestions: false,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: 'auth.email'.tr(),
                            hintText: 'auth.email_hint'.tr(),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        PasswordTextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          labelText: 'auth.password'.tr(),
                          hintText: 'auth.password_hint'.tr(),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      foregroundColor: context.palette.onPrimary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'common.loading'.tr(),
                            ),
                          )
                        : Text(
                            'auth.login'.tr(),
                            style: AppTypography.button(context).copyWith(
                              color: context.palette.onPrimary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'auth.help'.tr(),
                    style: AppTypography.caption(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
