import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/appointment_controller.dart';
import '../data/appointment_models.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  int? _status;

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentListPalette.of(context);
    final query = AppointmentMineQuery(status: _status);
    final appointments = ref.watch(appointmentMineProvider(query));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '我的预约', 'My bookings')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(appointmentMineProvider(query));
            await ref.read(appointmentMineProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final filter = _statusFilters(context)[index];
                    final selected = filter.status == _status;
                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _status = filter.status),
                      selectedColor: palette.chipSelectedBackground,
                      labelStyle: TextStyle(
                        color: selected
                            ? palette.chipSelectedText
                            : palette.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFFFFC4B9)
                            : palette.outline,
                      ),
                      backgroundColor: palette.chipBackground,
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemCount: _statusFilters(context).length,
                ),
              ),
              const SizedBox(height: 18),
              appointments.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return _AppointmentEmptyCard(
                      title: _t(context, '还没有预约记录', 'No booking history'),
                      subtitle: _t(
                        context,
                        '从医生列表里选择时间后，这里会显示你的预约状态。',
                        'After you choose a doctor and time, your booking status will appear here.',
                      ),
                      actionLabel: _t(context, '去预约', 'Book now'),
                      onAction: () => context.push('/appointments/doctors'),
                    );
                  }
                  return Column(
                    children: [
                      for (final item in page.list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AppointmentRecordCard(record: item),
                        ),
                    ],
                  );
                },
                error: (error, _) => _AppointmentEmptyCard(
                  title: _t(context, '加载失败', 'Load failed'),
                  subtitle: error.toString(),
                  actionLabel: _t(context, '重试', 'Retry'),
                  onAction: () =>
                      ref.invalidate(appointmentMineProvider(query)),
                ),
                loading: () => const _AppointmentListSkeleton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentRecordCard extends ConsumerWidget {
  const _AppointmentRecordCard({required this.record});

  final AppointmentRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _AppointmentListPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final avatarUrl = apiClient.resolveUrl(record.doctorAvatar);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: avatarUrl.isNotEmpty
                    ? CachedRemoteImage(
                        avatarUrl,
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _MiniAvatar(name: record.displayDoctorName),
                      )
                    : _MiniAvatar(name: record.displayDoctorName),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.displayDoctorName,
                            style: TextStyle(
                              color: palette.primaryText,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StatusBadge(status: record.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (record.doctorTitle.isNotEmpty ||
                        record.doctorHospital.isNotEmpty)
                      Text(
                        [
                          if (record.doctorTitle.isNotEmpty) record.doctorTitle,
                          if (record.doctorHospital.isNotEmpty)
                            record.doctorHospital,
                        ].join(' / '),
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${record.appointDate}  ${record.appointTimeSlot}',
                      style: TextStyle(
                        color: palette.bodyText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_meetTypeLabel(context, record.meetType)} · ${_displayPrice(record)}',
                      style: const TextStyle(
                        color: Color(0xFFFF9585),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (record.meetLink.trim().isNotEmpty ||
              record.remark.trim().isNotEmpty ||
              record.confirmRemark.trim().isNotEmpty ||
              record.cancelReason.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: palette.softBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.meetLink.trim().isNotEmpty)
                    _MetaLine(
                      label: _t(context, '接诊信息', 'Meeting'),
                      value: record.meetLink,
                    ),
                  if (record.remark.trim().isNotEmpty)
                    _MetaLine(
                      label: _t(context, '预约备注', 'Remark'),
                      value: record.remark,
                    ),
                  if (record.confirmRemark.trim().isNotEmpty)
                    _MetaLine(
                      label: _t(context, '医生备注', 'Doctor note'),
                      value: record.confirmRemark,
                    ),
                  if (record.cancelReason.trim().isNotEmpty)
                    _MetaLine(
                      label: _t(context, '取消原因', 'Cancel reason'),
                      value: record.cancelReason,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton(
                onPressed: () =>
                    context.push('/appointments/doctors/${record.doctorId}'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFC7BC)),
                ),
                child: Text(_t(context, '查看医生', 'View doctor')),
              ),
              const Spacer(),
              if (record.meetLink.trim().isNotEmpty &&
                  (record.status == 1 || record.status == 2))
                TextButton(
                  onPressed: () => _openMeetLink(context, record.meetLink),
                  child: Text(_t(context, '打开链接', 'Open link')),
                ),
              if (record.status == 0 || record.status == 1)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9585),
                  ),
                  onPressed: () => _cancelAppointment(context, ref, record),
                  child: Text(_t(context, '取消预约', 'Cancel booking')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayPrice(AppointmentRecord record) {
    final formatted = record.price.toStringAsFixed(
      record.price.truncateToDouble() == record.price ? 0 : 2,
    );
    return '${record.currency.isEmpty ? 'USD' : record.currency} $formatted';
  }

  Future<void> _openMeetLink(BuildContext context, String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      context.showCenteredNotice(_t(context, '链接无效', 'Invalid link'));
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showCenteredNotice(
        _t(context, '无法打开接诊链接', 'Unable to open meeting link'),
      );
    }
  }

  Future<void> _cancelAppointment(
    BuildContext context,
    WidgetRef ref,
    AppointmentRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text(_t(context, '取消预约', 'Cancel booking')),
        content: Text(
          _t(
            context,
            '确认取消 ${record.appointDate} ${record.appointTimeSlot} 的预约吗？',
            'Cancel the booking on ${record.appointDate} ${record.appointTimeSlot}?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t(context, '保留', 'Keep')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(_t(context, '确认取消', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .cancelAppointment(appointmentId: record.id);
      ref.invalidate(appointmentMineProvider);
      if (context.mounted) {
        context.showCenteredNotice(_t(context, '已取消预约', 'Booking canceled'));
      }
    } on Object catch (error) {
      if (context.mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentListPalette.of(context);
    return Container(
      width: 86,
      height: 86,
      color: palette.avatarBackground,
      alignment: Alignment.center,
      child: Text(
        name.characters.first,
        style: TextStyle(
          color: palette.secondaryText,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final palette = switch (status) {
      1 => (const Color(0xFFE7F0FF), const Color(0xFF4F7BDE)),
      2 => (const Color(0xFFFFF1EE), const Color(0xFFFF8D7F)),
      3 => (const Color(0xFFF2F4F7), const Color(0xFF8E95A0)),
      4 => (const Color(0xFFFDECEC), const Color(0xFFDA6B6B)),
      _ => (const Color(0xFFFFF4E5), const Color(0xFFDD9A38)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(context, status),
        style: TextStyle(
          color: palette.$2,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentListPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: TextStyle(color: palette.bodyText, fontSize: 14, height: 1.55),
          children: [
            TextSpan(
              text: '$label：',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _AppointmentEmptyCard extends StatelessWidget {
  const _AppointmentEmptyCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentListPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_rounded,
            size: 36,
            color: Color(0xFFFFB4A8),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _AppointmentListSkeleton extends StatelessWidget {
  const _AppointmentListSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentListPalette.of(context);
    return Column(
      children: List<Widget>.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 198,
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

List<({int? status, String label})> _statusFilters(BuildContext context) {
  return [
    (status: null, label: _t(context, '全部', 'All')),
    (status: 0, label: _t(context, '待确认', 'Pending')),
    (status: 1, label: _t(context, '已确认', 'Confirmed')),
    (status: 2, label: _t(context, '已完成', 'Completed')),
    (status: 3, label: _t(context, '已取消', 'Canceled')),
    (status: 4, label: _t(context, '已拒绝', 'Rejected')),
  ];
}

String _statusLabel(BuildContext context, int status) {
  switch (status) {
    case 1:
      return _t(context, '已确认', 'Confirmed');
    case 2:
      return _t(context, '已完成', 'Completed');
    case 3:
      return _t(context, '已取消', 'Canceled');
    case 4:
      return _t(context, '已拒绝', 'Rejected');
    default:
      return _t(context, '待确认', 'Pending');
  }
}

String _meetTypeLabel(BuildContext context, String value) {
  switch (value) {
    case 'phone':
      return _t(context, '电话', 'Phone');
    case 'address':
      return _t(context, '线下', 'In person');
    case 'link':
      return _t(context, '线上', 'Online');
    default:
      return _t(context, '待确认', 'TBD');
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _AppointmentListPalette {
  const _AppointmentListPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.avatarBackground,
    required this.chipBackground,
    required this.chipSelectedBackground,
    required this.chipSelectedText,
    required this.primaryText,
    required this.secondaryText,
    required this.bodyText,
    required this.outline,
  });

  factory _AppointmentListPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _AppointmentListPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      avatarBackground: isDark
          ? scheme.surfaceContainerHigh
          : const Color(0xFFEDEFF4),
      chipBackground: scheme.surfaceContainerLow,
      chipSelectedBackground: isDark
          ? const Color(0x33FF9585)
          : const Color(0xFFFFE1DB),
      chipSelectedText: isDark
          ? const Color(0xFFFFB4A8)
          : const Color(0xFFFF7C69),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF4D5562),
      outline: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color avatarBackground;
  final Color chipBackground;
  final Color chipSelectedBackground;
  final Color chipSelectedText;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
  final Color outline;
}
