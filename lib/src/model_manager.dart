import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'download_progress.dart';

class ModelManager {
  final MethodChannel _channel;
  final Map<String, StreamController<DownloadProgress>> _activeDownloads = {};
  final _progressController = StreamController<DownloadProgress>.broadcast();

  ModelManager(this._channel) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// Gets the local storage path for models.
  Future<String> getModelsRoot() async {
    final supportDir = await getApplicationSupportDirectory();
    String rootPath = supportDir.path;
    if (Platform.isMacOS) {
      rootPath = p.dirname(supportDir.path);
    }
    return p.join(rootPath, 'models');
  }

  /// Gets the full path for a specific model repo.
  Future<String> getModelPath(String repoId) async {
    final root = await getModelsRoot();
    return p.join(root, repoId);
  }

  /// Checks if the model's config.json exists locally.
  Future<bool> isDownloaded(String repoId) async {
    final modelPath = await getModelPath(repoId);
    final configFile = File(p.join(modelPath, 'config.json'));
    return configFile.exists();
  }

  /// Downloads a model from HuggingFace/Mirror.
  Stream<DownloadProgress> downloadModel(String repoId, {String? endpoint}) {
    if (_activeDownloads.containsKey(repoId)) {
      return _activeDownloads[repoId]!.stream;
    }

    final controller = StreamController<DownloadProgress>.broadcast();
    _activeDownloads[repoId] = controller;

    _startDownload(repoId, endpoint, controller);
    return controller.stream;
  }

  /// Cancels an ongoing download.
  Future<void> cancelDownload(String repoId) async {
    await _channel.invokeMethod('cancelDownload', {'repoId': repoId});
    _cleanup(repoId);
  }

  /// Deletes a model from local storage.
  /// Throws an [Exception] if the model directory does not exist.
  Future<void> deleteModel(String repoId) async {
    final path = await getModelPath(repoId);
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    } else {
      throw Exception('Model not found: $repoId');
    }
  }

  Future<void> _startDownload(
    String repoId,
    String? endpoint,
    StreamController<DownloadProgress> controller,
  ) async {
    try {
      final bool started = await _channel.invokeMethod('downloadModel', {
        'repoId': repoId,
        'endpoint': endpoint,
      });

      if (!started) {
        throw Exception('Failed to start native downloader');
      }
    } catch (e) {
      controller.addError(e);
      _cleanup(repoId);
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    final String? repoId = call.arguments['repoId'];
    if (repoId == null) return;

    switch (call.method) {
      case 'downloadProgress':
        final double progress = call.arguments['progress'] ?? 0.0;
        final ev = DownloadProgress(
          repoId: repoId,
          progress: progress,
          isDone: progress >= 1.0,
        );
        _activeDownloads[repoId]?.add(ev);
        _progressController.add(ev);
        break;
      case 'downloadComplete':
        final String? path = call.arguments['path'];
        final ev = DownloadProgress(
          repoId: repoId,
          progress: 1.0,
          isDone: true,
          path: path,
        );
        _activeDownloads[repoId]?.add(ev);
        _progressController.add(ev);
        _cleanup(repoId);
        break;
      case 'downloadError':
        final String error = call.arguments['error'] ?? 'Unknown error';
        _activeDownloads[repoId]?.addError(error);
        _cleanup(repoId);
        break;
    }
  }

  void _cleanup(String repoId) {
    _activeDownloads[repoId]?.close();
    _activeDownloads.remove(repoId);
  }
}
