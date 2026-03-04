# mlx_localllm_example

A comprehensive example application demonstrating the full capabilities of the `mlx_localllm` plugin on macOS and iOS.

## Features Demonstrated

- **Platform Support Checking**: Detects if the current device supports MLX acceleration.
- **Model Discovery**: Shows how to download models from Hugging Face or mirrors.
- **Download Management**: Real-time progress tracking and cancellation support.
- **Inference Engine**: Loading local models and generating text with adjustable parameters (temperature, stop sequences).

## Running the Example

### 1. Requirements
- **Hardware**: A physical Apple Silicon device (iPhone/iPad with iOS 17+ or Mac with macOS 14+).
- **Toolchain**: Xcode 15+ and Flutter 3.24+.

### 2. Setup
No manual dependency configuration is required as the plugin uses native SPM support.

```bash
flutter pub get
```

### 3. Execution

#### For macOS:
```bash
flutter run -d macos
```

#### For iOS (Real Device):
```bash
flutter run -d ios
```

## Note on Models
The example default to downloading `mlx-community/Qwen2.5-0.5B-Instruct-4bit`. Ensure you have a stable internet connection for the initial download (~350MB).
