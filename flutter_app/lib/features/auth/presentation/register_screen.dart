import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/auth_controller.dart';
import '../data/auth_protocol.dart';
import 'auth_page_frame.dart';

enum _RegisterMethod { email, phone }

enum _RegisterStep { account, verify }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  Timer? _cooldownTimer;
  int _codeCooldown = 0;
  bool _isSendingCode = false;
  bool _agreementAccepted = false;
  bool _awaitingProfileCompletion = false;
  _RegisterMethod _method = _RegisterMethod.email;
  _RegisterStep _step = _RegisterStep.account;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          context.push('/protocol/${AuthProtocolType.terms.routeValue}');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          context.push('/protocol/${AuthProtocolType.privacy.routeValue}');
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (_awaitingProfileCompletion && next.hasValue && next.value != null) {
        _awaitingProfileCompletion = false;
        context.go('/register/profile');
      }
      if (next.hasError) {
        _awaitingProfileCompletion = false;
        _showError(next.error);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final formDisabled = isLoading || _isSendingCode;

    return AuthPageFrame(
      title: context.l10n.registerTitle,
      subtitle: '',
      leading: IconButton.filledTonal(
        onPressed: formDisabled ? null : _handleBack,
        icon: const Icon(Icons.arrow_back),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RegisterMethodTabs(
              selected: _method,
              enabled: !formDisabled,
              onChanged: _changeMethod,
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _step == _RegisterStep.account
                  ? _RegisterAccountStep(
                      key: const ValueKey('account-step'),
                      method: _method,
                      identifierController: _identifierController,
                      enabled: !formDisabled,
                      agreementAccepted: _agreementAccepted,
                      termsRecognizer: _termsRecognizer,
                      privacyRecognizer: _privacyRecognizer,
                      onAgreementChanged: (value) {
                        setState(() => _agreementAccepted = value ?? false);
                      },
                      onContinue: _continueToVerification,
                      validateIdentifier: _validateIdentifier,
                    )
                  : _RegisterVerifyStep(
                      key: const ValueKey('verify-step'),
                      method: _method,
                      identifierController: _identifierController,
                      codeController: _codeController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      enabled: !formDisabled,
                      isSubmitting: isLoading,
                      isSendingCode: _isSendingCode,
                      codeButtonText: _codeButtonText(context),
                      canSendCode: _canSendCode(formDisabled),
                      onSendCode: _sendVerificationCode,
                      onContinue: _submitRegister,
                      validateIdentifier: _validateIdentifier,
                      validateCode: _required,
                      validatePassword: _validatePassword,
                      validateConfirmPassword: _validateConfirmPassword,
                      submitLabel: isLoading
                          ? context.l10n.registering
                          : context.l10n.continueLabel,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMethod(_RegisterMethod method) {
    if (_method == method) {
      return;
    }

    _cooldownTimer?.cancel();
    setState(() {
      _method = method;
      _step = _RegisterStep.account;
      _identifierController.clear();
      _codeController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _codeCooldown = 0;
    });
  }

  void _backToAccountStep() {
    if (_step == _RegisterStep.account) {
      return;
    }
    setState(() {
      _step = _RegisterStep.account;
      _codeController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _handleBack() {
    if (_step == _RegisterStep.verify) {
      _backToAccountStep();
      return;
    }
    context.go('/login');
  }

  bool _canSendCode(bool formDisabled) {
    return !formDisabled && _codeCooldown <= 0;
  }

  String _codeButtonText(BuildContext context) {
    if (_codeCooldown > 0) {
      return '${context.l10n.resendVerificationCodeIn} $_codeCooldown s';
    }
    return context.l10n.sendVerificationCode;
  }

  void _continueToVerification() {
    final error = _validateIdentifier(_identifierController.text);
    if (error != null) {
      _showSnackBar(error);
      return;
    }
    if (!_agreementAccepted) {
      _showSnackBar(context.l10n.agreementRequired);
      return;
    }

    setState(() => _step = _RegisterStep.verify);
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
      final delivery = _method == _RegisterMethod.email
          ? await controller.sendRegisterEmailCode(
              email: _identifierController.text.trim(),
            )
          : await controller.sendRegisterPhoneCode(
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

  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _awaitingProfileCompletion = true;
    await ref
        .read(authControllerProvider.notifier)
        .accountRegister(
          registerType: _method == _RegisterMethod.email ? 'email' : 'phone',
          email: _method == _RegisterMethod.email
              ? _identifierController.text.trim()
              : null,
          mobile: _method == _RegisterMethod.phone
              ? _identifierController.text.trim()
              : null,
          password: _passwordController.text,
          emailCode: _method == _RegisterMethod.email
              ? _codeController.text.trim()
              : null,
          mobileCode: _method == _RegisterMethod.phone
              ? _codeController.text.trim()
              : null,
          memberRole: 'patient',
          locale: Localizations.localeOf(context).toLanguageTag(),
          timezone: DateTime.now().timeZoneName,
        );
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
    if (_method == _RegisterMethod.email) {
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

class _RegisterAccountStep extends StatelessWidget {
  const _RegisterAccountStep({
    super.key,
    required this.method,
    required this.identifierController,
    required this.enabled,
    required this.agreementAccepted,
    required this.termsRecognizer,
    required this.privacyRecognizer,
    required this.onAgreementChanged,
    required this.onContinue,
    required this.validateIdentifier,
  });

  final _RegisterMethod method;
  final TextEditingController identifierController;
  final bool enabled;
  final bool agreementAccepted;
  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;
  final ValueChanged<bool?> onAgreementChanged;
  final VoidCallback onContinue;
  final FormFieldValidator<String> validateIdentifier;

  @override
  Widget build(BuildContext context) {
    final accountGap = (MediaQuery.sizeOf(context).height * 0.12)
        .clamp(88.0, 148.0)
        .toDouble();

    return Column(
      children: [
        _RegisterInputField(
          controller: identifierController,
          enabled: enabled,
          keyboardType: method == _RegisterMethod.email
              ? TextInputType.emailAddress
              : TextInputType.phone,
          textInputAction: TextInputAction.done,
          hint: method == _RegisterMethod.email
              ? context.l10n.loginEmailPlaceholder
              : context.l10n.phoneNumber,
          icon: method == _RegisterMethod.email
              ? Icons.mail_outline_rounded
              : Icons.phone_in_talk_rounded,
          badgeVariant: method == _RegisterMethod.email
              ? _FieldBadgeVariant.darkSquare
              : _FieldBadgeVariant.lightCircle,
          validator: validateIdentifier,
          onFieldSubmitted: (_) => onContinue(),
        ),
        SizedBox(height: accountGap),
        AuthPrimaryButton(
          onPressed: enabled ? onContinue : null,
          label: context.l10n.continueLabel,
          height: 60,
          borderRadius: 22,
          backgroundColor: const Color(0xFFFFC7C1),
          disabledBackgroundColor: const Color(0xFFFFDCD8),
        ),
        const SizedBox(height: 24),
        _AgreementCheckboxRow(
          value: agreementAccepted,
          enabled: enabled,
          onChanged: onAgreementChanged,
          termsRecognizer: termsRecognizer,
          privacyRecognizer: privacyRecognizer,
        ),
      ],
    );
  }
}

class _RegisterVerifyStep extends StatelessWidget {
  const _RegisterVerifyStep({
    super.key,
    required this.method,
    required this.identifierController,
    required this.codeController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.enabled,
    required this.isSubmitting,
    required this.isSendingCode,
    required this.codeButtonText,
    required this.canSendCode,
    required this.onSendCode,
    required this.onContinue,
    required this.validateIdentifier,
    required this.validateCode,
    required this.validatePassword,
    required this.validateConfirmPassword,
    required this.submitLabel,
  });

  final _RegisterMethod method;
  final TextEditingController identifierController;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool enabled;
  final bool isSubmitting;
  final bool isSendingCode;
  final String codeButtonText;
  final bool canSendCode;
  final VoidCallback onSendCode;
  final VoidCallback onContinue;
  final FormFieldValidator<String> validateIdentifier;
  final FormFieldValidator<String> validateCode;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    final verifyGap = (MediaQuery.sizeOf(context).height * 0.08)
        .clamp(56.0, 108.0)
        .toDouble();

    return Column(
      children: [
        _RegisterInputField(
          controller: identifierController,
          enabled: enabled,
          readOnly: true,
          keyboardType: method == _RegisterMethod.email
              ? TextInputType.emailAddress
              : TextInputType.phone,
          textInputAction: TextInputAction.next,
          hint: method == _RegisterMethod.email
              ? context.l10n.loginEmailPlaceholder
              : context.l10n.phoneNumber,
          icon: method == _RegisterMethod.email
              ? Icons.mail_outline_rounded
              : Icons.phone_in_talk_rounded,
          badgeVariant: _FieldBadgeVariant.darkSquare,
          validator: validateIdentifier,
        ),
        const SizedBox(height: 14),
        _RegisterInputField(
          controller: codeController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          hint: context.l10n.verificationCode,
          icon: Icons.verified_user_outlined,
          badgeVariant: _FieldBadgeVariant.darkShield,
          validator: validateCode,
          suffix: _VerificationCodeButton(
            text: codeButtonText,
            enabled: canSendCode,
            isLoading: isSendingCode,
            onPressed: onSendCode,
          ),
        ),
        const SizedBox(height: 14),
        _RegisterInputField(
          controller: passwordController,
          enabled: enabled,
          obscureText: true,
          textInputAction: TextInputAction.next,
          hint: context.l10n.newPassword,
          icon: Icons.lock_outline_rounded,
          badgeVariant: _FieldBadgeVariant.darkSquare,
          validator: validatePassword,
        ),
        const SizedBox(height: 14),
        _RegisterInputField(
          controller: confirmPasswordController,
          enabled: enabled,
          obscureText: true,
          textInputAction: TextInputAction.done,
          hint: context.l10n.confirmPassword,
          icon: Icons.lock_reset_outlined,
          badgeVariant: _FieldBadgeVariant.darkSquare,
          validator: validateConfirmPassword,
          onFieldSubmitted: (_) => onContinue(),
        ),
        SizedBox(height: verifyGap),
        AuthPrimaryButton(
          onPressed: enabled ? onContinue : null,
          label: submitLabel,
          isLoading: isSubmitting,
          height: 60,
          borderRadius: 22,
          backgroundColor: const Color(0xFFFFC7C1),
          disabledBackgroundColor: const Color(0xFFFFDCD8),
        ),
      ],
    );
  }
}

enum _FieldBadgeVariant { darkSquare, lightCircle, darkShield }

class _RegisterInputField extends StatelessWidget {
  const _RegisterInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.badgeVariant,
    required this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final _FieldBadgeVariant badgeVariant;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF353740),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9EA2AE),
        ),
        errorMaxLines: 2,
        filled: true,
        fillColor: const Color(0xFFF3F5FA),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 12),
          child: _RegisterFieldBadge(icon: icon, variant: badgeVariant),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 78),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFFF9585), width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}

class _RegisterFieldBadge extends StatelessWidget {
  const _RegisterFieldBadge({required this.icon, required this.variant});

  final IconData icon;
  final _FieldBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final isLight = variant == _FieldBadgeVariant.lightCircle;
    final borderRadius = switch (variant) {
      _FieldBadgeVariant.lightCircle => BorderRadius.circular(22),
      _FieldBadgeVariant.darkShield => BorderRadius.circular(16),
      _FieldBadgeVariant.darkSquare => BorderRadius.circular(14),
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF313338),
        borderRadius: borderRadius,
        border: isLight
            ? Border.all(color: const Color(0xFFF0F1F5), width: 1.2)
            : null,
      ),
      child: Icon(
        icon,
        size: 22,
        color: isLight ? const Color(0xFF5F6470) : Colors.white,
      ),
    );
  }
}

class _RegisterMethodTabs extends StatelessWidget {
  const _RegisterMethodTabs({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final _RegisterMethod selected;
  final bool enabled;
  final ValueChanged<_RegisterMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RegisterMethodTab(
            label: context.l10n.emailRegister,
            selected: selected == _RegisterMethod.email,
            enabled: enabled,
            onTap: () => onChanged(_RegisterMethod.email),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _RegisterMethodTab(
            label: context.l10n.phoneRegister,
            selected: selected == _RegisterMethod.phone,
            enabled: enabled,
            onTap: () => onChanged(_RegisterMethod.phone),
          ),
        ),
      ],
    );
  }
}

class _RegisterMethodTab extends StatelessWidget {
  const _RegisterMethodTab({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? const Color(0xFFFFE2DD)
        : const Color(0xFFF3E5DF);
    final foregroundColor = selected
        ? const Color(0xFFFF8E80)
        : const Color(0xFFB59A92);

    return FilledButton(
      onPressed: enabled ? onTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.7),
        disabledForegroundColor: foregroundColor.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
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
      padding: const EdgeInsets.only(right: 10),
      child: TextButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6B87E6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      ),
    );
  }
}

class _AgreementCheckboxRow extends StatelessWidget {
  const _AgreementCheckboxRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;
  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF9B9EAA),
      height: 1.5,
      fontWeight: FontWeight.w500,
    );
    final linkStyle = const TextStyle(
      color: Color(0xFFFF9585),
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Checkbox(
            value: value,
            onChanged: enabled ? onChanged : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: const BorderSide(color: Color(0xFFD0D3DB), width: 1.5),
            activeColor: const Color(0xFFFF9585),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text.rich(
              TextSpan(
                style: baseStyle,
                children: [
                  TextSpan(text: '${context.l10n.loginAgreementPrefix} '),
                  TextSpan(
                    text: context.l10n.termsOfUse,
                    style: linkStyle,
                    recognizer: enabled ? termsRecognizer : null,
                  ),
                  TextSpan(text: ' ${context.l10n.loginAgreementJoin} '),
                  TextSpan(
                    text: context.l10n.privacyPolicy,
                    style: linkStyle,
                    recognizer: enabled ? privacyRecognizer : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
