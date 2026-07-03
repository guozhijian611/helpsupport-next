import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
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
  static const _gpuLayers = String.fromEnvironment(
    'HELP_SUPPORT_LLAMA_GPU_LAYERS',
    defaultValue: '',
  );
  static const _backend = String.fromEnvironment(
    'HELP_SUPPORT_LLAMA_BACKEND',
    defaultValue: 'auto',
  );
  static const _developerToolsChannel = MethodChannel(
    'helpsupport/developer_tools',
  );

  Future<LlamaRuntimeStatus> inspectRuntime() async {
    final path = _resolvedLibraryPath();
    try {
      DynamicLibrary.open(path);
      await _resolvedGpuLayers();
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
    final buffer = StringBuffer();
    await for (final token in generateStream(
      model: model,
      modelPath: modelPath,
      systemPrompt: systemPrompt,
      history: history,
      userMessage: userMessage,
    )) {
      buffer.write(token);
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw StateError('本地模型未返回有效内容');
    }
    return text;
  }

  Stream<String> generateStream({
    required LocalModelItem model,
    required String modelPath,
    required String systemPrompt,
    required List<LocalChatMessage> history,
    required String userMessage,
  }) async* {
    final runtime = await inspectRuntime();
    if (!runtime.isAvailable) {
      throw StateError('本地推理库不可用：${runtime.errorMessage}');
    }

    Llama.libraryPath = runtime.libraryPath;
    final gpuLayers = await _resolvedGpuLayers();
    var emittedToken = false;
    try {
      await for (final token in _generateStreamWithLayers(
        model: model,
        modelPath: modelPath,
        systemPrompt: systemPrompt,
        history: history,
        userMessage: userMessage,
        gpuLayers: gpuLayers,
      )) {
        emittedToken = true;
        yield token;
      }
      return;
    } on Object {
      if (!_isAutoBackend() || gpuLayers == 0 || emittedToken) {
        rethrow;
      }
    }

    yield* _generateStreamWithLayers(
      model: model,
      modelPath: modelPath,
      systemPrompt: systemPrompt,
      history: history,
      userMessage: userMessage,
      gpuLayers: 0,
    );
  }

  Stream<String> _generateStreamWithLayers({
    required LocalModelItem model,
    required String modelPath,
    required String systemPrompt,
    required List<LocalChatMessage> history,
    required String userMessage,
    required int gpuLayers,
  }) async* {
    final prompt = _buildPrompt(systemPrompt, history, userMessage);
    final parent = LlamaParent(
      _loadCommand(model, modelPath, gpuLayers: gpuLayers),
    );
    final tokens = StreamController<String>();
    StreamSubscription<String>? subscription;
    Future<void>? completionGuard;

    try {
      await parent.init();
      subscription = parent.stream.listen(
        (token) {
          if (token.isNotEmpty && !tokens.isClosed) {
            tokens.add(token);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!tokens.isClosed) {
            tokens.addError(error, stackTrace);
          }
        },
      );
      final promptId = await parent.sendPrompt(prompt);
      final completionFuture = parent.completions
          .firstWhere((event) => event.promptId == promptId)
          .timeout(const Duration(minutes: 3));
      completionGuard = completionFuture.then(
        (completion) {
          if (!completion.success && !tokens.isClosed) {
            tokens.addError(StateError(completion.errorDetails ?? '本地模型推理失败'));
          }
          return tokens.close();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!tokens.isClosed) {
            tokens.addError(error, stackTrace);
          }
          return tokens.close();
        },
      );

      await for (final token in tokens.stream) {
        yield token;
      }
    } finally {
      if (completionGuard != null) {
        await completionGuard;
      }
      await subscription?.cancel();
      if (!tokens.isClosed) {
        await tokens.close();
      }
      await parent.dispose();
    }
  }

  LlamaLoad _loadCommand(
    LocalModelItem model,
    String modelPath, {
    required int gpuLayers,
  }) {
    final contextParams = ContextParams()
      ..nCtx = model.contextSize > 0 ? model.contextSize : 2048
      ..nPredict = 512
      ..nThreads = max(2, Platform.numberOfProcessors ~/ 2)
      ..nThreadsBatch = max(2, Platform.numberOfProcessors ~/ 2);
    final samplerParams = SamplerParams()
      ..temp = model.defaultTemperature > 0 ? model.defaultTemperature : 0.7
      ..topP = model.defaultTopP > 0 ? model.defaultTopP : 0.95
      ..penaltyRepeat = 1.1;

    final modelParams = ModelParams();
    modelParams.nGpuLayers = gpuLayers;
    if (gpuLayers == 0) {
      contextParams
        ..offloadKqv = false
        ..opOffload = false;
    }

    return LlamaLoad(
      path: modelPath,
      modelParams: modelParams,
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
    if (Platform.isAndroid) {
      return 'libmtmd.so';
    }
    if (Platform.isLinux) {
      return 'libllama.so';
    }
    if (Platform.isIOS) {
      return '@rpath/libllama.framework/libllama';
    }
    if (Platform.isMacOS) {
      return 'libllama.dylib';
    }
    if (Platform.isWindows) {
      return 'llama.dll';
    }
    return 'libllama.so';
  }

  Future<int> _resolvedGpuLayers() async {
    final configuredGpuLayers = int.tryParse(_gpuLayers);
    final mode = _backend.trim().toLowerCase();
    if (mode == 'gpu') {
      if (!await _supportsGpuOffload()) {
        throw StateError('当前设备不支持本地模型 GPU 模式');
      }
      return configuredGpuLayers ?? 99;
    }
    if (Platform.isAndroid) {
      return 0;
    }
    if (mode == 'auto' && await _supportsGpuOffload()) {
      return configuredGpuLayers ?? 99;
    }
    return 0;
  }

  bool _isAutoBackend() => _backend.trim().toLowerCase() == 'auto';

  Future<bool> _supportsGpuOffload() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return true;
    }
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final diagnostics = await _developerToolsChannel
          .invokeMapMethod<String, Object?>('getLocalLlmDiagnostics');
      return diagnostics?['supportsGpuOffload'] == true;
    } on Object {
      return false;
    }
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
