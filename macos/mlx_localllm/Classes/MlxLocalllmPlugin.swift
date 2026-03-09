#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif
import Foundation

class MLXStreamHandler: NSObject, FlutterStreamHandler {
    var sink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.sink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.sink = nil
        return nil
    }
}


public class MlxLocalllmPlugin: NSObject, FlutterPlugin {
    
    private var mlxService: NativeMLXService?
    private var channel: FlutterMethodChannel?
    private let progressStreamHandler = MLXStreamHandler()
    private let generateStreamHandler = MLXStreamHandler()

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

        let progressChannel = FlutterEventChannel(name: "mlx_localllm_events", binaryMessenger: messenger)
        progressChannel.setStreamHandler(instance.progressStreamHandler)
        
        let generateChannel = FlutterEventChannel(name: "mlx_localllm_generate_events", binaryMessenger: messenger)
        generateChannel.setStreamHandler(instance.generateStreamHandler)
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
                
                await self.mlxService?.downloadModel(repoId: repoId, endpoint: endpoint, onProgress: { progress, downloadedBytes, totalBytes in
                    let data: [String: Any] = [
                        "event": "progress", 
                        "repoId": repoId, 
                        "progress": progress,
                        "downloadedBytes": downloadedBytes,
                        "totalBytes": totalBytes
                    ]
                    DispatchQueue.main.async {
                        self.progressStreamHandler.sink?(data)
                    }
                }, onComplete: { path in
                    let data: [String: Any] = ["event": "complete", "repoId": repoId, "path": path]
                    DispatchQueue.main.async {
                        self.progressStreamHandler.sink?(data)
                    }
                }, onError: { errorMsg in
                    let data: [String: Any] = ["event": "error", "repoId": repoId, "error": errorMsg]
                    DispatchQueue.main.async {
                        self.progressStreamHandler.sink?(data)
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
        case "setCustomStoragePath":
            let args = call.arguments as? [String: Any]
            let path = args?["path"] as? String
            Task {
                await self.mlxService?.setCustomModelDirectory(path: path)
                result(nil)
            }
        case "getDownloadedModels":
            Task {
                let models = await self.mlxService?.getDownloadedModels() ?? []
                result(models)
            }
        case "getCurrentStoragePath":
            Task {
                let path = await self.mlxService?.getCurrentStoragePath() ?? ""
                result(path)
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
                    let temperature = (args["temperature"] as? NSNumber)?.floatValue ?? 0.0
                    let maxTokens = (args["max_tokens"] as? NSNumber)?.intValue ?? 1024
                    let stopSequences = args["stop_sequences"] as? [String] ?? []
                    
                    var extraOptions = args
                    extraOptions.removeValue(forKey: "prompt")
                    extraOptions.removeValue(forKey: "temperature")
                    extraOptions.removeValue(forKey: "max_tokens")
                    extraOptions.removeValue(forKey: "stop_sequences")
                    
                    var extraJSON = "{}"
                    if let jsonData = try? JSONSerialization.data(withJSONObject: extraOptions, options: [.prettyPrinted, .sortedKeys]),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        extraJSON = jsonString
                    }
                    
                    #if DEBUG
                    NSLog("[MLX] Generate Prompt: %@", prompt as NSString)
                    NSLog("[MLX] Config: temperature=%f, max_tokens=%d, extra_body=%@", Float(temperature), Int32(maxTokens), extraJSON as NSString)
                    #endif
                    
                    var response: String?
                    #if os(macOS)
                    if #available(macOS 14.0, *) {
                        response = try await self.mlxService?.generate(
                            prompt: prompt,
                            temperature: Float(temperature),
                            maxTokens: maxTokens,
                            stopSequences: stopSequences,
                            extraOptions: extraOptions
                        )
                    }
                    #elseif os(iOS)
                    if #available(iOS 17.0, *) {
                        response = try await self.mlxService?.generate(
                            prompt: prompt,
                            temperature: Float(temperature),
                            maxTokens: maxTokens,
                            stopSequences: stopSequences,
                            extraOptions: extraOptions
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
        case "generateStream":
            #if arch(arm64)
            guard let args = call.arguments as? [String: Any],
                  let prompt = args["prompt"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing prompt", details: nil))
                return
            }
            Task {
                do {
                    let temperature = (args["temperature"] as? NSNumber)?.floatValue ?? 0.0
                    let maxTokens = (args["max_tokens"] as? NSNumber)?.intValue ?? 1024
                    let stopSequences = args["stop_sequences"] as? [String] ?? []
                    
                    var extraOptions = args
                    extraOptions.removeValue(forKey: "prompt")
                    extraOptions.removeValue(forKey: "temperature")
                    extraOptions.removeValue(forKey: "max_tokens")
                    extraOptions.removeValue(forKey: "stop_sequences")
                    
                    var extraJSON = "{}"
                    if let jsonData = try? JSONSerialization.data(withJSONObject: extraOptions, options: [.prettyPrinted, .sortedKeys]),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        extraJSON = jsonString
                    }
                    
                    #if DEBUG
                    NSLog("[MLX] GenerateStream Prompt: %@", prompt as NSString)
                    NSLog("[MLX] Config: temperature=%f, max_tokens=%d, extra_body=%@", Float(temperature), Int32(maxTokens), extraJSON as NSString)
                    #endif

                    #if os(macOS)
                    if #available(macOS 14.0, *) {
                        try await self.mlxService?.generateStream(
                            prompt: prompt,
                            temperature: Float(temperature),
                            maxTokens: maxTokens,
                            stopSequences: stopSequences,
                            extraOptions: extraOptions,
                            onToken: { token in
                                DispatchQueue.main.async {
                                    self.generateStreamHandler.sink?(["text": token])
                                }
                            }
                        )
                        DispatchQueue.main.async {
                            self.generateStreamHandler.sink?(["done": true])
                        }
                    }
                    #elseif os(iOS)
                    if #available(iOS 17.0, *) {
                        try await self.mlxService?.generateStream(
                            prompt: prompt,
                            temperature: Float(temperature),
                            maxTokens: maxTokens,
                            stopSequences: stopSequences,
                            extraOptions: extraOptions,
                            onToken: { token in
                                DispatchQueue.main.async {
                                    self.generateStreamHandler.sink?(["text": token])
                                }
                            }
                        )
                        DispatchQueue.main.async {
                            self.generateStreamHandler.sink?(["done": true])
                        }
                    }
                    #endif
                    result(true)
                } catch {
                    DispatchQueue.main.async {
                        self.generateStreamHandler.sink?(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
                    }
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
