import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/local_model/data/local_model_models.dart';

class ModelDownloader {
  const ModelDownloader(this._dio, this._preferences);

  final Dio _dio;
  final SharedPreferences _preferences;

  Future<LocalModelDownloadState> readState(
    LocalModelItem model, {
    required String memberId,
  }) async {
    final manifest = _readManifest(model, memberId: memberId);
    final target = await _modelFile(model, memberId: memberId);
    final filePath = manifest['file_path'] as String? ?? '';
    final storedSha256 = manifest['sha256'] as String? ?? '';
    if (filePath.isEmpty || storedSha256.isEmpty) {
      return _restoreExistingFileState(model, memberId: memberId, file: target);
    }

    final file = File(filePath);
    if (!await file.exists()) {
      await _preferences.remove(_manifestKey(model, memberId: memberId));
      return _restoreExistingFileState(model, memberId: memberId, file: target);
    }

    if (model.sha256.isNotEmpty &&
        storedSha256.toLowerCase() != model.sha256.toLowerCase()) {
      return _restoreExistingFileState(model, memberId: memberId, file: target);
    }

    return LocalModelDownloadState.ready(
      filePath: filePath,
      sha256: storedSha256,
    );
  }

  Future<LocalModelDownloadState> download(
    LocalModelItem model, {
    required String memberId,
    required void Function(double progress) onProgress,
    required void Function() onVerifying,
  }) async {
    final url = model.downloadUrl.trim();
    if (url.isEmpty) {
      throw const FormatException('模型下载地址为空');
    }
    if (model.sha256.trim().isEmpty) {
      throw const FormatException('模型 SHA256 未配置');
    }

    final target = await _modelFile(model, memberId: memberId);
    final restored = await _restoreExistingFileState(
      model,
      memberId: memberId,
      file: target,
    );
    if (restored.isReady) {
      return restored;
    }

    final temp = File('${target.path}.download');
    await target.parent.create(recursive: true);
    if (await temp.exists()) {
      await temp.delete();
    }

    await _dio.download(
      url,
      temp.path,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (total <= 0) {
          return;
        }
        onProgress((received / total).clamp(0, 0.99));
      },
    );

    onVerifying();
    final actualSha256 = await _sha256(temp);
    if (actualSha256.toLowerCase() != model.sha256.toLowerCase()) {
      await temp.delete();
      throw const FormatException('模型 SHA256 校验失败');
    }

    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);

    final state = LocalModelDownloadState.ready(
      filePath: target.path,
      sha256: actualSha256,
    );
    await _writeManifest(model, memberId: memberId, state: state);
    return state;
  }

  Future<void> deleteModel(
    LocalModelItem model, {
    required String memberId,
  }) async {
    final manifest = _readManifest(model, memberId: memberId);
    final filePath = manifest['file_path'] as String? ?? '';
    if (filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _preferences.remove(_manifestKey(model, memberId: memberId));
  }

  Future<LocalModelDownloadState> _restoreExistingFileState(
    LocalModelItem model, {
    required String memberId,
    required File file,
  }) async {
    if (!await file.exists()) {
      return const LocalModelDownloadState.notDownloaded();
    }

    final expectedSha256 = model.sha256.trim();
    if (expectedSha256.isEmpty) {
      return const LocalModelDownloadState.notDownloaded();
    }

    final actualSha256 = await _sha256(file);
    if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
      return const LocalModelDownloadState.notDownloaded();
    }

    final state = LocalModelDownloadState.ready(
      filePath: file.path,
      sha256: actualSha256,
    );
    await _writeManifest(model, memberId: memberId, state: state);
    final temp = File('${file.path}.download');
    if (await temp.exists()) {
      await temp.delete();
    }
    return state;
  }

  Future<File> _modelFile(
    LocalModelItem model, {
    required String memberId,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${root.path}/helpsupport_models/${_safePart(memberId)}',
    );
    final extension = _extensionFromUrl(model.downloadUrl);
    final shaPart = model.sha256.length >= 8
        ? model.sha256.substring(0, 8)
        : 'unverified';
    return File(
      '${directory.path}/${_safePart(model.code)}_$shaPart$extension',
    );
  }

  Future<String> _sha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Map<String, Object?> _readManifest(
    LocalModelItem model, {
    required String memberId,
  }) {
    final raw = _preferences.getString(_manifestKey(model, memberId: memberId));
    if (raw == null || raw.isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      _preferences.remove(_manifestKey(model, memberId: memberId));
    }
    return const {};
  }

  Future<void> _writeManifest(
    LocalModelItem model, {
    required String memberId,
    required LocalModelDownloadState state,
  }) {
    return _preferences.setString(
      _manifestKey(model, memberId: memberId),
      jsonEncode({
        'model_id': model.id,
        'code': model.code,
        'file_path': state.filePath,
        'sha256': state.sha256,
        'downloaded_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  String _manifestKey(LocalModelItem model, {required String memberId}) {
    return 'helpsupport.local_model.${_safePart(memberId)}.${model.id}';
  }

  String _extensionFromUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return '.gguf';
    }
    final extension = path.substring(dotIndex);
    return extension.length <= 12 ? extension : '.gguf';
  }

  String _safePart(String value) {
    final normalized = value.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]+'),
      '_',
    );
    return normalized.isEmpty ? 'default' : normalized;
  }
}
