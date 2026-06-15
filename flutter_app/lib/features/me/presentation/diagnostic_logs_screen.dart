import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/build_info.dart';
import '../../../core/diagnostics/diagnostic_log_service.dart';
import '../../../core/i18n/app_locale_controller.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/settings_repository.dart';

class DiagnosticLogsScreen extends ConsumerStatefulWidget {
  const DiagnosticLogsScreen({super.key});

  @override
  ConsumerState<DiagnosticLogsScreen> createState() =>
      _DiagnosticLogsScreenState();
}

class _DiagnosticLogsScreenState extends ConsumerState<DiagnosticLogsScreen> {
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String _deviceId = '';
  String _platform = '';
  String _locale = '';
  String _timezone = '';
  List<DiagnosticLogEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadDiagnostics());
  }

  Future<void> _loadDiagnostics() async {
    final diagnosticService = ref.read(diagnosticLogServiceProvider);
    final deviceService = ref.read(deviceRegistrationServiceProvider);
    try {
      final entries = await diagnosticService.readEntries();
      final deviceId = await deviceService.readCurrentDeviceId() ?? '';
      final locale =
          ref.read(appLocaleProvider)?.toLanguageTag() ??
          PlatformDispatcher.instance.locale.toLanguageTag();
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = entries;
        _deviceId = deviceId;
        _platform = deviceService.currentPlatform() ?? '';
        _locale = locale;
        _timezone = DateTime.now().timeZoneName;
        _error = null;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = _errorText(error);
      });
    }
  }

  Future<void> _uploadLogs() async {
    if (_uploading) {
      return;
    }
    if (_entries.isEmpty) {
      context.showCenteredNotice(context.l10n.diagnosticsUploadEmpty);
      return;
    }

    setState(() => _uploading = true);
    final diagnosticService = ref.read(diagnosticLogServiceProvider);
    final deviceService = ref.read(deviceRegistrationServiceProvider);
    try {
      final locale =
          ref.read(appLocaleProvider)?.toLanguageTag() ??
          PlatformDispatcher.instance.locale.toLanguageTag();
      final uploadEntries = _entries.reversed
          .map((item) => item.toJson())
          .toList(growable: false);
      final receipt = await ref
          .read(meSettingsRepositoryProvider)
          .uploadDiagnosticLogs(
            deviceId: _deviceId.isEmpty
                ? await deviceService.readCurrentDeviceId() ?? ''
                : _deviceId,
            platform: _platform.isEmpty
                ? deviceService.currentPlatform() ?? ''
                : _platform,
            appVersion: BuildInfo.appVersion,
            locale: locale,
            timezone: _timezone.isEmpty
                ? DateTime.now().timeZoneName
                : _timezone,
            source: 'manual',
            firstLogAt: uploadEntries.first['created_at']?.toString(),
            lastLogAt: uploadEntries.last['created_at']?.toString(),
            entries: uploadEntries,
          );
      await diagnosticService.recordInfo(
        category: 'diagnostic.upload',
        message: 'Manual diagnostic upload succeeded',
        details: {
          'upload_id': receipt.id,
          'entry_count': receipt.entryCount,
          'uploaded_at': receipt.uploadedAt,
        },
      );
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(context.l10n.diagnosticsUploadSuccess);
      await _loadDiagnostics();
    } on Object catch (error) {
      await diagnosticService.recordError(
        category: 'diagnostic.upload',
        message: 'Manual diagnostic upload failed',
        details: {'error': _errorText(error)},
      );
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_errorText(error));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DiagnosticPalette.of(context);
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(context.l10n.diagnosticsTitle),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        actions: [
          IconButton(
            onPressed: _loading ? null : () => unawaited(_loadDiagnostics()),
            tooltip: context.l10n.diagnosticsRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          TextButton(
            onPressed: _loading || _uploading ? null : _uploadLogs,
            child: _uploading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: palette.accent,
                    ),
                  )
                : Text(
                    context.l10n.diagnosticsUpload,
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: palette.accent))
            : RefreshIndicator(
                onRefresh: _loadDiagnostics,
                color: palette.accent,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    _SummaryCard(
                      palette: palette,
                      count: _entries.length,
                      deviceId: _deviceId,
                      platform: _platform,
                      locale: _locale,
                      timezone: _timezone,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      _ErrorCard(message: _error!, palette: palette),
                    ] else if (_entries.isEmpty) ...[
                      const SizedBox(height: 18),
                      _EmptyCard(palette: palette),
                    ] else ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                        child: Text(
                          context.l10n.diagnosticsEntriesTitle,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: palette.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      ..._entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LogEntryCard(
                            entry: entry,
                            palette: palette,
                            timestamp: _dateFormat.format(
                              entry.createdAt.toLocal(),
                            ),
                            levelLabel: _levelLabel(context, entry.level),
                            onTap: () =>
                                _showEntryDetails(context, entry, palette),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  void _showEntryDetails(
    BuildContext context,
    DiagnosticLogEntry entry,
    _DiagnosticPalette palette,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.cardBackground,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final bottomPadding = MediaQuery.of(sheetContext).viewPadding.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomPadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_levelLabel(sheetContext, entry.level)} · ${_dateFormat.format(entry.createdAt.toLocal())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.diagnosticsDetailsTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.detailBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SelectableText(
                      entry.details.isEmpty
                          ? context.l10n.diagnosticsNoDetails
                          : entry.details,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.primaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _levelLabel(BuildContext context, DiagnosticLogLevel level) {
    return switch (level) {
      DiagnosticLogLevel.info => context.l10n.diagnosticsLevelInfo,
      DiagnosticLogLevel.warning => context.l10n.diagnosticsLevelWarning,
      DiagnosticLogLevel.error => context.l10n.diagnosticsLevelError,
    };
  }

  String _errorText(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final text = error.toString().trim();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

class _DiagnosticPalette {
  const _DiagnosticPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.detailBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.divider,
    required this.infoColor,
    required this.warningColor,
    required this.errorColor,
  });

  static _DiagnosticPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    if (isDark) {
      return _DiagnosticPalette(
        pageBackground: scheme.surface,
        cardBackground: scheme.surfaceContainerHigh,
        detailBackground: scheme.surfaceContainerHighest,
        primaryText: scheme.onSurface,
        secondaryText: scheme.onSurfaceVariant,
        accent: const Color(0xFFFFB4A8),
        divider: Colors.white.withValues(alpha: 0.08),
        infoColor: const Color(0xFF7AB8FF),
        warningColor: const Color(0xFFFFC46B),
        errorColor: const Color(0xFFFF9585),
      );
    }
    return const _DiagnosticPalette(
      pageBackground: Color(0xFFF7F7FA),
      cardBackground: Colors.white,
      detailBackground: Color(0xFFF3F5FA),
      primaryText: Color(0xFF303236),
      secondaryText: Color(0xFF8A9098),
      accent: Color(0xFFFF8D7F),
      divider: Color(0xFFE4E7EC),
      infoColor: Color(0xFF5A81DA),
      warningColor: Color(0xFFFFAE4D),
      errorColor: Color(0xFFFF9585),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color detailBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color divider;
  final Color infoColor;
  final Color warningColor;
  final Color errorColor;

  Color levelColor(DiagnosticLogLevel level) {
    return switch (level) {
      DiagnosticLogLevel.info => infoColor,
      DiagnosticLogLevel.warning => warningColor,
      DiagnosticLogLevel.error => errorColor,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.palette,
    required this.count,
    required this.deviceId,
    required this.platform,
    required this.locale,
    required this.timezone,
  });

  final _DiagnosticPalette palette;
  final int count;
  final String deviceId;
  final String platform;
  final String locale;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.diagnosticsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.diagnosticsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.secondaryText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(
                label: context.l10n.diagnosticsMetaVersion,
                value: BuildInfo.shortVersion,
                palette: palette,
              ),
              _MetaChip(
                label: context.l10n.diagnosticsMetaEntries,
                value: '$count',
                palette: palette,
              ),
              _MetaChip(
                label: context.l10n.diagnosticsMetaPlatform,
                value: platform.isEmpty ? '-' : platform,
                palette: palette,
              ),
              _MetaChip(
                label: context.l10n.diagnosticsMetaLocale,
                value: locale.isEmpty ? '-' : locale,
                palette: palette,
              ),
              _MetaChip(
                label: context.l10n.diagnosticsMetaTimezone,
                value: timezone.isEmpty ? '-' : timezone,
                palette: palette,
              ),
            ],
          ),
          if (deviceId.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '${context.l10n.diagnosticsMetaDeviceId}: $deviceId',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final _DiagnosticPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.detailBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.palette});

  final _DiagnosticPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: palette.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.diagnosticsEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.diagnosticsEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.palette});

  final String message;
  final _DiagnosticPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: palette.errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.primaryText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({
    required this.entry,
    required this.palette,
    required this.timestamp,
    required this.levelLabel,
    required this.onTap,
  });

  final DiagnosticLogEntry entry;
  final _DiagnosticPalette palette;
  final String timestamp;
  final String levelLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: palette.cardBackground,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette
                      .levelColor(entry.level)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  switch (entry.level) {
                    DiagnosticLogLevel.info => Icons.info_outline_rounded,
                    DiagnosticLogLevel.warning => Icons.warning_amber_rounded,
                    DiagnosticLogLevel.error => Icons.error_outline_rounded,
                  },
                  color: palette.levelColor(entry.level),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$levelLabel · $timestamp',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                    if (entry.details.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.details.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.primaryText.withValues(alpha: 0.78),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: palette.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
