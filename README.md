# mlx_localllm

[English](#english) | [简体中文](#简体中文)

---

<a name="english"></a>
## English

A Flutter plugin for high-performance localized LLM inference on macOS using Apple's **MLX** framework. It provides zero-latency interaction by loading models directly into the application process.

### Features
- 🚀 **Native Acceleration**: Built on MLX for optimal performance on Apple Silicon.
- 📦 **In-Process**: No external dependencies like Ollama required.
- 🌐 **Robust Downloader**: Built-in support for HuggingFace and mirrors (hf-mirror.com) with resilient progress reporting.
- 🛠️ **Easy Integration**: Comprehensive API for model management and inference.

### Requirements
- **iOS**: 17.0 or higher.
- **macOS**: 14.0 or higher.
- **Hardware**: Apple Silicon (M1, M2, M3, iPhone 12+, etc.).
- **Flutter**: 3.0.0 or higher.

### Installation

1. Add the dependency to your `pubspec.yaml`:
   ```bash
   flutter pub add mlx_localllm
   ```

2. **CRITICAL STEP**: Since this plugin relies on Swift Package Manager (SPM) for MLX, you must configure your project:

   #### For macOS
   ```bash
   cd macos
   ruby ../path/to/mlx_localllm/scripts/setup_example_macos.rb
   ```

   #### For iOS
   Due to the current limitations of CocoaPods and SPM integration in Flutter, you need to manually add the dependency:
   1. Open `ios/Runner.xcworkspace` in Xcode.
   2. Go to **Project Settings** -> **Package Dependencies**.
   3. Add `https://github.com/ml-explore/mlx-swift-llm`.
   4. Ensure the **Runner** Target includes the library in **Frameworks, Libraries, and Embedded Content**.
   5. **Real Device Required**: MLX does not support the iOS Simulator (Metal GPU requirement).

### Usage

#### Check Support
```dart
bool supported = await MlxLocalllm.isSupported();
```

#### Download Model
```dart
MlxLocalllm.modelManager.downloadModel('mlx-community/Qwen2.5-0.5B-Instruct-4bit')
  .listen((progress) {
    print('Download progress: ${progress.progress * 100}%');
  });
```

#### Run Inference
```dart
await MlxLocalllm.inferenceEngine.loadModel('mlx-community/Qwen2.5-0.5B-Instruct-4bit');
String response = await MlxLocalllm.inferenceEngine.generate('Hello, who are you?');
print(response);
```

---

<a name="简体中文"></a>
## 简体中文

基于 Apple **MLX** 框架的 macOS 高性能本地大模型推理 Flutter 插件。通过将模型直接加载到应用进程中，提供零延迟的交互体验。

### 特性
- 🚀 **原生加速**: 基于 MLX 针对 Apple Silicon 深度优化。
- 📦 **进程内推理**: 无需安装 Ollama 等外部服务，集成度高。
- 🌐 **鲁棒下载器**: 内置对 HuggingFace 及其镜像站（如 hf-mirror.com）的支持，优化了进度上报稳定性。
- 🛠️ **全功能 API**: 提供完整的模型下载、删除、状态检查库及推理引擎。

### 系统要求
- **iOS**: 17.0 及以上。
- **系统**: macOS 14.0 及以上。
- **硬件**: Apple Silicon 系列芯片 (M1, M2, iPhne 15 Pro 等)。
- **Flutter**: 3.0.0 及以上。

### 安装指南

1. 在 `pubspec.yaml` 中添加依赖：
   ```bash
   flutter pub add mlx_localllm
   ```

2. **关键步骤**: 该插件通过 Swift Package Manager (SPM) 引用 MLX，由于 CocoaPods 与 SPM 的集成限制，您需要进行以下配置：

   #### macOS 配置
   ```bash
   cd macos
   ruby path/to/mlx_localllm/scripts/setup_example_macos.rb
   ```

   #### iOS 配置
   需手动在 Xcode 中关联依赖：
   1. 使用 Xcode 打开 `ios/Runner.xcworkspace`。
   2. 在 **Project Settings** -> **Package Dependencies** 中添加包：`https://github.com/ml-explore/mlx-swift-llm`。
   3. 确保 **Runner** Target 的 **Frameworks, Libraries, and Embedded Content** 已包含该库。
   4. **必须使用真机**: iOS 模拟器由于不支持 Metal GPU 扩展，无法运行 MLX。

### 快速开始

#### 硬件支持检测
```dart
bool supported = await MlxLocalllm.isSupported();
```

#### 模型下载
```dart
MlxLocalllm.modelManager.downloadModel('mlx-community/Qwen2.5-0.5B-Instruct-4bit')
  .listen((progress) {
    print('下载进度: ${progress.progress * 100}%');
  });
```

#### 执行推理
```dart
await MlxLocalllm.inferenceEngine.loadModel('mlx-community/Qwen2.5-0.5B-Instruct-4bit');
String response = await MlxLocalllm.inferenceEngine.generate('你好，请做下自我介绍');
print(response);
```

### 许可证
MIT License.
