import Foundation

@Observable
class ScanConfiguration {
    var scanPaths: [URL] = []
    var excludedPaths: [URL] = []
    var includeHiddenFiles: Bool = false
    var maxScanDepth: Int = 10
    var minFileSize: Int64 = 0
    var maxFileSize: Int64 = 0 // 0 means no limit
    var fileExtensions: Set<String> = []
    var excludeExtensions: Set<String> = []
    var enabledCategories: Set<FileCategory> = Set(FileCategory.allCases)
    var followSymlinks: Bool = false
    var scanNetworkVolumes: Bool = false
    
    // Default initialization
    init() {
        setupDefaultPaths()
    }
    
    private func setupDefaultPaths() {
        // Add common development directories
        if let homeDirectory = FileManager.default.homeDirectoryForCurrentUser as URL? {
            // Common project directories
            let projectDirs = ["Projects", "workspace", "Work", "Developer", "src"]
            for dir in projectDirs {
                let projectPath = homeDirectory.appendingPathComponent(dir)
                if FileManager.default.fileExists(atPath: projectPath.path) {
                    scanPaths.append(projectPath)
                }
            }
            
            // Add hidden development directories
            let hiddenDirs = [
                ".vscode", ".cursor", ".augment", ".amazonq",
                ".config", ".local", ".cache"
            ]
            for dir in hiddenDirs {
                let hiddenPath = homeDirectory.appendingPathComponent(dir)
                if FileManager.default.fileExists(atPath: hiddenPath.path) {
                    scanPaths.append(hiddenPath)
                }
            }
        }
        
        // Add current directory if available
        if let currentPath = FileManager.default.currentDirectoryPath as String? {
            scanPaths.append(URL(fileURLWithPath: currentPath))
        }
    }
    
    // MARK: - Validation
    
    func validate() -> [String] {
        var errors: [String] = []
        
        if scanPaths.isEmpty {
            errors.append("At least one scan path must be specified")
        }
        
        for path in scanPaths {
            if !FileManager.default.fileExists(atPath: path.path) {
                errors.append("Scan path does not exist: \(path.path)")
            }
        }
        
        for path in excludedPaths {
            if !FileManager.default.fileExists(atPath: path.path) {
                errors.append("Excluded path does not exist: \(path.path)")
            }
        }
        
        if maxScanDepth < 1 {
            errors.append("Maximum scan depth must be at least 1")
        }
        
        if minFileSize < 0 {
            errors.append("Minimum file size cannot be negative")
        }
        
        if maxFileSize < 0 {
            errors.append("Maximum file size cannot be negative")
        }
        
        if minFileSize > maxFileSize && maxFileSize > 0 {
            errors.append("Minimum file size cannot be greater than maximum file size")
        }
        
        return errors
    }
    
    // MARK: - Path Management
    
    func addScanPath(_ url: URL) {
        if !scanPaths.contains(url) {
            scanPaths.append(url)
        }
    }
    
    func removeScanPath(_ url: URL) {
        scanPaths.removeAll { $0 == url }
    }
    
    func addExcludedPath(_ url: URL) {
        if !excludedPaths.contains(url) {
            excludedPaths.append(url)
        }
    }
    
    func removeExcludedPath(_ url: URL) {
        excludedPaths.removeAll { $0 == url }
    }
    
    // MARK: - Category Management
    
    func enableCategory(_ category: FileCategory) {
        enabledCategories.insert(category)
    }
    
    func disableCategory(_ category: FileCategory) {
        enabledCategories.remove(category)
    }
    
    func isCategoryEnabled(_ category: FileCategory) -> Bool {
        return enabledCategories.contains(category)
    }
    
    // MARK: - File Extension Management
    
    func addFileExtension(_ fileExtension: String) {
        let cleanExtension = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        if !cleanExtension.isEmpty {
            fileExtensions.insert(cleanExtension.lowercased())
        }
    }
    
    func removeFileExtension(_ fileExtension: String) {
        let cleanExtension = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        fileExtensions.remove(cleanExtension.lowercased())
    }
    
    func addExcludeExtension(_ fileExtension: String) {
        let cleanExtension = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        if !cleanExtension.isEmpty {
            excludeExtensions.insert(cleanExtension.lowercased())
        }
    }
    
    func removeExcludeExtension(_ fileExtension: String) {
        let cleanExtension = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        excludeExtensions.remove(cleanExtension.lowercased())
    }
    
    // MARK: - Filter Logic
    
    func shouldIncludeFile(_ url: URL) -> Bool {
        // Check if file is in excluded paths
        for excludedPath in excludedPaths {
            if url.path.hasPrefix(excludedPath.path) {
                return false
            }
        }
        
        // Check file size constraints
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                if fileSize < minFileSize {
                    return false
                }
                if maxFileSize > 0 && fileSize > maxFileSize {
                    return false
                }
            }
        } catch {
            return false
        }
        
        // Check file extensions
        if !fileExtensions.isEmpty {
            let fileExtension = url.pathExtension.lowercased()
            if !fileExtensions.contains(fileExtension) {
                return false
            }
        }
        
        // Check excluded extensions
        if !excludeExtensions.isEmpty {
            let fileExtension = url.pathExtension.lowercased()
            if excludeExtensions.contains(fileExtension) {
                return false
            }
        }
        
        // Check hidden files
        if !includeHiddenFiles {
            let filename = url.lastPathComponent
            if filename.hasPrefix(".") {
                return false
            }
        }
        
        // Check category
        let category = FileCategory.categorize(url: url)
        return enabledCategories.contains(category)
    }
    
    // MARK: - Presets
    
    static let developmentPreset: ScanConfiguration = {
        let config = ScanConfiguration()
        config.enabledCategories = [
            .developmentTools, .aiAssistants, .configurations,
            .dependencies, .buildArtifacts, .scripts, .documents
        ]
        config.includeHiddenFiles = true
        config.excludeExtensions = ["DS_Store", "localized"]
        return config
    }()
    
    static let cleanupPreset: ScanConfiguration = {
        let config = ScanConfiguration()
        config.enabledCategories = [.caches, .temporary, .logs]
        config.minFileSize = 1024 // Skip very small files
        return config
    }()
    
    static let comprehensivePreset: ScanConfiguration = {
        let config = ScanConfiguration()
        config.enabledCategories = Set(FileCategory.allCases)
        config.includeHiddenFiles = true
        config.followSymlinks = false
        return config
    }()
}

// MARK: - ScanConfiguration Extensions

extension ScanConfiguration {
    var summary: String {
        var parts: [String] = []
        
        parts.append("\(scanPaths.count) scan path(s)")
        parts.append("\(enabledCategories.count) categor\(enabledCategories.count == 1 ? "y" : "ies")")
        
        if maxFileSize > 0 {
            parts.append("max size: \(FileSizeFormatter.formattedString(fromBytes: maxFileSize))")
        }
        
        if !fileExtensions.isEmpty {
            parts.append("\(fileExtensions.count) extension filter(s)")
        }
        
        return parts.joined(separator: ", ")
    }
}
