import Foundation
import SwiftUI

@Observable
class FileScannerViewModel {
    var isScanning = false
    var scanResults: [VirtualFile] = []
    var currentScanPath = ""
    var filesScanned = 0
    var totalFiles = 0
    var scanProgress: Double = 0.0
    var scanErrors: [String] = []
    var configuration = ScanConfiguration()
    
    private var scanTask: Task<Void, Never>?
    
    func startScan() {
        guard !isScanning else { return }
        
        let errors = configuration.validate()
        if !errors.isEmpty {
            scanErrors = errors
            return
        }
        
        isScanning = true
        scanResults.removeAll()
        scanErrors.removeAll()
        filesScanned = 0
        totalFiles = 0
        scanProgress = 0.0
        
        scanTask = Task {
            await performScan()
            await MainActor.run {
                isScanning = false
            }
        }
    }
    
    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }
    
    private func performScan() async {
        let startTime = Date()
        var allFiles: [VirtualFile] = []
        
        for scanPath in configuration.scanPaths {
            if Task.isCancelled { break }
            
            await MainActor.run {
                currentScanPath = scanPath.path
            }
            
            let files = await scanDirectory(scanPath)
            allFiles.append(contentsOf: files)
        }
        
        // Remove duplicates and sort
        let uniqueFiles = Array(Set(allFiles)).sorted { $0.name < $1.name }
        
        await MainActor.run {
            scanResults = uniqueFiles
            scanProgress = 1.0
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("Scan completed in \(duration) seconds, found \(uniqueFiles.count) files")
    }
    
    private func scanDirectory(_ url: URL) async -> [VirtualFile] {
        var files: [VirtualFile] = []
        
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let scannedFiles = self.scanDirectorySync(url, depth: 0)
                continuation.resume(returning: scannedFiles)
            }
        }
        
        return files
    }
    
    private func scanDirectorySync(_ url: URL, depth: Int) -> [VirtualFile] {
        guard depth <= configuration.maxScanDepth else { return [] }
        
        var files: [VirtualFile] = []
        let fileManager = FileManager.default
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            guard resourceValues.isDirectory == true else {
                // It's a file, check if we should include it
                if configuration.shouldIncludeFile(url) {
                    return [VirtualFile(url: url)]
                }
                return []
            }
            
            // Skip packages unless specifically requested
            if resourceValues.isPackage == true && !url.pathExtension.isEmpty {
                return []
            }
            
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .isPackageKey,
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .creationDateKey
                ],
                options: [.skipsHiddenFiles])
            
            for itemURL in contents {
                if Task.isCancelled { break }
                
                // Update progress
                filesScanned += 1
                if filesScanned % 100 == 0 {
                    DispatchQueue.main.async {
                        self.scanProgress = Double(self.filesScanned) / max(1000, self.totalFiles)
                    }
                }
                
                // Skip if should not include
                if !configuration.shouldIncludeFile(itemURL) {
                    continue
                }
                
                // Check if it's a directory
                do {
                    let itemResourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
                    
                    if itemResourceValues.isDirectory == true {
                        // Recursively scan subdirectory
                        let subFiles = scanDirectorySync(itemURL, depth: depth + 1)
                        files.append(contentsOf: subFiles)
                    } else {
                        // It's a file, add it to results
                        let virtualFile = VirtualFile(url: itemURL)
                        
                        // Categorize the file
                        let category = FileCategory.toolSpecificCategory(for: itemURL) ?? FileCategory.categorize(url: itemURL)
                        virtualFile.addToCategory(category)
                        
                        // Add tool-specific metadata as tags
                        let metadata = virtualFile.metadata
                        if let toolName = metadata.toolName {
                            virtualFile.addTag(toolName)
                        }
                        if let purpose = metadata.purpose {
                            virtualFile.addTag(purpose)
                        }
                        
                        files.append(virtualFile)
                    }
                } catch {
                    // Skip files we can't access
                    DispatchQueue.main.async {
                        self.scanErrors.append("Cannot access \(itemURL.path): \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.scanErrors.append("Cannot scan directory \(url.path): \(error.localizedDescription)")
            }
        }
        
        return files
    }
    
    // MARK: - Scan Statistics
    
    var statistics: ScanStatistics {
        ScanStatistics(results: scanResults)
    }
    
    func filesForCategory(_ category: FileCategory) -> [VirtualFile] {
        return scanResults.filter { $0.categories.contains(category) }
    }
    
    func filesWithTag(_ tag: String) -> [VirtualFile] {
        return scanResults.filter { $0.tags.contains(tag) }
    }
    
    func searchFiles(query: String) -> [VirtualFile] {
        guard !query.isEmpty else { return scanResults }
        
        let lowercaseQuery = query.lowercased()
        return scanResults.filter { file in
            file.name.lowercased().contains(lowercaseQuery) ||
            file.originalPath.lowercased().contains(lowercaseQuery) ||
            file.tags.contains { $0.lowercased().contains(lowercaseQuery) } ||
            file.categories.contains { $0.rawValue.lowercased().contains(lowercaseQuery) }
        }
    }
}

// MARK: - Scan Statistics

struct ScanStatistics {
    let results: [VirtualFile]
    
    var totalFiles: Int {
        results.count
    }
    
    var totalSize: Int64 {
        results.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSize: String {
        FileSizeFormatter.formattedString(fromBytes: totalSize)
    }
    
    var categoryBreakdown: [(FileCategory, Int)] {
        let categoryCounts = Dictionary(grouping: results) { file in
            file.categories.first ?? .unknown
        }.mapValues { $0.count }
        
        return FileCategory.allCases.compactMap { category in
            categoryCounts[category].map { count in
                (category, count)
            }
        }.sorted { $0.1 > $1.1 }
    }
    
    var tagBreakdown: [(String, Int)] {
        let tagCounts = Dictionary(grouping: results.flatMap { $0.tags }) { tag in tag }
            .mapValues { $0.count }
        
        return tagCounts.sorted { $0.1 > $1.1 }.prefix(10).map { ($0.key, $0.value) }
    }
    
    var largestFiles: [VirtualFile] {
        results.sorted { $0.size > $1.size }.prefix(10).map { $0 }
    }
    
    var recentlyModified: [VirtualFile] {
        results.sorted { file1, file2 in
            guard let date1 = file1.modificationDate, let date2 = file2.modificationDate else {
                return false
            }
            return date1 > date2
        }.prefix(10).map { $0 }
    }
}

// MARK: - FileScannerViewModel Extensions

extension FileScannerViewModel {
    func applyPreset(_ preset: ScanConfigurationPreset) {
        configuration = preset.configuration
    }
    
    func exportResults(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = ScanExportData(
            files: scanResults,
            configuration: configuration,
            scanDate: Date(),
            statistics: statistics
        )
        
        let data = try encoder.encode(exportData)
        try data.write(to: url)
    }
    
    func importResults(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(ScanExportData.self, from: data)
        scanResults = importData.files
        configuration = importData.configuration
    }
}

// MARK: - Scan Configuration Presets

enum ScanConfigurationPreset: String, CaseIterable, Identifiable {
    case development = "Development"
    case cleanup = "Cleanup"
    case comprehensive = "Comprehensive"
    case aiTools = "AI Tools"
    
    var id: String { rawValue }
    
    var configuration: ScanConfiguration {
        switch self {
        case .development:
            return .developmentPreset
        case .cleanup:
            return .cleanupPreset
        case .comprehensive:
            return .comprehensivePreset
        case .aiTools:
            var config = ScanConfiguration()
            config.enabledCategories = [.aiAssistants, .configurations, .caches, .logs]
            config.includeHiddenFiles = true
            return config
        }
    }
    
    var description: String {
        switch self {
        case .development:
            return "Scan development-related files and tools"
        case .cleanup:
            return "Focus on files that can be safely cleaned up"
        case .comprehensive:
            return "Scan all file types and categories"
        case .aiTools:
            return "Focus on AI assistant and tool files"
        }
    }
}

// MARK: - Scan Export Data

struct ScanExportData: Codable {
    let files: [VirtualFileExport]
    let configuration: ScanConfigurationExport
    let scanDate: Date
    let statistics: ScanStatisticsExport
}

struct VirtualFileExport: Codable {
    let url: URL
    let name: String
    let size: Int64
    let creationDate: Date?
    let modificationDate: Date?
    let categories: [String]
    let tags: [String]
}

struct ScanConfigurationExport: Codable {
    let scanPaths: [URL]
    let excludedPaths: [URL]
    let includeHiddenFiles: Bool
    let maxScanDepth: Int
    let minFileSize: Int64
    let maxFileSize: Int64
    let fileExtensions: [String]
    let excludeExtensions: [String]
    let enabledCategories: [String]
}

struct ScanStatisticsExport: Codable {
    let totalFiles: Int
    let totalSize: Int64
    let categoryBreakdown: [(String, Int)]
    let tagBreakdown: [(String, Int)]
}
