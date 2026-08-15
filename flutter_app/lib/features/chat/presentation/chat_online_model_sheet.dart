import 'package:flutter/material.dart';

import '../data/chat_models.dart';

Future<OnlineChatModel?> showOnlineChatModelSheet(
  BuildContext context, {
  required List<OnlineChatModel> models,
  required int selectedModelId,
}) {
  return showModalBottomSheet<OnlineChatModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _OnlineChatModelSheet(models: models, selectedModelId: selectedModelId),
  );
}

class _OnlineChatModelSheet extends StatefulWidget {
  const _OnlineChatModelSheet({
    required this.models,
    required this.selectedModelId,
  });

  final List<OnlineChatModel> models;
  final int selectedModelId;

  @override
  State<_OnlineChatModelSheet> createState() => _OnlineChatModelSheetState();
}

class _OnlineChatModelSheetState extends State<_OnlineChatModelSheet> {
  late int _selectedId;

  @override
  void initState() {
    super.initState();
    final selectedExists = widget.models.any(
      (model) => model.id == widget.selectedModelId,
    );
    _selectedId = selectedExists
        ? widget.selectedModelId
        : _defaultModelId(widget.models);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _t(context, '选择在线 AI 模型', 'Choose an online AI model'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              context,
              '模型由后台预设并启用，每个聊天模式会分别记住你的选择。',
              'Models are enabled by administrators. Each chat mode remembers its own selection.',
            ),
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 18),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.models.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final model = widget.models[index];
                final selected = model.id == _selectedId;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedId = model.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer.withValues(alpha: 0.62)
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      model.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (model.isDefault) ...[
                                    const SizedBox(width: 8),
                                    _ModelBadge(
                                      label: _t(context, '默认', 'Default'),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${model.type} · ${model.model}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _selectedId <= 0
                ? null
                : () {
                    final selected = widget.models.firstWhere(
                      (model) => model.id == _selectedId,
                    );
                    Navigator.of(context).pop(selected);
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFFFF9585),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.smart_toy_outlined),
            label: Text(_t(context, '使用此模型', 'Use this model')),
          ),
        ],
      ),
    );
  }
}

class _ModelBadge extends StatelessWidget {
  const _ModelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

int _defaultModelId(List<OnlineChatModel> models) {
  for (final model in models) {
    if (model.isDefault) {
      return model.id;
    }
  }
  return models.isEmpty ? 0 : models.first.id;
}
