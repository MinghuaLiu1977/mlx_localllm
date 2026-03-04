#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif
import Foundation

public class MlxLocalllmPlugin: NSObject, FlutterPlugin {
    
    private var mlxService: NativeMLXService?
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(macOS)
        let messenger = registrar.messenger
        #elseif os(iOS)
        let messenger = registrar.messenger()
        #endif
        let channel = FlutterMethodChannel(name: "mlx_localllm", binaryMessenger: messenger)
        let instance = MlxLocalllmPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if os(macOS)
        if #available(macOS 14.0, *) {
            if mlxService == nil {
                mlxService = NativeMLXService()
            }
        }
        #elseif os(iOS)
        if #available(iOS 17.0, *) {
            if mlxService == nil {
                mlxService = NativeMLXService()
            }
        }
        #endif

        switch call.method {
        case "isSupported":
            #if arch(arm64)
            #if os(macOS)
            if #available(macOS 14.0, *) {
                result(true)
            } else {
                result(false)
            }
            #elseif os(iOS)
            if #available(iOS 17.0, *) {
                result(true)
            } else {
                result(false)
            }
            #endif
            #else
            result(false) // Intel Macs / x86 simulators are not supported for inference
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
                    var success = false
                    #if os(macOS)
                    if #available(macOS 14.0, *) {
                        success = try await self.mlxService?.loadModel(path: modelPath) ?? false
                    }
                    #elseif os(iOS)
                    if #available(iOS 17.0, *) {
                        success = try await self.mlxService?.loadModel(path: modelPath) ?? false
                    }
                    #endif
                    result(success)
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
            let endpoint = args["endpoint"] as? String ?? "https://hf-mirror.com"
            let channel = self.channel
            Task {
                #if os(macOS)
                let isAvailable = true // Already checked by MlxLocalllmPlugin logic if needed
                #elseif os(iOS)
                let isAvailable = true
                #endif
                
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
                #if os(macOS)
                if #available(macOS 14.0, *) {
                    await self.mlxService?.cancelDownload(repoId: repoId)
                }
                #elseif os(iOS)
                if #available(iOS 17.0, *) {
                    await self.mlxService?.cancelDownload(repoId: repoId)
                }
                #endif
            }
            result(true)
            #else
            result(FlutterError(code: "UNSUPPORTED_ARCH", message: "Apple Silicon required", details: nil))
            #endif
        case "unloadModel":
            Task {
                await self.mlxService?.unloadModel()
                result(true)
            }
        case "checkModelExists":
            guard let args = call.arguments as? [String: Any],
                  let repoId = args["repoId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing repoId", details: nil))
                return
            }
            Task {
                let exists = await self.mlxService?.checkModelExists(repoId: repoId) ?? false
                result(exists)
            }
        case "deleteModel":
            guard let args = call.arguments as? [String: Any],
                  let repoId = args["repoId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing repoId", details: nil))
                return
            }
            Task {
                do {
                    try await self.mlxService?.deleteModel(repoId: repoId)
                    result(true)
                } catch {
                    result(FlutterError(code: "DELETE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        case "generate":
            #if arch(arm64)
            guard let args = call.arguments as? [String: Any],
                  let prompt = args["prompt"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing prompt", details: nil))
                return
            }
            Task {
                do {
                    let temperature = args["temperature"] as? Double ?? 0.0
                    let stopSequences = args["stop_sequences"] as? [String] ?? []
                    
                    var response: String?
                    #if os(macOS)
                    if #available(macOS 14.0, *) {
                        response = try await self.mlxService?.generate(
                            prompt: prompt,
                            temperature: Float(temperature),
                            stopSequences: stopSequences
                        )
                    }
                    #elseif os(iOS)
                    if #available(iOS 17.0, *) {
                        response = try await self.mlxService?.generate(
                            prompt: prompt,
                            temperature: Float(temperature),
                            stopSequences: stopSequences
                        )
                    }
                    #endif
                    
                    result(response ?? "")
                } catch {
                    result(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
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
