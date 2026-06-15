import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/i18n/language_switcher.dart';
import '../application/auth_controller.dart';
import 'auth_page_frame.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(next.error))));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return AuthPageFrame(
      title: context.l10n.loginTitle,
      subtitle: context.l10n.loginSubtitle,
      trailing: const LanguageSwitcher(onDark: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                AuthTextField(
                  controller: _usernameController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  label: context.l10n.username,
                  icon: Icons.person_outline,
                  validator: _required,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  label: context.l10n.password,
                  icon: Icons.lock_outline,
                  validator: _required,
                  onFieldSubmitted: (_) => _submitAccountLogin(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            onPressed: _submitAccountLogin,
            icon: Icons.login_rounded,
            isLoading: isLoading,
            label: isLoading
                ? context.l10n.loggingIn
                : context.l10n.accountLogin,
          ),
          const SizedBox(height: 22),
          AuthDivider(label: context.l10n.authOtherMethods),
          const SizedBox(height: 16),
          AuthSecondaryButton(
            onPressed: isLoading
                ? null
                : ref.read(authControllerProvider.notifier).googleLogin,
            icon: Icons.g_mobiledata,
            label: context.l10n.googleLogin,
          ),
          const SizedBox(height: 12),
          AuthSecondaryButton(
            onPressed: isLoading
                ? null
                : ref.read(authControllerProvider.notifier).appleLogin,
            icon: Icons.apple,
            backgroundColor: const Color(0xFF101010),
            foregroundColor: Colors.white,
            borderColor: const Color(0xFF101010),
            label: context.l10n.appleLogin,
          ),
          const SizedBox(height: 18),
          AuthAgreementNotice(text: context.l10n.loginAgreementNotice),
          const SizedBox(height: 12),
          AuthLinkButton(
            text: context.l10n.loginNoAccount,
            actionText: context.l10n.registerAction,
            onPressed: () => context.go('/register'),
            onDark: false,
          ),
        ],
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

    await ref
        .read(authControllerProvider.notifier)
        .accountLogin(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
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
