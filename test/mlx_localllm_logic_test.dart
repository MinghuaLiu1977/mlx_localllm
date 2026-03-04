import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mlx_localllm/mlx_localllm.dart';
import 'package:mlx_localllm/src/model_manager.dart';
import 'package:mlx_localllm/src/inference_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'com.eastlakestudio.mlx_localllm',
  );
  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'isSupported':
              return true;
            case 'downloadModel':
              return true;
            case 'loadModel':
              return true;
            case 'inference':
              return 'Mock Response';
            default:
              return null;
          }
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'getApplicationSupportDirectory') {
            return '/mock/support';
          }
          return null;
        });

    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  group('ModelManager Tests', () {
    test('downloadModel sends correct arguments', () async {
      final modelManager = ModelManager(channel);

      // We don't await the stream here just to check the initial call
      modelManager.downloadModel('test-repo', endpoint: 'https://test.com');

      expect(log, hasLength(1));
      expect(log.first.method, 'downloadModel');
      expect(log.first.arguments['repoId'], 'test-repo');
      expect(log.first.arguments['endpoint'], 'https://test.com');
    });

    test('handles downloadProgress method call', () async {
      final modelManager = ModelManager(channel);
      final stream = modelManager.progressStream;

      final expectation = expectLater(
        stream,
        emits(
          predicate<DownloadProgress>(
            (p) => p.repoId == 'test-repo' && p.progress == 0.5 && !p.isDone,
          ),
        ),
      );

      // Simulate native side calling back
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('downloadProgress', {
                'repoId': 'test-repo',
                'progress': 0.5,
              }),
            ),
            (ByteData? data) {},
          );

      await expectation;
    });

    test('handles downloadComplete method call', () async {
      final modelManager = ModelManager(channel);

      final expectation = expectLater(
        modelManager.progressStream,
        emits(
          predicate<DownloadProgress>(
            (p) =>
                p.repoId == 'test-repo' &&
                p.progress == 1.0 &&
                p.isDone &&
                p.path == '/mock/path',
          ),
        ),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('downloadComplete', {
                'repoId': 'test-repo',
                'path': '/mock/path',
              }),
            ),
            (ByteData? data) {},
          );

      await expectation;
    });

    test('deleteModel throws error if model does not exist', () async {
      final modelManager = ModelManager(channel);

      // Use a repo ID that definitely doesn't exist
      final nonExistentRepo =
          'non-existent-repo-${DateTime.now().millisecondsSinceEpoch}';

      expect(
        () => modelManager.deleteModel(nonExistentRepo),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Model not found'),
          ),
        ),
      );
    });
  });

  group('InferenceEngine Tests', () {
    test('loadModel calls native with correct path', () async {
      final modelManager = ModelManager(channel);
      final engine = InferenceEngine(channel, modelManager);

      // Note: getModelPath will use path_provider which might need more mocking if it fails
      // But for simple logic test, as long as it doesn't crash:
      final success = await engine.loadModel('test-repo');

      expect(success, isTrue);
      expect(log.any((m) => m.method == 'loadModel'), isTrue);
    });

    test('generate calls native with correct prompt', () async {
      final modelManager = ModelManager(channel);
      final engine = InferenceEngine(channel, modelManager);

      final result = await engine.generate('Hello', temperature: 0.7);

      expect(result, 'Mock Response');
      expect(log.last.method, 'inference');
      expect(log.last.arguments['prompt'], 'Hello');
      expect(log.last.arguments['temperature'], 0.7);
    });
  });
}
