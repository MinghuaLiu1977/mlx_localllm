import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'spm_plugin_platform_interface.dart';

/// An implementation of [SpmPluginPlatform] that uses method channels.
class MethodChannelSpmPlugin extends SpmPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('spm_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
