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
  final TextEditingController _temperatureController = TextEditingController(
    text: '1.0',
  );
  final TextEditingController _maxTokensController = TextEditingController(
    text: '256',
  );
  final TextEditingController _storagePathController = TextEditingController();
  final TextEditingController _extraBodyController = TextEditingController(
    text:
        '{\n  "top_p": 0.8,\n  "top_k": 20,\n  "min_p": 0.0,\n  "presence_penalty": 1.5,\n  "repetition_penalty": 1.0,\n  "chat_template_kwargs": {"enable_thinking": false}\n}',
  );

  String _status = 'Idle';
  double _progress = 0;
  String _response = '';
  bool _isSupported = false;
  String _currentStoragePath = '';
  List<String> _downloadedModels = [];
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
      final type = event['event'];

      setState(() {
        if (type == 'progress') {
          final p = event['progress'];
          if (p != null) {
            _progress = (p as num).toDouble();
          }
          final downloadedBytes = event['downloadedBytes'] as num?;
          final totalBytes = event['totalBytes'] as num?;
          if (downloadedBytes != null && totalBytes != null && totalBytes > 0) {
            final downloadedMb = (downloadedBytes / (1024 * 1024))
                .toStringAsFixed(1);
            final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            _status = 'Downloading... $downloadedMb MB / $totalMb MB';
          } else {
            _status = 'Downloading...';
          }
        } else if (type == 'complete') {
          _progress = 1.0;
          _status = 'Download Complete';
        } else if (type == 'error') {
          _status = 'Download Error: ${event['error']}';
        }
      });
    });
  }

  Future<void> _checkSupport() async {
    final supported = await MlxLocalllm().isSupported();
    final path = await MlxLocalllm().getCurrentStoragePath();
    final models = await MlxLocalllm().getDownloadedModels();
    setState(() {
      _isSupported = supported;
      _currentStoragePath = path;
      _downloadedModels = models;
    });
  }

  Future<void> _downloadModel() async {
    final repoId = _repoController.text.trim();
    setState(() {
      _status = 'Connecting to HuggingFace...';
      _progress = 0;
    });

    try {
      await MlxLocalllm().downloadModel(repoId);
      // Wait for EventChannel 'complete' or 'error' events to update the UI
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

  Future<void> _setStoragePath() async {
    final path = _storagePathController.text.trim();
    try {
      await MlxLocalllm().setCustomStoragePath(path.isEmpty ? null : path);
      final actualPath = await MlxLocalllm().getCurrentStoragePath();
      setState(() {
        _status = 'Storage path updated';
        _currentStoragePath = actualPath;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _listModels() async {
    try {
      final models = await MlxLocalllm().getDownloadedModels();
      setState(() {
        _downloadedModels = models;
      });
      if (models.isEmpty) {
        setState(() => _status = 'No downloaded models found in path.');
      } else {
        setState(() => _status = 'Downloaded Models:\n${models.join('\n')}');
      }
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
    _response = '';

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

  Future<void> _generateStream() async {
    final prompt = _promptController.text.trim();
    final temp = double.tryParse(_temperatureController.text) ?? 0.0;
    final tokens = int.tryParse(_maxTokensController.text) ?? 1024;

    setState(() {
      _status = 'Generating Stream...';
      _response = '';
    });

    try {
      final stream = MlxLocalllm().generateStream(
        prompt: prompt,
        config: GenerateConfig(
          temperature: temp,
          maxTokens: tokens,
          topP: 0.8,
          presencePenalty: 1.5,
          extraBody: _extraBodyController.text,
        ),
      );
      await for (final text in stream) {
        setState(() {
          _response += text;
        });
      }
      setState(() => _status = 'Done');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    final temp = double.tryParse(_temperatureController.text) ?? 0.0;
    final tokens = int.tryParse(_maxTokensController.text) ?? 1024;

    setState(() {
      _status = 'Generating (blocking)...';
      _response = '';
    });

    try {
      final result = await MlxLocalllm().generate(
        prompt: prompt,
        config: GenerateConfig(
          temperature: temp,
          maxTokens: tokens,
          topP: 0.8,
          extraBody: _extraBodyController.text,
        ),
      );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _storagePathController,
                          decoration: InputDecoration(
                            labelText:
                                'Custom Storage Path (Leave empty for default)',
                            hintText: _currentStoragePath,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _setStoragePath,
                        child: const Text('Set'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Path: $_currentStoragePath',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<String>(
                    expandedInsets: EdgeInsets.zero,
                    initialSelection: _repoController.text,
                    controller: _repoController,
                    label: const Text('HuggingFace Repo ID (Select or Input)'),
                    dropdownMenuEntries: _downloadedModels
                        .map(
                          (m) => DropdownMenuEntry<String>(value: m, label: m),
                        )
                        .toList(),
                    onSelected: (String? selection) {
                      if (selection != null) {
                        setState(() {
                          _repoController.text = selection;
                        });
                      }
                    },
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _listModels,
                        child: const Text('List Local'),
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
                    decoration: const InputDecoration(
                      labelText: 'Prompt',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextField(
                                controller: _temperatureController,
                                decoration: const InputDecoration(
                                  labelText: 'Temperature',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                              TextField(
                                controller: _maxTokensController,
                                decoration: const InputDecoration(
                                  labelText: 'Max Tokens',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _extraBodyController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              labelText: 'Extra Body (JSON)',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: MlxLocalllm().isModelLoaded
                            ? _generateStream
                            : null,
                        child: const Text('Generate (Stream)'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: MlxLocalllm().isModelLoaded
                            ? _generate
                            : null,
                        child: const Text('Generate (Non-stream)'),
                      ),
                      if (!MlxLocalllm().isModelLoaded)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Please load a model first',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: SelectableText(
                        _response.isEmpty
                            ? '(Waiting for response)'
                            : _response,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
