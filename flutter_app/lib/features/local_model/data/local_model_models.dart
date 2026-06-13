class LocalModelItem {
  const LocalModelItem({
    required this.id,
    required this.name,
    required this.code,
    required this.provider,
    required this.modelFamily,
    required this.quantization,
    required this.fileSize,
    required this.downloadUrl,
    required this.sha256,
    required this.intro,
    required this.license,
    required this.minMemoryMb,
    required this.contextSize,
  });

  final int id;
  final String name;
  final String code;
  final String provider;
  final String modelFamily;
  final String quantization;
  final int fileSize;
  final String downloadUrl;
  final String sha256;
  final String intro;
  final String license;
  final int minMemoryMb;
  final int contextSize;

  factory LocalModelItem.fromJson(Map<String, dynamic> json) {
    return LocalModelItem(
      id: _intValue(json['id']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
      provider: _stringValue(json['provider']),
      modelFamily: _stringValue(json['model_family']),
      quantization: _stringValue(json['quantization']),
      fileSize: _intValue(json['file_size']),
      downloadUrl: _stringValue(json['download_url']),
      sha256: _stringValue(json['sha256']),
      intro: _stringValue(json['intro']),
      license: _stringValue(json['license']),
      minMemoryMb: _intValue(json['min_memory_mb']),
      contextSize: _intValue(json['context_size']),
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
    required this.firstMessage,
  });

  final int id;
  final int modelId;
  final String chatMode;
  final String locale;
  final String title;
  final String firstMessage;

  factory LocalModelPrompt.fromJson(Map<String, dynamic> json) {
    return LocalModelPrompt(
      id: _intValue(json['id']),
      modelId: _intValue(json['model_id']),
      chatMode: _stringValue(json['chat_mode']),
      locale: _stringValue(json['locale']),
      title: _stringValue(json['title']),
      firstMessage: _stringValue(json['first_message']),
    );
  }
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

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}
