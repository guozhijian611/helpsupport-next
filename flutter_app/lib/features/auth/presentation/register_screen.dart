import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/i18n/language_switcher.dart';
import '../application/auth_controller.dart';
import 'auth_page_frame.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _cooldownTimer;
  int _emailCodeCooldown = 0;
  bool _isSendingCode = false;
  bool _agreementAccepted = false;
  String _memberRole = 'patient';

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        context.go('/home');
      }
      if (next.hasError) {
        _showError(next.error);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final formDisabled = isLoading || _isSendingCode;

    return AuthPageFrame(
      title: context.l10n.registerTitle,
      subtitle: context.l10n.registerSubtitle,
      leading: IconButton.filledTonal(
        onPressed: formDisabled ? null : () => context.go('/login'),
        icon: const Icon(Icons.arrow_back),
      ),
      trailing: const LanguageSwitcher(onDark: true),
      footer: AuthLinkButton(
        text: context.l10n.registerHasAccount,
        actionText: context.l10n.loginAction,
        onPressed: () => context.go('/login'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthTextField(
              controller: _usernameController,
              enabled: !formDisabled,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              label: context.l10n.username,
              icon: Icons.person_outline,
              validator: _validateUsername,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _emailController,
              enabled: !formDisabled,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              label: context.l10n.email,
              icon: Icons.alternate_email_rounded,
              validator: _validateEmail,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _canSendEmailCode(formDisabled)
                    ? _sendEmailCode
                    : null,
                icon: _isSendingCode
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_read_outlined),
                label: Text(_emailCodeButtonText(context)),
              ),
            ),
            const SizedBox(height: 4),
            AuthTextField(
              controller: _emailCodeController,
              enabled: !formDisabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              label: context.l10n.emailCode,
              icon: Icons.verified_outlined,
              validator: _required,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              enabled: !formDisabled,
              obscureText: true,
              textInputAction: TextInputAction.next,
              label: context.l10n.password,
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
              onFieldSubmitted: (_) => _submitRegister(),
            ),
            const SizedBox(height: 18),
            _RoleSelector(
              selected: _memberRole,
              enabled: !formDisabled,
              onChanged: (value) => setState(() => _memberRole = value),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _agreementAccepted,
              onChanged: formDisabled
                  ? null
                  : (value) {
                      setState(() => _agreementAccepted = value ?? false);
                    },
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                context.l10n.authAgreementText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            AuthPrimaryButton(
              onPressed: _submitRegister,
              icon: Icons.person_add_alt_1_rounded,
              isLoading: isLoading,
              label: isLoading
                  ? context.l10n.registering
                  : context.l10n.registerSubmit,
            ),
          ],
        ),
      ),
    );
  }

  bool _canSendEmailCode(bool formDisabled) {
    return !formDisabled && _emailCodeCooldown <= 0;
  }

  String _emailCodeButtonText(BuildContext context) {
    if (_emailCodeCooldown > 0) {
      return '${context.l10n.resendEmailCodeIn} $_emailCodeCooldown s';
    }
    return context.l10n.sendEmailCode;
  }

  Future<void> _sendEmailCode() async {
    final error = _validateEmail(_emailController.text);
    if (error != null) {
      _showSnackBar(error);
      return;
    }

    setState(() => _isSendingCode = true);
    try {
      final delivery = await ref
          .read(authControllerProvider.notifier)
          .sendRegisterEmailCode(email: _emailController.text.trim());
      if (!mounted) {
        return;
      }
      _startEmailCodeCooldown(delivery.resendAfter);
      _showSnackBar('${context.l10n.registerEmailCodeSent} ${delivery.email}');
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

  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_agreementAccepted) {
      _showSnackBar(context.l10n.agreementRequired);
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .accountRegister(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailCode: _emailCodeController.text.trim(),
          memberRole: _memberRole,
          locale: Localizations.localeOf(context).toLanguageTag(),
        );
  }

  void _startEmailCodeCooldown(int seconds) {
    _cooldownTimer?.cancel();
    final initialSeconds = seconds > 0 ? seconds : 120;
    setState(() => _emailCodeCooldown = initialSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_emailCodeCooldown <= 1) {
        timer.cancel();
        setState(() => _emailCodeCooldown = 0);
        return;
      }
      setState(() => _emailCodeCooldown--);
    });
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.requiredField;
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return context.l10n.requiredField;
    }
    if (text.length < 3 || text.length > 32) {
      return context.l10n.usernameLengthRule;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return context.l10n.requiredField;
    }
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) {
      return context.l10n.invalidEmail;
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.l10n.memberRoleLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'patient',
                icon: const Icon(Icons.favorite_border_rounded),
                label: Text(context.l10n.patient),
              ),
              ButtonSegment(
                value: 'doctor',
                icon: const Icon(Icons.medical_services_outlined),
                label: Text(context.l10n.doctor),
              ),
            ],
            selected: {selected},
            onSelectionChanged: enabled
                ? (values) {
                    if (values.isNotEmpty) {
                      onChanged(values.first);
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
