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

2. **Platform Setup**:
   - **macOS/iOS**: The plugin uses Swift Package Manager (SPM) to manage MLX dependencies. Flutter (3.24+) will automatically resolve these dependencies.
   - **Real Device Required**: MLX requires Metal GPU support, so inference only works on physical Apple Silicon devices (M1, M2, iPhone 12+, etc.), not in simulators.

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

2. **平台配置**:
   - **macOS/iOS**: 插件使用 Swift Package Manager (SPM) 管理 MLX 依赖。Flutter (3.24+) 会自动处理这些依赖。
   - **必须使用真机**: MLX 需要 Metal GPU 加持，推理功能仅在物理设备（M1、M2、iPhone 12+ 等）上运行，不支持模拟器。

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
