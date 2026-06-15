import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/centered_notice.dart';
import '../application/me_content_controller.dart';
import '../data/me_content_models.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final palette = _JournalPalette.of(context);
    final journals = ref.watch(journalEntriesProvider);
    final month = DateTime(_selectedDate.year, _selectedDate.month);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '日记', 'Journal')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: journals.when(
          data: (page) {
            final entries = page.list;
            final selectedKey = _dateKey(_selectedDate);
            final selectedEntries = entries
                .where((item) => item.entryDate == selectedKey)
                .toList(growable: false);
            final week = _weekDays(_selectedDate);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(journalEntriesProvider);
                await ref.read(journalEntriesProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                    decoration: BoxDecoration(
                      color: palette.cardBackground,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _MonthArrow(
                              icon: Icons.chevron_left_rounded,
                              onTap: () => setState(
                                () => _selectedDate = DateTime(
                                  month.year,
                                  month.month - 1,
                                  _selectedDate.day.clamp(1, 28),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  DateFormat('yyyy-MM').format(month),
                                  style: TextStyle(
                                    color: palette.primaryText,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            _MonthArrow(
                              icon: Icons.chevron_right_rounded,
                              onTap: () => setState(
                                () => _selectedDate = DateTime(
                                  month.year,
                                  month.month + 1,
                                  _selectedDate.day.clamp(1, 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            for (final label in const [
                              '日',
                              '一',
                              '二',
                              '三',
                              '四',
                              '五',
                              '六',
                            ])
                              Expanded(
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: palette.bodyText,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        for (final day in week) ...[
                          if (day == week.first)
                            Divider(color: palette.outline, height: 1),
                          const SizedBox(height: 10),
                          _WeekDayCell(
                            day: day,
                            isSelected: _dateKey(day) == selectedKey,
                            isToday: _dateKey(day) == _dateKey(DateTime.now()),
                            count: entries
                                .where(
                                  (item) => item.entryDate == _dateKey(day),
                                )
                                .length,
                            onTap: () => setState(() => _selectedDate = day),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: palette.secondaryText,
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  if (selectedEntries.isEmpty)
                    _JournalEmptyPanel(
                      date: _selectedDate,
                      onCreate: () => _openEditor(context),
                    )
                  else
                    _TimelineList(
                      entries: selectedEntries,
                      onTap: (entry) => _openEditor(context, entry: entry),
                    ),
                ],
              ),
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5A81DA),
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          onPressed: () => _openEditor(context),
          child: Text(
            _t(context, '开始记录', 'Start journaling'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  List<DateTime> _weekDays(DateTime selected) {
    final weekday = selected.weekday % 7;
    final start = DateTime(
      selected.year,
      selected.month,
      selected.day,
    ).subtract(Duration(days: weekday));
    return List<DateTime>.generate(
      7,
      (index) => start.add(Duration(days: index)),
      growable: false,
    );
  }

  Future<void> _openEditor(BuildContext context, {JournalEntry? entry}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JournalEditorSheet(
        initialDate: entry != null
            ? DateTime.tryParse(entry.entryDate) ?? _selectedDate
            : _selectedDate,
        entry: entry,
      ),
    );
    if (saved == true) {
      ref.invalidate(journalEntriesProvider);
    }
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _JournalPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: palette.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: palette.secondaryText),
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.count,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _JournalPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF5A81DA)
                        : (day.month == DateTime.now().month
                              ? palette.primaryText
                              : palette.mutedText),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1877F2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (isSelected)
                      Text(
                        isToday ? _t(context, '今日', 'Today') : '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Text(
                        count <= 0
                            ? _t(context, '无记录', 'No entry')
                            : _t(context, '$count条记录', '$count entries'),
                        style: TextStyle(
                          color: palette.bodyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.entries, required this.onTap});

  final List<JournalEntry> entries;
  final ValueChanged<JournalEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index += 1)
          _TimelineItem(
            entry: entries[index],
            isLast: index == entries.length - 1,
            onTap: () => onTap(entries[index]),
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.isLast,
    required this.onTap,
  });

  final JournalEntry entry;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _JournalPalette.of(context);
    return SizedBox(
      height: 172,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF5A81DA),
                      width: 4,
                    ),
                    color: palette.cardBackground,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 3, color: const Color(0xFFBED0FB)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.entryDateTimeLabel,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.primaryText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  entry.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.secondaryText,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFC0C3CA),
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEmptyPanel extends StatelessWidget {
  const _JournalEmptyPanel({required this.date, required this.onCreate});

  final DateTime date;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = _JournalPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            _t(
              context,
              '${_dateKey(date)} 还没有记录',
              'No journal entry on ${_dateKey(date)}',
            ),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              context,
              '开始记录一次聊天感受、今天的触发点，或者恢复过程里的细小变化。',
              'Record a conversation reflection, today\'s trigger, or a small recovery change.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.secondaryText, height: 1.55),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onCreate,
            child: Text(_t(context, '立即记录', 'Write now')),
          ),
        ],
      ),
    );
  }
}

class _JournalEditorSheet extends ConsumerStatefulWidget {
  const _JournalEditorSheet({required this.initialDate, this.entry});

  final DateTime initialDate;
  final JournalEntry? entry;

  @override
  ConsumerState<_JournalEditorSheet> createState() =>
      _JournalEditorSheetState();
}

class _JournalEditorSheetState extends ConsumerState<_JournalEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _date = widget.entry != null
        ? DateTime.tryParse(widget.entry!.entryDate) ?? widget.initialDate
        : widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _JournalPalette.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  _t(context, '记录', 'Record'),
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _t(context, '标题', 'Title'),
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _EditorField(
                controller: _titleController,
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Text(
                _t(context, '内容', 'Content'),
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _EditorField(
                controller: _contentController,
                minLines: 7,
                maxLines: 8,
              ),
              const SizedBox(height: 18),
              Text(
                _t(context, '记录日期', 'Entry date'),
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickDate,
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: palette.softBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _dateKey(_date),
                        style: TextStyle(
                          color: palette.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(_t(context, '取消', 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5A81DA),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_t(context, '记录', 'Save')),
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

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (result == null) {
      return;
    }
    setState(() => _date = result);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      context.showCenteredNotice(_t(context, '请先填写标题', 'Please enter a title'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(meContentRepositoryProvider)
          .saveJournal(
            id: widget.entry?.id,
            entryDate: _dateKey(_date),
            entryTime:
                widget.entry?.entryTime ??
                DateFormat('HH:mm').format(DateTime.now()),
            title: title,
            content: content,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.minLines,
    required this.maxLines,
  });

  final TextEditingController controller;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = _JournalPalette.of(context);
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.softBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _JournalPalette {
  const _JournalPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.bodyText,
    required this.mutedText,
    required this.outline,
  });

  factory _JournalPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _JournalPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF6B7078),
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
          : const Color(0xFFD0D3DA),
      outline: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
  final Color mutedText;
  final Color outline;
}
