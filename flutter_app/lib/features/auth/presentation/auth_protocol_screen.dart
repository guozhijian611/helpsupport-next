import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../application/auth_protocol_controller.dart';
import '../data/auth_protocol.dart';

class AuthProtocolScreen extends ConsumerWidget {
  const AuthProtocolScreen({super.key, required this.type});

  final AuthProtocolType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = AuthProtocolQuery(
      type: type,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    final document = ref.watch(authProtocolProvider(query));
    final currentDocument = document.asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text(_title(context, currentDocument))),
      body: SafeArea(
        child: document.when(
          data: (value) => _ProtocolBody(
            title: _title(context, value),
            content: _HtmlProtocolFormatter.toPlainText(value.content),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ProtocolErrorView(
            message: _errorText(context, error),
            onRetry: () => ref.invalidate(authProtocolProvider(query)),
          ),
        ),
      ),
    );
  }

  String _title(BuildContext context, AuthProtocolDocument? document) {
    final title = document?.title.trim() ?? '';
    if (title.isNotEmpty) {
      return title;
    }

    return switch (type) {
      AuthProtocolType.terms => context.l10n.termsOfUse,
      AuthProtocolType.privacy => context.l10n.privacyPolicy,
    };
  }

  String _errorText(BuildContext context, Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    final text = error.toString().trim();
    if (text.isEmpty) {
      return context.l10n.networkUnavailable;
    }

    return text
        .replaceFirst(RegExp(r'^.*message: '), '')
        .replaceFirst(RegExp(r', traceId: .*$'), '');
  }
}

class _ProtocolBody extends StatelessWidget {
  const _ProtocolBody({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = content.trim().isEmpty ? '-' : content.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 18),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.75),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolErrorView extends StatelessWidget {
  const _ProtocolErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _HtmlProtocolFormatter {
  static final RegExp _breakTag = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _listItemOpen = RegExp(
    r'<li[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _blockOpen = RegExp(
    r'<(p|div|h[1-6]|ul|ol|blockquote)[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _blockClose = RegExp(
    r'</(p|div|h[1-6]|li|ul|ol|blockquote)>',
    caseSensitive: false,
  );
  static final RegExp _allTags = RegExp(r'<[^>]+>');
  static final RegExp _lineSpaces = RegExp(r'[ \t\u00A0]+');
  static final RegExp _multiBlankLines = RegExp(r'\n{3,}');

  static String toPlainText(String html) {
    if (html.trim().isEmpty) {
      return '';
    }

    var text = html
        .replaceAll(_breakTag, '\n')
        .replaceAll(_listItemOpen, '\n• ')
        .replaceAll(_blockOpen, '\n')
        .replaceAll(_blockClose, '\n')
        .replaceAll(_allTags, '');
    text = _decodeEntities(text)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_multiBlankLines, '\n\n');

    final buffer = StringBuffer();
    var previousBlank = true;
    for (final rawLine in text.split('\n')) {
      final line = rawLine.replaceAll(_lineSpaces, ' ').trim();
      if (line.isEmpty) {
        if (!previousBlank && buffer.isNotEmpty) {
          buffer.write('\n\n');
        }
        previousBlank = true;
        continue;
      }

      if (!previousBlank && buffer.isNotEmpty) {
        buffer.write('\n');
      }
      buffer.write(line);
      previousBlank = false;
    }

    return buffer.toString().trim();
  }

  static String _decodeEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }
}
