class LocalModelItem {
  const LocalModelItem({
    required this.id,
    required this.name,
    required this.code,
    required this.provider,
    required this.modelFamily,
    this.capability = 'llm',
    required this.quantization,
    required this.fileSize,
    required this.downloadUrl,
    required this.sha256,
    required this.intro,
    required this.license,
    required this.minMemoryMb,
    required this.contextSize,
    required this.defaultTemperature,
    required this.defaultTopP,
  });

  final int id;
  final String name;
  final String code;
  final String provider;
  final String modelFamily;
  final String capability;
  final String quantization;
  final int fileSize;
  final String downloadUrl;
  final String sha256;
  final String intro;
  final String license;
  final int minMemoryMb;
  final int contextSize;
  final double defaultTemperature;
  final double defaultTopP;

  factory LocalModelItem.fromJson(Map<String, dynamic> json) {
    return LocalModelItem(
      id: _intValue(json['id']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
      provider: _stringValue(json['provider']),
      modelFamily: _stringValue(json['model_family']),
      capability: _stringValue(json['capability'], fallback: 'llm'),
      quantization: _stringValue(json['quantization']),
      fileSize: _intValue(json['file_size']),
      downloadUrl: _stringValue(json['download_url']),
      sha256: _stringValue(json['sha256']),
      intro: _stringValue(json['intro']),
      license: _stringValue(json['license']),
      minMemoryMb: _intValue(json['min_memory_mb']),
      contextSize: _intValue(json['context_size']),
      defaultTemperature: _doubleValue(json['default_temperature']),
      defaultTopP: _doubleValue(json['default_top_p']),
    );
  }
}

class LocalModelPrompt {
  const LocalModelPrompt({
    required this.id,
    required this.modelId,
    required this.chatMode,
    required this.locale,
    required this.title,
    required this.systemPrompt,
    required this.firstMessage,
    required this.safetyPrompt,
  });

  final int id;
  final int modelId;
  final String chatMode;
  final String locale;
  final String title;
  final String systemPrompt;
  final String firstMessage;
  final String safetyPrompt;

  factory LocalModelPrompt.fromJson(Map<String, dynamic> json) {
    return LocalModelPrompt(
      id: _intValue(json['id']),
      modelId: _intValue(json['model_id']),
      chatMode: _stringValue(json['chat_mode']),
      locale: _stringValue(json['locale']),
      title: _stringValue(json['title']),
      systemPrompt: _stringValue(json['system_prompt']),
      firstMessage: _stringValue(json['first_message']),
      safetyPrompt: _stringValue(json['safety_prompt']),
    );
  }
}

enum LocalModelDownloadStatus {
  notDownloaded,
  downloading,
  verifying,
  ready,
  failed,
}

class LocalModelDownloadState {
  const LocalModelDownloadState({
    required this.status,
    this.progress = 0,
    this.filePath = '',
    this.sha256 = '',
    this.errorMessage = '',
  });

  const LocalModelDownloadState.notDownloaded()
    : this(status: LocalModelDownloadStatus.notDownloaded);

  const LocalModelDownloadState.downloading(double progress)
    : this(status: LocalModelDownloadStatus.downloading, progress: progress);

  const LocalModelDownloadState.verifying()
    : this(status: LocalModelDownloadStatus.verifying);

  const LocalModelDownloadState.ready({
    required String filePath,
    required String sha256,
  }) : this(
         status: LocalModelDownloadStatus.ready,
         progress: 1,
         filePath: filePath,
         sha256: sha256,
       );

  const LocalModelDownloadState.failed(String errorMessage)
    : this(status: LocalModelDownloadStatus.failed, errorMessage: errorMessage);

  final LocalModelDownloadStatus status;
  final double progress;
  final String filePath;
  final String sha256;
  final String errorMessage;

  bool get isReady => status == LocalModelDownloadStatus.ready;
  bool get isBusy =>
      status == LocalModelDownloadStatus.downloading ||
      status == LocalModelDownloadStatus.verifying;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}
