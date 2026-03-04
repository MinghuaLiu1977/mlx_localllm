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
