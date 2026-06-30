import 'package:flutter/material.dart';
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
        .clamp(320.0, 460.0)
        .toDouble();
    final query = DoctorPatientCandidatesQuery(
      keyword: _keyword,
      page: _page,
      pageSize: _pageSize,
    );
    final candidates = ref.watch(doctorPatientCandidatesProvider(query));

    return AlertDialog(
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
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: candidates.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        _t(context, '没有找到患者', 'No patients found'),
                        style: TextStyle(color: palette.mutedText),
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: page.list.length,
                          separatorBuilder: (_, _) =>
                              Divider(color: palette.outline, height: 1),
                          itemBuilder: (context, index) {
                            final patient = page.list[index];
                            return _CandidatePatientTile(
                              patient: patient,
                              onAdd: patient.isBound
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pop(patient.memberId),
                            );
                          },
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
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    error.toString(),
                    style: TextStyle(color: palette.mutedText),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
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
                    ? Image.network(
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipOval(
        child: avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _SmallPatientAvatar(),
              )
            : const _SmallPatientAvatar(),
      ),
      title: Text(
        patient.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.primaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        _t(
          context,
          'ID ${patient.memberId} · ${patient.genderLabel} · ${patient.ageLabel}岁',
          'ID ${patient.memberId} · ${patient.genderLabel} · age ${patient.ageLabel}',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: palette.secondaryText),
      ),
      trailing: FilledButton(
        onPressed: onAdd,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF9585),
          disabledBackgroundColor: palette.avatarBackground,
          disabledForegroundColor: palette.secondaryText,
        ),
        child: Text(
          patient.isBound
              ? _t(context, '已添加', 'Added')
              : _t(context, '添加', 'Add'),
        ),
      ),
    );
  }
}

class _SmallPatientAvatar extends StatelessWidget {
  const _SmallPatientAvatar();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPatientsPalette.of(context);
    return Container(
      width: 44,
      height: 44,
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
  });

  final int page;
  final int pageSize;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (total <= pageSize) {
      return const SizedBox.shrink();
    }

    final palette = _DoctorPatientsPalette.of(context);
    final pageCount = (total / pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
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
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: _t(context, '下一页', 'Next page'),
          ),
        ],
      ),
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
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color avatarBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color outline;
}
