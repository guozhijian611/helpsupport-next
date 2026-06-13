import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/i18n/l10n_extensions.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.emailLogin,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.login),
              label: Text(context.l10n.continueLabel),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showPending(context),
              icon: const Icon(Icons.g_mobiledata),
              label: Text(context.l10n.googleLogin),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showPending(context),
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

  void _showPending(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.networkUnavailable)));
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
