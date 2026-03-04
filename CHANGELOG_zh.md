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
