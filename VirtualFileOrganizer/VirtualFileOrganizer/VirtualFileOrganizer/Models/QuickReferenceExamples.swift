import SwiftUI
import FoundationModels
import AppIntents
import CoreSpotlight

/// Quick reference examples for file access operations
/// Copy and adapt these snippets as needed

// MARK: - Supporting Types

enum FileCategory: String, Codable {
    case image = "Image"
    case document = "Document"
    case video = "Video"
    case audio = "Audio"
    case code = "Code"
    case archive = "Archive"
    case other = "Other"
}

// MARK: - Example 1: Request Directory Access

struct Example1_RequestAccess: View {
    @State private var fileAccessManager = FileAccessManager()
    @State private var selectedDirectories: [URL] = []
    
    var body: some View {
        VStack {
            if selectedDirectories.isEmpty {
                Button("Select Directories to Scan") {
                    fileAccessManager.requestDirectoryAccess { urls in
                        selectedDirectories = urls
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Access granted to \(selectedDirectories.count) directories")
                
                List(selectedDirectories, id: \.self) { url in
                    Text(url.path(percentEncoded: false))
                }
            }
        }
    }
}

// MARK: - Example 2: Safely Read File Content

struct Example2_ReadFile: View {
    let fileURL: URL
    @State private var fileAccessManager = FileAccessManager()
    @State private var content: String = ""
    @State private var error: FileAccessError?
    
    var body: some View {
        VStack {
            if let error = error {
                FileAccessErrorView(
                    error: error,
                    onRetry: { loadFile() },
                    onRequestAccess: { requestAccess() }
                )
            } else {
                Text(content)
                    .padding()
            }
        }
        .onAppear { loadFile() }
    }
    
    private func loadFile() {
        let result = fileAccessManager.safelyAccessFile(fileURL) { url in
            try String(contentsOf: url, encoding: .utf8)
        }
        
        switch result {
        case .success(let text):
            content = text
        case .failure(let err):
            error = err
        }
    }
    
    private func requestAccess() {
        fileAccessManager.requestDirectoryAccess { urls in
            if !urls.isEmpty {
                error = nil
                loadFile()
            }
        }
    }
}

// MARK: - Example 3: Scan Directory with Progress

struct Example3_ScanDirectory: View {
    @State private var fileAccessManager = FileAccessManager()
    @State private var files: [URL] = []
    @State private var isScanning = false
    @State private var currentPath = ""
    @State private var error: FileAccessError?
    
    var body: some View {
        VStack(spacing: 20) {
            if isScanning {
                ProgressView()
                Text("Scanning: \(currentPath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let error = error {
                FileAccessErrorView(
                    error: error,
                    onRetry: { scanDirectory() },
                    onRequestAccess: { requestAndScan() }
                )
            } else {
                Text("Found \(files.count) files")
                Button("Start Scan") {
                    requestAndScan()
                }
            }
        }
        .padding()
    }
    
    private func requestAndScan() {
        fileAccessManager.requestDirectoryAccess { urls in
            guard let firstURL = urls.first else { return }
            scanDirectory(at: firstURL)
        }
    }
    
    private func scanDirectory(at url: URL? = nil) {
        guard let url = url ?? fileAccessManager.savedURLs.first else {
            return
        }
        
        isScanning = true
        error = nil
        
        Task {
            let result = await Task.detached {
                fileAccessManager.safelyScanDirectory(url, maxDepth: 5) { path, depth in
                    DispatchQueue.main.async {
                        currentPath = path.lastPathComponent
                    }
                }
            }.value
            
            await MainActor.run {
                isScanning = false
                
                switch result {
                case .success(let urls):
                    files = urls
                case .failure(let err):
                    error = err
                }
            }
        }
    }
}

// MARK: - Example 4: Using VirtualFile with Security

struct Example4_VirtualFileUsage: View {
    let virtualFile: VirtualFile
    @State private var fileData: Data?
    @State private var error: String?
    
    var body: some View {
        VStack {
            if let error = error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            } else if let data = fileData {
                Text("Loaded \(data.count) bytes")
            } else {
                ProgressView()
            }
        }
        .onAppear { loadFileData() }
    }
    
    private func loadFileData() {
        // VirtualFile handles security-scoped access automatically
        let result = try? virtualFile.accessSecurely { url in
            try Data(contentsOf: url)
        }
        
        if let data = result {
            fileData = data
        } else {
            error = "Failed to load file"
        }
    }
}

// MARK: - Example 5: Permission Flow in Main App

struct Example5_AppWithPermissions: View {
    @State private var fileAccessManager = FileAccessManager()
    @State private var hasAccess = false
    
    var body: some View {
        Group {
            if hasAccess {
                mainContent
            } else {
                permissionRequest
            }
        }
        .onAppear {
            // Check if we already have saved bookmarks
            hasAccess = !fileAccessManager.savedURLs.isEmpty
        }
    }
    
    private var permissionRequest: some View {
        FileAccessPermissionView(
            selectedDirectories: Binding(
                get: { fileAccessManager.savedURLs },
                set: { _ in hasAccess = true }
            )
        )
    }
    
    private var mainContent: some View {
        VStack {
            Text("App Content Here")
            
            Button("Manage Access") {
                hasAccess = false
            }
        }
    }
}

// MARK: - APPLE INTELLIGENCE INTEGRATION EXAMPLES

// MARK: - Example 9: Foundation Models - AI File Summarizer

import FoundationModels

@Observable
class AIFileSummarizer {
    private let model = SystemLanguageModel.default
    private var session: LanguageModelSession?
    
    var isAvailable: Bool {
        if case .available = model.availability {
            return true
        }
        return false
    }
    
    var availabilityMessage: String {
        switch model.availability {
        case .available:
            return "AI is ready"
        case .unavailable(.deviceNotEligible):
            return "Device not eligible for Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            return "AI model is downloading..."
        case .unavailable(let reason):
            return "AI unavailable: \(reason)"
        }
    }
    
    func initializeSession() {
        let instructions = """
        You are a helpful file management assistant.
        Analyze file content and provide concise, useful summaries.
        Focus on key information and maintain clarity.
        Keep responses under 150 words unless asked otherwise.
        """
        session = LanguageModelSession(instructions: instructions)
    }
    
    func summarizeFileContent(_ content: String, fileName: String) async throws -> String {
        guard isAvailable else {
            throw AIError.modelUnavailable
        }
        
        if session == nil {
            initializeSession()
        }
        
        let prompt = """
        Summarize this file named "\(fileName)":
        
        \(content)
        
        Provide a brief, useful summary focusing on the main content and purpose.
        """
        
        let response = try await session!.respond(to: prompt)
        return response.content
    }
    
    func analyzeMultipleFiles(_ files: [(name: String, content: String)]) async throws -> FilesAnalysis {
        guard isAvailable else {
            throw AIError.modelUnavailable
        }
        
        if session == nil {
            initializeSession()
        }
        
        let filesList = files.map { "- \($0.name): \($0.content.prefix(200))..." }.joined(separator: "\n")
        
        let prompt = """
        Analyze these files and provide insights:
        
        \(filesList)
        
        Generate an analysis with categories and key findings.
        """
        
        let response = try await session!.respond(
            to: prompt,
            generating: FilesAnalysis.self
        )
        
        return response.content
    }
    
    enum AIError: Error {
        case modelUnavailable
    }
}

@Generable(description: "Analysis of multiple files with categorization")
struct FilesAnalysis {
    @Guide(description: "Main category or theme of these files")
    var primaryCategory: String
    
    @Guide(description: "List of key findings", .count(3...5))
    var keyFindings: [String]
    
    @Guide(description: "Suggested organization strategy")
    var organizationSuggestion: String
}

struct Example9_AIFileSummarizer: View {
    @State private var fileAccessManager = FileAccessManager()
    @State private var summarizer = AIFileSummarizer()
    @State private var selectedFile: VirtualFile?
    @State private var summary: String = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Model availability status
            HStack {
                Image(systemName: summarizer.isAvailable ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(summarizer.isAvailable ? .green : .orange)
                Text(summarizer.availabilityMessage)
                    .font(.caption)
            }
            
            if summarizer.isAvailable {
                Button("Select File to Summarize") {
                    selectAndSummarizeFile()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                if isLoading {
                    ProgressView("Analyzing with Apple Intelligence...")
                }
                
                if let error = error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
                
                if !summary.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("AI Summary", systemImage: "sparkles")
                                .font(.headline)
                            
                            Text(summary)
                                .font(.body)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding()
                    }
                }
            }
        }
        .padding()
    }
    
    private func selectAndSummarizeFile() {
        fileAccessManager.requestDirectoryAccess { urls in
            guard let firstURL = urls.first else { return }
            
            Task {
                isLoading = true
                error = nil
                
                let result = fileAccessManager.safelyAccessFile(firstURL) { url in
                    try String(contentsOf: url, encoding: .utf8)
                }
                
                switch result {
                case .success(let content):
                    do {
                        summary = try await summarizer.summarizeFileContent(
                            content,
                            fileName: firstURL.lastPathComponent
                        )
                    } catch {
                        self.error = "Failed to generate summary: \(error.localizedDescription)"
                    }
                case .failure(let fileError):
                    self.error = fileError.localizedDescription
                }
                
                isLoading = false
            }
        }
    }
}

// MARK: - Example 10: Foundation Models - Smart File Organizer with Tool Calling

@Observable
class SmartFileOrganizer {
    private var session: LanguageModelSession?
    private let fileAccessManager = FileAccessManager()
    
    func initializeWithTools() {
        let instructions = """
        You are a file organization assistant.
        Use the available tools to search and categorize files.
        Provide helpful suggestions for organizing user's files.
        """
        
        let searchTool = FileSearchTool(manager: fileAccessManager)
        let categorizeTool = FileCategorizationTool()
        
        session = LanguageModelSession(
            instructions: instructions,
            tools: [searchTool, categorizeTool]
        )
    }
    
    func organizeFiles(in directory: URL, criteria: String) async throws -> OrganizationPlan {
        if session == nil {
            initializeWithTools()
        }
        
        let prompt = """
        Analyze files in the directory and create an organization plan based on: \(criteria)
        Use the search tool to find files and categorization tool to suggest groups.
        """
        
        let response = try await session!.respond(
            to: prompt,
            generating: OrganizationPlan.self
        )
        
        return response.content
    }
}

@Generable(description: "A plan for organizing files into groups")
struct OrganizationPlan {
    @Guide(description: "Suggested folder categories", .count(3...8))
    var categories: [String]
    
    @Guide(description: "Rationale for this organization structure")
    var rationale: String
    
    @Guide(description: "Estimated number of files to move")
    var estimatedFileCount: Int
}

struct FileSearchTool: Tool {
    let manager: FileAccessManager
    
    struct Arguments: Codable {
        var pattern: String
        var maxResults: Int = 50
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Search through accessible directories
        var foundFiles: [String] = []
        
        for url in manager.savedURLs {
            let result = manager.safelyScanDirectory(url, maxDepth: 3)
            if case .success(let files) = result {
                let matching = files.filter { file in
                    file.lastPathComponent.localizedCaseInsensitiveContains(arguments.pattern)
                }
                foundFiles.append(contentsOf: matching.prefix(arguments.maxResults).map { $0.lastPathComponent })
            }
        }
        
        let resultString = foundFiles.isEmpty 
            ? "No files found matching '\(arguments.pattern)'"
            : "Found \(foundFiles.count) files:\n" + foundFiles.joined(separator: "\n")
        
        return .string(resultString)
    }
}

struct FileCategorizationTool: Tool {
    struct Arguments: Codable {
        var fileExtensions: [String]
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        var categories: [String: [String]] = [:]
        
        for ext in arguments.fileExtensions {
            let category = categorizeExtension(ext)
            categories[category, default: []].append(ext)
        }
        
        let result = categories.map { category, extensions in
            "\(category): \(extensions.joined(separator: ", "))"
        }.joined(separator: "\n")
        
        return .string(result)
    }
    
    private func categorizeExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic": return "Images"
        case "mp4", "mov", "avi": return "Videos"
        case "pdf", "doc", "docx", "txt": return "Documents"
        case "mp3", "wav", "aac": return "Audio"
        case "swift", "py", "js", "java": return "Code"
        default: return "Other"
        }
    }
}

// MARK: - Example 11: Visual Intelligence - File Discovery by Image

import AppIntents

// Define file entity for Visual Intelligence
struct FileEntity: AppEntity {
    var id: String
    var name: String
    var path: String
    var thumbnailName: String?
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("File"),
            numericFormat: "\(placeholder: .int) files"
        )
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(path)",
            image: thumbnailName != nil ? .init(named: thumbnailName!) : .init(systemName: "doc")
        )
    }
}

struct FileIntentValueQuery: IntentValueQuery {
    typealias Input = <#type#>
    
    func values(for input: SemanticContentDescriptor) async throws -> [FileEntity] {
        // Use labels from visual intelligence to find matching files
        let labels = input.labels
        
        // Search files that match the visual description
        let fileAccessManager = FileAccessManager()
        var matchingFiles: [FileEntity] = []
        
        for url in fileAccessManager.savedURLs {
            let result = fileAccessManager.safelyScanDirectory(url, maxDepth: 2)
            if case .success(let files) = result {
                // Filter files by labels (e.g., "document", "photo", "code")
                for file in files {
                    if matchesLabels(file: file, labels: labels) {
                        matchingFiles.append(FileEntity(
                            id: file.path,
                            name: file.lastPathComponent,
                            path: file.path(percentEncoded: false),
                            thumbnailName: nil
                        ))
                    }
                }
            }
        }
        
        return Array(matchingFiles.prefix(10))
    }
    
    private func matchesLabels(file: URL, labels: [String]) -> Bool {
        let fileName = file.lastPathComponent.lowercased()
        let ext = file.pathExtension.lowercased()
        
        for label in labels {
            let labelLower = label.lowercased()
            if fileName.contains(labelLower) {
                return true
            }
            
            // Match by category
            if labelLower.contains("photo") || labelLower.contains("image") {
                if ["jpg", "jpeg", "png", "gif", "heic"].contains(ext) {
                    return true
                }
            }
            
            if labelLower.contains("document") || labelLower.contains("text") {
                if ["pdf", "doc", "docx", "txt", "md"].contains(ext) {
                    return true
                }
            }
            
            if labelLower.contains("code") || labelLower.contains("programming") {
                if ["swift", "py", "js", "java", "cpp", "c"].contains(ext) {
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - Example 12: App Intents - Siri Integration

struct SearchFilesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Files"
    static var description: LocalizedStringResource = "Search for files by name or type"
    
    @Parameter(title: "Search Term")
    var searchTerm: String
    
    @Parameter(title: "File Type", default: nil)
    var fileType: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Search for \(\.$searchTerm) files") {
            \.$fileType
        }
    }
    
    func perform() async throws -> some ReturnsValue<[FileEntity]> & ProvidesDialog {
        let fileAccessManager = FileAccessManager()
        var foundFiles: [FileEntity] = []
        
        for url in fileAccessManager.savedURLs {
            let result = fileAccessManager.safelyScanDirectory(url, maxDepth: 5)
            if case .success(let files) = result {
                let matching = files.filter { file in
                    let nameMatch = file.lastPathComponent.localizedCaseInsensitiveContains(searchTerm)
                    let typeMatch = fileType == nil || file.pathExtension.lowercased() == fileType?.lowercased()
                    return nameMatch && typeMatch
                }
                
                foundFiles.append(contentsOf: matching.map { file in
                    FileEntity(
                        id: file.path,
                        name: file.lastPathComponent,
                        path: file.path(percentEncoded: false),
                        thumbnailName: nil
                    )
                })
            }
        }
        
        let limitedResults = Array(foundFiles.prefix(20))
        let dialog: IntentDialog
        
        if limitedResults.isEmpty {
            dialog = "No files found matching '\(searchTerm)'"
        } else {
            dialog = "Found \(limitedResults.count) files matching '\(searchTerm)'"
        }
        
        return .result(value: limitedResults, dialog: dialog)
    }
}

struct GetFileDetailsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get File Details"
    static var supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    
    @Parameter(title: "File Path")
    var filePath: String
    
    func perform() async throws -> some ReturnsValue<FileDetails> & ProvidesDialog {
        let fileURL = URL(fileURLWithPath: filePath)
        let fileAccessManager = FileAccessManager()
        
        let result = fileAccessManager.safelyAccessFile(fileURL) { url in
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
            return FileDetails(
                name: url.lastPathComponent,
                size: attributes[.size] as? Int64 ?? 0,
                modifiedDate: attributes[.modificationDate] as? Date ?? Date(),
                fileType: url.pathExtension
            )
        }
        
        switch result {
        case .success(let details):
            // If file is large, open app to show full details
            if details.size > 10_000_000 && systemContext.currentMode.canContinueInForeground {
                try await continueInForeground(alwaysConfirm: false)
            }
            
            let sizeString = ByteCountFormatter.string(fromByteCount: details.size, countStyle: .file)
            return .result(
                value: details,
                dialog: "\(details.name) is \(sizeString), modified on \(details.modifiedDate.formatted(date: .abbreviated, time: .shortened))"
            )
            
        case .failure(let error):
            throw error
        }
    }
}

@Generable(description: "Detailed information about a file")
struct FileDetails {
    var name: String
    var size: Int64
    var modifiedDate: Date
    var fileType: String
}

// App Shortcuts for Siri
struct FileAccessAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchFilesIntent(),
            phrases: [
                "Search for \(\.$searchTerm) in \(.applicationName)",
                "Find \(\.$searchTerm) files with \(.applicationName)",
                "Look for \(\.$searchTerm) using \(.applicationName)"
            ],
            shortTitle: "Search Files",
            systemImageName: "magnifyingglass"
        )
    }
}

// MARK: - Example 13: Spotlight Integration

extension VirtualFile {
    var searchableAttributes: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: fileType ?? .data)
        
        attributes.title = name
        attributes.displayName = name
        attributes.alternateNames = [name, originalPath]
        attributes.contentDescription = "File: \(name)"
        
        if let size = size as? Int {
            attributes.fileSize = NSNumber(value: size)
        }
        
        attributes.contentCreationDate = creationDate
        attributes.contentModificationDate = modificationDate
        attributes.keywords = Array(tags)
        
        // Add category information
        let categoryNames = categories.map { $0.rawValue }
        attributes.keywords?.append(contentsOf: categoryNames)
        
        return attributes
    }
}

@Observable
class SpotlightIndexManager {
    private let index = CSSearchableIndex.default()
    
    func indexFiles(_ files: [VirtualFile]) async throws {
        let items = files.map { file in
            CSSearchableItem(
                uniqueIdentifier: file.id.uuidString,
                domainIdentifier: "com.yourapp.files",
                attributeSet: file.searchableAttributes
            )
        }
        
        try await index.indexSearchableItems(items)
    }
    
    func updateFile(_ file: VirtualFile) async throws {
        let item = CSSearchableItem(
            uniqueIdentifier: file.id.uuidString,
            domainIdentifier: "com.yourapp.files",
            attributeSet: file.searchableAttributes
        )
        
        try await index.indexSearchableItems([item])
    }
    
    func removeFile(_ file: VirtualFile) async throws {
        try await index.deleteSearchableItems(withIdentifiers: [file.id.uuidString])
    }
    
    func removeAllFiles() async throws {
        try await index.deleteSearchableItems(withDomainIdentifiers: ["com.yourapp.files"])
    }
}

struct Example13_SpotlightIntegration: View {
    @State private var fileAccessManager = FileAccessManager()
    @State private var spotlightManager = SpotlightIndexManager()
    @State private var indexedFilesCount = 0
    @State private var isIndexing = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Spotlight Integration")
                .font(.headline)
            
            if indexedFilesCount > 0 {
                Label("\(indexedFilesCount) files indexed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            
            Button("Index Files for Spotlight") {
                indexFiles()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isIndexing)
            
            if isIndexing {
                ProgressView("Indexing files...")
            }
            
            if let error = error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
            
            Button("Clear Spotlight Index", role: .destructive) {
                clearIndex()
            }
            .buttonStyle(.bordered)
            .disabled(isIndexing)
        }
        .padding()
    }
    
    private func indexFiles() {
        fileAccessManager.requestDirectoryAccess { urls in
            Task {
                isIndexing = true
                error = nil
                
                var allFiles: [VirtualFile] = []
                
                for url in urls {
                    let result = fileAccessManager.safelyScanDirectory(url, maxDepth: 5)
                    if case .success(let files) = result {
                        allFiles.append(contentsOf: files.map { VirtualFile(url: $0) })
                    }
                }
                
                do {
                    try await spotlightManager.indexFiles(allFiles)
                    indexedFilesCount = allFiles.count
                } catch {
                    self.error = "Failed to index: \(error.localizedDescription)"
                }
                
                isIndexing = false
            }
        }
    }
    
    private func clearIndex() {
        Task {
            isIndexing = true
            do {
                try await spotlightManager.removeAllFiles()
                indexedFilesCount = 0
            } catch {
                self.error = "Failed to clear index: \(error.localizedDescription)"
            }
            isIndexing = false
        }
    }
}

// MARK: - Example 14: Streaming AI Responses

struct Example14_StreamingAIAnalysis: View {
    @State private var fileAccessManager = FileAccessManager()
    @State private var session: LanguageModelSession?
    @State private var analysis: FilesAnalysis.PartiallyGenerated?
    @State private var isStreaming = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Streaming AI File Analysis")
                .font(.headline)
            
            Button("Analyze Files with Streaming") {
                analyzeFiles()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isStreaming)
            
            if isStreaming {
                ProgressView("Analyzing...")
            }
            
            if let analysis = analysis {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let category = analysis.primaryCategory {
                            LabeledContent("Category") {
                                Text(category)
                                    .bold()
                            }
                        }
                        
                        if let findings = analysis.keyFindings, !findings.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Findings")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                ForEach(findings, id: \.self) { finding in
                                    Label(finding, systemImage: "sparkles")
                                        .font(.body)
                                }
                            }
                        }
                        
                        if let suggestion = analysis.organizationSuggestion {
                            LabeledContent("Organization Tip") {
                                Text(suggestion)
                                    .italic()
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }
    
    private func analyzeFiles() {
        fileAccessManager.requestDirectoryAccess { urls in
            Task {
                isStreaming = true
                
                // Initialize session
                let instructions = """
                Analyze file collections and provide organizational insights.
                Focus on patterns, categories, and helpful recommendations.
                """
                session = LanguageModelSession(instructions: instructions)
                
                // Gather file information
                var fileInfos: [(String, String)] = []
                for url in urls {
                    let result = fileAccessManager.safelyScanDirectory(url, maxDepth: 2)
                    if case .success(let files) = result {
                        let info = files.prefix(50).map { file in
                            (file.lastPathComponent, file.pathExtension)
                        }
                        fileInfos.append(contentsOf: info)
                    }
                }
                
                let filesList = fileInfos.map { "\($0.0) (.\($0.1))" }.joined(separator: "\n")
                let prompt = "Analyze these \(fileInfos.count) files and provide insights:\n\(filesList)"
                
                // Stream the response
                let stream = session!.streamResponse(
                    to: prompt,
                    generating: FilesAnalysis.self
                )
                
                do {
                    for try await partial in stream {
                        analysis = partial
                    }
                } catch {
                    print("Streaming error: \(error)")
                }
                
                isStreaming = false
            }
        }
    }
}

// MARK: - Example 6: Batch File Operations

class Example6_BatchOperations {
    let fileAccessManager = FileAccessManager()
    
    func processFiles(_ urls: [URL], operation: (URL) throws -> Void) async -> [(URL, Result<Void, FileAccessError>)] {
        var results: [(URL, Result<Void, FileAccessError>)] = []
        
        for url in urls {
            let result = fileAccessManager.safelyAccessFile(url) { url in
                try operation(url)
            }
            results.append((url, result.map { _ in () }))
        }
        
        return results
    }
    
    func calculateTotalSize(_ urls: [URL]) async -> Result<Int64, FileAccessError> {
        var totalSize: Int64 = 0
        
        for url in urls {
            let result = fileAccessManager.safelyAccessFile(url) { url in
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
                return attributes[.size] as? Int64 ?? 0
            }
            
            switch result {
            case .success(let size):
                totalSize += size
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(totalSize)
    }
}

// MARK: - Example 7: Settings View with Access Management

struct Example7_SettingsView: View {
    @State private var fileAccessManager = FileAccessManager()
    
    var body: some View {
        Form {
            Section("File Access") {
                if fileAccessManager.savedURLs.isEmpty {
                    Text("No directories configured")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(fileAccessManager.savedURLs, id: \.self) { url in
                        HStack {
                            Image(systemName: "folder")
                            Text(url.path(percentEncoded: false))
                            Spacer()
                            Button("Remove") {
                                fileAccessManager.removeBookmark(for: url)
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
                
                Button("Add Directory") {
                    fileAccessManager.requestDirectoryAccess { _ in }
                }
            }
            
            Section {
                Button("Clear All Access", role: .destructive) {
                    fileAccessManager.clearAllBookmarks()
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Example 8: File Monitor with Security

@Observable
class Example8_FileMonitor {
    private let fileAccessManager = FileAccessManager()
    private var monitoredURLs: [URL] = []
    var changedFiles: Set<URL> = []
    
    func startMonitoring(_ urls: [URL]) {
        monitoredURLs = urls
        
        // Note: In a real implementation, you'd use FileManager's
        // directory monitoring or FSEvents API
        
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await checkForChanges()
            }
        }
    }
    
    private func checkForChanges() async {
        for url in monitoredURLs {
            let result = fileAccessManager.safelyAccessFile(url) { url in
                try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
            }
            
            switch result {
            case .success(let attributes):
                if let modDate = attributes[.modificationDate] as? Date {
                    // Check if modified recently
                    if Date().timeIntervalSince(modDate) < 300 { // 5 minutes
                        changedFiles.insert(url)
                    }
                }
            case .failure:
                // File no longer accessible
                changedFiles.remove(url)
            }
        }
    }
}

// MARK: - Preview

#Preview("Request Access") {
    Example1_RequestAccess()
}

#Preview("Settings") {
    Example7_SettingsView()
}

#Preview("Permission Flow") {
    Example5_AppWithPermissions()
}

#Preview("AI File Summarizer") {
    Example9_AIFileSummarizer()
}

#Preview("Spotlight Integration") {
    Example13_SpotlightIntegration()
}

#Preview("Streaming AI Analysis") {
    Example14_StreamingAIAnalysis()
}

