import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

enum SpeechPriority { onlineFirst, localFirst }

final asrPriorityProvider = NotifierProvider<AsrPriorityController, SpeechPriority>(
  AsrPriorityController.new,
);

final ttsPriorityProvider = NotifierProvider<TtsPriorityController, SpeechPriority>(
  TtsPriorityController.new,
);

class AsrPriorityController extends _SpeechPriorityController {
  @override
  String get storageKey => 'app.speech.asr_priority';
}

class TtsPriorityController extends _SpeechPriorityController {
  @override
  String get storageKey => 'app.speech.tts_priority';
}

abstract class _SpeechPriorityController extends Notifier<SpeechPriority> {
  String get storageKey;

  @override
  SpeechPriority build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    return stored == SpeechPriority.localFirst.name
        ? SpeechPriority.localFirst
        : SpeechPriority.onlineFirst;
  }

  Future<void> setPriority(SpeechPriority value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setString(storageKey, value.name);
  }
}

bool useLocalSpeech({
  required String speechRuntime,
  required SpeechPriority priority,
}) {
  return switch (speechRuntime) {
    'online' => false,
    'local' => true,
    _ => priority == SpeechPriority.localFirst,
  };
}
