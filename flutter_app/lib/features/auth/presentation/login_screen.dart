import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/i18n/language_switcher.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/auth_controller.dart';
import '../data/auth_protocol.dart';
import 'auth_page_frame.dart';

enum _LoginMethod { email, phone }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginMethod _loginMethod = _LoginMethod.email;
  bool _agreementAccepted = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        context.go('/home');
      }
      if (next.hasError) {
        context.showCenteredNotice(_errorText(next.error));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return AuthPageFrame(
      title: context.l10n.loginTitle,
      subtitle: '',
      trailing: const LanguageSwitcher(onDark: true),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LoginMethodTabs(
              selected: _loginMethod,
              enabled: !isLoading,
              onChanged: (method) => setState(() => _loginMethod = method),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _usernameController,
              enabled: !isLoading,
              keyboardType: _loginMethod == _LoginMethod.email
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              textInputAction: TextInputAction.next,
              label: _loginMethod == _LoginMethod.email
                  ? context.l10n.loginEmailPlaceholder
                  : context.l10n.phoneNumber,
              icon: _loginMethod == _LoginMethod.email
                  ? Icons.mail_rounded
                  : Icons.phone_iphone_rounded,
              validator: _required,
            ),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: true,
              textInputAction: TextInputAction.done,
              label: context.l10n.password,
              icon: Icons.lock_rounded,
              validator: _required,
              onFieldSubmitted: (_) => _submitAccountLogin(),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _InlineActionButton(
                  text: context.l10n.forgotPassword,
                  onPressed: isLoading
                      ? null
                      : () => context.go('/forgot-password'),
                ),
                const Spacer(),
                _InlineActionButton(
                  text: context.l10n.registerAccountAction,
                  onPressed: isLoading ? null : () => context.go('/register'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AuthPrimaryButton(
              onPressed: _submitAccountLogin,
              isLoading: isLoading,
              height: 46,
              borderRadius: 16,
              backgroundColor: _agreementAccepted
                  ? const Color(0xFFFF9585)
                  : const Color(0xFFFFD2CE),
              disabledBackgroundColor: const Color(0xFFFFD2CE),
              label: isLoading
                  ? context.l10n.loggingIn
                  : context.l10n.accountLogin,
            ),
            const SizedBox(height: 14),
            _SocialLoginButton(
              onPressed: isLoading
                  ? null
                  : () => _submitSocialLogin(
                      ref.read(authControllerProvider.notifier).appleLogin,
                    ),
              label: context.l10n.appleLogin,
              backgroundColor: const Color(0xFF101010),
              foregroundColor: Colors.white,
              borderColor: const Color(0xFF101010),
              leading: const Icon(Icons.apple, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            _SocialLoginButton(
              onPressed: isLoading
                  ? null
                  : () => _submitSocialLogin(
                      ref.read(authControllerProvider.notifier).googleLogin,
                    ),
              label: context.l10n.googleLogin,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF303236),
              borderColor: const Color(0xFFECE4E0),
              leading: const _GoogleMark(),
            ),
            const SizedBox(height: 8),
            _LoginAgreement(
              value: _agreementAccepted,
              enabled: !isLoading,
              onChanged: (value) {
                setState(() => _agreementAccepted = value ?? false);
              },
              onTermsTap: () => context.push(
                '/protocol/${AuthProtocolType.terms.routeValue}',
              ),
              onPrivacyTap: () => context.push(
                '/protocol/${AuthProtocolType.privacy.routeValue}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.requiredField;
    }
    return null;
  }

  Future<void> _submitAccountLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_ensureAgreementAccepted()) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .accountLogin(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _submitSocialLogin(Future<void> Function() login) async {
    if (!_ensureAgreementAccepted()) {
      return;
    }

    await login();
  }

  bool _ensureAgreementAccepted() {
    if (_agreementAccepted) {
      return true;
    }
    _showSnackBar(context.l10n.agreementRequired);
    return false;
  }

  void _showSnackBar(String message) {
    context.showCenteredNotice(message);
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

class _LoginMethodTabs extends StatelessWidget {
  const _LoginMethodTabs({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final _LoginMethod selected;
  final bool enabled;
  final ValueChanged<_LoginMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LoginMethodTab(
            label: context.l10n.emailLogin,
            selected: selected == _LoginMethod.email,
            enabled: enabled,
            onTap: () => onChanged(_LoginMethod.email),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _LoginMethodTab(
            label: context.l10n.phoneLogin,
            selected: selected == _LoginMethod.phone,
            enabled: enabled,
            onTap: () => onChanged(_LoginMethod.phone),
          ),
        ),
      ],
    );
  }
}

class _LoginMethodTab extends StatelessWidget {
  const _LoginMethodTab({
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
    final textColor = selected
        ? const Color(0xFFFF9585)
        : const Color(0xFFB18A81);
    final backgroundColor = selected
        ? const Color(0xFFFDEAE7)
        : const Color(0xFFF0E8E4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ).copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFFF9585),
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Text(text),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.onPressed,
    required this.label,
    required this.leading,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget leading;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.55),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 10),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 28,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 29,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _LoginAgreement extends StatefulWidget {
  const _LoginAgreement({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_LoginAgreement> createState() => _LoginAgreementState();
}

class _LoginAgreementState extends State<_LoginAgreement> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = widget.enabled ? widget.onTermsTap : null;
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = widget.enabled ? widget.onPrivacyTap : null;
  }

  @override
  void didUpdateWidget(covariant _LoginAgreement oldWidget) {
    super.didUpdateWidget(oldWidget);
    _termsRecognizer.onTap = widget.enabled ? widget.onTermsTap : null;
    _privacyRecognizer.onTap = widget.enabled ? widget.onPrivacyTap : null;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    const accent = Color(0xFFFF9585);
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: muted,
      height: 1.45,
      fontWeight: FontWeight.w600,
    );
    final linkStyle = TextStyle(
      color: widget.enabled ? accent : accent.withValues(alpha: 0.58),
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Checkbox(
            value: widget.value,
            onChanged: widget.enabled ? widget.onChanged : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(color: muted.withValues(alpha: 0.42), width: 1.5),
            activeColor: accent,
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
                    recognizer: _termsRecognizer,
                  ),
                  TextSpan(text: ' ${context.l10n.loginAgreementJoin} '),
                  TextSpan(
                    text: context.l10n.privacyPolicy,
                    style: linkStyle,
                    recognizer: _privacyRecognizer,
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
