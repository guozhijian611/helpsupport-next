import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/app_providers.dart';
import '../application/appointment_controller.dart';
import '../data/appointment_models.dart';

class AppointmentDoctorListScreen extends ConsumerStatefulWidget {
  const AppointmentDoctorListScreen({super.key});

  @override
  ConsumerState<AppointmentDoctorListScreen> createState() =>
      _AppointmentDoctorListScreenState();
}

class _AppointmentDoctorListScreenState
    extends ConsumerState<AppointmentDoctorListScreen> {
  final _keywordController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentDoctorListPalette.of(context);
    final query = AppointmentDoctorQuery(keyword: _keyword);
    final doctors = ref.watch(appointmentDoctorListProvider(query));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '预约真人医生', 'Book a doctor')),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push('/appointments/mine'),
            child: Text(_t(context, '我的预约', 'My bookings')),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(appointmentDoctorListProvider(query));
            await ref.read(appointmentDoctorListProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _AppointmentSearchBar(
                controller: _keywordController,
                onSearch: () =>
                    setState(() => _keyword = _keywordController.text.trim()),
              ),
              const SizedBox(height: 18),
              doctors.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return _EmptyStateCard(
                      title: _t(context, '暂无可预约医生', 'No available doctors'),
                      subtitle: _t(
                        context,
                        '试试更换关键词，或稍后再查看新的预约排班。',
                        'Try another keyword or check back later for new schedules.',
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final doctor in page.list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _DoctorListCard(
                            doctor: doctor,
                            onTap: () => context.push(
                              '/appointments/doctors/${doctor.doctorId}',
                            ),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, _) => _EmptyStateCard(
                  title: _t(context, '加载失败', 'Load failed'),
                  subtitle: error.toString(),
                  actionLabel: _t(context, '重试', 'Retry'),
                  onAction: () {
                    ref.invalidate(appointmentDoctorListProvider(query));
                  },
                ),
                loading: () => const _DoctorListSkeleton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentSearchBar extends StatelessWidget {
  const _AppointmentSearchBar({
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentDoctorListPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: palette.outline),
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                hintText: _t(context, '输入关键词', 'Search doctor'),
                hintStyle: TextStyle(color: palette.secondaryText),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: palette.secondaryText,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: onSearch, child: Text(_t(context, '搜索', 'Go'))),
      ],
    );
  }
}

class _DoctorListCard extends ConsumerWidget {
  const _DoctorListCard({required this.doctor, required this.onTap});

  final AppointmentDoctor doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenPalette = _AppointmentDoctorListPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final avatarUrl = apiClient.resolveUrl(doctor.avatar);
    final subtitleParts = [
      if (doctor.title.isNotEmpty) doctor.title,
      if (doctor.hospital.isNotEmpty) doctor.hospital,
      if (doctor.department.isNotEmpty) doctor.department,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: screenPalette.cardBackground,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        width: 114,
                        height: 114,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _DoctorAvatarPlaceholder(doctor: doctor, size: 114),
                      )
                    : _DoctorAvatarPlaceholder(doctor: doctor, size: 114),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.displayName,
                      style: TextStyle(
                        color: screenPalette.primaryText,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' / '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: screenPalette.bodyText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      doctor.specialty.isEmpty
                          ? _t(
                              context,
                              '查看可预约时段并了解医生信息',
                              'View available times and profile',
                            )
                          : doctor.specialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: screenPalette.secondaryText,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9585),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onTap,
                        child: Text(_t(context, '预约', 'Book')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorAvatarPlaceholder extends StatelessWidget {
  const _DoctorAvatarPlaceholder({required this.doctor, required this.size});

  final AppointmentDoctor doctor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentDoctorListPalette.of(context);
    final initial = doctor.displayName.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      color: palette.avatarBackground,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: palette.secondaryText,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentDoctorListPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 34,
            color: Color(0xFFFFB4A8),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 20,
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DoctorListSkeleton extends StatelessWidget {
  const _DoctorListSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = _AppointmentDoctorListPalette.of(context);
    return Column(
      children: List<Widget>.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 146,
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

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _AppointmentDoctorListPalette {
  const _AppointmentDoctorListPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.avatarBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.bodyText,
    required this.outline,
  });

  factory _AppointmentDoctorListPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _AppointmentDoctorListPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      avatarBackground: isDark
          ? scheme.surfaceContainerHigh
          : const Color(0xFFEDEFF4),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF70757D),
      outline: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color avatarBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
  final Color outline;
}
