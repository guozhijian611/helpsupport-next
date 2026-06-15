import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';

class CommunityPostEditorScreen extends ConsumerStatefulWidget {
  const CommunityPostEditorScreen({super.key});

  @override
  ConsumerState<CommunityPostEditorScreen> createState() =>
      _CommunityPostEditorScreenState();
}

class _CommunityPostEditorScreenState
    extends ConsumerState<CommunityPostEditorScreen> {
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  final Set<int> _selectedTagIds = <int>{};

  @override
  void dispose() {
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(communityTagsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(title: Text(context.l10n.communityNewPost)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _contentController,
                    minLines: 10,
                    maxLines: 16,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: context.l10n.communityPostHint,
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 30),
                  TextField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      labelText: _t(context, '可选链接', 'Optional link'),
                      hintText: 'https://',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t(context, '选择标签', 'Choose tags'),
                    style: const TextStyle(
                      color: Color(0xFF303236),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  tags.when(
                    data: (items) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in items.take(8))
                          _SelectableTagChip(
                            tag: tag,
                            selected: _selectedTagIds.contains(tag.id),
                            onTap: () => setState(() {
                              if (_selectedTagIds.contains(tag.id)) {
                                _selectedTagIds.remove(tag.id);
                              } else {
                                _selectedTagIds.add(tag.id);
                              }
                            }),
                          ),
                      ],
                    ),
                    error: (_, _) => Text(
                      _t(
                        context,
                        '标签加载失败，可直接发布纯文本。',
                        'Tags failed to load. You can still publish text only.',
                      ),
                      style: const TextStyle(color: Color(0xFF96999F)),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                title: Text(context.l10n.communityAnonymous),
                subtitle: Text(
                  _t(
                    context,
                    '匿名后不会展示昵称与头像，但仍保留审核和互动。',
                    'Anonymous posts hide your profile but keep moderation and engagement.',
                  ),
                ),
                onChanged: (value) => setState(() => _isAnonymous = value),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _submit(context),
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_outlined),
              label: Text(context.l10n.communityPublish),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      context.showCenteredNotice(context.l10n.communityPostHint);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final tags = await ref.read(communityTagsProvider.future);
      final selectedTags = tags
          .where((tag) => _selectedTagIds.contains(tag.id))
          .map((tag) => tag.name)
          .toList(growable: false);
      await ref
          .read(communityRepositoryProvider)
          .createPost(
            content: content,
            isAnonymous: _isAnonymous,
            tags: selectedTags,
            linkUrl: _linkController.text.trim(),
          );
      ref.invalidate(communityPostsProvider);
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(context.l10n.communityPendingReview);
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _SelectableTagChip extends StatelessWidget {
  const _SelectableTagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final CommunityTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('# ${tag.name}'),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFEEE9),
      checkmarkColor: const Color(0xFFFF9585),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFFF9585) : const Color(0xFF6B7380),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
