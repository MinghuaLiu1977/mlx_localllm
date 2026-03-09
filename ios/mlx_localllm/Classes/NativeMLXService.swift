#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif
import Foundation
#if arch(arm64)
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers
#endif
import Hub

class DownloadProgressDelegate: NSObject, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    let onProgress: (Int64) -> Void
    var continuation: CheckedContinuation<(URL, URLResponse), Error>?
    
    init(onProgress: @escaping (Int64) -> Void) {
        self.onProgress = onProgress
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        onProgress(totalBytesWritten)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.moveItem(at: location, to: tempURL)
            if let response = downloadTask.response {
                continuation?.resume(returning: (tempURL, response))
            } else {
                continuation?.resume(throwing: URLError(.badServerResponse))
            }
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}


@available(macOS 14.0, iOS 17.0, *)
public actor NativeMLXService {
    
    #if arch(arm64)
    private var container: ModelContainer?
    #endif
    private var downloadTasks: [String: Task<Void, Never>] = [:]
    private var activeHubs: [String: HubApi] = [:]
    
    // 自定义模型根目录路径
    private var customModelDirectory: URL?
    
    public init() {}
    
    /// 将 [String: Any] 转换为 [String: any Sendable]，并确保 Bool 类型的正确性
    private func convertToSafeContext(_ input: [String: Any]?) -> [String: any Sendable]? {
        guard let input = input else { return nil }
        var result: [String: any Sendable] = [:]
        
        for (key, value) in input {
            if let boolValue = value as? Bool {
                result[key] = boolValue
            } else if let stringValue = value as? String {
                if stringValue.lowercased() == "true" {
                    result[key] = true
                } else if stringValue.lowercased() == "false" {
                    result[key] = false
                } else {
                    result[key] = stringValue
                }
            } else if let numberValue = value as? NSNumber {
                // 处理 JSON 转换中可能出现的 NSNumber 为 Bool 的情况
                if CFGetTypeID(numberValue) == CFBooleanGetTypeID() {
                    result[key] = numberValue.boolValue
                } else {
                    result[key] = numberValue
                }
            } else if let dictValue = value as? [String: Any] {
                // 递归处理嵌套字典
                if let converted = convertToSafeContext(dictValue) {
                    result[key] = converted
                }
            } else if let val = value as? String {
                result[key] = val
            } else if let val = value as? Int {
                result[key] = val
            } else if let val = value as? Double {
                result[key] = val
            } else if let val = value as? Float {
                result[key] = val
            }
        }
        return result.isEmpty ? nil : result
    }
    
    /// 设置自定义存储路径
    public func setCustomModelDirectory(path: String?) {
        if let path = path, !path.isEmpty {
            self.customModelDirectory = URL(fileURLWithPath: path)
        } else {
            self.customModelDirectory = nil
        }
    }
    
    /// 获取模型存储的基础目录 (Application Support 或 自定义路径)
    private func getModelDirectory() -> URL {
        let baseDir: URL
        if let customPath = customModelDirectory {
            baseDir = customPath
        } else {
            let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            baseDir = paths[0].appendingPathComponent("models", isDirectory: true)
        }
        
        if !FileManager.default.fileExists(atPath: baseDir.path) {
            try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        }
        return baseDir
    }
    
    /// 获取已下载或正在下载的模型目录列表
    public func getDownloadedModels() -> [String] {
        let baseDir = getModelDirectory()
        var models: [String] = []
        
        do {
            let authorDirs = try FileManager.default.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
            for authorUrl in authorDirs {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: authorUrl.path, isDirectory: &isDir), isDir.boolValue {
                    let authorName = authorUrl.lastPathComponent
                    
                    // 尝试获取下一级目录 (模型名)
                    let modelDirs = try FileManager.default.contentsOfDirectory(at: authorUrl, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
                    
                    var foundSubDir = false
                    for modelUrl in modelDirs {
                        var isSubDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: modelUrl.path, isDirectory: &isSubDir), isSubDir.boolValue {
                            let modelName = modelUrl.lastPathComponent
                            models.append("\(authorName)/\(modelName)")
                            foundSubDir = true
                        }
                    }
                    
                    // 如果一级目录下没有子目录，则认为该目录本身可能就是一个模型（虽然 HF 常用 author/model）
                    if !foundSubDir {
                        models.append(authorName)
                    }
                }
            }
        } catch {
            #if DEBUG
            print("Error scanning for models: \(error)")
            #endif
        }
        
        return models
    }

    /// 获取当前存储路径
    public func getCurrentStoragePath() -> String {
        return getModelDirectory().path
    }

    public func downloadModel(repoId: String, endpoint: String? = nil, 
                                onProgress: @Sendable @escaping (Double, Int64, Int64) -> Void,
                                onComplete: @Sendable @escaping (String) -> Void,
                                onError: @Sendable @escaping (String) -> Void) {
        
        #if !arch(arm64)
        onError("Unsupported architecture: MLX requires Apple Silicon (arm64)")
        return
        #else
        if downloadTasks[repoId] != nil {
            return
        }

        let cleanEndpoint = (endpoint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "https://hf-mirror.com")
        
        let downloadBase = getModelDirectory()
        let hub = HubApi(downloadBase: downloadBase, endpoint: cleanEndpoint)
        activeHubs[repoId] = hub 
        
        let task = Task {
            do {
                let repoDir = downloadBase.appendingPathComponent(repoId)
                try? FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
                
                let filenames = try await hub.getFilenames(from: repoId)
                
                var totalBytes: Int64 = 0
                var fileSizes: [String: Int64] = [:]
                
                try await withThrowingTaskGroup(of: (String, Int64).self) { group in
                    for filename in filenames {
                        let urlString = "\(cleanEndpoint)/\(repoId)/resolve/main/\(filename)"
                        guard let url = URL(string: urlString) else { continue }
                        
                        group.addTask {
                            do {
                                return try await withThrowingTaskGroup(of: Int64.self) { timeoutGroup in
                                    timeoutGroup.addTask {
                                        let response = try await hub.httpHeadCompatible(for: url)
                                        let sizeStr = response.value(forHTTPHeaderField: "X-Linked-Size") ?? 
                                                     response.value(forHTTPHeaderField: "Content-Length") ?? "1024"
                                        return Int64(sizeStr) ?? 1024
                                    }
                                    
                                    timeoutGroup.addTask {
                                        try await Task.sleep(nanoseconds: 7 * 1_000_000_000)
                                        throw NSError(domain: "MLXProber", code: -1, userInfo: [NSLocalizedDescriptionKey: "Probing timeout"])
                                    }
                                    
                                    let firstResult = try await timeoutGroup.next()
                                    timeoutGroup.cancelAll()
                                    return (filename, firstResult ?? 1024)
                                }
                            } catch {
                                return (filename, 1024)
                            }
                        }
                    }
                    
                    for try await (filename, size) in group {
                        fileSizes[filename] = size
                        totalBytes += size
                    }
                }
                
                if Task.isCancelled { return }

                var downloadedBytes: Int64 = 0
                for filename in filenames {
                    if Task.isCancelled { break }
                    
                    let destination = repoDir.appendingPathComponent(filename)
                    if filename.contains("/") {
                        try? FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                    }
                    
                    let expectedFileSize = fileSizes[filename] ?? 1024
                    
                    if !FileManager.default.fileExists(atPath: destination.path) {
                        let urlString = "\(cleanEndpoint)/\(repoId)/resolve/main/\(filename)"
                        guard let url = URL(string: urlString) else { continue }
                        
                        let resumeDataURL = repoDir.appendingPathComponent("\(filename.replacingOccurrences(of: "/", with: "_")).resumeData")
                        
                        var lastReportedBytes: Int64 = downloadedBytes
                        let delegate = DownloadProgressDelegate { written in
                            if Task.isCancelled { return }
                            let currentDownloaded = downloadedBytes + written
                            if currentDownloaded - lastReportedBytes > 1024 * 1024 {
                                let progress = min(1.0, Double(currentDownloaded) / Double(totalBytes))
                                onProgress(progress, currentDownloaded, totalBytes)
                                lastReportedBytes = currentDownloaded
                            }
                        }
                        
                        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
                        
                        do {
                            let (tempURL, urlResponse) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(URL, URLResponse), Error>) in
                                delegate.continuation = continuation
                                let task: URLSessionDownloadTask
                                if FileManager.default.fileExists(atPath: resumeDataURL.path),
                                   let resumeData = try? Data(contentsOf: resumeDataURL) {
                                    task = session.downloadTask(withResumeData: resumeData)
                                } else {
                                    task = session.downloadTask(with: url)
                                }
                                task.resume()
                            }
                            
                            guard let httpResponse = urlResponse as? HTTPURLResponse, 
                                  (200...299).contains(httpResponse.statusCode) else {
                                throw NSError(domain: "MLXDownloader", code: (urlResponse as? HTTPURLResponse)?.statusCode ?? -1,
                                            userInfo: [NSLocalizedDescriptionKey: "HTTP Error downloading \(filename)"])
                            }
                            
                            try FileManager.default.moveItem(at: tempURL, to: destination)
                            try? FileManager.default.removeItem(at: resumeDataURL) // clear resume data on success
                            
                            downloadedBytes += expectedFileSize
                            let progress = min(1.0, Double(downloadedBytes) / Double(totalBytes))
                            onProgress(progress, downloadedBytes, totalBytes)
                        } catch let error as URLError {
                            if let resumeData = error.downloadTaskResumeData {
                                try? resumeData.write(to: resumeDataURL)
                            }
                            throw error
                        } catch {
                            throw error
                        }
                    } else {
                        downloadedBytes += expectedFileSize
                        let progress = min(1.0, Double(downloadedBytes) / Double(totalBytes))
                        onProgress(progress, downloadedBytes, totalBytes)
                    }
                }
                
                if !Task.isCancelled {
                    onProgress(1.0, totalBytes, totalBytes)
                    onComplete(repoDir.path)
                }
            } catch {
                if !Task.isCancelled {
                    onError(error.localizedDescription)
                }
            }
            self.removeInternalResources(repoId: repoId)
        }
        
        downloadTasks[repoId] = task
        #endif
    }
    
    private func removeInternalResources(repoId: String) {
        downloadTasks.removeValue(forKey: repoId)
        activeHubs.removeValue(forKey: repoId)
    }

    public func cancelDownload(repoId: String) {
        downloadTasks[repoId]?.cancel()
        downloadTasks.removeValue(forKey: repoId)
    }
    public func unloadModel() {
        #if arch(arm64)
        self.container = nil
        #endif
    }

    public func checkModelExists(repoId: String) -> Bool {
        let repoDir = getModelDirectory().appendingPathComponent(repoId)
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: repoDir.path, isDirectory: &isDir) && isDir.boolValue
    }

    public func deleteModel(repoId: String) throws {
        let repoDir = getModelDirectory().appendingPathComponent(repoId)
        if FileManager.default.fileExists(atPath: repoDir.path) {
            try FileManager.default.removeItem(at: repoDir)
        }
    }

    public func loadModel(path: String) async throws -> Bool {
        #if !arch(arm64)
        throw NSError(domain: "NativeMLXService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unsupported architecture: MLX requires Apple Silicon (arm64)"])
        #else
        // Resolve path: if it's not absolute, treat it as a repoId relative to models directory
        let modelURL: URL
        if path.hasPrefix("/") {
            modelURL = URL(fileURLWithPath: path)
        } else {
            modelURL = getModelDirectory().appendingPathComponent(path)
        }

        do {
            let configuration = ModelConfiguration(directory: modelURL)
            self.container = try await LLMModelFactory.shared.loadContainer(configuration: configuration)
            return true
        } catch {
            throw error
        }
        #endif
    }
    
    public func generate(prompt: String, temperature: Float = 0.0, maxTokens: Int = 1024, stopSequences: [String] = [], extraOptions: [String: Any]? = nil) async throws -> String {
        #if !arch(arm64)
        throw NSError(domain: "NativeMLXService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unsupported architecture: MLX requires Apple Silicon (arm64)"])
        #else
        guard let container = self.container else {
            throw NSError(domain: "NativeMLXService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        var fullText = ""
        let lmPrompt = prompt.isEmpty ? " " : prompt
        var rawKwargs = extraOptions?["chat_template_kwargs"] as? [String: Any] ?? [:]
        
        // 强制开启生成引导词
        if rawKwargs["add_generation_prompt"] == nil {
            rawKwargs["add_generation_prompt"] = true
        }
        
        let chatTemplateKwargs = convertToSafeContext(rawKwargs)
        
        #if DEBUG
        NSLog("[MLX] Chat template kwargs: \(String(describing: chatTemplateKwargs))")
        #endif
        let input = UserInput(prompt: lmPrompt, additionalContext: chatTemplateKwargs)
        let lmInput = try await container.prepare(input: input)
        
        var parameters = GenerateParameters(
            maxTokens: maxTokens,
            temperature: temperature
        )
        if let topP = extraOptions?["top_p"] as? Double {
            parameters.topP = Float(topP)
        } else if let topP = extraOptions?["top_p"] as? Float {
            parameters.topP = topP
        }
        
        
        if let repPen = extraOptions?["repetition_penalty"] as? Double {
            parameters.repetitionPenalty = Float(repPen)
        } else if let presPen = extraOptions?["presence_penalty"] as? Double {
            parameters.repetitionPenalty = Float(presPen)
        }
        
        let stream = try await container.generate(input: lmInput, parameters: parameters)
        
        for try await generation in stream {
            if case .chunk(let text) = generation {
                var shouldStop = false
                for stop in stopSequences {
                    if text.contains(stop) {
                        shouldStop = true
                        break
                    }
                }
                
                fullText += text
                if shouldStop { break }
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        #endif
    }
    
    public func generateStream(prompt: String, temperature: Float = 0.0, maxTokens: Int = 1024, stopSequences: [String] = [], extraOptions: [String: Any]? = nil, onToken: @Sendable @escaping (String) -> Void) async throws {
        #if !arch(arm64)
        throw NSError(domain: "NativeMLXService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unsupported architecture: MLX requires Apple Silicon (arm64)"])
        #else
        guard let container = self.container else {
            throw NSError(domain: "NativeMLXService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        let lmPrompt = prompt.isEmpty ? " " : prompt
        var rawKwargs = extraOptions?["chat_template_kwargs"] as? [String: Any] ?? [:]
        
        // 强制开启生成引导词
        if rawKwargs["add_generation_prompt"] == nil {
            rawKwargs["add_generation_prompt"] = true
        }
        
        let chatTemplateKwargs = convertToSafeContext(rawKwargs)
        
        #if DEBUG
        NSLog("[MLX] Chat template kwargs: \(String(describing: chatTemplateKwargs))")
        #endif
        let input = UserInput(prompt: lmPrompt, additionalContext: chatTemplateKwargs)
        let lmInput = try await container.prepare(input: input)
        
        var parameters = GenerateParameters(
            maxTokens: maxTokens,
            temperature: temperature
        )
        if let topP = extraOptions?["top_p"] as? Double {
            parameters.topP = Float(topP)
        } else if let topP = extraOptions?["top_p"] as? Float {
            parameters.topP = topP
        }
        
        
        if let repPen = extraOptions?["repetition_penalty"] as? Double {
            parameters.repetitionPenalty = Float(repPen)
        } else if let presPen = extraOptions?["presence_penalty"] as? Double {
            parameters.repetitionPenalty = Float(presPen)
        }
        
        let stream = try await container.generate(input: lmInput, parameters: parameters)
        
        var logBuffer = ""
        for try await generation in stream {
            if case .chunk(let text) = generation {
                onToken(text)
                logBuffer += text
                // 累积 30 字符或遇换行时打印，防止输出过于频繁
                if logBuffer.count >= 30 || logBuffer.contains("\n") {
                    let lines = logBuffer.components(separatedBy: "\n")
                    if lines.count > 1 {
                        for line in lines.dropLast() {
                            #if DEBUG
                            NSLog("[MLX] %@", line as NSString)
                            #endif
                        }
                        logBuffer = lines.last ?? ""
                    } else {
                        #if DEBUG
                        NSLog("[MLX] %@", logBuffer as NSString)
                        #endif
                        logBuffer = ""
                    }
                }
                var shouldStop = false
                for stop in stopSequences {
                    if text.contains(stop) { shouldStop = true; break }
                }
                if shouldStop { break }
            }
        }
        #if DEBUG
        if !logBuffer.isEmpty {
            NSLog("[MLX] %@", logBuffer as NSString)
        }
        #endif
        #endif
    }
}
