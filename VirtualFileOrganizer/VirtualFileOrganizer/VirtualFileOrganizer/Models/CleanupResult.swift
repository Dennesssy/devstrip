import Foundation

enum CleanupResult: Identifiable {
    case success(VirtualFile)
    case failure(VirtualFile, Error)
    case skipped(VirtualFile, String)
    
    var id: UUID {
        UUID()
    }
    
    var file: VirtualFile {
        switch self {
        case .success(let file), .failure(let file, _), .skipped(let file, _):
            return file
        }
    }
    
    var wasSuccessful: Bool {
        switch self {
        case .success:
            return true
        case .failure, .skipped:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .failure(_, let error):
            return error.localizedDescription
        case .skipped(_, let reason):
            return reason
        case .success:
            return nil
        }
    }
    
    var resultType: String {
        switch self {
        case .success:
            return "Deleted"
        case .failure:
            return "Failed"
        case .skipped:
            return "Skipped"
        }
    }
    
    var resultIcon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }
    
    var resultColor: String {
        switch self {
        case .success:
            return "green"
        case .failure:
            return "red"
        case .skipped:
            return "orange"
        }
    }
}

// MARK: - Cleanup Statistics

struct CleanupStatistics {
    let totalFiles: Int
    let successfulDeletions: Int
    let failedDeletions: Int
    let skippedFiles: Int
    let totalSizeFreed: Int64
    let duration: TimeInterval
    
    var successRate: Double {
        guard totalFiles > 0 else { return 0.0 }
        return Double(successfulDeletions) / Double(totalFiles) * 100.0
    }
    
    var formattedTotalSizeFreed: String {
        FileSizeFormatter.formattedString(fromBytes: totalSizeFreed)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    static let empty = CleanupStatistics(
        totalFiles: 0,
        successfulDeletions: 0,
        failedDeletions: 0,
        skippedFiles: 0,
        totalSizeFreed: 0,
        duration: 0
    )
}

// MARK: - Cleanup Operation

struct CleanupOperation {
    let files: [VirtualFile]
    let configuration: CleanupConfiguration
    
    init(files: [VirtualFile], configuration: CleanupConfiguration = .default) {
        self.files = files
        self.configuration = configuration
    }
}

// MARK: - Cleanup Configuration

struct CleanupConfiguration {
    let moveToTrash: Bool
    let createBackup: Bool
    let confirmDeletion: Bool
    let skipSystemFiles: Bool
    let skipLockedFiles: Bool
    let dryRun: Bool
    
    static let `default` = CleanupConfiguration(
        moveToTrash: true,
        createBackup: false,
        confirmDeletion: true,
        skipSystemFiles: true,
        skipLockedFiles: true,
        dryRun: false
    )
    
    static let aggressive = CleanupConfiguration(
        moveToTrash: false, // Permanent deletion
        createBackup: true,
        confirmDeletion: false,
        skipSystemFiles: false,
        skipLockedFiles: false,
        dryRun: false
    )
    
    static let safe = CleanupConfiguration(
        moveToTrash: true,
        createBackup: true,
        confirmDeletion: true,
        skipSystemFiles: true,
        skipLockedFiles: true,
        dryRun: false
    )
}

// MARK: - Cleanup Progress

@Observable
class CleanupProgress {
    var currentFile: String = ""
    var filesProcessed: Int = 0
    var totalFiles: Int = 0
    var bytesProcessed: Int64 = 0
    var totalBytes: Int64 = 0
    var isRunning: Bool = false
    var currentOperation: String = ""
    var errors: [String] = []
    
    var progressFraction: Double {
        guard totalFiles > 0 else { return 0.0 }
        return Double(filesProcessed) / Double(totalFiles)
    }
    
    var formattedProgress: String {
        return "\(filesProcessed) / \(totalFiles) files"
    }
    
    var formattedSizeProgress: String {
        let processed = FileSizeFormatter.formattedString(fromBytes: bytesProcessed)
        let total = FileSizeFormatter.formattedString(fromBytes: totalBytes)
        return "\(processed) / \(total)"
    }
    
    func start(totalFiles: Int, totalBytes: Int64) {
        self.totalFiles = totalFiles
        self.totalBytes = totalBytes
        self.filesProcessed = 0
        self.bytesProcessed = 0
        self.isRunning = true
        self.errors.removeAll()
        self.currentOperation = "Preparing cleanup operation..."
    }
    
    func update(file: VirtualFile) {
        self.currentFile = file.name
        self.filesProcessed += 1
        self.bytesProcessed += file.size
    }
    
    func addError(_ error: String) {
        errors.append(error)
    }
    
    func finish() {
        isRunning = false
        currentOperation = "Cleanup completed"
    }
    
    func cancel() {
        isRunning = false
        currentOperation = "Cleanup cancelled"
    }
}

// MARK: - Cleanup Validation

extension CleanupOperation {
    func validate() -> [String] {
        var warnings: [String] = []
        
        if files.isEmpty {
            warnings.append("No files selected for cleanup")
        }
        
        let systemFiles = files.filter { file in
            file.url.path.hasPrefix("/System") || 
            file.url.path.hasPrefix("/Library") ||
            file.url.path.contains("/usr/")
        }
        
        if !systemFiles.isEmpty && !configuration.skipSystemFiles {
            warnings.append("\(systemFiles.count) system file(s) will be deleted")
        }
        
        let largeFiles = files.filter { $0.size > 100 * 1024 * 1024 } // > 100MB
        if !largeFiles.isEmpty {
            warnings.append("\(largeFiles.count) large file(s) (>100MB) will be deleted")
        }
        
        let recentlyModified = files.filter { file in
            guard let modified = file.modificationDate else { return false }
            let daysSinceModified = Date().timeIntervalSince(modified) / (24 * 60 * 60)
            return daysSinceModified < 7
        }
        
        if !recentlyModified.isEmpty {
            warnings.append("\(recentlyModified.count) recently modified file(s) will be deleted")
        }
        
        return warnings
    }
    
    func getSummary() -> String {
        let totalSize = files.reduce(0) { $0 + $1.size }
        let formattedSize = FileSizeFormatter.formattedString(fromBytes: totalSize)
        let categories = Set(files.map { Set($0.categories).map { $0.rawValue } }.joined())
        
        return """
        Files to delete: \(files.count)
        Total size: \(formattedSize)
        Categories: \(categories.joined(separator: ", "))
        Mode: \(configuration.moveToTrash ? "Move to Trash" : "Permanent deletion")
        """
    }
}
