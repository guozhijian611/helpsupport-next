import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

final localSpeechEngineProvider = Provider<LocalSpeechEngine>((ref) {
  final engine = LocalSpeechEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

class LocalSpeechEngine {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _asrReady = false;
  String _partial = '';

  Future<bool> ensureAsr() async {
    if (_asrReady) {
      return _stt.isAvailable;
    }
    _asrReady = await _stt.initialize();
    return _asrReady && _stt.isAvailable;
  }

  Future<void> startListen({
    required String locale,
    void Function(String text)? onPartial,
  }) async {
    _partial = '';
    final ready = await ensureAsr();
    if (!ready) {
      throw StateError('on-device ASR is unavailable');
    }
    await _stt.listen(
      onResult: (result) {
        _partial = result.recognizedWords.trim();
        onPartial?.call(_partial);
      },
      listenOptions: SpeechListenOptions(
        localeId: _asrLocale(locale),
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        onDevice: true,
      ),
    );
  }

  Future<String> stopListen() async {
    if (_stt.isListening) {
      await _stt.stop();
    }
    return _partial.trim();
  }

  Future<void> cancelListen() async {
    if (_stt.isListening) {
      await _stt.cancel();
    }
    _partial = '';
  }

  Future<void> speak(
    String text,
    String locale, {
    void Function()? onDone,
  }) async {
    final content = text.trim();
    if (content.isEmpty) {
      onDone?.call();
      return;
    }
    await _tts.stop();
    await _tts.setLanguage(_ttsLocale(locale));
    await _tts.setSpeechRate(0.47);
    _tts.setCompletionHandler(() => onDone?.call());
    _tts.setCancelHandler(() => onDone?.call());
    _tts.setErrorHandler((_) => onDone?.call());
    await _tts.speak(content);
  }

  Future<void> stopSpeak() => _tts.stop();

  void dispose() {
    if (_stt.isListening) {
      _stt.cancel();
    }
    _tts.stop();
  }

  String _asrLocale(String locale) {
    final normalized = locale.replaceAll('_', '-').toLowerCase();
    if (normalized.startsWith('zh')) {
      return 'zh_CN';
    }
    return 'en_US';
  }

  String _ttsLocale(String locale) {
    final normalized = locale.replaceAll('_', '-').toLowerCase();
    if (normalized.startsWith('zh')) {
      return 'zh-CN';
    }
    return 'en-US';
  }
}
