import Foundation
import Combine

public enum ModelDownloaderError: Error, LocalizedError {
    case invalidURL
    case downloadFailed(Error)
    case moveFailed(Error)
    case invalidResponse
    case fileListParseFailed
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Hugging Face URL"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .moveFailed(let error):
            return "Failed to save downloaded file: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .fileListParseFailed:
            return "Failed to parse file list from Hugging Face API"
        case .apiError(let msg):
            return "API Error: \(msg)"
        }
    }
}

/// A service responsible for downloading MLX Whisper models from the Hugging Face Hub.
@MainActor
public final class ModelDownloader: ObservableObject {
    public static let shared = ModelDownloader()
    
    @Published public private(set) var isDownloading = false
    @Published public private(set) var progress: Double = 0.0 // 0.0 to 1.0
    @Published public private(set) var currentFile: String = ""
    
    private init() {}
    
    /// Get the local directory where the model will be stored.
    public func modelsDirectory(for repoId: String) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("AltWisprFlow", isDirectory: true)
        return appDir.appendingPathComponent("Models", isDirectory: true).appendingPathComponent(repoId, isDirectory: true)
    }
    
    /// Check if the essential files for a model are already downloaded.
    public func isModelDownloaded(repoId: String) -> Bool {
        let dir = modelsDirectory(for: repoId)
        let fileManager = FileManager.default
        
        let configPath = dir.appendingPathComponent("config.json").path
        guard fileManager.fileExists(atPath: configPath) else { return false }
        
        // We expect at least one safetensors file
        do {
            let files = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            return files.contains { $0.pathExtension == "safetensors" }
        } catch {
            return false
        }
    }
    
    /// Download a model from Hugging Face Hub.
    /// - Parameter repoId: The repository ID, e.g., "mlx-community/whisper-tiny-mlx-4bit"
    public func downloadModel(repoId: String) async throws {
        guard !isDownloading else { return }
        
        isDownloading = true
        progress = 0.0
        currentFile = "Fetching file list..."
        
        defer {
            isDownloading = false
            progress = 0.0
            currentFile = ""
        }
        
        let targetDir = modelsDirectory(for: repoId)
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: targetDir.path) {
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }
        
        let allFiles = try await fetchFileList(repoId: repoId)
        
        // Filter down to the files we actually need to run the MLX Whisper model
        let filesToDownload = allFiles.filter { file in
            let ext = (file as NSString).pathExtension.lowercased()
            return ext == "safetensors" || ext == "json" || ext == "txt"
        }
        
        for (index, file) in filesToDownload.enumerated() {
            currentFile = file
            // Rough progress based on file count
            progress = Double(index) / Double(filesToDownload.count)
            
            try await downloadSingleFile(repoId: repoId, filename: file, targetDir: targetDir)
        }
        
        progress = 1.0
        currentFile = "Download complete"
    }
    
    private func fetchFileList(repoId: String) async throws -> [String] {
        guard let url = URL(string: "https://huggingface.co/api/models/\(repoId)") else {
            throw ModelDownloaderError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ModelDownloaderError.invalidResponse
        }
        
        struct HFModelResponse: Decodable {
            let siblings: [Sibling]
            struct Sibling: Decodable {
                let rfilename: String
            }
        }
        
        do {
            let modelInfo = try JSONDecoder().decode(HFModelResponse.self, from: data)
            return modelInfo.siblings.map { $0.rfilename }
        } catch {
            throw ModelDownloaderError.fileListParseFailed
        }
    }
    
    private func downloadSingleFile(repoId: String, filename: String, targetDir: URL) async throws {
        let fileURLString = "https://huggingface.co/\(repoId)/resolve/main/\(filename)"
        guard let url = URL(string: fileURLString) else {
            throw ModelDownloaderError.invalidURL
        }
        
        let targetFileURL = targetDir.appendingPathComponent(filename)
        
        // Skip if already exists
        if FileManager.default.fileExists(atPath: targetFileURL.path) {
            return
        }
        
        // Ensure subdirectory exists if filename contains slashes
        let directory = targetFileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (tempURL, response) = try await URLSession.shared.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ModelDownloaderError.invalidResponse
        }
        
        do {
            if FileManager.default.fileExists(atPath: targetFileURL.path) {
                try FileManager.default.removeItem(at: targetFileURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: targetFileURL)
        } catch {
            throw ModelDownloaderError.moveFailed(error)
        }
    }
}
