import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../application/community_controller.dart';

class CommunityPostEditorScreen extends ConsumerStatefulWidget {
  const CommunityPostEditorScreen({super.key});

  @override
  ConsumerState<CommunityPostEditorScreen> createState() =>
      _CommunityPostEditorScreenState();
}

class _CommunityPostEditorScreenState
    extends ConsumerState<CommunityPostEditorScreen> {
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.communityNewPost)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _contentController,
              minLines: 8,
              maxLines: 14,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: context.l10n.communityPostHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isAnonymous,
              title: Text(context.l10n.communityAnonymous),
              onChanged: (value) => setState(() => _isAnonymous = value),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.communityPostHint)));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .createPost(content: content, isAnonymous: _isAnonymous);
      ref.invalidate(communityPostsProvider);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.communityPendingReview)),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
