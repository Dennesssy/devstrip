import Foundation
import SwiftUI

enum FileCategory: String, CaseIterable, Identifiable {
    case developmentTools = "Development Tools"
    case aiAssistants = "AI Assistants"
    case configurations = "Configurations"
    case caches = "Caches"
    case logs = "Logs"
    case binaries = "Binaries"
    case dependencies = "Dependencies"
    case buildArtifacts = "Build Artifacts"
    case temporary = "Temporary Files"
    case documents = "Documents"
    case scripts = "Scripts"
    case archives = "Archives"
    case unknown = "Unknown"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .developmentTools:
            return "hammer.fill"
        case .aiAssistants:
            return "brain.head.profile"
        case .configurations:
            return "gearshape.2.fill"
        case .caches:
            return "clock.arrow.circlepath"
        case .logs:
            return "doc.text.fill"
        case .binaries:
            return "terminal.fill"
        case .dependencies:
            return "cube.box.fill"
        case .buildArtifacts:
            return "building.2.fill"
        case .temporary:
            return "trash.fill"
        case .documents:
            return "doc.fill"
        case .scripts:
            return "terminal.fill"
        case .archives:
            return "archivebox.fill"
        case .unknown:
            return "questionmark.folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .developmentTools:
            return .blue
        case .aiAssistants:
            return .purple
        case .configurations:
            return .orange
        case .caches:
            return .gray
        case .logs:
            return .red
        case .binaries:
            return .green
        case .dependencies:
            return .mint
        case .buildArtifacts:
            return .indigo
        case .temporary:
            return .secondary
        case .documents:
            return .primary
        case .scripts:
            return .cyan
        case .archives:
            return .brown
        case .unknown:
            return .gray
        }
    }
    
    var description: String {
        switch self {
        case .developmentTools:
            return "IDEs, editors, and development utilities"
        case .aiAssistants:
            return "AI coding assistants and tools"
        case .configurations:
            return "Settings and configuration files"
        case .caches:
            return "Temporary cache files and data"
        case .logs:
            return "Application and system logs"
        case .binaries:
            return "Executable files and tools"
        case .dependencies:
            return "Package managers and libraries"
        case .buildArtifacts:
            return "Compiled code and build outputs"
        case .temporary:
            return "Temporary files that can be cleaned"
        case .documents:
            return "Documentation and text files"
        case .scripts:
            return "Automation and utility scripts"
        case .archives:
            return "Compressed and archived files"
        case .unknown:
            return "Uncategorized files"
        }
    }
    
    // MARK: - Pattern Matching
    
    static func categorize(url: URL) -> FileCategory {
        let path = url.path.lowercased()
        let filename = url.lastPathComponent.lowercased()
        
        // AI Assistants
        if path.contains("amazonq") {
            return .aiAssistants
        }
        if path.contains("augment") {
            return .aiAssistants
        }
        if path.contains("cursor") {
            return .aiAssistants
        }
        
        // Development Tools
        if path.contains(".vscode") || path.contains("visual studio") {
            return .developmentTools
        }
        if path.contains("xcode") {
            return .developmentTools
        }
        if path.contains("jetbrains") || path.contains("intellij") {
            return .developmentTools
        }
        
        // Dependencies
        if path.contains("node_modules") {
            return .dependencies
        }
        if path.contains("pod") {
            return .dependencies
        }
        if path.contains("carthage") {
            return .dependencies
        }
        if path.contains("cargo") && (path.contains("registry") || path.contains("git")) {
            return .dependencies
        }
        
        // Build Artifacts
        if path.contains("target") && path.contains("debug") {
            return .buildArtifacts
        }
        if path.contains("target") && path.contains("release") {
            return .buildArtifacts
        }
        if path.contains("build") || path.contains("dist") {
            return .buildArtifacts
        }
        if path.contains("deriveddata") {
            return .buildArtifacts
        }
        
        // Caches
        if path.contains("cache") {
            return .caches
        }
        if filename.hasSuffix(".cache") {
            return .caches
        }
        
        // Configurations
        if filename.contains("config") || filename.hasSuffix(".json") || filename.hasSuffix(".yaml") || filename.hasSuffix(".yml") {
            return .configurations
        }
        if filename.hasSuffix(".toml") || filename.hasSuffix(".ini") {
            return .configurations
        }
        
        // Logs
        if filename.contains("log") || filename.hasSuffix(".log") {
            return .logs
        }
        
        // Archives
        if filename.hasSuffix(".zip") || filename.hasSuffix(".tar") || filename.hasSuffix(".gz") {
            return .archives
        }
        if filename.hasSuffix(".rar") || filename.hasSuffix(".7z") {
            return .archives
        }
        
        // Scripts
        if filename.hasSuffix(".sh") || filename.hasSuffix(".py") || filename.hasSuffix(".js") {
            return .scripts
        }
        if filename.hasSuffix(".rb") || filename.hasSuffix(".pl") || filename.hasSuffix(".php") {
            return .scripts
        }
        
        // Binaries
        if url.pathExtension.isEmpty && filename != "readme" && !filename.contains(".md") {
            // Check if it's executable
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return .binaries
            }
        }
        
        // Documents
        if filename.hasSuffix(".md") || filename.hasSuffix(".txt") || filename.hasSuffix(".rtf") {
            return .documents
        }
        
        // Temporary
        if filename.hasSuffix(".tmp") || filename.hasSuffix(".temp") || filename.contains("temp") {
            return .temporary
        }
        
        return .unknown
    }
    
    // MARK: - Tool-Specific Categories
    
    static func toolSpecificCategory(for url: URL) -> FileCategory? {
        let path = url.path.lowercased()
        
        // Amazon Q specific files
        if path.contains("amazonq") {
            if path.contains("cli-todo-lists") {
                return .aiAssistants
            }
            if url.lastPathComponent.hasSuffix(".json") {
                return .configurations
            }
        }
        
        // Augment specific files
        if path.contains("augment") {
            if path.contains("binaries") {
                return .binaries
            }
            if path.contains("task-storage") {
                return .caches
            }
            if url.lastPathComponent == "manifest" {
                return .configurations
            }
        }
        
        return nil
    }
}

// MARK: - Category Statistics

extension FileCategory {
    struct Statistics {
        let fileCount: Int
        let totalSize: Int64
        let lastModified: Date?
        
        var formattedSize: String {
            FileSizeFormatter.formattedString(fromBytes: totalSize)
        }
        
        var formattedLastModified: String {
            guard let date = lastModified else { return "Never" }
            return DateFormatter.modificationDateFormatter.string(from: date)
        }
    }
}

// MARK: - FileManager Extension

extension FileManager {
    func isExecutableFile(atPath path: String) -> Bool {
        return FileManager.default.isExecutableFile(atPath: path)
    }
}
