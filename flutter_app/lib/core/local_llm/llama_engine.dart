import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../../features/local_model/data/local_model_models.dart';
import 'local_chat_store.dart';

class LlamaRuntimeStatus {
  const LlamaRuntimeStatus({
    required this.isAvailable,
    required this.libraryPath,
    this.errorMessage = '',
  });

  const LlamaRuntimeStatus.available(String libraryPath)
    : this(isAvailable: true, libraryPath: libraryPath);

  const LlamaRuntimeStatus.unavailable(String libraryPath, String errorMessage)
    : this(
        isAvailable: false,
        libraryPath: libraryPath,
        errorMessage: errorMessage,
      );

  final bool isAvailable;
  final String libraryPath;
  final String errorMessage;
}

class LlamaEngine {
  const LlamaEngine();

  static const _libraryPath = String.fromEnvironment(
    'HELP_SUPPORT_LLAMA_LIBRARY_PATH',
    defaultValue: '',
  );

  Future<LlamaRuntimeStatus> inspectRuntime() async {
    final path = _resolvedLibraryPath();
    try {
      DynamicLibrary.open(path);
      return LlamaRuntimeStatus.available(path);
    } on Object catch (error) {
      return LlamaRuntimeStatus.unavailable(path, error.toString());
    }
  }

  Future<String> generate({
    required LocalModelItem model,
    required String modelPath,
    required String systemPrompt,
    required List<LocalChatMessage> history,
    required String userMessage,
  }) async {
    final prompt = _buildPrompt(systemPrompt, history, userMessage);
    final parent = LlamaParent(_loadCommand(model, modelPath));
    final buffer = StringBuffer();
    StreamSubscription<String>? subscription;
    final runtime = await inspectRuntime();
    if (!runtime.isAvailable) {
      throw StateError('本地推理库不可用：${runtime.errorMessage}');
    }

    Llama.libraryPath = runtime.libraryPath;

    try {
      await parent.init();
      subscription = parent.stream.listen(buffer.write);
      final promptId = await parent.sendPrompt(prompt);
      final completion = await parent.completions
          .firstWhere((event) => event.promptId == promptId)
          .timeout(const Duration(minutes: 3));
      if (!completion.success) {
        throw StateError(completion.errorDetails ?? '本地模型推理失败');
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) {
        throw StateError('本地模型未返回有效内容');
      }
      return text;
    } finally {
      await subscription?.cancel();
      await parent.dispose();
    }
  }

  LlamaLoad _loadCommand(LocalModelItem model, String modelPath) {
    final contextParams = ContextParams()
      ..nCtx = model.contextSize > 0 ? model.contextSize : 2048
      ..nPredict = 512
      ..nThreads = max(2, Platform.numberOfProcessors ~/ 2)
      ..nThreadsBatch = max(2, Platform.numberOfProcessors ~/ 2);
    final samplerParams = SamplerParams()
      ..temp = model.defaultTemperature > 0 ? model.defaultTemperature : 0.7
      ..topP = model.defaultTopP > 0 ? model.defaultTopP : 0.95
      ..penaltyRepeat = 1.1;

    return LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      contextParams: contextParams,
      samplingParams: samplerParams,
    );
  }

  String _buildPrompt(
    String systemPrompt,
    List<LocalChatMessage> history,
    String userMessage,
  ) {
    final chatHistory = ChatHistory(keepRecentPairs: 4)
      ..addMessage(role: Role.system, content: systemPrompt);
    for (final message in history.takeLast(12)) {
      chatHistory.addMessage(
        role: message.role == 'assistant' ? Role.assistant : Role.user,
        content: message.content,
      );
    }
    chatHistory
      ..addMessage(role: Role.user, content: userMessage)
      ..addMessage(role: Role.assistant, content: '');

    return chatHistory.exportFormat(
      ChatFormat.chatml,
      leaveLastAssistantOpen: true,
    );
  }

  String _resolvedLibraryPath() {
    if (_libraryPath.isNotEmpty) {
      return _libraryPath;
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return 'libllama.so';
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return 'libllama.dylib';
    }
    if (Platform.isWindows) {
      return 'llama.dll';
    }
    return 'libllama.so';
  }
}

extension _TakeLast<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) {
      return this;
    }
    return skip(length - count);
  }
}
