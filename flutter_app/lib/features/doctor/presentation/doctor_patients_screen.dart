import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() =>
      _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  static const _pageSize = 10;

  final _searchController = TextEditingController();
  String _keyword = '';
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    final query = DoctorPatientsQuery(
      keyword: _keyword,
      page: _page,
      pageSize: _pageSize,
    );
    final patients = ref.watch(doctorPatientsProvider(query));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '我的患者', 'My patients')),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openAddPatientDialog,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorPatientsProvider(query));
            await ref.read(doctorPatientsProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _SearchBar(
                controller: _searchController,
                onSearch: () => setState(() {
                  _keyword = _searchController.text.trim();
                  _page = 1;
                }),
              ),
              const SizedBox(height: 18),
              patients.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return _EmptyCard(
                      title: _t(context, '还没有绑定患者', 'No patients yet'),
                      subtitle: _t(
                        context,
                        '通过右上角添加患者后，这里会显示你的患者列表。',
                        'Add a patient from the top-right action to build your patient list.',
                      ),
                      actionLabel: _t(context, '添加患者', 'Add patient'),
                      onAction: _openAddPatientDialog,
                    );
                  }
                  return Column(
                    children: [
                      for (final patient in page.list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PatientCard(
                            patient: patient,
                            onOpen: () => context.push(
                              '/doctor/plan?memberId=${patient.memberId}',
                            ),
                            onDelete: () => _unbindPatient(patient),
                          ),
                        ),
                      _PatientPager(
                        page: page.page,
                        pageSize: page.pageSize,
                        total: page.total,
                        onPrev: page.page > 1
                            ? () => setState(() => _page -= 1)
                            : null,
                        onNext: page.page * page.pageSize < page.total
                            ? () => setState(() => _page += 1)
                            : null,
                      ),
                    ],
                  );
                },
                error: (error, _) => _EmptyCard(
                  title: _t(context, '加载失败', 'Load failed'),
                  subtitle: error.toString(),
                  actionLabel: _t(context, '重试', 'Retry'),
                  onAction: () => ref.invalidate(doctorPatientsProvider(query)),
                ),
                loading: () => const _PatientsSkeleton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unbindPatient(DoctorPatient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(dialogContext, '解绑患者', 'Remove patient')),
        content: Text(
          _t(
            dialogContext,
            '确认将 ${patient.displayName} 从你的患者列表中移除吗？',
            'Remove ${patient.displayName} from your patient list?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t(dialogContext, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(_t(dialogContext, '确认', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(doctorRepositoryProvider).unbindPatient(patient.memberId);
      ref.invalidate(doctorPatientsProvider);
      if (mounted) {
        context.showCenteredNotice(_t(context, '患者已解绑', 'Patient removed'));
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  Future<void> _openAddPatientDialog() async {
    final memberId = await showDialog<int>(
      context: context,
      builder: (_) => const _AddPatientDialog(),
    );
    if (memberId == null || !mounted) {
      return;
    }
    if (memberId <= 0) {
      context.showCenteredNotice(
        _t(context, '请输入有效患者ID', 'Enter a valid patient ID'),
      );
      return;
    }
    try {
      await ref.read(doctorRepositoryProvider).bindPatient(memberId);
      ref.invalidate(doctorPatientsProvider);
      ref.invalidate(doctorPatientCandidatesProvider);
      if (mounted) {
        context.showCenteredNotice(_t(context, '患者已添加', 'Patient added'));
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }
}

class _AddPatientDialog extends ConsumerStatefulWidget {
  const _AddPatientDialog();

  @override
  ConsumerState<_AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends ConsumerState<_AddPatientDialog> {
  static const _pageSize = 6;

  final _controller = TextEditingController();
  String _keyword = '';
  int _page = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    final contentHeight = (MediaQuery.sizeOf(context).height * 0.56)
        .clamp(360.0, 500.0)
        .toDouble();
    final query = DoctorPatientCandidatesQuery(
      keyword: _keyword,
      page: _page,
      pageSize: _pageSize,
    );
    final candidates = ref.watch(doctorPatientCandidatesProvider(query));
    final page = candidates.maybeWhen<DoctorPage<DoctorPatient>?>(
      data: (page) => page,
      orElse: () => null,
    );

    return AlertDialog(
      backgroundColor: palette.cardBackground,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(_t(context, '添加患者', 'Add patient')),
      content: SizedBox(
        width: 360,
        height: contentHeight,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: _t(
                  context,
                  '搜索患者ID、昵称或用户名',
                  'Search patient ID, nickname, or username',
                ),
                filled: true,
                fillColor: palette.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: palette.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: palette.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF9585),
                    width: 1.2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFFF9585),
                ),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFFF9585),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: candidates.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return Center(
                      child: _DialogMessage(
                        icon: Icons.search_off_rounded,
                        text: _t(context, '没有找到患者', 'No patients found'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: page.list.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: palette.outline, height: 1),
                    itemBuilder: (context, index) {
                      final patient = page.list[index];
                      return _CandidatePatientTile(
                        patient: patient,
                        onAdd: patient.isBound
                            ? null
                            : () => Navigator.of(context).pop(patient.memberId),
                      );
                    },
                  );
                },
                error: (error, _) => Center(
                  child: _DialogMessage(
                    icon: Icons.error_outline_rounded,
                    text: error.toString(),
                  ),
                ),
                loading: () => const _CandidateLoadingList(),
              ),
            ),
            _PatientPager(
              page: page?.page ?? _page,
              pageSize: page?.pageSize ?? _pageSize,
              total: page?.total ?? 0,
              compact: true,
              onPrev: page != null && page.page > 1
                  ? () => setState(() => _page -= 1)
                  : null,
              onNext: page != null && page.page * page.pageSize < page.total
                  ? () => setState(() => _page += 1)
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_t(context, '取消', 'Cancel')),
        ),
      ],
    );
  }

  void _search() {
    setState(() {
      _keyword = _controller.text.trim();
      _page = 1;
    });
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
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
                hintText: _t(context, '开始探索', 'Search patient'),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: palette.secondaryText,
                ),
                hintStyle: TextStyle(color: palette.secondaryText),
              ),
              style: TextStyle(color: palette.primaryText),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientCard extends ConsumerWidget {
  const _PatientCard({
    required this.patient,
    required this.onOpen,
    required this.onDelete,
  });

  final DoctorPatient patient;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _DoctorPatientsPalette.of(context);
    final avatarUrl = ref.watch(apiClientProvider).resolveUrl(patient.avatar);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              ClipOval(
                child: avatarUrl.isNotEmpty
                    ? CachedRemoteImage(
                        avatarUrl,
                        width: 66,
                        height: 66,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _PatientAvatarPlaceholder(),
                      )
                    : const _PatientAvatarPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.displayName,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        _Meta(
                          label: _t(context, '年龄', 'Age'),
                          value: patient.ageLabel,
                        ),
                        _Meta(
                          label: _t(context, '性别', 'Gender'),
                          value: patient.genderLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFF29B87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidatePatientTile extends ConsumerWidget {
  const _CandidatePatientTile({required this.patient, required this.onAdd});

  final DoctorPatient patient;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _DoctorPatientsPalette.of(context);
    final avatarUrl = ref.watch(apiClientProvider).resolveUrl(patient.avatar);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: avatarUrl.isNotEmpty
                ? CachedRemoteImage(
                    avatarUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _SmallPatientAvatar(),
                  )
                : const _SmallPatientAvatar(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _CandidateInfoChip(label: 'ID ${patient.memberId}'),
                    _CandidateInfoChip(label: patient.genderLabel),
                    _CandidateInfoChip(
                      label: patient.ageLabel == '--'
                          ? _t(context, '年龄未知', 'Age unknown')
                          : _t(
                              context,
                              '${patient.ageLabel}岁',
                              'Age ${patient.ageLabel}',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            height: 44,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFFFF9585),
                disabledBackgroundColor: palette.avatarBackground,
                disabledForegroundColor: palette.secondaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  patient.isBound
                      ? _t(context, '已添加', 'Added')
                      : _t(context, '添加', 'Add'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateInfoChip extends StatelessWidget {
  const _CandidateInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: palette.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
    );
  }
}

class _CandidateLoadingList extends StatelessWidget {
  const _CandidateLoadingList();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => Divider(color: palette.outline, height: 1),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const _LoadingBlock(width: 48, height: 48, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _LoadingBlock(width: 120, height: 16, radius: 8),
                    SizedBox(height: 10),
                    _LoadingBlock(width: 180, height: 14, radius: 7),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const _LoadingBlock(width: 66, height: 44, radius: 16),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.inputBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _SmallPatientAvatar extends StatelessWidget {
  const _SmallPatientAvatar();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return Container(
      width: 48,
      height: 48,
      color: palette.avatarBackground,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: palette.secondaryText),
    );
  }
}

class _PatientAvatarPlaceholder extends StatelessWidget {
  const _PatientAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return Container(
      width: 66,
      height: 66,
      color: palette.avatarBackground,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: palette.secondaryText),
    );
  }
}

class _PatientPager extends StatelessWidget {
  const _PatientPager({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPrev,
    required this.onNext,
    this.compact = false,
  });

  final int page;
  final int pageSize;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (total <= pageSize) {
      return const SizedBox.shrink();
    }

    final palette = _DoctorPatientsPalette.of(context);
    final pageCount = (total / pageSize).ceil();
    return Padding(
      padding: EdgeInsets.only(top: compact ? 12 : 4, bottom: compact ? 4 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PagerButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: _t(context, '上一页', 'Previous page'),
          ),
          Text(
            _t(context, '第 $page / $pageCount 页', 'Page $page / $pageCount'),
            style: TextStyle(
              color: palette.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          _PagerButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: _t(context, '下一页', 'Next page'),
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final Icon icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      color: const Color(0xFFFF9585),
      disabledColor: palette.secondaryText.withValues(alpha: 0.36),
      style: IconButton.styleFrom(
        fixedSize: const Size(38, 38),
        backgroundColor: const Color(0xFFFF9585).withValues(alpha: 0.08),
        disabledBackgroundColor: palette.inputBackground,
      ),
    );
  }
}

class _DialogMessage extends StatelessWidget {
  const _DialogMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 34, color: palette.secondaryText),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.2),
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              color: palette.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: value,
            style: TextStyle(
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
  const _EmptyCard({
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
    final palette = _DoctorPatientsPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.group_add_rounded,
            size: 36,
            color: Color(0xFF5A81DA),
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
              color: palette.mutedText,
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

class _PatientsSkeleton extends StatelessWidget {
  const _PatientsSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return Column(
      children: List<Widget>.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 114,
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

class _DoctorPatientsPalette {
  const _DoctorPatientsPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.avatarBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.outline,
    required this.inputBackground,
  });

  factory _DoctorPatientsPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorPatientsPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      avatarBackground: isDark
          ? scheme.surfaceContainerHigh
          : const Color(0xFFEDEFF4),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF8C919A),
      outline: scheme.outlineVariant,
      inputBackground: isDark
          ? scheme.surfaceContainerHigh
          : const Color(0xFFF6F7FB),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color avatarBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color outline;
  final Color inputBackground;
}
