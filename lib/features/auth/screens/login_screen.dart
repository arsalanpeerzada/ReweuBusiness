import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/biometrics/biometric_service.dart';
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
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final available = await widget.biometricService.isBiometricsAvailable();
    final enabled = widget.storageService.isBiometricsEnabled();
    final hasToken = await widget.storageService.getToken() != null;
    if (mounted) {
      setState(() {
        _canBiometric = available && (enabled || hasToken);
      });
    }
  }

  Future<void> _handleBiometricUnlock() async {
    final token = await widget.storageService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in with password first to link biometrics.'),
          ),
        );
      }
      return;
    }

    final authenticated = await widget.biometricService.authenticate(
      reason: 'Scan your face to unlock Reweu Companion',
      title: 'Face Scan Authentication',
    );
    if (authenticated && mounted) {
      HapticFeedback.mediumImpact();
      final businessId = widget.storageService.getBusinessId();
      if (businessId != null && businessId > 0) {
        context.go('/incidents?businessId=$businessId');
      } else {
        context.go('/incidents');
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await widget.authRepository.login(
        email: email,
        password: password,
      );

      final canBiometrics = await widget.biometricService.isBiometricsAvailable();
      if (canBiometrics) {
        await widget.storageService.setBiometricsEnabled(true);
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.palette.severityCritical,
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spaceLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      border: Border.all(
                        color: context.palette.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const AppLogo(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'Reweu Companion',
                    style: AppTypography.h1(context),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Incident Triage & Operational Companion',
                    style: AppTypography.bodySmall(context),
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
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Business Email',
                          hintText: 'Enter your account email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      PasswordTextField(
                        controller: _passwordController,
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Sign In',
                          style: AppTypography.button(context).copyWith(
                            color: context.palette.onPrimary,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Biometrics Unlock
                if (_canBiometric) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.palette.border),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                    ),
                    onPressed: _handleBiometricUnlock,
                    icon: Icon(
                      Icons.face_retouching_natural_rounded,
                      color: context.palette.primary,
                    ),
                    label: Text(
                      'Unlock with Face Scan',
                      style: AppTypography.button(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
