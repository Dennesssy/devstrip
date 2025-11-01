# Apple Intelligence Integration Guide

This guide demonstrates how to integrate various Apple Intelligence features into your file access application. Each example shows a different capability with production-ready code.

## Table of Contents

1. [Foundation Models (On-Device LLM)](#1-foundation-models)
2. [Tool Calling with AI](#2-tool-calling)
3. [Visual Intelligence](#3-visual-intelligence)
4. [App Intents & Siri](#4-app-intents--siri)
5. [Spotlight Integration](#5-spotlight-integration)
6. [Streaming AI Responses](#6-streaming-ai-responses)
7. [Configuration & Setup](#configuration--setup)

---

## 1. Foundation Models

**Example 9: AI File Summarizer**

Use Apple's on-device LLM to analyze and summarize file contents with complete privacy.

### Key Features:
- ✅ Check model availability before use
- ✅ Initialize session with custom instructions
- ✅ Generate text summaries
- ✅ Create structured data with `@Generable`
- ✅ Works entirely offline

### Code Highlights:

```swift
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
    
    func summarizeFileContent(_ content: String, fileName: String) async throws -> String {
        let instructions = """
        You are a helpful file management assistant.
        Analyze file content and provide concise, useful summaries.
        """
        session = LanguageModelSession(instructions: instructions)
        
        let prompt = "Summarize this file named '\(fileName)': \(content)"
        let response = try await session!.respond(to: prompt)
        return response.content
    }
}
```

### Structured Output with @Generable:

```swift
@Generable(description: "Analysis of multiple files")
struct FilesAnalysis {
    @Guide(description: "Main category or theme")
    var primaryCategory: String
    
    @Guide(description: "List of key findings", .count(3...5))
    var keyFindings: [String]
    
    @Guide(description: "Organization strategy")
    var organizationSuggestion: String
}

// Use it:
let response = try await session.respond(
    to: prompt,
    generating: FilesAnalysis.self
)
let analysis = response.content
```

### Model Availability States:

| State | Meaning | Action |
|-------|---------|--------|
| `.available` | Ready to use | Show AI features |
| `.unavailable(.deviceNotEligible)` | Device doesn't support it | Hide features |
| `.unavailable(.appleIntelligenceNotEnabled)` | User needs to enable it | Show settings prompt |
| `.unavailable(.modelNotReady)` | Model downloading | Show progress |

---

## 2. Tool Calling with AI

**Example 10: Smart File Organizer**

Let the AI use custom functions to search files and categorize them dynamically.

### Key Features:
- ✅ Define custom tools the AI can call
- ✅ Provide file system access to AI
- ✅ Get structured organization plans
- ✅ Handle tool errors gracefully

### Creating a Tool:

```swift
struct FileSearchTool: Tool {
    let manager: FileAccessManager
    
    struct Arguments: Codable {
        var pattern: String
        var maxResults: Int = 50
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        var foundFiles: [String] = []
        
        // Search through accessible directories
        for url in manager.savedURLs {
            let result = manager.safelyScanDirectory(url, maxDepth: 3)
            if case .success(let files) = result {
                let matching = files.filter { 
                    $0.lastPathComponent.localizedCaseInsensitiveContains(arguments.pattern)
                }
                foundFiles.append(contentsOf: matching.map { $0.lastPathComponent })
            }
        }
        
        return .string("Found \(foundFiles.count) files:\n\(foundFiles.joined(separator: "\n"))")
    }
}
```

### Using Tools in a Session:

```swift
let searchTool = FileSearchTool(manager: fileAccessManager)
let categorizeTool = FileCategorizationTool()

session = LanguageModelSession(
    instructions: "You are a file organization assistant. Use tools to help organize files.",
    tools: [searchTool, categorizeTool]
)

// The AI will automatically call tools when needed:
let response = try await session.respond(
    to: "Find all PDF files and suggest how to organize them",
    generating: OrganizationPlan.self
)
```

### Tool Error Handling:

```swift
do {
    let answer = try await session.respond("Organize my files")
} catch let error as LanguageModelSession.ToolCallError {
    print("Tool '\(error.tool.name)' failed: \(error.underlyingError)")
}
```

---

## 3. Visual Intelligence

**Example 11: File Discovery by Image**

Let users find files by taking photos or using visual search.

### Key Features:
- ✅ Integrate with system visual search
- ✅ Match files based on image content
- ✅ Use semantic labels from camera
- ✅ Display results in system UI

### Defining File Entity:

```swift
struct FileEntity: AppEntity {
    var id: String
    var name: String
    var path: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: "File",
            numericFormat: "\(placeholder: .int) files"
        )
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(path)",
            image: .init(systemName: "doc")
        )
    }
}
```

### Visual Search Query:

```swift
struct FileIntentValueQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [FileEntity] {
        // Get labels from visual intelligence (e.g., "document", "photo", "code")
        let labels = input.labels
        
        // Search your files
        let fileAccessManager = FileAccessManager()
        var matchingFiles: [FileEntity] = []
        
        for url in fileAccessManager.savedURLs {
            let result = fileAccessManager.safelyScanDirectory(url)
            if case .success(let files) = result {
                // Match files by labels
                for file in files where matchesLabels(file: file, labels: labels) {
                    matchingFiles.append(FileEntity(
                        id: file.path,
                        name: file.lastPathComponent,
                        path: file.path(percentEncoded: false)
                    ))
                }
            }
        }
        
        return Array(matchingFiles.prefix(10))
    }
}
```

### Label Matching Logic:

```swift
private func matchesLabels(file: URL, labels: [String]) -> Bool {
    let ext = file.pathExtension.lowercased()
    
    for label in labels {
        let labelLower = label.lowercased()
        
        // Match image-related labels
        if labelLower.contains("photo") || labelLower.contains("image") {
            if ["jpg", "jpeg", "png", "gif", "heic"].contains(ext) {
                return true
            }
        }
        
        // Match document labels
        if labelLower.contains("document") || labelLower.contains("text") {
            if ["pdf", "doc", "docx", "txt", "md"].contains(ext) {
                return true
            }
        }
        
        // Match code labels
        if labelLower.contains("code") || labelLower.contains("programming") {
            if ["swift", "py", "js", "java"].contains(ext) {
                return true
            }
        }
    }
    
    return false
}
```

---

## 4. App Intents & Siri

**Example 12: Siri Integration**

Allow users to search and interact with files using voice commands.

### Key Features:
- ✅ Define searchable intents
- ✅ Support Siri phrases
- ✅ Background and foreground modes
- ✅ Interactive dialogs
- ✅ App shortcuts

### Creating a Basic Intent:

```swift
struct SearchFilesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Files"
    static var description: LocalizedStringResource = "Search for files by name or type"
    
    @Parameter(title: "Search Term")
    var searchTerm: String
    
    @Parameter(title: "File Type", default: nil)
    var fileType: String?
    
    func perform() async throws -> some ReturnsValue<[FileEntity]> & ProvidesDialog {
        let fileAccessManager = FileAccessManager()
        var foundFiles: [FileEntity] = []
        
        // Search logic
        for url in fileAccessManager.savedURLs {
            let result = fileAccessManager.safelyScanDirectory(url, maxDepth: 5)
            if case .success(let files) = result {
                let matching = files.filter { file in
                    file.lastPathComponent.localizedCaseInsensitiveContains(searchTerm)
                }
                foundFiles.append(contentsOf: matching.map { /* convert to FileEntity */ })
            }
        }
        
        let dialog: IntentDialog = foundFiles.isEmpty 
            ? "No files found matching '\(searchTerm)'"
            : "Found \(foundFiles.count) files"
        
        return .result(value: Array(foundFiles.prefix(20)), dialog: dialog)
    }
}
```

### Intent Modes:

Control when your app opens:

```swift
struct GetFileDetailsIntent: AppIntent {
    static var supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    
    func perform() async throws -> some IntentResult {
        // Start in background
        let details = fetchDetails()
        
        // Open app for large files
        if details.size > 10_000_000 && systemContext.currentMode.canContinueInForeground {
            try await continueInForeground(alwaysConfirm: false)
        }
        
        return .result(value: details)
    }
}
```

Available modes:
- `.background` - Runs entirely in background
- `.foreground(.immediate)` - Opens app immediately
- `.foreground(.dynamic)` - Can request foreground during execution
- `.foreground(.deferred)` - Runs in background, opens app before completion

### App Shortcuts for Siri:

```swift
struct FileAccessAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchFilesIntent(),
            phrases: [
                "Search for \(\.$searchTerm) in \(.applicationName)",
                "Find \(\.$searchTerm) files",
                "Look for \(\.$searchTerm)"
            ],
            shortTitle: "Search Files",
            systemImageName: "magnifyingglass"
        )
    }
}
```

**Users can now say:**
- "Search for vacation in MyApp"
- "Find PDF files"
- "Look for Swift code"

---

## 5. Spotlight Integration

**Example 13: Make Files Discoverable**

Index your files so users can find them in system-wide search.

### Key Features:
- ✅ Add files to Spotlight index
- ✅ Update file metadata
- ✅ Remove deleted files
- ✅ Search from anywhere on device

### Making Files Searchable:

```swift
extension VirtualFile {
    var searchableAttributes: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: fileType ?? .data)
        
        attributes.title = name
        attributes.displayName = name
        attributes.contentDescription = "File: \(name)"
        attributes.fileSize = NSNumber(value: size)
        attributes.contentCreationDate = creationDate
        attributes.contentModificationDate = modificationDate
        attributes.keywords = Array(tags)
        
        // Add category information
        let categoryNames = categories.map { $0.rawValue }
        attributes.keywords?.append(contentsOf: categoryNames)
        
        return attributes
    }
}
```

### Index Manager:

```swift
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
}
```

### Usage:

```swift
// Index new files
let spotlightManager = SpotlightIndexManager()
try await spotlightManager.indexFiles(virtualFiles)

// Update when modified
try await spotlightManager.updateFile(modifiedFile)

// Remove when deleted
try await spotlightManager.removeFile(deletedFile)
```

---

## 6. Streaming AI Responses

**Example 14: Real-time AI Analysis**

Display AI-generated content as it's being created, not all at once.

### Key Features:
- ✅ Progressive UI updates
- ✅ Snapshot-based streaming
- ✅ Structured output streaming
- ✅ SwiftUI integration

### Streaming with Snapshots:

```swift
struct Example14_StreamingAIAnalysis: View {
    @State private var analysis: FilesAnalysis.PartiallyGenerated?
    @State private var isStreaming = false
    
    var body: some View {
        VStack {
            if let analysis = analysis {
                // UI updates automatically as properties become available
                if let category = analysis.primaryCategory {
                    Text("Category: \(category)")
                }
                
                if let findings = analysis.keyFindings {
                    ForEach(findings, id: \.self) { finding in
                        Label(finding, systemImage: "sparkles")
                    }
                }
            }
        }
    }
    
    private func analyzeFiles() {
        Task {
            isStreaming = true
            
            let session = LanguageModelSession(instructions: "Analyze files...")
            let stream = session.streamResponse(
                to: prompt,
                generating: FilesAnalysis.self
            )
            
            // Updates `analysis` progressively
            for try await partial in stream {
                analysis = partial
            }
            
            isStreaming = false
        }
    }
}
```

### How Snapshots Work:

The `@Generable` macro automatically creates a `PartiallyGenerated` type where all properties are optional:

```swift
@Generable
struct FilesAnalysis {
    var primaryCategory: String
    var keyFindings: [String]
    var organizationSuggestion: String
}

// Automatically generates:
struct FilesAnalysis.PartiallyGenerated {
    var primaryCategory: String?      // Nil until generated
    var keyFindings: [String]?         // Gradually fills up
    var organizationSuggestion: String? // Appears last
}
```

This allows SwiftUI to reactively update as each part becomes available.

---

## Configuration & Setup

### 1. Add Required Frameworks

```swift
import FoundationModels      // On-device LLM
import AppIntents            // Siri & system integration
import VisualIntelligence    // Image-based search
import CoreSpotlight         // System-wide indexing
```

### 2. Entitlements & Privacy

Add to your `Info.plist`:

```xml
<key>NSFileProviderDomainUsageDescription</key>
<string>We need access to organize and search your files</string>

<key>NSAppleEventsUsageDescription</key>
<string>Enable AI-powered file management features</string>
```

### 3. Check Device Compatibility

```swift
@Observable
class FeatureAvailability {
    var supportsFoundationModels: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }
    
    var supportsVisualIntelligence: Bool {
        // Check if running on iOS 18.2+ and supported device
        if #available(iOS 18.2, *) {
            return true
        }
        return false
    }
}
```

### 4. Graceful Degradation

Always provide fallbacks when AI features aren't available:

```swift
struct FileAnalysisView: View {
    let featureAvailability = FeatureAvailability()
    
    var body: some View {
        if featureAvailability.supportsFoundationModels {
            AIFileSummarizerView()
        } else {
            ManualFileOrganizationView()
        }
    }
}
```

---

## Best Practices

### Privacy & Security
- ✅ All AI processing happens on-device
- ✅ No data leaves the device
- ✅ Respect file access permissions
- ✅ Use security-scoped resources properly

### Performance
- ✅ Check model availability before use
- ✅ Cache AI session results when appropriate
- ✅ Use streaming for long responses
- ✅ Limit context size (4,096 tokens max)

### User Experience
- ✅ Show clear status messages
- ✅ Provide alternatives when AI unavailable
- ✅ Use progress indicators for long operations
- ✅ Make AI features discoverable but optional

### Error Handling
- ✅ Handle all availability states
- ✅ Provide recovery options
- ✅ Test on devices without Apple Intelligence
- ✅ Log errors for debugging

---

## Testing

### Test Matrix

| Feature | Device Required | iOS Version | Settings |
|---------|----------------|-------------|----------|
| Foundation Models | A17 Pro+ or M1+ | iOS 18.2+ | Apple Intelligence enabled |
| Visual Intelligence | iPhone 16+ | iOS 18.2+ | Camera access |
| App Intents | Any | iOS 16+ | Siri enabled |
| Spotlight | Any | iOS 9+ | Spotlight enabled |

### Test Scenarios

1. **AI Unavailable**: Test on devices without Apple Intelligence
2. **Permissions Denied**: Test file access error handling
3. **Large Files**: Test performance with big documents
4. **Network Offline**: Verify everything works offline
5. **Voice Commands**: Test all Siri phrases

---

## Quick Reference

### Common Tasks

**Initialize AI Session:**
```swift
let session = LanguageModelSession(instructions: "You are...")
```

**Generate Text:**
```swift
let response = try await session.respond(to: "Analyze this file...")
print(response.content)
```

**Generate Structured Data:**
```swift
let result = try await session.respond(to: prompt, generating: MyType.self)
let data = result.content
```

**Stream Responses:**
```swift
let stream = session.streamResponse(to: prompt, generating: MyType.self)
for try await partial in stream {
    updateUI(with: partial)
}
```

**Add to Spotlight:**
```swift
try await CSSearchableIndex.default().indexSearchableItems(items)
```

**Create App Intent:**
```swift
struct MyIntent: AppIntent {
    static var title: LocalizedStringResource = "Do Something"
    func perform() async throws -> some IntentResult { ... }
}
```

---

## Resources

### Apple Documentation
- [Foundation Models Documentation](https://developer.apple.com/documentation/FoundationModels)
- [App Intents Guide](https://developer.apple.com/documentation/AppIntents)
- [Visual Intelligence Integration](https://developer.apple.com/documentation/VisualIntelligence)
- [Core Spotlight Framework](https://developer.apple.com/documentation/CoreSpotlight)

### Sample Code
- All examples are in `QuickReferenceExamples.swift`
- Each example is self-contained and can be copied
- Preview providers included for testing

### Support
- Check `IMPLEMENTATION_SUMMARY.md` for file access basics
- Review `FileAccessErrorHandling.swift` for error patterns
- See `VirtualFile.swift` for security-scoped access

---

**Built with ❤️ for Apple Intelligence**

*Last updated: October 31, 2025*
