# mlx_localllm

![mlx_localllm_mockup](assets/mlx_localllm_mockup.png)

[English](#english) | [简体中文](#简体中文)

---

<a name="english"></a>
## English

A Flutter plugin for high-performance localized LLM inference on macOS using Apple's **MLX** framework. It provides zero-latency interaction by loading models directly into the application process.

### Features
- 🚀 **Native Acceleration**: Built on Apple's MLX for optimal performance on Apple Silicon.
- 📦 **In-Process Inference**: No external sidecars or servers (like Ollama) required.
- 🌐 **Robust Downloader**: Built-in support for Hugging Face and mirrors with resilient chunk-based downloading.
- 🛠️ **Full Lifecycle**: From model discovery and download to stateful conversational inference.

### Platform Support

| Platform | Support | Architecture | Min OS |
| :--- | :---: | :--- | :--- |
| **macOS** | ✅ | Apple Silicon (ARM64) / Intel (x86_64 Mock) | 14.0+ |
| **iOS** | ✅ | ARM64 | 17.0+ |
| **Android** | ❌ | - | - |
| **Windows** | ❌ | - | - |
| **Linux** | ❌ | - | - |
| **Web** | ❌ | - | - |

### Requirements
- **macOS**: 14.0 or higher.
- **iOS**: 17.0 or higher.
- **Hardware**: Apple Silicon (M1, M2, M3, etc.) for inference.
- **Flutter**: 3.0.0 or higher.

### Installation

1. Add the dependency to your `pubspec.yaml`:
   ```bash
   flutter pub add mlx_localllm
   ```

2. **Platform Setup**:
   The plugin uses **Swift Package Manager (SPM)** natively (requires Flutter 3.24+).
   - **macOS/iOS**: Dependencies are automatically resolved by the Flutter toolchain.
   - **Architecture**:
     - **Apple Silicon (ARM64)**: Fully supported with native MLX acceleration.
     - **Intel (x86_64)**: Supported via **Mocking**. You can compile and link on Intel Macs, but inference calls will return an "Unsupported architecture" error. This allows for seamless development across different Mac architectures.

### Usage

#### Check Support
```dart
bool supported = await MlxLocalllm().isSupported();
```

#### Download Model
```dart
// Track progress via modelEvents stream
MlxLocalllm().modelEvents.listen((event) {
  if (event['event'] == 'progress') {
    print('Download progress: ${event['progress'] * 100}%');
  } else if (event['event'] == 'complete') {
    print('Download complete at ${event['path']}');
  }
});

await MlxLocalllm().downloadModel('mlx-community/Qwen2.5-0.5B-Instruct-4bit');
```

### API Reference

#### `MlxLocalllm` Singleton

| Method | Description | Returns |
| :--- | :--- | :--- |
| `isSupported()` | Checks if hardware supports MLX (requires Apple Silicon GPU). | `Future<bool>` |
| `downloadModel(repoId)` | Starts background download from HF. Monitor via `modelEvents`. | `Future<bool>` |
| `loadModel(path)` | Loads model into memory from absolute path or repoId. | `Future<bool>` |
| `unloadModel()` | Releases model and frees system memory. | `Future<bool>` |
| `generate(prompt, config)` | Generates complete response (blocking). | `Future<String>` |
| `generateStream(prompt, config)` | Yields text chunks in real-time. | `Stream<String>` |
| `checkModelExists(repoId)` | Checks if model folder exists locally. | `Future<bool>` |
| `deleteModel(repoId)` | Deletes model from disk. | `Future<bool>` |
| `setCustomStoragePath(path)` | Sets/Resets model storage root folder. | `Future<void>` |

---

#### `GenerateConfig` Parameters

Detailed control over model output:

| Parameter | Type | Default | Description |
| :--- | :---: | :---: | :--- |
| `temperature` | `double` | `0.0` | Higher = creative, Lower = deterministic. |
| `maxTokens` | `int` | `1024` | Maximum length of generated response. |
| `topP` | `double` | `0.95` | Nucleus sampling probability threshold. |
| `presence_penalty`| `double` | `0.0` | Positive values penalize tokens already present. |
| `stopSequences` | `List` | `[]` | Tokens that stop generation (e.g. `["\nUser:"]`). |
| `extraBody` | `String` | `null` | A JSON string for advanced backend options. |

---

#### Advanced Configuration (`extraBody`)

Pass advanced parameters through `extraBody` as a JSON string:

```dart
GenerateConfig(
  extraBody: jsonEncode({
    "top_k": 50,
    "repetition_penalty": 1.2,
    "chat_template_kwargs": {
      "enable_thinking": true  // Required for reasoning models like Qwen3.5
    }
  })
)
```

#### Thinking Mode (Reasoning) Guide
Thinking models (like **Qwen/Qwen3.5-7B-Instruct**) use a special template logic to externalize their reasoning process.
1. **Enable Reasoning**: Include `"enable_thinking": true` in `chat_template_kwargs`.
2. **Handle Output**: The model will output text enclosed in `<think>...</think>` tags before the final answer.
3. **Hide Reasoning**: Set `"enable_thinking": false`. Depending on the model's template, it may output no tags or empty tags.

### Error Handling
The plugin throws `MlxEngineException` for native errors. Always wrap calls in try-catch:

```dart
try {
  await MlxLocalllm().generate(prompt: "...");
} on MlxEngineException catch (e) {
  print("Code: ${e.code}, Message: ${e.message}");
}
```

---

<a name="简体中文"></a>
## 简体中文

基于 Apple **MLX** 框架的 macOS/iOS 高性能本地大模型推理 Flutter 插件。通过将模型直接加载到应用进程中，提供零延迟的交互体验。

### 特性
- 🚀 **原生加速**: 基于 Apple MLX 针对 Apple Silicon 芯片深度优化。
- 📦 **进程内推理**: 无需安装 Ollama 等外部服务，零延迟通信。
- 🌐 **鲁棒下载器**: 内置分块下载机制，支持 Hugging Face 及其镜像站。
- 🛠️ **多平台支持**: 同时支持 macOS 和 iOS 平台。
- 💻 **架构兼容**: 支持 x86 架构 Mock 编译，确保 Intel Mac 开发者也能正常运行项目。

### 平台支持

| 平台 | 支持 | 架构 | 最低系统版本 |
| :--- | :---: | :--- | :--- |
| **macOS** | ✅ | Apple Silicon (ARM64) / Intel (x86_64 Mock) | 14.0+ |
| **iOS** | ✅ | ARM64 | 17.0+ |
| **Android** | ❌ | - | - |
| **Windows** | ❌ | - | - |
| **Linux** | ❌ | - | - |
| **Web** | ❌ | - | - |

### 系统要求
- **macOS**: 14.0 及以上。
- **iOS**: 17.0 及以上。
- **硬件**: Apple Silicon 系列芯片 (M1, M2, M3 等) 仅在这些芯片上支持推理。
- **Flutter**: 3.0.0 及以上。

### 安装指南

1. 在 `pubspec.yaml` 中添加依赖：
   ```bash
   flutter pub add mlx_localllm
   ```

2. **平台配置**:
   - **macOS/iOS**: 插件使用 Swift Package Manager (SPM) 管理 MLX 依赖。Flutter (3.24+) 会自动处理这些依赖。
   - **架构要求**: 
     - **Apple Silicon (ARM64)**: 原生支持，具备 MLX 加速。
     - **Intel (x86_64)**: 支持 **Mock 编译**。您可以在 Intel Mac 上正常编译和链接项目，但推理调用将返回“不支持的架构”错误。这极大地方便了跨架构的协同开发。

### API 参考

#### `MlxLocalllm` 单例方法

| 方法 | 描述 | 返回值 |
| :--- | :--- | :--- |
| `isSupported()` | 检查硬件是否支持 MLX (需要 Apple Silicon GPU)。 | `Future<bool>` |
| `downloadModel(repoId)` | 从 HuggingFace 开始后台下载。需通过 `modelEvents` 监控进度。 | `Future<bool>` |
| `loadModel(path)` | 从绝对路径或 repoId 将模型加载到内存。 | `Future<bool>` |
| `unloadModel()` | 从内存中卸载模型，释放系统资源。 | `Future<bool>` |
| `generate(prompt, config)` | 生成完整文本响应（阻塞式）。 | `Future<String>` |
| `generateStream(prompt, config)` | 实时返回生成的文本片段。 | `Stream<String>` |
| `checkModelExists(repoId)` | 检查模型文件夹是否已在本地存在。 | `Future<bool>` |
| `deleteModel(repoId)` | 从磁盘删除模型。 | `Future<bool>` |
| `setCustomStoragePath(path)` | 设置或重置模型的根存储目录。 | `Future<void>` |

---

#### `GenerateConfig` 配置参数

用于精确控制模型输出行为：

| 参数 | 类型 | 默认值 | 描述 |
| :--- | :---: | :---: | :--- |
| `temperature` | `double` | `0.0` | 越高越具创造性，越低越确定（Deterministic）。 |
| `maxTokens` | `int` | `1024` | 响应生成的最大 Token 数量。 |
| `topP` | `double` | `0.95` | 核采样（Nucleus sampling）概率阈值。 |
| `presence_penalty`| `double` | `0.0` | 正值会惩罚已出现的 Token，减少重复。 |
| `stopSequences` | `List` | `[]` | 停止生成的序列（如 `["\nUser:"]`）。 |
| `extraBody` | `String` | `null` | 传递给原生层的高级 JSON 配置字符串。 |

---

#### 高级配置 (`extraBody`)

通过 `extraBody` 以 JSON 字符串形式传递底层高级参数：

```dart
GenerateConfig(
  extraBody: jsonEncode({
    "top_k": 50,
    "repetition_penalty": 1.2,
    "chat_template_kwargs": {
      "enable_thinking": true  // 针对 Qwen3.5 等推理模型必填
    }
  })
)
```

#### 推理模式 (Thinking Mode) 指南
推理模型（如 **Qwen/Qwen3.5-7B-Instruct**）使用特殊的模板逻辑来外部化其思维链（CoT）。
1. **启动推理**: 在 `chat_template_kwargs` 中包含 `"enable_thinking": true`。
2. **输出处理**: 模型会在最终回答前输出被 `<think>...</think>` 标签包裹的思维过程。
3. **关闭推理**: 设置 `"enable_thinking": false`。根据模型模板不同，可能不输出标签或输出空标签。

### 错误处理
插件在发生原生错误时会抛出 `MlxEngineException`。建议始终使用 try-catch 包裹调用：

```dart
try {
  await MlxLocalllm().generate(prompt: "...");
} on MlxEngineException catch (e) {
  print("错误码: ${e.code}, 消息: ${e.message}");
}
```

### 许可证
MIT License.
