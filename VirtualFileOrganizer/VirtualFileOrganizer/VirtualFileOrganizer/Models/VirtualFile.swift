import Foundation
import UniformTypeIdentifiers

@Observable
class VirtualFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let originalPath: String
    var name: String
    var fileExtension: String
    var size: Int64
    var creationDate: Date?
    var modificationDate: Date?
    var fileType: UTType?
    private var _categories: Set<FileCategory>
    private var _tags: Set<String>
    
    // Security-scoped bookmark data for persistent file access
    private var bookmarkData: Data?
    
    var categories: Set<FileCategory> {
        get { _categories }
        set { _categories = newValue }
    }
    
    var tags: Set<String> {
        get { _tags }
        set { _tags = newValue }
    }
    
    init(url: URL) {
        self.url = url
        self.originalPath = url.path(percentEncoded: false)
        self.name = url.lastPathComponent
        self.fileExtension = url.pathExtension
        self._categories = []
        self._tags = []
        
        // Start accessing security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Create security-scoped bookmark for future access
        if didStartAccessing {
            do {
                self.bookmarkData = try url.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            } catch {
                print("Failed to create bookmark: \(error.localizedDescription)")
                self.bookmarkData = nil
            }
        }
        
        // Get file attributes - use path(percentEncoded: false) for better compatibility
        let path = url.path(percentEncoded: false)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            self.size = attributes[.size] as? Int64 ?? 0
            self.creationDate = attributes[.creationDate] as? Date
            self.modificationDate = attributes[.modificationDate] as? Date
        } catch {
            // Safely handle missing or inaccessible files
            self.size = 0
            self.creationDate = nil
            self.modificationDate = nil
        }
        
        // Determine file type - use safer resource value fetching
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
            self.fileType = resourceValues.contentType
        } catch {
            self.fileType = nil
        }
    }
    
    /// Access the file with proper security scoping
    func accessSecurely<T>(_ block: (URL) throws -> T) rethrows -> T? {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        if didStartAccessing {
            return try block(url)
        }
        return nil
    }
    
    /// Resolve the file URL from bookmark data if available
    func resolveURL() -> URL? {
        guard let bookmarkData = bookmarkData else { return url }
        
        var isStale = false
        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // Recreate the bookmark if it's stale
                if let newBookmarkData = try? resolvedURL.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    self.bookmarkData = newBookmarkData
                }
            }
            
            return resolvedURL
        } catch {
            print("Failed to resolve bookmark: \(error.localizedDescription)")
            return url
        }
    }
    
    func addToCategory(_ category: FileCategory) {
        categories.insert(category)
    }
    
    func removeFromCategory(_ category: FileCategory) {
        categories.remove(category)
    }
    
    func addTag(_ tag: String) {
        tags.insert(tag)
    }
    
    func removeTag(_ tag: String) {
        tags.remove(tag)
    }
    
    // MARK: - Computed Properties
    
    var formattedSize: String {
        FileSizeFormatter.formattedString(fromBytes: size)
    }
    
    var formattedModificationDate: String? {
        guard let date = modificationDate else { return nil }
        return DateFormatter.modificationDateFormatter.string(from: date)
    }
    
    var isDirectory: Bool {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return false
        }
        return (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }
    
    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        
        guard let fileType = fileType else {
            return "doc.fill"
        }
        
        // Common file type mappings
        if fileType.conforms(to: .json) {
            return "doc.text.fill"
        } else if fileType.conforms(to: .plainText) {
            return "doc.plaintext.fill"
        } else if fileType.conforms(to: .executable) {
            return "terminal.fill"
        } else if fileType.conforms(to: .archive) {
            return "archivebox.fill"
        } else {
            return "doc.fill"
        }
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(url)
    }
    
    static func == (lhs: VirtualFile, rhs: VirtualFile) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - File Metadata

extension VirtualFile {
    struct Metadata {
        let toolName: String?
        let version: String?
        let purpose: String?
        let lastAccessed: Date?
        
        init(url: URL) {
            // Extract tool information from path
            let pathComponents = url.pathComponents
            self.toolName = Self.extractToolName(from: pathComponents)
            self.version = Self.extractVersion(from: pathComponents)
            self.purpose = Self.extractPurpose(from: url)
            self.lastAccessed = Self.extractLastAccessed(from: url)
        }
        
        private static func extractToolName(from components: [String]) -> String? {
            // Look for common tool patterns in path
            for component in components {
                if component.contains("amazonq") {
                    return "Amazon Q"
                } else if component.contains("augment") {
                    return "Augment"
                } else if component.contains(".vscode") {
                    return "VS Code"
                } else if component.contains("node_modules") {
                    return "Node.js"
                } else if component.contains("target") && component.contains("rust") {
                    return "Rust"
                }
            }
            return nil
        }
        
        private static func extractVersion(from components: [String]) -> String? {
            // Extract version numbers from path components
            for component in components {
                if component.hasPrefix("v") && component.dropFirst().allSatisfy({ $0.isNumber || $0 == "." }) {
                    return component
                }
            }
            return nil
        }
        
        private static func extractPurpose(from url: URL) -> String? {
            let name = url.lastPathComponent.lowercased()
            if name.contains("config") || name.hasSuffix(".json") {
                return "Configuration"
            } else if name.contains("cache") {
                return "Cache"
            } else if name.contains("log") {
                return "Log"
            } else if name.contains("temp") || name.hasSuffix(".tmp") {
                return "Temporary"
            }
            return nil
        }
        
        private static func extractLastAccessed(from url: URL) -> Date? {
            return (try? url.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
        }
    }
    
    var metadata: Metadata {
        Metadata(url: url)
    }
}
