import 'package:flutter/services.dart';
import 'model_manager.dart';

class InferenceEngine {
  final MethodChannel _channel;
  final ModelManager _modelManager;
  String? _currentModelId;

  InferenceEngine(this._channel, this._modelManager);

  /// Currently loaded model ID.
  String? get currentModelId => _currentModelId;

  /// Loads a model into memory.
  Future<bool> loadModel(String repoId) async {
    if (_currentModelId == repoId) return true;

    final path = await _modelManager.getModelPath(repoId);
    final bool success = await _channel.invokeMethod('loadModel', {
      'modelPath': path,
    });

    if (success) {
      _currentModelId = repoId;
    }
    return success;
  }

  /// Performs inference.
  Future<String> generate(
    String prompt, {
    double temperature = 0.0,
    List<String>? stopSequences,
  }) async {
    final String result = await _channel.invokeMethod('inference', {
      'prompt': prompt,
      'temperature': temperature,
      'stop_sequences': stopSequences ?? [],
    });
    return result;
  }
}
