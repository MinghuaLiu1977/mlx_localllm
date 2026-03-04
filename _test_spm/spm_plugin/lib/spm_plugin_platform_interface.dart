import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'spm_plugin_method_channel.dart';

abstract class SpmPluginPlatform extends PlatformInterface {
  /// Constructs a SpmPluginPlatform.
  SpmPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SpmPluginPlatform _instance = MethodChannelSpmPlugin();

  /// The default instance of [SpmPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSpmPlugin].
  static SpmPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SpmPluginPlatform] when
  /// they register themselves.
  static set instance(SpmPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
