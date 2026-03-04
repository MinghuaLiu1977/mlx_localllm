import 'package:flutter/services.dart';
import 'src/model_manager.dart';
import 'src/inference_engine.dart';

export 'src/model_manager.dart' show ModelManager;
export 'src/inference_engine.dart' show InferenceEngine;
export 'src/download_progress.dart' show DownloadProgress;

class MlxLocalllm {
  static const MethodChannel _channel = MethodChannel(
    'com.eastlakestudio.mlx_localllm',
  );

  static final ModelManager modelManager = ModelManager(_channel);

  static final InferenceEngine inferenceEngine = InferenceEngine(
    _channel,
    modelManager,
  );

  /// Checks if the current hardware/OS supports MLX.
  ///
  /// Requires Apple Silicon (M1/M2/M3) and macOS 14.0+.
  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod('isSupported');
    } catch (_) {
      return false;
    }
  }
}
