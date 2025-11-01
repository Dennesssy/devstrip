# Apple Intelligence Integration for File Access Apps

A comprehensive, production-ready integration of Apple Intelligence features into file management applications. All processing happens on-device with complete privacy.

## 🌟 Features

### Foundation Models (On-Device LLM)
- ✅ AI-powered file summarization
- ✅ Intelligent file organization suggestions
- ✅ Smart content analysis
- ✅ Structured data generation with `@Generable`
- ✅ Real-time streaming responses
- ✅ Custom tool calling for file operations

### Visual Intelligence
- ✅ Find files by taking photos
- ✅ Image-based file discovery
- ✅ Semantic search integration
- ✅ System-wide visual search support

### App Intents & Siri
- ✅ Voice-controlled file search
- ✅ Siri shortcuts for common tasks
- ✅ Background and foreground execution modes
- ✅ Interactive result snippets
- ✅ Multi-turn conversations

### Spotlight Integration
- ✅ System-wide file indexing
- ✅ Quick file discovery
- ✅ Rich metadata search
- ✅ Deep linking to app content

## 🚀 Quick Start

### 1. Requirements
- **Devices**: iPhone 15 Pro+, iPad with M1+, or Mac with M1+
- **iOS**: 18.2 or later
- **Xcode**: 16.0 or later
- **Swift**: 6.0 or later

### 2. Installation

Add required frameworks to your project:

```swift
import SwiftUI
import FoundationModels      // On-device AI
import AppIntents            // Siri & system integration
import VisualIntelligence    // Image-based search
import CoreSpotlight         // System-wide indexing
```

### 3. Basic Usage

```swift
// Check if AI is available
let model = SystemLanguageModel.default
if case .available = model.availability {
    // Use AI features
    let session = LanguageModelSession(instructions: "You are a helpful assistant")
    let response = try await session.respond(to: "Summarize this file")
    print(response.content)
}
```

## 📚 Documentation

### Getting Started
1. **[Quick Start Guide](QUICK_START_APPLE_INTELLIGENCE.md)** - Get running in 5 minutes
2. **[Integration Guide](APPLE_INTELLIGENCE_INTEGRATION_GUIDE.md)** - Comprehensive feature walkthrough
3. **[Architecture Overview](APPLE_INTELLIGENCE_ARCHITECTURE.md)** - System design and data flows

### Code Examples
All examples are in **`QuickReferenceExamples.swift`**:

| Example | Feature | Description |
|---------|---------|-------------|
| **Example 9** | Foundation Models | AI file summarization |
| **Example 10** | Tool Calling | Smart file organizer with custom tools |
| **Example 11** | Visual Intelligence | Image-based file discovery |
| **Example 12** | App Intents | Siri integration and voice commands |
| **Example 13** | Spotlight | System-wide file indexing |
| **Example 14** | Streaming | Real-time AI responses |

## 💡 Key Concepts

### 1. On-Device Processing

All AI operations happen locally on the device:

```
Your App → Foundation Models → Neural Engine → Response
              ↓
         (No network)
         (Complete privacy)
```

### 2. Availability Checking

Always verify AI is available before use:

```swift
@Observable
class AIFeature {
    private let model = SystemLanguageModel.default
    
    var isAvailable: Bool {
        if case .available = model.availability {
            return true
        }
        return false
    }
    
    var statusMessage: String {
        switch model.availability {
        case .available:
            return "AI is ready"
        case .unavailable(.deviceNotEligible):
            return "Device not supported"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable in Settings → Apple Intelligence"
        case .unavailable(.modelNotReady):
            return "Downloading AI model..."
        case .unavailable(let reason):
            return "Unavailable: \(reason)"
        }
    }
}
```

### 3. Structured Output

Generate Swift types directly from AI:

```swift
@Generable(description: "File analysis results")
struct FileAnalysis {
    var category: String
    @Guide(description: "Key topics", .count(3...5))
    var topics: [String]
    var summary: String
}

// Generate structured data
let response = try await session.respond(
    to: prompt,
    generating: FileAnalysis.self
)

let analysis = response.content
print(analysis.category)  // "Document"
print(analysis.topics)    // ["Swift", "iOS", "Development"]
```

### 4. Tool Calling

Let AI use your custom functions:

```swift
struct FileSearchTool: Tool {
    struct Arguments: Codable {
        var searchTerm: String
        var fileType: String?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Search files using your app's logic
        let results = searchFiles(term: arguments.searchTerm, type: arguments.fileType)
        return .string("Found \(results.count) files")
    }
}

// AI will automatically use this tool when needed
let session = LanguageModelSession(
    instructions: "Help organize files",
    tools: [FileSearchTool()]
)
```

## 🎯 Use Cases

### 1. Smart File Summarization

```swift
let summarizer = AIFileSummarizer()
let summary = try await summarizer.summarizeFileContent(
    fileContent,
    fileName: "MyDocument.txt"
)
print(summary)
// "This document discusses Swift development best practices,
//  focusing on memory management and concurrency patterns."
```

### 2. Intelligent Organization

```swift
let organizer = SmartFileOrganizer()
let plan = try await organizer.organizeFiles(
    in: documentsDirectory,
    criteria: "Organize by project and file type"
)
print(plan.categories)
// ["iOS Projects", "Web Development", "Documentation", "Resources"]
```

### 3. Visual Search

User takes photo of a document → System calls your app → You return matching files:

```swift
struct FileIntentValueQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [FileEntity] {
        // Use labels like "document", "receipt", "photo"
        let matches = findFiles(matching: input.labels)
        return matches
    }
}
```

### 4. Voice Commands

"Hey Siri, find my Swift files"

```swift
struct SearchFilesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Files"
    
    @Parameter(title: "Search Term")
    var searchTerm: String
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let results = searchFiles(term: searchTerm)
        return .result(
            value: results,
            dialog: "Found \(results.count) files matching '\(searchTerm)'"
        )
    }
}
```

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│          Your App                   │
│  ┌────────────────────────────┐    │
│  │   FileAccessManager        │    │
│  │   (Security & Access)      │    │
│  └──────────┬─────────────────┘    │
│             │                       │
│  ┌──────────▼─────────────────┐    │
│  │   VirtualFile              │    │
│  │   (Metadata & Attributes)  │    │
│  └──────────┬─────────────────┘    │
└─────────────┼─────────────────────┘
              │
    ┌─────────┴────────┐
    │                  │
    ▼                  ▼
┌──────────┐    ┌──────────────┐
│Foundation│    │   System     │
│ Models   │    │ Integration  │
│ (AI)     │    │ (Siri, etc.) │
└──────────┘    └──────────────┘
```

## 🔒 Privacy & Security

### Complete Privacy
- ✅ All processing on-device
- ✅ No data sent to cloud
- ✅ No network requests
- ✅ Encrypted neural engine
- ✅ Respects user consent

### File Access Security
- ✅ Security-scoped bookmarks
- ✅ Proper resource management
- ✅ Sandboxed file access
- ✅ User permission required
- ✅ Safe error handling

### Best Practices
```swift
// Always use security-scoped access
let didStartAccessing = url.startAccessingSecurityScopedResource()
defer {
    if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
    }
}

// Use FileAccessManager for safety
let result = fileAccessManager.safelyAccessFile(url) { url in
    try Data(contentsOf: url)
}
```

## ⚡ Performance

### Token Limits
- **Context Window**: 4,096 tokens (~16KB text)
- **Includes**: Instructions + Prompt + Response + History
- **Strategy**: Chunk large files, use multiple sessions

### Optimization Tips

```swift
// ✅ Good: Process in batches
for batch in files.chunked(into: 10) {
    let results = await processFiles(batch)
}

// ❌ Bad: Load everything at once
let results = await processFiles(allFiles)

// ✅ Good: Stream long responses
let stream = session.streamResponse(to: prompt, generating: Analysis.self)
for try await partial in stream {
    updateUI(partial)
}

// ❌ Bad: Wait for complete response
let response = try await session.respond(to: longPrompt)
```

### Memory Management
- Limit concurrent AI sessions (2-3 max)
- Release sessions when done
- Cache results when appropriate
- Monitor memory usage with Instruments

## 🧪 Testing

### Availability Testing
```swift
@Test("AI features work when available")
func testAIFeatures() async throws {
    let summarizer = AIFileSummarizer()
    
    guard summarizer.isAvailable else {
        return // Skip on unsupported devices
    }
    
    let summary = try await summarizer.summarizeFile("Test content")
    #expect(!summary.isEmpty)
}
```

### Device Matrix

| Device | Foundation Models | Visual Intelligence | App Intents | Spotlight |
|--------|------------------|---------------------|-------------|-----------|
| iPhone 15 Pro | ✅ | ✅ | ✅ | ✅ |
| iPhone 16 | ✅ | ✅ | ✅ | ✅ |
| iPad Pro M1+ | ✅ | ✅ | ✅ | ✅ |
| Mac M1+ | ✅ | ❌ | ✅ | ✅ |
| iPhone 15 | ❌ | ❌ | ✅ | ✅ |

## 🐛 Troubleshooting

### Common Issues

**"Model not available"**
- Check device compatibility (A17 Pro or M1+)
- Verify iOS 18.2 or later
- Enable Apple Intelligence in Settings

**"Permission denied"**
- Request directory access with FileAccessManager
- Check sandboxing and entitlements
- Verify user granted permission

**"Context window exceeded"**
- Reduce prompt size (max 4,096 tokens)
- Split large files into chunks
- Use multiple sessions

**Poor AI responses**
- Improve instructions (be specific)
- Add examples in instructions
- Use structured output (@Generable)
- Adjust temperature if needed

### Debugging

```swift
// View session transcript
print(session.transcript)

// Catch tool errors
catch let error as LanguageModelSession.ToolCallError {
    print("Tool '\(error.tool.name)' failed")
    print(error.underlyingError)
}

// Check file access
let result = fileAccessManager.safelyAccessFile(url) { url in
    print("Accessing: \(url)")
    return try operation(url)
}
```

## 📦 Project Structure

```
YourApp/
├── QuickReferenceExamples.swift              # 14 complete examples
├── FileAccessManager.swift                   # Core file operations
├── VirtualFile.swift                         # File representation
├── FileAccessErrorHandling.swift             # Error management
├── FileAccessPermissionView.swift            # Permission UI
│
├── Documentation/
│   ├── QUICK_START_APPLE_INTELLIGENCE.md    # 5-minute quickstart
│   ├── APPLE_INTELLIGENCE_INTEGRATION_GUIDE.md  # Comprehensive guide
│   ├── APPLE_INTELLIGENCE_ARCHITECTURE.md   # System design
│   └── README_APPLE_INTELLIGENCE.md         # This file
│
└── Tests/
    └── AppleIntelligenceTests.swift          # Unit tests
```

## 🚢 Deployment

### Pre-Launch Checklist

- [ ] Test on devices without Apple Intelligence
- [ ] Test with AI disabled in settings
- [ ] Test file access permissions flow
- [ ] Test with large files (>100MB)
- [ ] Test with thousands of files
- [ ] Verify graceful degradation
- [ ] Check all error messages
- [ ] Test Siri phrases
- [ ] Verify Spotlight integration
- [ ] Test VoiceOver compatibility
- [ ] Review privacy strings
- [ ] Validate no network requests
- [ ] Performance testing with Instruments
- [ ] App Store screenshots (AI and non-AI modes)

### App Store Requirements

**Info.plist Entries:**
```xml
<key>NSFileProviderDomainUsageDescription</key>
<string>Access files to provide AI-powered organization and search</string>
```

**App Description:**
- Mention Apple Intelligence features are optional
- List supported devices
- Highlight privacy-preserving on-device processing

**Testing Notes:**
- Provide test account with sample files
- Include instructions for enabling Apple Intelligence
- Document fallback behavior for unsupported devices

## 🎓 Learning Path

### Beginner (1-2 hours)
1. Read [Quick Start Guide](QUICK_START_APPLE_INTELLIGENCE.md)
2. Run Example 9 (AI File Summarizer)
3. Test on your device
4. Modify prompt and see results

### Intermediate (1 day)
1. Read [Integration Guide](APPLE_INTELLIGENCE_INTEGRATION_GUIDE.md)
2. Implement Examples 9-12
3. Add Siri support
4. Test with real files

### Advanced (2-3 days)
1. Read [Architecture Overview](APPLE_INTELLIGENCE_ARCHITECTURE.md)
2. Implement custom tools
3. Add Visual Intelligence
4. Integrate Spotlight
5. Optimize performance
6. Deploy to production

## 🤝 Contributing

Found an issue or want to improve examples?

1. File an issue with details
2. Submit a pull request
3. Share your use cases
4. Suggest new examples

## 📄 License

This code is provided as educational examples. Adapt freely for your projects.

## 🙏 Acknowledgments

Built using:
- **Foundation Models** - Apple's on-device LLM
- **App Intents** - System integration framework
- **Visual Intelligence** - Image-based search
- **Core Spotlight** - System-wide indexing
- **SwiftUI** - Modern UI framework

## 📞 Support

- **Documentation**: See guides in this repository
- **Issues**: File via project repository
- **Forums**: [Apple Developer Forums](https://developer.apple.com/forums/)
- **WWDC**: Watch Apple Intelligence sessions

## 🔗 Resources

### Official Documentation
- [Foundation Models](https://developer.apple.com/documentation/FoundationModels)
- [App Intents](https://developer.apple.com/documentation/AppIntents)
- [Visual Intelligence](https://developer.apple.com/documentation/VisualIntelligence)
- [Core Spotlight](https://developer.apple.com/documentation/CoreSpotlight)

### WWDC Sessions
- Introducing Apple Intelligence
- Get started with Foundation Models
- Explore App Intents
- Visual Intelligence integration

### Sample Projects
- All examples in `QuickReferenceExamples.swift`
- Production-ready code
- Copy and adapt freely

---

## 🎯 What's Next?

1. **Start Simple**: Run Example 9 (AI Summarizer)
2. **Add Features**: Implement Siri and Spotlight
3. **Go Advanced**: Add Visual Intelligence and custom tools
4. **Ship It**: Deploy to production with confidence

---

**Version**: 1.0  
**Last Updated**: October 31, 2025  
**Swift**: 6.0+  
**iOS**: 18.2+  

**Built with ❤️ for Apple Intelligence**

---

Ready to add AI superpowers to your file app? Start with the [Quick Start Guide](QUICK_START_APPLE_INTELLIGENCE.md)!
