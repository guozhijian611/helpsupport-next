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
  bool _creatingFolder = false;

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(doctorTaskTemplateFoldersProvider);
    final templates = ref.watch(
      doctorTaskTemplatesProvider(
        DoctorTaskTemplatesQuery(folderId: _selectedFolderId),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
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
              folders.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = item.id == _selectedFolderId;
                        return ChoiceChip(
                          label: Text(item.name),
                          selected: selected,
                          onSelected: (_) => setState(
                            () => _selectedFolderId = selected ? '' : item.id,
                          ),
                          selectedColor: const Color(0xFFFFE1DB),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFFFF7C69)
                                : const Color(0xFF7D828A),
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemCount: items.length,
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
                  if (items.isEmpty) {
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
                      for (final template in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _TemplateCard(template: template),
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

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, '添加模板文件夹', 'Add template folder')),
        content: TextField(
          controller: controller,
          autofocus: true,
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
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(_t(context, '确定', 'Confirm')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    setState(() => _creatingFolder = true);
    try {
      final folder = await ref
          .read(doctorRepositoryProvider)
          .saveTaskTemplateFolder(name: name);
      ref.invalidate(doctorTaskTemplateFoldersProvider);
      setState(() => _selectedFolderId = folder.id);
      ref.invalidate(doctorTaskTemplatesProvider);
      if (!mounted) {
        return;
      }
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final DoctorTaskTemplate template;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(template.color, const Color(0xFF5A81DA));
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  template.title,
                  style: const TextStyle(
                    color: Color(0xFF303236),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
            style: const TextStyle(
              color: Color(0xFF7D828A),
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8C919A),
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
    return Column(
      children: List<Widget>.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
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
