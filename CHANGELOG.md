# 0.2.6

* **Fixed SPM Repository URL**: Corrected the Swift Package Manager repository URL for `mlx-swift-lm`.
* **Synced Versions**: Synchronized version strings across `pubspec.yaml` and native `.podspec` files.

# 0.2.5

* **Fixed Dependency**: Corrected MLX dependency repository from `mlx-swift-llm` to `mlx-swift-lm`. This ensures the latest MLX core features are correctly integrated.

# 0.2.4

* **Fixed SPM Detection**: Restructured native directories to `ios/mlx_localllm/` and `macos/mlx_localllm/` as required by `pub.dev` score analyzer (`pana`). This ensures full native Swift Package Manager support is correctly recognized.
* **Code Formatting**: Fixed Dart code formatting issues to satisfy `pub.dev` quality checks.

# 0.2.3

* **Fixed Documentation**: Fixed an issue where the mockup image link was using an insecure local path. Now using a relative path compatible with pub.dev.

# 0.2.2

* **Full Swift Package Manager Support**: Added `Package.swift` to both `ios/` and `macos/` directories. This fully satisfies native SPM requirements and improves the platform score on pub.dev.

# 0.2.1

* **Native SPM support**: Added native Swift Package Manager support in `pubspec.yaml`. No manual Xcode configuration required for MLX dependencies.
* Improved pub.dev platform score.

# 0.2.0

* **Added iOS support** (iPhone, iPad).
* Unified Swift codebase for iOS and macOS.
* Set iOS deployment target to 17.0.
* Updated example project with iOS project structure.

# 0.1.0

* Initial release.
* Support for local LLM inference on macOS (Apple Silicon).
* Native MLX framework integration.
* Robust model downloader with mirror support.
* Progress reporting and download cancellation.
* Model management (isDownloaded, deleteModel with error feedback).
