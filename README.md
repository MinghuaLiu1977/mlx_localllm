# mlx_localllm

![mlx_localllm_mockup](file:///Users/minghualiu/.gemini/antigravity/brain/4fcf25fc-9ae6-463d-8ef3-940782249222/mlx_localllm_mockup_png_1772604563112.png)

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
| **iOS** | ✅ | Apple Silicon (ARM64) | 17.0+ |
| **macOS** | ✅ | Apple Silicon (ARM64) | 14.0+ |
| **Android** | ❌ | - | - |
| **Windows** | ❌ | - | - |
| **Linux** | ❌ | - | - |
| **Web** | ❌ | - | - |

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
   The plugin uses **Swift Package Manager (SPM)** natively (requires Flutter 3.24+).
   - **macOS/iOS**: Dependencies are automatically resolved by the Flutter toolchain. No manual Xcode configuration is typically required.
   - **Real Device Required**: Inference requires Metal GPU acceleration. It **will not run on simulators**.

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
- 🚀 **原生加速**: 基于 Apple MLX 针对 Apple Silicon 芯片深度优化。
- 📦 **进程内推理**: 无需安装 Ollama 等外部服务，零延迟通信。
- 🌐 **鲁棒下载器**: 内置分块下载机制，支持 Hugging Face 及其镜像站。
- 🛠️ **全栈能力**: 提供从模型搜索、下载、管理到推断的完整链路。

### 平台支持

| 平台 | 支持 | 架构 | 最低系统版本 |
| :--- | :---: | :--- | :--- |
| **iOS** | ✅ | Apple Silicon (ARM64) | 17.0+ |
| **macOS** | ✅ | Apple Silicon (ARM64) | 14.0+ |
| **Android** | ❌ | - | - |
| **Windows** | ❌ | - | - |
| **Linux** | ❌ | - | - |
| **Web** | ❌ | - | - |

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
