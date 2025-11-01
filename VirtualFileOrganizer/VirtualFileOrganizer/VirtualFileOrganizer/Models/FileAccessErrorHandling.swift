import SwiftUI

/// Errors that can occur during file access operations
enum FileAccessError: LocalizedError {
    case permissionDenied(URL)
    case fileNotFound(URL)
    case directoryNotAccessible(URL)
    case bookmarkResolutionFailed(URL)
    case securityScopedAccessFailed(URL)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let url):
            return "Permission denied to access: \(url.lastPathComponent)"
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .directoryNotAccessible(let url):
            return "Cannot access directory: \(url.lastPathComponent)"
        case .bookmarkResolutionFailed(let url):
            return "Cannot restore access to: \(url.lastPathComponent)"
        case .securityScopedAccessFailed(let url):
            return "Security check failed for: \(url.lastPathComponent)"
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied, .directoryNotAccessible, .bookmarkResolutionFailed:
            return "Try selecting the directory again to grant access."
        case .fileNotFound:
            return "The file may have been moved or deleted."
        case .securityScopedAccessFailed:
            return "Please restart the app and try again."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}

/// A view that displays file access errors with helpful recovery options
struct FileAccessErrorView: View {
    let error: FileAccessError
    let onRetry: (() -> Void)?
    let onRequestAccess: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text(error.errorDescription ?? "An error occurred")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                if let onRetry = onRetry {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let onRequestAccess = onRequestAccess,
                   shouldShowAccessButton {
                    Button("Grant Access") {
                        onRequestAccess()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(40)
    }
    
    private var errorIcon: String {
        switch error {
        case .permissionDenied, .directoryNotAccessible:
            return "lock.shield"
        case .fileNotFound:
            return "doc.badge.ellipsis"
        case .bookmarkResolutionFailed, .securityScopedAccessFailed:
            return "exclamationmark.triangle"
        case .unknown:
            return "exclamationmark.circle"
        }
    }
    
    private var shouldShowAccessButton: Bool {
        switch error {
        case .permissionDenied, .directoryNotAccessible, .bookmarkResolutionFailed:
            return true
        default:
            return false
        }
    }
}

/// Extension to safely handle file operations with proper error handling
extension FileAccessManager {
    /// Safely access a file and handle common errors
    func safelyAccessFile<T>(
        _ url: URL,
        operation: (URL) throws -> T
    ) -> Result<T, FileAccessError> {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return .failure(.fileNotFound(url))
        }
        
        // Try to access with security scoping
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard didStartAccessing else {
            // Try to resolve from bookmark
            if let resolvedURL = resolveBookmark(for: url) {
                return safelyAccessFile(resolvedURL, operation: operation)
            }
            return .failure(.securityScopedAccessFailed(url))
        }
        
        do {
            let result = try operation(url)
            return .success(result)
        } catch let error as NSError {
            // Check for specific error codes
            switch error.code {
            case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
                return .failure(.permissionDenied(url))
            case NSFileNoSuchFileError, NSFileReadNoSuchFileError:
                return .failure(.fileNotFound(url))
            default:
                return .failure(.unknown(error))
            }
        }
    }
    
    /// Safely scan a directory with error handling
    func safelyScanDirectory(
        _ url: URL,
        maxDepth: Int = 10,
        progressHandler: ((URL, Int) -> Void)? = nil
    ) -> Result<[URL], FileAccessError> {
        return safelyAccessFile(url) { url in
            try scanDirectoryRecursive(
                url,
                currentDepth: 0,
                maxDepth: maxDepth,
                progressHandler: progressHandler
            )
        }
    }
    
    private func scanDirectoryRecursive(
        _ url: URL,
        currentDepth: Int,
        maxDepth: Int,
        progressHandler: ((URL, Int) -> Void)?
    ) throws -> [URL] {
        guard currentDepth <= maxDepth else { return [] }
        
        progressHandler?(url, currentDepth)
        
        var files: [URL] = []
        let fileManager = FileManager.default
        
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            
            if resourceValues.isDirectory == true {
                // Recursively scan subdirectory
                let subFiles = try scanDirectoryRecursive(
                    itemURL,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth,
                    progressHandler: progressHandler
                )
                files.append(contentsOf: subFiles)
            } else {
                files.append(itemURL)
            }
        }
        
        return files
    }
}

// MARK: - Preview

#Preview("Permission Denied") {
    FileAccessErrorView(
        error: .permissionDenied(URL(fileURLWithPath: "/Users/test/Documents")),
        onRetry: { print("Retry") },
        onRequestAccess: { print("Request Access") }
    )
}

#Preview("File Not Found") {
    FileAccessErrorView(
        error: .fileNotFound(URL(fileURLWithPath: "/Users/test/file.txt")),
        onRetry: { print("Retry") },
        onRequestAccess: nil
    )
}
