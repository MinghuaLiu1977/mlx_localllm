import 'package:flutter/material.dart';
import 'package:mlx_localllm/mlx_localllm.dart';
import 'dart:async';

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
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _checkSupport();
    _setupEventListener();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _setupEventListener() {
    _eventSubscription = MlxLocalllm().modelEvents.listen((event) {
      final type = event['type'];
      final value = (event['value'] as num).toDouble();

      setState(() {
        _progress = value;
        if (type == 'downloadProgress') {
          _status = 'Downloading...';
        } else if (type == 'loadProgress') {
          _status = 'Loading...';
        }
      });
    });
  }

  Future<void> _checkSupport() async {
    final supported = await MlxLocalllm().isSupported();
    setState(() => _isSupported = supported);
  }

  Future<void> _downloadModel() async {
    final repoId = _repoController.text.trim();
    setState(() {
      _status = 'Connecting to HuggingFace...';
      _progress = 0;
    });

    try {
      final success = await MlxLocalllm().downloadModel(repoId);
      setState(() {
        _status = success ? 'Download Complete' : 'Download Failed';
        _progress = 1.0;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _deleteModel() async {
    final repoId = _repoController.text.trim();
    try {
      final success = await MlxLocalllm().deleteModel(repoId);
      setState(() {
        _status = success ? 'Model Deleted' : 'Delete Failed';
        _progress = 0;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _checkModelExists() async {
    final repoId = _repoController.text.trim();
    try {
      final exists = await MlxLocalllm().checkModelExists(repoId);
      setState(() {
        _status = exists ? 'Model Exists Locally' : 'Model Not Found';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _loadModel() async {
    final repoId = _repoController.text.trim();
    setState(() {
      _status = 'Loading model...';
      _progress = 0;
    });

    try {
      final success = await MlxLocalllm().loadModel(repoId);
      setState(() {
        _status = success ? 'Model Loaded' : 'Load Failed';
        _progress = 1.0;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _unloadModel() async {
    try {
      final success = await MlxLocalllm().unloadModel();
      setState(() {
        _status = success ? 'Model Unloaded' : 'Unload Failed';
        _progress = 0;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    setState(() => _status = 'Generating...');

    try {
      final result = await MlxLocalllm().generate(prompt: prompt);
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
                  onPressed: _downloadModel,
                  child: const Text('Download'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _deleteModel,
                  child: const Text('Delete'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _checkModelExists,
                  child: const Text('Check'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadModel,
                  child: const Text('Load'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _unloadModel,
                  child: const Text('Unload'),
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
                    onPressed: () {
                      setState(() {
                        _progress = 0;
                        _status = "Cancelled mockup progress";
                      });
                    },
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
