import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// An industry-standard secure password edit box supporting:
/// - Obscure/Reveal toggle with tactile haptic feedback
/// - AutofillHints (AutofillHints.password)
/// - Custom validator & error states
/// - Focused & idle highlight transitions
/// - Soft keyboard submit actions
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final FocusNode? focusNode;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _toggleObscure() {
    HapticFeedback.selectionClick();
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      obscureText: _obscureText,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: _obscureText
          ? TextInputType.visiblePassword
          : TextInputType.text,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: AppTypography.body(context).copyWith(
        color: palette.textPrimary,
        letterSpacing: _obscureText ? 1.5 : 0.2,
      ),
      cursorColor: palette.primary,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: AppTypography.body(context).copyWith(
          color: palette.textHint,
          letterSpacing: 0,
        ),
        labelStyle: TextStyle(
          color: _isFocused ? palette.primary : palette.textSecondary,
        ),
        filled: true,
        fillColor: palette.surfaceContainer,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: _isFocused ? palette.primary : palette.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: _isFocused ? palette.primary : palette.textSecondary,
          ),
          tooltip: _obscureText ? 'auth.show_password'.tr() : 'auth.hide_password'.tr(),
          onPressed: widget.enabled ? _toggleObscure : null,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceMD,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.severityCritical),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.severityCritical, width: 2),
        ),
      ),
    );
  }
}
