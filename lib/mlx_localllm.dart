import 'dart:async';
import 'package:flutter/services.dart';

/// Exceptions specific to MLX Engine
class MlxEngineException implements Exception {
  final String code;
  final String message;

  MlxEngineException(this.code, this.message);

  @override
  String toString() => "MlxEngineException($code): $message";
}

/// A high-performance local LLM singleton using Apple MLX.
class MlxLocalllm {
  // Singleton Pattern
  MlxLocalllm._internal();
  static final MlxLocalllm _instance = MlxLocalllm._internal();
  factory MlxLocalllm() => _instance;

  static const MethodChannel _channel = MethodChannel('mlx_localllm');
  static const EventChannel _eventChannel = EventChannel('mlx_localllm_events');

  Stream<Map<String, dynamic>>? _eventStream;

  /// Stream for model-related events (download progress, loading progress, etc.)
  Stream<Map<String, dynamic>> get modelEvents {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
    return _eventStream!;
  }

  /// Checks if the current hardware is supported by MLX (i.e. has a GPU).
  Future<bool> isSupported() async {
    try {
      final bool? supported = await _channel.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Downloads the MLX model from HuggingFace.
  /// Use [modelEvents] to track download progress.
  Future<bool> downloadModel(String repoId) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('downloadModel', {
        'repoId': repoId,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      throw MlxEngineException(e.code, e.message ?? "Download failed");
    }
  }

  /// Checks if the model folder exists locally.
  Future<bool> checkModelExists(String repoId) async {
    try {
      final bool? exists = await _channel.invokeMethod<bool>(
        'checkModelExists',
        {'repoId': repoId},
      );
      return exists ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Unloads the current model from memory to free up resources.
  Future<bool> unloadModel() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('unloadModel');
      return success ?? false;
    } on PlatformException catch (e) {
      throw MlxEngineException(e.code, e.message ?? "Unload failed");
    }
  }

  /// Deletes the model folder from local storage.
  Future<bool> deleteModel(String repoId) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('deleteModel', {
        'repoId': repoId,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      throw MlxEngineException(e.code, e.message ?? "Delete failed");
    }
  }

  /// Loads the MLX model from the given absolute string path or repo ID.
  /// Use [modelEvents] to track loading progress.
  ///
  /// Throws an [MlxEngineException] if the operation fails.
  Future<bool> loadModel(String modelPath) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      throw MlxEngineException(
        e.code,
        e.message ?? "Unknown error loading model",
      );
    } catch (e) {
      throw MlxEngineException("UNKNOWN_ERROR", e.toString());
    }
  }

  /// Generates text based on the given prompt.
  ///
  /// Throws an [MlxEngineException] if the text generation fails.
  Future<String> generate({required String prompt}) async {
    try {
      final String? response = await _channel.invokeMethod<String>('generate', {
        'prompt': prompt,
      });
      return response ?? "";
    } on PlatformException catch (e) {
      throw MlxEngineException(
        e.code,
        e.message ?? "Unknown error during generation",
      );
    } catch (e) {
      throw MlxEngineException("UNKNOWN_ERROR", e.toString());
    }
  }
}
