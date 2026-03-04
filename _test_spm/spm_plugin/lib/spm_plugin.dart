
import 'spm_plugin_platform_interface.dart';

class SpmPlugin {
  Future<String?> getPlatformVersion() {
    return SpmPluginPlatform.instance.getPlatformVersion();
  }
}
