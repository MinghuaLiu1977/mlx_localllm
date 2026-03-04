import 'package:flutter_test/flutter_test.dart';
import 'package:mlx_localllm/mlx_localllm.dart';
import 'package:mlx_localllm/mlx_localllm_platform_interface.dart';
import 'package:mlx_localllm/mlx_localllm_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMlxLocalllmPlatform
    with MockPlatformInterfaceMixin
    implements MlxLocalllmPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MlxLocalllmPlatform initialPlatform = MlxLocalllmPlatform.instance;

  test('$MethodChannelMlxLocalllm is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMlxLocalllm>());
  });

  test('getPlatformVersion', () async {
    MlxLocalllm mlxLocalllmPlugin = MlxLocalllm();
    MockMlxLocalllmPlatform fakePlatform = MockMlxLocalllmPlatform();
    MlxLocalllmPlatform.instance = fakePlatform;

    expect(await mlxLocalllmPlugin.getPlatformVersion(), '42');
  });
}
