import FlutterMacOS
import Foundation

public class MlxLocalllmPlugin: NSObject, FlutterPlugin {
    
    private var mlxService: NativeMLXService?
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.eastlakestudio.mlx_localllm", binaryMessenger: registrar.messenger)
        let instance = MlxLocalllmPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if arch(arm64)
        if #available(macOS 14.0, *) {
            if mlxService == nil {
                mlxService = NativeMLXService()
            }
        }
        #endif

        switch call.method {
        case "isSupported":
            #if arch(arm64)
            if #available(macOS 14.0, *) {
                result(true)
            } else {
                result(false)
            }
            #else
            result(false)
            #endif
        case "loadModel":
            #if arch(arm64)
            guard let args = call.arguments as? [String: Any],
                  let modelPath = args["modelPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing modelPath", details: nil))
                return
            }
            Task {
                do {
                    if #available(macOS 14.0, *) {
                        let success = try await self.mlxService?.loadModel(path: modelPath) ?? false
                        result(success)
                    } else {
                        result(false)
                    }
                } catch {
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                }
            }
            #else
            result(FlutterError(code: "UNSUPPORTED_ARCH", message: "Apple Silicon required", details: nil))
            #endif
        case "downloadModel":
            #if arch(arm64)
            guard let args = call.arguments as? [String: Any],
                  let repoId = args["repoId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing repoId", details: nil))
                return
            }
            if #available(macOS 14.0, *) {
                let endpoint = args["endpoint"] as? String ?? "https://hf-mirror.com"
                let channel = self.channel
                Task {
                    await self.mlxService?.downloadModel(repoId: repoId, endpoint: endpoint, onProgress: { progress in
                        let progressArgs: [String: Any] = ["repoId": repoId, "progress": progress]
                        DispatchQueue.main.async {
                            channel?.invokeMethod("downloadProgress", arguments: progressArgs)
                        }
                    }, onComplete: { path in
                        let completeArgs: [String: Any] = ["repoId": repoId, "path": path]
                        DispatchQueue.main.async {
                            channel?.invokeMethod("downloadComplete", arguments: completeArgs)
                        }
                    }, onError: { errorMsg in
                        let errorArgs: [String: Any] = ["repoId": repoId, "error": errorMsg]
                        DispatchQueue.main.async {
                            channel?.invokeMethod("downloadError", arguments: errorArgs)
                        }
                    })
                }
                result(true)
            } else {
                result(FlutterError(code: "UNSUPPORTED", message: "Requires macOS 14.0", details: nil))
            }
            #else
            result(FlutterError(code: "UNSUPPORTED_ARCH", message: "Apple Silicon required", details: nil))
            #endif
        case "cancelDownload":
            #if arch(arm64)
            guard let args = call.arguments as? [String: Any],
                  let repoId = args["repoId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing repoId", details: nil))
                return
            }
            Task {
                if #available(macOS 14.0, *) {
                    await self.mlxService?.cancelDownload(repoId: repoId)
                }
            }
            result(true)
            #else
            result(FlutterError(code: "UNSUPPORTED_ARCH", message: "Apple Silicon required", details: nil))
            #endif
        case "inference":
            #if arch(arm64)
            guard let args = call.arguments as? [String: Any],
                  let prompt = args["prompt"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing prompt", details: nil))
                return
            }
            Task {
                if #available(macOS 14.0, *) {
                    do {
                        let temperature = args["temperature"] as? Double ?? 0.0
                        let stopSequences = args["stop_sequences"] as? [String] ?? []
                        
                        if let response = try await self.mlxService?.generate(
                            prompt: prompt,
                            temperature: Float(temperature),
                            stopSequences: stopSequences
                        ) {
                            result(response)
                        } else {
                            result("")
                        }
                    } catch {
                        result(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
                    }
                } else {
                    result(FlutterError(code: "UNSUPPORTED", message: "Requires macOS 14.0", details: nil))
                }
            }
            #else
            result(FlutterError(code: "UNSUPPORTED_ARCH", message: "Apple Silicon required", details: nil))
            #endif
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
