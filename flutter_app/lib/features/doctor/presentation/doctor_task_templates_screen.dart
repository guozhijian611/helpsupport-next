import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/centered_notice.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorTaskTemplatesScreen extends ConsumerStatefulWidget {
  const DoctorTaskTemplatesScreen({super.key});

  @override
  ConsumerState<DoctorTaskTemplatesScreen> createState() =>
      _DoctorTaskTemplatesScreenState();
}

class _DoctorTaskTemplatesScreenState
    extends ConsumerState<DoctorTaskTemplatesScreen> {
  String _selectedFolderId = '';
  _TemplateSourceFilter _sourceFilter = _TemplateSourceFilter.all;
  bool _creatingFolder = false;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    final folders = ref.watch(doctorTaskTemplateFoldersProvider);
    final templates = ref.watch(
      doctorTaskTemplatesProvider(
        DoctorTaskTemplatesQuery(folderId: _selectedFolderId),
      ),
    );

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '任务模板', 'Task templates')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorTaskTemplateFoldersProvider);
            ref.invalidate(doctorTaskTemplatesProvider);
            await Future.wait([
              ref.read(doctorTaskTemplateFoldersProvider.future),
              ref.read(
                doctorTaskTemplatesProvider(
                  DoctorTaskTemplatesQuery(folderId: _selectedFolderId),
                ).future,
              ),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              OutlinedButton.icon(
                onPressed: _creatingFolder ? null : _createFolder,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  side: const BorderSide(color: Color(0xFF5A81DA)),
                  foregroundColor: const Color(0xFF5A81DA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _t(context, '添加模板文件夹', 'Add template folder'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              _SourceFilterBar(
                value: _sourceFilter,
                onChanged: (value) {
                  setState(() {
                    _sourceFilter = value;
                    _selectedFolderId = '';
                  });
                },
              ),
              const SizedBox(height: 14),
              folders.when(
                data: (items) {
                  final visibleItems = items
                      .where((item) => _matchesSource(item.doctorId))
                      .toList(growable: false);
                  if (visibleItems.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      padding: const EdgeInsets.only(right: 24),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        final selected = item.id == _selectedFolderId;
                        return ChoiceChip(
                          label: _FolderChipLabel(
                            folder: item,
                            selected: selected,
                          ),
                          selected: selected,
                          onSelected: (_) => setState(
                            () => _selectedFolderId = selected ? '' : item.id,
                          ),
                          selectedColor: const Color(0xFFFFE1DB),
                          backgroundColor: palette.cardBackground,
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFFFF7C69)
                                : palette.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemCount: visibleItems.length,
                    ),
                  );
                },
                error: (_, _) => const SizedBox.shrink(),
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              templates.when(
                data: (items) {
                  final visibleItems = items
                      .where((item) => _matchesSource(item.doctorId))
                      .toList(growable: false);
                  if (visibleItems.isEmpty) {
                    return _EmptyBlock(
                      title: _t(context, '还没有任务模板', 'No task templates'),
                      subtitle: _t(
                        context,
                        '管理员维护或医生端发布后，模板会同步显示在这里。',
                        'Templates will appear here after they are published.',
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final template in visibleItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _TemplateCard(
                            template: template,
                            onTap: () => _openTemplateDetail(template),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, _) => _EmptyBlock(
                  title: _t(context, '加载失败', 'Load failed'),
                  subtitle: error.toString(),
                ),
                loading: () => const _ListSkeleton(count: 4, height: 148),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesSource(int doctorId) {
    return switch (_sourceFilter) {
      _TemplateSourceFilter.all => true,
      _TemplateSourceFilter.system => doctorId == 0,
      _TemplateSourceFilter.mine => doctorId > 0,
    };
  }

  Future<void> _openTemplateDetail(DoctorTaskTemplate template) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TemplateDetailSheet(template: template),
    );
  }

  Future<void> _createFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CreateTemplateFolderDialog(),
    );
    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    setState(() => _creatingFolder = true);
    try {
      final folder = await ref
          .read(doctorRepositoryProvider)
          .saveTaskTemplateFolder(name: name);
      if (!mounted) {
        return;
      }
      setState(() {
        _sourceFilter = _TemplateSourceFilter.mine;
        _selectedFolderId = folder.id;
      });
      ref.invalidate(doctorTaskTemplateFoldersProvider);
      ref.invalidate(doctorTaskTemplatesProvider);
      context.showCenteredNotice(
        _t(context, '模板文件夹已添加', 'Template folder created'),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _creatingFolder = false);
      }
    }
  }
}

class _CreateTemplateFolderDialog extends StatefulWidget {
  const _CreateTemplateFolderDialog();

  @override
  State<_CreateTemplateFolderDialog> createState() =>
      _CreateTemplateFolderDialogState();
}

class _CreateTemplateFolderDialogState
    extends State<_CreateTemplateFolderDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t(context, '添加模板文件夹', 'Add template folder')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: _t(context, '请输入文件夹名称', 'Enter a folder name'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_t(context, '取消', 'Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_t(context, '确定', 'Confirm')),
        ),
      ],
    );
  }
}

enum _TemplateSourceFilter { all, system, mine }

class _SourceFilterBar extends StatelessWidget {
  const _SourceFilterBar({required this.value, required this.onChanged});

  final _TemplateSourceFilter value;
  final ValueChanged<_TemplateSourceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SourceFilterButton(
            label: _t(context, '全部', 'All'),
            selected: value == _TemplateSourceFilter.all,
            onTap: () => onChanged(_TemplateSourceFilter.all),
          ),
          _SourceFilterButton(
            label: _t(context, '系统预设', 'System'),
            selected: value == _TemplateSourceFilter.system,
            onTap: () => onChanged(_TemplateSourceFilter.system),
          ),
          _SourceFilterButton(
            label: _t(context, '我的创建', 'Mine'),
            selected: value == _TemplateSourceFilter.mine,
            onTap: () => onChanged(_TemplateSourceFilter.mine),
          ),
        ],
      ),
    );
  }
}

class _SourceFilterButton extends StatelessWidget {
  const _SourceFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFF5A81DA) : palette.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderChipLabel extends StatelessWidget {
  const _FolderChipLabel({required this.folder, required this.selected});

  final DoctorTaskTemplateFolder folder;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? const Color(0xFFFF7C69)
        : _DoctorTaskTemplatesPalette.of(context).mutedText;
    final sourceColor = folder.doctorId == 0
        ? const Color(0xFF5A81DA)
        : const Color(0xFFFF9585);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(folder.name),
        const SizedBox(width: 6),
        Text(
          folder.doctorId == 0
              ? _t(context, '系统', 'Sys')
              : _t(context, '我的', 'Mine'),
          style: TextStyle(
            color: selected ? textColor : sourceColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final DoctorTaskTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    final color = _parseColor(template.color, const Color(0xFF5A81DA));
    return Material(
      color: palette.cardBackground,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      template.title,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SourceBadge(isSystem: template.doctorId == 0),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: palette.mutedText),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                template.description.isEmpty
                    ? _t(
                        context,
                        '模板会记录固定时段、频率和奖励积分，方便后续批量配置给患者。',
                        'Templates store schedule, frequency, and reward settings for reuse.',
                      )
                    : template.description,
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Pill(
                    label: template.stage.isEmpty
                        ? _t(context, '未分阶段', 'No stage')
                        : template.stage,
                  ),
                  _Pill(label: '${template.startTime}-${template.endTime}'),
                  _Pill(
                    label: template.frequency.isEmpty
                        ? 'daily'
                        : template.frequency,
                  ),
                  _Pill(
                    label: _t(
                      context,
                      '积分 ${template.rewardScore}',
                      'Score ${template.rewardScore}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateDetailSheet extends StatelessWidget {
  const _TemplateDetailSheet({required this.template});

  final DoctorTaskTemplate template;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    final color = _parseColor(template.color, const Color(0xFF5A81DA));
    return FractionallySizedBox(
      heightFactor: 0.76,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.pageBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: palette.softBackground,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              style: TextStyle(
                                color: palette.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _SourceBadge(isSystem: template.doctorId == 0),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _TemplateDetailGrid(template: template),
                  if (template.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _TemplateDetailBlock(
                      title: _t(context, '模板说明', 'Description'),
                      child: Text(
                        template.description,
                        style: TextStyle(
                          color: palette.mutedText,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateDetailGrid extends StatelessWidget {
  const _TemplateDetailGrid({required this.template});

  final DoctorTaskTemplate template;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _TemplateDetailMetric(
          label: _t(context, '阶段', 'Stage'),
          value: template.stage.isEmpty
              ? _t(context, '未分阶段', 'No stage')
              : template.stage,
        ),
        _TemplateDetailMetric(
          label: _t(context, '类型', 'Type'),
          value: template.taskType,
        ),
        _TemplateDetailMetric(
          label: _t(context, '优先级', 'Priority'),
          value: template.priority,
        ),
        _TemplateDetailMetric(
          label: _t(context, '时间', 'Time'),
          value: '${template.startTime}-${template.endTime}',
        ),
        _TemplateDetailMetric(
          label: _t(context, '频率', 'Frequency'),
          value: template.frequency,
        ),
        _TemplateDetailMetric(
          label: _t(context, '积分', 'Score'),
          value: '${template.rewardScore}',
        ),
      ],
    );
  }
}

class _TemplateDetailMetric extends StatelessWidget {
  const _TemplateDetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    return Container(
      width: (MediaQuery.sizeOf(context).width - 56) / 2,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '--' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateDetailBlock extends StatelessWidget {
  const _TemplateDetailBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.isSystem});

  final bool isSystem;

  @override
  Widget build(BuildContext context) {
    final label = isSystem
        ? _t(context, '系统预设', 'System')
        : _t(context, '我的创建', 'Mine');
    final color = isSystem ? const Color(0xFF5A81DA) : const Color(0xFFFF9585);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5A81DA),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            title,
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
              color: palette.mutedText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.count, required this.height});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskTemplatesPalette.of(context);
    return Column(
      children: List<Widget>.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String value, Color fallback) {
  final hex = value.replaceAll('#', '').trim();
  if (hex.length == 6) {
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) {
      return Color(0xFF000000 | parsed);
    }
  }
  return fallback;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _DoctorTaskTemplatesPalette {
  const _DoctorTaskTemplatesPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.primaryText,
    required this.mutedText,
  });

  factory _DoctorTaskTemplatesPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorTaskTemplatesPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color mutedText;
}
