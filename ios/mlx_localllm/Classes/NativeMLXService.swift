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

@available(macOS 14.0, *)
public actor NativeMLXService {
    
    #if arch(arm64)
    private var container: ModelContainer?
    #endif
    private var downloadTasks: [String: Task<Void, Never>] = [:]
    private var activeHubs: [String: HubApi] = [:]
    
    public init() {}
    
    /// 获取模型存储的基础目录 (Application Support)
    private func getModelDirectory() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("models", isDirectory: true)
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        return appSupport
    }

    public func downloadModel(repoId: String, endpoint: String? = nil, 
                                onProgress: @Sendable @escaping (Double) -> Void,
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
                        
                        let (bytes, response) = try await URLSession.shared.bytes(from: url)
                        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                           throw NSError(domain: "MLXDownloader", code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                                       userInfo: [NSLocalizedDescriptionKey: "HTTP Error downloading \(filename)"])
                        }
                        
                        var fileData = Data()
                        fileData.reserveCapacity(Int(httpResponse.expectedContentLength > 0 ? httpResponse.expectedContentLength : expectedFileSize))
                        
                        var lastReportedBytes: Int64 = downloadedBytes
                        for try await byte in bytes {
                            fileData.append(byte)
                            downloadedBytes += 1
                            
                            if downloadedBytes - lastReportedBytes > 1024 * 1024 {
                                let progress = min(1.0, Double(downloadedBytes) / Double(totalBytes))
                                onProgress(progress)
                                lastReportedBytes = downloadedBytes
                            }
                        }
                        try fileData.write(to: destination)
                        
                        let progress = min(1.0, Double(downloadedBytes) / Double(totalBytes))
                        onProgress(progress)
                    } else {
                        downloadedBytes += expectedFileSize
                        let progress = min(1.0, Double(downloadedBytes) / Double(totalBytes))
                        onProgress(progress)
                    }
                }
                
                if !Task.isCancelled {
                    onProgress(1.0)
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
    
    public func generate(prompt: String, temperature: Float = 0.0, stopSequences: [String] = []) async throws -> String {
        #if !arch(arm64)
        throw NSError(domain: "NativeMLXService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unsupported architecture: MLX requires Apple Silicon (arm64)"])
        #else
        guard let container = self.container else {
            throw NSError(domain: "NativeMLXService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        var fullText = ""
        let lmPrompt = prompt.isEmpty ? " " : prompt
        let input = UserInput(prompt: lmPrompt)
        let lmInput = try await container.prepare(input: input)
        
        let parameters = GenerateParameters(
            maxTokens: 1024,
            temperature: temperature
        )
        
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
        
        var cleanText = fullText
        if cleanText.hasPrefix(lmPrompt) {
            cleanText = String(cleanText.dropFirst(lmPrompt.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleanText
        #endif
    }
}
