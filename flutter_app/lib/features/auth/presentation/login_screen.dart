import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../application/auth_controller.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loginTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.l10n.loginTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.loginSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: context.l10n.username,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: context.l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: _required,
                    onFieldSubmitted: (_) => _submitAccountLogin(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isLoading ? null : _submitAccountLogin,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(
                isLoading ? context.l10n.loggingIn : context.l10n.accountLogin,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : ref.read(authControllerProvider.notifier).googleLogin,
              icon: const Icon(Icons.g_mobiledata),
              label: Text(context.l10n.googleLogin),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : ref.read(authControllerProvider.notifier).appleLogin,
              icon: const Icon(Icons.apple),
              label: Text(context.l10n.appleLogin),
            ),
            const SizedBox(height: 28),
            _ApiBaseUrlTile(baseUrl: ApiClient.apiBaseUrl),
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

class _ApiBaseUrlTile extends StatelessWidget {
  const _ApiBaseUrlTile({required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.dns_outlined),
        title: Text(context.l10n.apiBaseUrlLabel),
        subtitle: Text(baseUrl),
      ),
    );
  }
}
