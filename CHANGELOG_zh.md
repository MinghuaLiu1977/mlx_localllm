# 0.2.11

* **改进推理日志**: 实现了行缓冲日志输出，支持实时的推理过程监控，提升了日志的可读性。
* **支持 Jinja 模板参数**: 增加了向模型分词器传递 `chat_template_kwargs` 的功能，支持动态控制模型行为。
* **修复思考模式显示**: 默认注入 `add_generation_prompt` 参数并优化了输出清洗逻辑，确保 Qwen3.5 等模型的 `<think>` 标签和推理过程能正确渲染。
* **类型安全的参数传递**: 在 Swift 原生层实现了 `additionalContext` 的健壮类型转换，确保 Dart 传入的各种格式参数都能被正确解析。

# 0.2.10

* **修复 iOS SPM 支持**: 增加了 `ios/mlx_localllm/Package.swift`，以满足 iOS 平台对原生 Swift Package Manager 的识别要求。
* **统一原生结构**: 确保 `ios` 和 `macos` 目录具有完全一致的 Swift Package 结构，提升兼容性评分。

# 0.2.9

* **iOS 支持**: 增加对 iOS 平台（iPhone/iPad）的完整支持，基于 Apple MLX 框架。
* **x86 架构支持 (Mock)**: 通过条件编译支持 x86 (Intel Mac) 架构编译。在 x86 环境下推理功能将返回“不支持的架构”错误，但允许项目正常编译与链接。
* **重构原生代码**: 通过共享源码文件统一了 iOS 和 macOS 的 Swift 实现。
* **提升 Pub.dev 评分**: 修复了测试中的 Lint 错误并更新了 example 项目结构。

# 0.2.8

* **修复原生错误**: 修复了 `NativeMLXService` 缺失的成员方法（`unloadModel`, `checkModelExists`, `deleteModel`）。
* **同步 API 名称**: 统一了 Dart 与 Swift 之间的 `MethodChannel` 及其方法名称。
* **稳定示例项目**: 验证了示例项目在 macOS ARM (SPM) 环境下的编译成功。

# 0.2.7

* **聚焦 macOS ARM**: 专门针对 Apple Silicon macOS 进行了优化和稳定。
* **全量 API 实现**: 完成了 `loadModel`, `unloadModel`, `generate`, `downloadModel` (带进度流), `checkModelExists`, 以及 `deleteModel`。
* **状态管理**: 改进了模型生命周期管理，支持自动缓存与引用追踪。
* **EventChannel 支持**: 增加了健壮的事件流，用于模型下载与加载过程中的实时进度与状态报告。

# 0.2.6

* **修复 SPM 仓库 URL**: 修正了 `mlx-swift-lm` 的 Swift Package Manager 仓库地址。
* **同步版本号**: 同步了 `pubspec.yaml` 与原生 `.podspec` 文件中的版本号。

# 0.2.5

* **修复依赖**: 将 MLX 依赖仓库从 `mlx-swift-llm` 修正为 `mlx-swift-lm`。这确保了 MLX 核心功能的正确集成。

# 0.2.4

* **修复 SPM 检测问题**: 将原生目录结构调整为 `ios/mlx_localllm/` 和 `macos/mlx_localllm/`，以符合 `pub.dev` 评分分析器 (`pana`) 的要求。这确保了原生 Swift Package Manager 支持能被正确识别。
* **代码格式化**: 修复了 Dart 代码格式问题，以满足 `pub.dev` 的质量检查。

# 0.2.3

* **修复文档问题**: 修复了 README 中图片链接使用本地路径的问题。现在使用符合 pub.dev 要求的相对路径。

# 0.2.2

* **完善 Swift Package Manager 支持**: 在 `ios/` 和 `macos/` 目录下增加了 `Package.swift` 文件。这完全满足了原生 SPM 的要求，并提升了 pub.dev 上的平台评分。

# 0.2.1

* **原生 SPM 支持**: 在 `pubspec.yaml` 中增加了原生 Swift Package Manager 支持。不再需要手动在 Xcode 中配置 MLX 依赖。
* 提升了 pub.dev 的平台评分。

# 0.2.0

* **新增 iOS 支持** (iPhone, iPad)。
* 采用统一的 Swift 代码库同时支持 iOS 和 macOS。
* 设置 iOS 最低部署版本为 17.0。
* 为 example 项目增加了 iOS 项目结构。

# 0.1.0

* 初始版本发布。
* 支持 macOS (Apple Silicon) 本地大模型推理。
* 原生集成 Apple MLX 框架。
* 包含鲁棒的模型下载器，支持 HuggingFace 镜像站。
* 支持下载进度实时上报与取消功能。
* 完善的模型管理（状态检查、带报错反馈的删除逻辑）。
