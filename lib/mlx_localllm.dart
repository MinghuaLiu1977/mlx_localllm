import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Exceptions specific to MLX Engine
class MlxEngineException implements Exception {
  final String code;
  final String message;

  MlxEngineException(this.code, this.message);

  @override
  String toString() => "MlxEngineException($code): $message";
}

/// Configuration parameters for generating text with the local LLM.
class GenerateConfig {
  /// Controls the randomness of the output. Higher values (e.g., 0.8) make
  /// output more random, while lower values (e.g., 0.2) make it more focused.
  /// Defaults to null (backend default, usually 0.0 or 1.0 depending on framework).
  final double? temperature;

  /// The maximum number of tokens to generate.
  /// Defaults to null (backend default).
  final int? maxTokens;

  /// nucleus sampling: only consider tokens with a cumulative probability
  /// of [topP]. A value of 0.95 means it will ignore the tail 5% of tokens.
  /// Lower values reduce "hallucinations" and increase consistency.
  final double? topP;

  /// Penalizes new tokens based on whether they appear in the text so far.
  /// Increases the likelihood of the model talking about new topics.
  final double? presencePenalty;

  /// A list of string sequences that will cause the generation to stop early.
  /// Common values: `["<|im_end|>", "\nUser:"]`.
  final List<String> stopSequences;

  /// A JSON string containing additional options passed to the MLX backend.
  ///
  /// Supported keys:
  /// - `top_k` (int): Limit sampling to top K tokens.
  /// - `repetition_penalty` (double): Penalize repeated tokens.
  /// - `chat_template_kwargs` (Map): Model-specific tokenizer options.
  ///   - `enable_thinking` (bool): Toggle reasoning for models like Qwen3.5.
  final String? extraBody;

  const GenerateConfig({
    this.temperature,
    this.maxTokens,
    this.topP,
    this.presencePenalty,
    this.stopSequences = const [],
    this.extraBody,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (topP != null) 'top_p': topP,
      if (presencePenalty != null) 'presence_penalty': presencePenalty,
      'stop_sequences': stopSequences,
    };

    if (extraBody != null && extraBody!.isNotEmpty) {
      try {
        final Map<String, dynamic> extra = jsonDecode(extraBody!);
        map.addAll(extra);
      } catch (e) {
        // Fallback or warning if JSON is invalid
        if (kDebugMode) {
          print("[MlxLocalllm] Warning: failed to parse extraBody JSON: $e");
        }
      }
    }

    if (kDebugMode) {
      print("[MlxLocalllm] Final config map: $map");
    }
    return map;
  }
}

/// A high-performance local LLM singleton using Apple MLX.
class MlxLocalllm {
  // Singleton Pattern
  MlxLocalllm._internal();
  static final MlxLocalllm _instance = MlxLocalllm._internal();
  factory MlxLocalllm() => _instance;

  static const MethodChannel _channel = MethodChannel('mlx_localllm');
  static const EventChannel _eventChannel = EventChannel('mlx_localllm_events');
  static const EventChannel _generateEventChannel = EventChannel(
    'mlx_localllm_generate_events',
  );

  Stream<Map<String, dynamic>>? _eventStream;
  String? _currentModelPath;

  /// Whether a model is currently loaded in memory.
  bool get isModelLoaded => _currentModelPath != null;

  /// The path of the currently loaded model, or null if none is loaded.
  String? get currentModelPath => _currentModelPath;

  /// Stream for model-related events such as download progress.
  ///
  /// During a download via [downloadModel], this stream emits maps of the format:
  /// - `{'event': 'progress', 'repoId': '<id>', 'progress': 0.85}`
  /// - `{'event': 'complete', 'repoId': '<id>', 'path': '<local_path>'}`
  /// - `{'event': 'error', 'repoId': '<id>', 'error': '<message>'}`
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

  /// Downloads the MLX model from HuggingFace to the local device.
  ///
  /// The [repoId] is the model identifier on HuggingFace (e.g.
  /// `'mlx-community/Qwen2.5-0.5B-Instruct-4bit'`).
  ///
  /// Use [modelEvents] to track the download progress in real-time.
  /// Returns `true` if the download initiation is successful.
  /// Throws an [MlxEngineException] on platform error.
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
      if (success == true) {
        _currentModelPath = null;
      }
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

  /// Sets a custom absolute path where models should be downloaded and stored.
  ///
  /// Passing `null` or an empty string restores the default platform directory.
  Future<void> setCustomStoragePath(String? path) async {
    try {
      await _channel.invokeMethod('setCustomStoragePath', {'path': path});
    } on PlatformException catch (e) {
      throw MlxEngineException(
        e.code,
        e.message ?? "Failed to set custom storage path",
      );
    }
  }

  /// Gets the currently active storage path.
  Future<String> getCurrentStoragePath() async {
    try {
      final String? path = await _channel.invokeMethod('getCurrentStoragePath');
      return path ?? "";
    } on PlatformException catch (e) {
      throw MlxEngineException(
        e.code,
        e.message ?? "Failed to get current storage path",
      );
    }
  }

  /// Retrieves a list of repository IDs (model directory names) that currently exist
  /// in the active storage directory.
  Future<List<String>> getDownloadedModels() async {
    try {
      final List<dynamic>? models = await _channel.invokeMethod(
        'getDownloadedModels',
      );
      return models?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      throw MlxEngineException(
        e.code,
        e.message ?? "Failed to get downloaded models",
      );
    }
  }

  /// Loads an MLX model into memory for inference.
  ///
  /// You can pass a [modelPath] as either an absolute file path or directly
  /// use the HuggingFace `repoId` if the model was downloaded via [downloadModel].
  ///
  /// Returns `true` if loading is successful.
  /// Throws an [MlxEngineException] if the operation fails or the model
  /// exceeds hardware constraints.
  Future<bool> loadModel(String modelPath) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
      });
      if (success == true) {
        _currentModelPath = modelPath;
      }
      return success ?? false;
    } on PlatformException catch (e) {
      _currentModelPath = null;
      throw MlxEngineException(
        e.code,
        e.message ?? "Unknown error loading model",
      );
    } catch (e) {
      _currentModelPath = null;
      throw MlxEngineException("UNKNOWN_ERROR", e.toString());
    }
  }

  /// Generates a complete text response based on the given [prompt].
  ///
  /// This is a blocking operation and will await until the full text sequence
  /// is generated by the local LLM. For real-time typing effects,
  /// see [generateStream].
  ///
  /// Optional parameters:
  /// - [config]: A [GenerateConfig] object to control temperature, max tokens,
  ///   stop sequences, and any [extraOptions] passed down to MLX.
  ///
  /// Throws an [MlxEngineException] if the text generation fails or if the
  /// model has not been loaded yet.
  Future<String> generate({
    required String prompt,
    GenerateConfig? config,
  }) async {
    final conf = config ?? const GenerateConfig();
    try {
      final String? response = await _channel.invokeMethod<String>('generate', {
        'prompt': prompt,
        ...conf.toMap(),
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

  /// Generates text as an asynchronous stream based on the given [prompt].
  ///
  /// This method enables a typewriter effect in the UI by yielding standard
  /// `String` chunks as soon as they are inferred by the model.
  ///
  /// Optional parameters:
  /// - [config]: A [GenerateConfig] object to control temperature, max tokens,
  ///   stop sequences, and any [extraOptions] passed down to MLX.
  ///
  /// Throws an [MlxEngineException] if the text generation fails.
  Stream<String> generateStream({
    required String prompt,
    GenerateConfig? config,
  }) {
    final conf = config ?? const GenerateConfig();
    final controller = StreamController<String>();
    StreamSubscription? sub;
    bool isClosed = false;

    sub = _generateEventChannel.receiveBroadcastStream().listen(
      (event) {
        if (isClosed) return;
        if (event is Map) {
          if (event['text'] != null) {
            final chunk = event['text'] as String;

            controller.add(chunk);
          }
          if (event['done'] == true) {
            isClosed = true;
            sub?.cancel();
            controller.close();
          }
        }
      },
      onError: (error) {
        if (isClosed) return;
        isClosed = true;
        controller.addError(error);
        sub?.cancel();
        controller.close();
      },
    );

    _channel
        .invokeMethod('generateStream', {'prompt': prompt, ...conf.toMap()})
        .catchError((error) {
          if (!isClosed) {
            isClosed = true;
            controller.addError(error);
            sub?.cancel();
            controller.close();
          }
        });

    return controller.stream;
  }
}

// End of file
