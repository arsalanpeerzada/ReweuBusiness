import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/biometrics/biometric_service.dart';
import '../../../core/security/app_lock.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../sign_out.dart';

/// Shown instead of app content until the user passes biometrics (or the
/// device passcode).
class LockScreen extends StatefulWidget {
  /// Where to return after unlocking.
  final String? from;

  const LockScreen({super.key, this.from});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final ok = await context.read<BiometricService>().authenticate();
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      context.read<AppLockController>().unlock();
      final target = widget.from;
      context.go(target != null && target.startsWith('/') && !target.startsWith('/lock')
          ? target
          : '/incidents');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.palette.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceLG),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        child: Text('lock.title'.tr(), style: AppTypography.h2(context)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'lock.body'.tr(),
                      style: AppTypography.bodySmall(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.palette.primary,
                        foregroundColor: context.palette.onPrimary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _authenticating ? null : _unlock,
                      icon: const Icon(Icons.fingerprint),
                      label: Text('lock.unlock'.tr(), style: AppTypography.button(context)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _authenticating ? null : () => signOut(context),
                      child: Text('lock.use_password'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
