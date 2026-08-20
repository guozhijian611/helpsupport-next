import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

enum SpeechPriority { onlineFirst, localFirst }

enum ReplyPlaybackPreference { follow, textFirst, autoPlay }

final asrPriorityProvider = NotifierProvider<AsrPriorityController, SpeechPriority>(
  AsrPriorityController.new,
);

final ttsPriorityProvider = NotifierProvider<TtsPriorityController, SpeechPriority>(
  TtsPriorityController.new,
);

final replyPlaybackProvider =
    NotifierProvider<ReplyPlaybackController, ReplyPlaybackPreference>(
      ReplyPlaybackController.new,
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

class ReplyPlaybackController extends Notifier<ReplyPlaybackPreference> {
  static const storageKey = 'app.speech.reply_playback';

  @override
  ReplyPlaybackPreference build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    return switch (stored) {
      'textFirst' => ReplyPlaybackPreference.textFirst,
      'autoPlay' => ReplyPlaybackPreference.autoPlay,
      _ => ReplyPlaybackPreference.follow,
    };
  }

  Future<void> setPreference(ReplyPlaybackPreference value) async {
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

bool shouldAutoPlayReply({
  required bool personaAutoPlay,
  required ReplyPlaybackPreference preference,
}) {
  return switch (preference) {
    ReplyPlaybackPreference.follow => personaAutoPlay,
    ReplyPlaybackPreference.textFirst => false,
    ReplyPlaybackPreference.autoPlay => true,
  };
}
