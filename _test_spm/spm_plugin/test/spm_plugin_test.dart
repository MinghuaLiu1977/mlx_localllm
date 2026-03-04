import 'package:flutter_test/flutter_test.dart';
import 'package:spm_plugin/spm_plugin.dart';
import 'package:spm_plugin/spm_plugin_platform_interface.dart';
import 'package:spm_plugin/spm_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSpmPluginPlatform
    with MockPlatformInterfaceMixin
    implements SpmPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SpmPluginPlatform initialPlatform = SpmPluginPlatform.instance;

  test('$MethodChannelSpmPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSpmPlugin>());
  });

  test('getPlatformVersion', () async {
    SpmPlugin spmPlugin = SpmPlugin();
    MockSpmPluginPlatform fakePlatform = MockSpmPluginPlatform();
    SpmPluginPlatform.instance = fakePlatform;

    expect(await spmPlugin.getPlatformVersion(), '42');
  });
}
