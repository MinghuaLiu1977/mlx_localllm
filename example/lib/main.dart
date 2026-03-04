import 'package:flutter/material.dart';
import 'package:mlx_localllm/mlx_localllm.dart';

void main() {
  runApp(const MaterialApp(home: ExampleApp()));
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final TextEditingController _repoController = TextEditingController(
    text: 'mlx-community/Qwen2.5-0.5B-Instruct-4bit',
  );
  final TextEditingController _promptController = TextEditingController(
    text: 'Hello, what is MLX?',
  );

  String _status = 'Idle';
  double _progress = 0;
  String _response = '';
  bool _isSupported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await MlxLocalllm.isSupported();
    setState(() => _isSupported = supported);
  }

  void _download() {
    final repoId = _repoController.text.trim();
    if (repoId.isEmpty) return;

    setState(() {
      _status = 'Downloading...';
      _progress = 0;
    });

    MlxLocalllm.modelManager
        .downloadModel(repoId)
        .listen(
          (p) {
            setState(() {
              _progress = p.progress;
              if (p.isDone) _status = 'Downloaded';
            });
          },
          onError: (e) {
            setState(() => _status = 'Error: $e');
          },
        );
  }

  void _cancelDownload() {
    final repoId = _repoController.text.trim();
    MlxLocalllm.modelManager.cancelDownload(repoId);
    setState(() => _status = 'Download cancelled');
  }

  Future<void> _delete() async {
    final repoId = _repoController.text.trim();
    try {
      await MlxLocalllm.modelManager.deleteModel(repoId);
      setState(() => _status = 'Deleted');
    } catch (e) {
      setState(() => _status = 'Error deleting: ${e.toString()}');
    }
  }

  Future<void> _generate() async {
    final repoId = _repoController.text.trim();
    final prompt = _promptController.text.trim();

    setState(() => _status = 'Loading model...');

    try {
      final loaded = await MlxLocalllm.inferenceEngine.loadModel(repoId);
      if (!loaded) {
        setState(() => _status = 'Failed to load model');
        return;
      }

      setState(() => _status = 'Generating...');
      final result = await MlxLocalllm.inferenceEngine.generate(prompt);
      setState(() {
        _response = result;
        _status = 'Done';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MLX Local LLM Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported: $_isSupported',
              style: TextStyle(
                color: _isSupported ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repoController,
              decoration: const InputDecoration(
                labelText: 'HuggingFace Repo ID',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _download,
                  child: const Text('Download'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _delete, child: const Text('Delete')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final exists = await MlxLocalllm.modelManager.isDownloaded(
                      _repoController.text.trim(),
                    );
                    setState(
                      () => _status = exists ? 'Exists locally' : 'Not found',
                    );
                  },
                  child: const Text('Check'),
                ),
              ],
            ),
            if (_progress > 0 && _progress < 1) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(_progress * 100).toStringAsFixed(1)}%'),
                  TextButton(
                    onPressed: _cancelDownload,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 32),
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Prompt'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _generate, child: const Text('Generate')),
            const SizedBox(height: 16),
            Text(
              'Status: $_status',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Response:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Text(
                _response.isEmpty ? '(Waiting for response)' : _response,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
