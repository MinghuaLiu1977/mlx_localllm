import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mlx_localllm_method_channel.dart';

abstract class MlxLocalllmPlatform extends PlatformInterface {
  /// Constructs a MlxLocalllmPlatform.
  MlxLocalllmPlatform() : super(token: _token);

  static final Object _token = Object();

  static MlxLocalllmPlatform _instance = MethodChannelMlxLocalllm();

  /// The default instance of [MlxLocalllmPlatform] to use.
  ///
  /// Defaults to [MethodChannelMlxLocalllm].
  static MlxLocalllmPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MlxLocalllmPlatform] when
  /// they register themselves.
  static set instance(MlxLocalllmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
