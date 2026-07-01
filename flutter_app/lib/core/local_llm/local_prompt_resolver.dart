import '../../features/local_model/data/local_model_models.dart';

class ResolvedLocalPrompt {
  const ResolvedLocalPrompt({
    required this.systemPrompt,
    required this.firstMessage,
    required this.hasPreset,
  });

  final String systemPrompt;
  final String firstMessage;
  final bool hasPreset;
}

class LocalPromptResolver {
  const LocalPromptResolver();

  ResolvedLocalPrompt resolve({
    required int modelId,
    required String chatMode,
    required String locale,
    required List<LocalModelPrompt> prompts,
  }) {
    final candidates = prompts
        .where((prompt) => prompt.chatMode == chatMode)
        .where((prompt) => prompt.modelId == modelId || prompt.modelId == 0)
        .toList(growable: false);
    final exact = _bestLocale(candidates, locale);
    final prompt = exact ?? (candidates.isNotEmpty ? candidates.first : null);

    final systemPrompt = [
      if (prompt?.systemPrompt.trim().isNotEmpty == true)
        prompt!.systemPrompt.trim()
      else
        _defaultSystemPrompt(chatMode),
      if (prompt?.safetyPrompt.trim().isNotEmpty == true)
        prompt!.safetyPrompt.trim(),
    ].join('\n\n');

    return ResolvedLocalPrompt(
      systemPrompt: systemPrompt,
      firstMessage: prompt?.firstMessage.trim() ?? '',
      hasPreset: prompt != null,
    );
  }

  LocalModelPrompt? _bestLocale(List<LocalModelPrompt> prompts, String locale) {
    if (prompts.isEmpty) {
      return null;
    }
    final normalized = locale.toLowerCase();
    final exact = prompts.where(
      (prompt) => prompt.locale.toLowerCase() == normalized,
    );
    if (exact.isNotEmpty) {
      return exact.first;
    }
    final language = normalized.split('-').first;
    final sameLanguage = prompts.where(
      (prompt) => prompt.locale.toLowerCase().split('-').first == language,
    );
    if (sameLanguage.isNotEmpty) {
      return sameLanguage.first;
    }
    final english = prompts.where(
      (prompt) => prompt.locale.toLowerCase().startsWith('en'),
    );
    return english.isNotEmpty ? english.first : prompts.first;
  }

  String _defaultSystemPrompt(String chatMode) {
    return switch (chatMode) {
      'doctor' =>
        'You are a cautious mental health support assistant. Offer grounding, clarification, and practical next steps without making medical diagnoses.',
      'patient' =>
        'You help the user organize symptoms, feelings, triggers, and notes they may want to discuss with a clinician.',
      _ =>
        'You are a warm, steady, and patient support companion. Listen carefully, reflect feelings, and avoid judgment.',
    };
  }
}
