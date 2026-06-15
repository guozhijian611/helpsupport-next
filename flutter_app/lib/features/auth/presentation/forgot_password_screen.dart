import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/i18n/language_switcher.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import 'auth_page_frame.dart';

enum _ResetMethod { email, phone }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _cooldownTimer;
  int _codeCooldown = 0;
  bool _isSendingCode = false;
  bool _isSubmitting = false;
  _ResetMethod _method = _ResetMethod.email;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formDisabled = _isSendingCode || _isSubmitting;

    return AuthPageFrame(
      title: context.l10n.forgotPasswordTitle,
      subtitle: context.l10n.forgotPasswordSubtitle,
      leading: IconButton.filledTonal(
        onPressed: formDisabled ? null : () => context.go('/login'),
        icon: const Icon(Icons.arrow_back),
      ),
      trailing: const LanguageSwitcher(onDark: true),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<_ResetMethod>(
              segments: [
                ButtonSegment(
                  value: _ResetMethod.email,
                  label: Text(context.l10n.email),
                  icon: const Icon(Icons.mail_outline_rounded),
                ),
                ButtonSegment(
                  value: _ResetMethod.phone,
                  label: Text(context.l10n.phoneNumber),
                  icon: const Icon(Icons.phone_iphone_rounded),
                ),
              ],
              selected: {_method},
              onSelectionChanged: formDisabled
                  ? null
                  : (values) {
                      if (values.isNotEmpty) {
                        _changeMethod(values.first);
                      }
                    },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _identifierController,
              enabled: !formDisabled,
              keyboardType: _method == _ResetMethod.email
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              textInputAction: TextInputAction.next,
              label: _method == _ResetMethod.email
                  ? context.l10n.email
                  : context.l10n.phoneNumber,
              icon: _method == _ResetMethod.email
                  ? Icons.mail_outline_rounded
                  : Icons.phone_iphone_rounded,
              validator: _validateIdentifier,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _codeController,
              enabled: !formDisabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              label: context.l10n.verificationCode,
              icon: Icons.verified_outlined,
              validator: _required,
              suffix: _VerificationCodeButton(
                text: _codeButtonText(context),
                enabled: !formDisabled && _codeCooldown <= 0,
                isLoading: _isSendingCode,
                onPressed: _sendVerificationCode,
              ),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              enabled: !formDisabled,
              obscureText: true,
              textInputAction: TextInputAction.next,
              label: context.l10n.newPassword,
              icon: Icons.lock_outline,
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmPasswordController,
              enabled: !formDisabled,
              obscureText: true,
              textInputAction: TextInputAction.done,
              label: context.l10n.confirmPassword,
              icon: Icons.lock_reset_outlined,
              validator: _validateConfirmPassword,
              onFieldSubmitted: (_) => _submitReset(),
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              onPressed: _submitReset,
              isLoading: _isSubmitting,
              icon: Icons.restart_alt_rounded,
              label: _isSubmitting
                  ? context.l10n.resettingPassword
                  : context.l10n.resetPasswordAction,
            ),
            const SizedBox(height: 12),
            AuthLinkButton(
              text: context.l10n.forgotPasswordHasAccount,
              actionText: context.l10n.loginAction,
              onPressed: () => context.go('/login'),
              onDark: false,
            ),
          ],
        ),
      ),
    );
  }

  void _changeMethod(_ResetMethod method) {
    if (_method == method) {
      return;
    }

    _cooldownTimer?.cancel();
    setState(() {
      _method = method;
      _identifierController.clear();
      _codeController.clear();
      _codeCooldown = 0;
    });
  }

  String _codeButtonText(BuildContext context) {
    if (_codeCooldown > 0) {
      return '${context.l10n.resendVerificationCodeIn} $_codeCooldown s';
    }
    return context.l10n.sendVerificationCode;
  }

  Future<void> _sendVerificationCode() async {
    final error = _validateIdentifier(_identifierController.text);
    if (error != null) {
      _showSnackBar(error);
      return;
    }

    setState(() => _isSendingCode = true);
    try {
      final controller = ref.read(authControllerProvider.notifier);
      final delivery = _method == _ResetMethod.email
          ? await controller.sendForgotEmailCode(
              email: _identifierController.text.trim(),
            )
          : await controller.sendForgotPhoneCode(
              mobile: _identifierController.text.trim(),
            );
      if (!mounted) {
        return;
      }
      _startCodeCooldown(delivery.resendAfter);
      _showSnackBar(
        '${context.l10n.verificationCodeSentTo} ${delivery.target}',
      );
    } on Object catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _submitReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .passwordReset(
            resetType: _method == _ResetMethod.email ? 'email' : 'phone',
            email: _method == _ResetMethod.email
                ? _identifierController.text.trim()
                : null,
            mobile: _method == _ResetMethod.phone
                ? _identifierController.text.trim()
                : null,
            emailCode: _method == _ResetMethod.email
                ? _codeController.text.trim()
                : null,
            mobileCode: _method == _ResetMethod.phone
                ? _codeController.text.trim()
                : null,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.passwordResetSuccess);
      context.go('/login');
    } on Object catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _startCodeCooldown(int seconds) {
    _cooldownTimer?.cancel();
    final initialSeconds = seconds > 0 ? seconds : 120;
    setState(() => _codeCooldown = initialSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_codeCooldown <= 1) {
        timer.cancel();
        setState(() => _codeCooldown = 0);
        return;
      }
      setState(() => _codeCooldown--);
    });
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.requiredField;
    }
    return null;
  }

  String? _validateIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return context.l10n.requiredField;
    }
    if (_method == _ResetMethod.email) {
      final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!pattern.hasMatch(text)) {
        return context.l10n.invalidEmail;
      }
      return null;
    }
    if (!RegExp(r'^1\d{10}$').hasMatch(text)) {
      return context.l10n.invalidPhone;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return context.l10n.requiredField;
    }
    if (text.length < 6) {
      return context.l10n.passwordLengthRule;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return context.l10n.requiredField;
    }
    if (text != _passwordController.text) {
      return context.l10n.passwordMismatch;
    }
    return null;
  }

  void _showError(Object? error) {
    _showSnackBar(_errorText(error));
  }

  void _showSnackBar(String text) {
    context.showCenteredNotice(text);
  }

  String _errorText(Object? error) {
    final text = error.toString();
    if (text.isEmpty) {
      return context.l10n.networkUnavailable;
    }
    return text
        .replaceFirst(RegExp(r'^.*message: '), '')
        .replaceFirst(RegExp(r', traceId: .*$'), '');
  }
}

class _VerificationCodeButton extends StatelessWidget {
  const _VerificationCodeButton({
    required this.text,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6B87E6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      ),
    );
  }
}
