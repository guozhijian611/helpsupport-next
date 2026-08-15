import 'package:flutter/material.dart';

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

Future<String?> showChatPromptConfigSheet(
  BuildContext context, {
  required String chatMode,
  required String title,
  required String initialPrompt,
  bool requiredPrompt = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChatPromptConfigSheet(
      chatMode: chatMode,
      title: title,
      initialPrompt: initialPrompt,
      requiredPrompt: requiredPrompt,
    ),
  );
}

class ChatPromptSummaryBar extends StatelessWidget {
  const ChatPromptSummaryBar({
    super.key,
    required this.label,
    required this.prompt,
    required this.onEdit,
  });

  final String label;
  final String prompt;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = prompt.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Material(
        color: isDark
            ? colors.surfaceContainerHighest
            : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9585),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        normalized.isEmpty
                            ? _t(
                                context,
                                '请先设置对话提示词',
                                'Set a chat prompt first',
                              )
                            : normalized,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.edit_note_rounded,
                  color: colors.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPromptConfigSheet extends StatefulWidget {
  const _ChatPromptConfigSheet({
    required this.chatMode,
    required this.title,
    required this.initialPrompt,
    required this.requiredPrompt,
  });

  final String chatMode;
  final String title;
  final String initialPrompt;
  final bool requiredPrompt;

  @override
  State<_ChatPromptConfigSheet> createState() => _ChatPromptConfigSheetState();
}

class _ChatPromptConfigSheetState extends State<_ChatPromptConfigSheet> {
  late final TextEditingController _controller;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presets = _promptPresets(context, widget.chatMode);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.86),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E7EC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _t(
                      context,
                      '进入对话前需要明确本次 AI 的角色边界，也可以直接选择内置提示词。',
                      'Define the AI role before entering the chat, or pick a built-in prompt.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final preset in presets)
                      ActionChip(
                        label: Text(preset.title),
                        avatar: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 17,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.text = preset.prompt;
                            _errorText = '';
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  minLines: 5,
                  maxLines: 9,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: _t(
                      context,
                      '输入你希望 AI 遵守的角色、边界和回应方式',
                      'Describe the role, boundaries, and response style for the AI',
                    ),
                    errorText: _errorText.isEmpty ? null : _errorText,
                    filled: true,
                    fillColor: isDark
                        ? colors.surfaceContainerHighest
                        : const Color(0xFFF7F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9585),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _submit,
                    child: Text(
                      _t(context, '保存并进入', 'Save and continue'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final prompt = _controller.text.trim();
    if (widget.requiredPrompt && prompt.isEmpty) {
      setState(() {
        _errorText = _t(
          context,
          '请先填写或选择一个提示词',
          'Enter or choose a prompt first',
        );
      });
      return;
    }
    Navigator.of(context).pop(prompt);
  }
}

class _PromptPreset {
  const _PromptPreset({required this.title, required this.prompt});

  final String title;
  final String prompt;
}

List<_PromptPreset> _promptPresets(BuildContext context, String chatMode) {
  final isZh = Localizations.localeOf(context).languageCode == 'zh';
  return switch (chatMode) {
    'doctor' => [
      _PromptPreset(
        title: _t(context, '认知行为方法', 'CBT support'),
        prompt: isZh
            ? '请以谨慎、温和的 AI 心理医生助手身份回应。优先帮助我澄清困扰、识别想法和情绪之间的关系，并给出可执行的小步骤。不要做医学诊断；如发现自伤、自杀、伤人或失控风险，请明确建议我立即联系家属、急救电话或线下精神心理专科。'
            : 'Respond as a cautious and gentle AI mental-health support assistant. Help me clarify the concern, connect thoughts with emotions, and suggest small practical steps. Do not make a medical diagnosis; if self-harm, suicide, harm to others, or loss of control appears, tell me to contact family, emergency services, or an in-person mental-health clinician immediately.',
      ),
      _PromptPreset(
        title: _t(context, '情绪稳定建议', 'Grounding support'),
        prompt: isZh
            ? '请先帮助我稳定情绪，再用简短问题了解当下发生了什么。每次回复都给出一个可以立刻尝试的安抚或整理动作，并保持专业边界，不替代真实医生诊疗。'
            : 'Start by helping me regulate my emotions, then ask brief questions to understand what is happening. Include one immediate grounding or organizing action in each reply, while keeping clear boundaries and not replacing real clinical care.',
      ),
    ],
    'patient' => [
      _PromptPreset(
        title: _t(context, '焦虑来访者', 'Anxious patient'),
        prompt: isZh
            ? '请扮演一位正在被焦虑困扰的模拟病人。用真实但克制的方式表达担心、躯体不适和回避行为，等待我通过提问逐步了解情况，不要一次性给出全部背景。'
            : 'Role-play as a simulated patient struggling with anxiety. Express worries, physical discomfort, and avoidance in a realistic but contained way. Let me uncover the situation through questions instead of giving all background at once.',
      ),
      _PromptPreset(
        title: _t(context, '复诊沟通练习', 'Follow-up practice'),
        prompt: isZh
            ? '请扮演一位准备复诊的模拟病人。围绕症状变化、睡眠、服药感受、触发事件和想问医生的问题进行互动，帮助我练习更清晰的问诊和回应。'
            : 'Role-play as a simulated patient preparing for a follow-up visit. Interact around symptom changes, sleep, medication experience, triggers, and questions for the doctor so I can practice clearer clinical communication.',
      ),
    ],
    'ai_doctor' => [
      _PromptPreset(
        title: _t(context, '就诊信息整理', 'Visit preparation'),
        prompt: isZh
            ? '请帮助我整理症状、持续时间、可能诱因、既往病史、用药情况和需要向医生提问的内容。不要做诊断、开药或调整处方；如发现紧急危险信号，请明确建议立即线下就医或联系急救。'
            : 'Help me organize symptoms, duration, possible triggers, medical history, medications, and questions for a clinician. Do not diagnose, prescribe, or change medication; clearly advise urgent in-person care or emergency services for danger signs.',
      ),
      _PromptPreset(
        title: _t(context, '健康问题清单', 'Health concern checklist'),
        prompt: isZh
            ? '请一次问我一个简短问题，帮助我把当前健康困扰整理成清晰的问题清单和时间线，最后给出可带去就诊的摘要。保持谨慎，不替代真实医生。'
            : 'Ask one short question at a time to turn my current health concern into a clear checklist and timeline, then prepare a summary for a clinical visit. Stay cautious and do not replace a real clinician.',
      ),
    ],
    _ => [
      _PromptPreset(
        title: _t(context, '稳定陪伴', 'Steady companion'),
        prompt: isZh
            ? '请像稳定、耐心的心理陪伴者一样回应。先接住我的情绪，再帮助我把感受、事实和下一步分开，不评判、不说教，也不替我做重大决定。'
            : 'Respond like a steady and patient support companion. Acknowledge my emotions first, then help me separate feelings, facts, and next steps. Avoid judgment, lectures, and making major decisions for me.',
      ),
      _PromptPreset(
        title: _t(context, '睡前整理', 'Night reflection'),
        prompt: isZh
            ? '请陪我做睡前情绪整理。用温和简短的方式帮我回顾今天最困扰的事、已经完成的小事和明天可以降低压力的一步。'
            : 'Help me do a gentle night reflection. Briefly guide me through the most difficult part of today, one small thing I completed, and one step that can reduce pressure tomorrow.',
      ),
    ],
  };
}
