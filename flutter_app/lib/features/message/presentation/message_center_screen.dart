import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/message_controller.dart';
import '../data/message_models.dart';

class MessageCenterScreen extends ConsumerStatefulWidget {
  const MessageCenterScreen({super.key});

  @override
  ConsumerState<MessageCenterScreen> createState() =>
      _MessageCenterScreenState();
}

class _MessageCenterScreenState extends ConsumerState<MessageCenterScreen> {
  bool _unreadOnly = false;
  bool _markingAll = false;

  MessageQuery get _query =>
      MessageQuery(isRead: _unreadOnly ? 2 : null, pageSize: 50);

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messageListProvider(_query));
    final unreadCount = ref.watch(unreadMessageCountProvider);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final unreadValue = unreadCount.asData?.value ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(_t(context, '消息中心', 'Messages')),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: unreadValue <= 0 || _markingAll ? null : _markAllRead,
            child: Text(_t(context, '全部已读', 'Mark all read')),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Row(
                children: [
                  _MessageFilterChip(
                    label: _t(context, '全部', 'All'),
                    selected: !_unreadOnly,
                    onTap: () => setState(() => _unreadOnly = false),
                  ),
                  const SizedBox(width: 10),
                  _MessageFilterChip(
                    label: unreadValue > 0
                        ? '${_t(context, '未读', 'Unread')} · $unreadValue'
                        : _t(context, '未读', 'Unread'),
                    selected: _unreadOnly,
                    onTap: () => setState(() => _unreadOnly = true),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              messages.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return _MessageEmptyState(unreadOnly: _unreadOnly);
                  }
                  return Column(
                    children: [
                      for (final item in page.list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MessageCard(
                            item: item,
                            onTap: () =>
                                _openMessage(session?.currentRole, item),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, _) => _MessageStatusCard(
                  title: _t(context, '加载失败', 'Load failed'),
                  subtitle: error.toString(),
                ),
                loading: () => const _MessageListSkeleton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(unreadMessageCountProvider);
    ref.invalidate(messageListProvider);
    await Future.wait([
      ref.read(unreadMessageCountProvider.future),
      ref.read(messageListProvider(_query).future),
    ]);
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ref.read(messageRepositoryProvider).readMessage(all: true);
      ref.invalidate(unreadMessageCountProvider);
      ref.invalidate(messageListProvider);
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  Future<void> _openMessage(String? role, MessageItem item) async {
    if (item.unread) {
      await ref.read(messageRepositoryProvider).readMessage(messageId: item.id);
      ref.invalidate(unreadMessageCountProvider);
      ref.invalidate(messageListProvider);
    }
    if (!mounted) {
      return;
    }

    final route = _resolveRoute(role, item);
    if (route == null) {
      return;
    }
    if (route.startsWith('/home')) {
      context.go(route);
      return;
    }
    context.push(route);
  }
}

class _MessageFilterChip extends StatelessWidget {
  const _MessageFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFFFE1DB),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFFF7C69) : const Color(0xFF7D828A),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.item, required this.onTap});

  final MessageItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = _messageScheme(item.messageType);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(scheme.icon, color: scheme.color),
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
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF303236),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (item.unread)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF9585),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.content.trim().isEmpty
                          ? _t(context, '点击查看消息详情', 'Tap to view the message')
                          : item.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D828A),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _messageTypeLabel(context, item.messageType),
                            style: TextStyle(
                              color: scheme.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(item.createTime),
                          style: const TextStyle(
                            color: Color(0xFFB0B3BA),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFB0B3BA),
                        ),
                      ],
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

class _MessageEmptyState extends StatelessWidget {
  const _MessageEmptyState({required this.unreadOnly});

  final bool unreadOnly;

  @override
  Widget build(BuildContext context) {
    return _MessageStatusCard(
      title: unreadOnly
          ? _t(context, '没有未读消息', 'No unread messages')
          : _t(context, '消息中心暂时为空', 'No messages yet'),
      subtitle: unreadOnly
          ? _t(
              context,
              '新的任务、预约和社区互动提醒会显示在这里。',
              'New task, appointment, and community alerts will appear here.',
            )
          : _t(
              context,
              '后续的系统提醒、社区互动和治疗通知都会汇总到这里。',
              'System alerts, community interactions, and care updates will appear here.',
            ),
    );
  }
}

class _MessageStatusCard extends StatelessWidget {
  const _MessageStatusCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7D828A),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageListSkeleton extends StatelessWidget {
  const _MessageListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 122,
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

class _MessageScheme {
  const _MessageScheme({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}

_MessageScheme _messageScheme(int type) {
  return switch (type) {
    1 => const _MessageScheme(
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF9585),
      background: Color(0xFFFFEEE9),
    ),
    2 => const _MessageScheme(
      icon: Icons.forum_rounded,
      color: Color(0xFF986FF5),
      background: Color(0xFFF0EAFF),
    ),
    3 => const _MessageScheme(
      icon: Icons.task_alt_rounded,
      color: Color(0xFF5A81DA),
      background: Color(0xFFEAF0FF),
    ),
    4 => const _MessageScheme(
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFFFAE4D),
      background: Color(0xFFFFF3E0),
    ),
    _ => const _MessageScheme(
      icon: Icons.notifications_active_rounded,
      color: Color(0xFFA4C3CC),
      background: Color(0xFFEFF6F8),
    ),
  };
}

String _messageTypeLabel(BuildContext context, int type) {
  return switch (type) {
    1 => _t(context, '关注提醒', 'Follow'),
    2 => _t(context, '互动回复', 'Replies'),
    3 => _t(context, '治疗任务', 'Tasks'),
    4 => _t(context, '预约更新', 'Appointments'),
    _ => _t(context, '系统通知', 'System'),
  };
}

String _formatTime(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) {
    return value;
  }
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes.clamp(1, 59)}m';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d';
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

String? _resolveRoute(String? role, MessageItem item) {
  if (item.messageType == 1 ||
      item.messageType == 2 ||
      item.bizType.startsWith('community_')) {
    return '/home?tab=community';
  }
  if (item.messageType == 3) {
    return role == 'doctor' ? '/doctor/plan' : '/home?tab=plan';
  }
  if (item.messageType == 4) {
    return role == 'doctor' ? '/doctor/patients' : '/appointments/mine';
  }
  if (item.bizType == 'doctor_profile') {
    return '/me/settings';
  }
  return null;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
