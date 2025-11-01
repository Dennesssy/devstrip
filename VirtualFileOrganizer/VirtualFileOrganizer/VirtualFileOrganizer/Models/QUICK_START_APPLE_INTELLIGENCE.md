# Quick Start: Apple Intelligence in 5 Minutes

Get Apple Intelligence features running in your file access app in just a few minutes.

## 🚀 Step 1: Add Imports (30 seconds)

Add these imports to your SwiftUI file:

```swift
import SwiftUI
import FoundationModels
import AppIntents
import VisualIntelligence
import CoreSpotlight
```

## 🧠 Step 2: Add AI File Summarizer (2 minutes)

Copy this into your project:

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
    
    func summarizeFile(_ content: String) async throws -> String {
        if session == nil {
            session = LanguageModelSession(
                instructions: "You are a helpful file assistant. Summarize file content concisely."
            )
        }
        
        let response = try await session!.respond(to: "Summarize: \(content)")
        return response.content
    }
}
```

## 📱 Step 3: Create Simple UI (1 minute)

Add this view:

```swift
struct AIFileSummarizerView: View {
    @State private var summarizer = AIFileSummarizer()
    @State private var summary = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            if summarizer.isAvailable {
                Button("Summarize a File") {
                    Task {
                        isLoading = true
                        // Your file content here
                        let content = "Sample file content..."
                        summary = try await summarizer.summarizeFile(content) ?? "Error"
                        isLoading = false
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if isLoading {
                    ProgressView()
                }
                
                if !summary.isEmpty {
                    Text(summary)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Text("Apple Intelligence not available")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
```

## ✅ Step 4: Test It (1 minute)

1. Run on iPhone 15 Pro or later (or Mac with M1+)
2. iOS 18.2 or later
3. Enable Apple Intelligence in Settings
4. Tap the button and see AI magic! ✨

---

## 🎯 What You Just Built

You now have:
- ✅ On-device AI processing
- ✅ Privacy-preserving file analysis
- ✅ Graceful fallback when AI unavailable
- ✅ Production-ready error handling

## 🚀 Next Steps

### Add Siri Support (5 minutes)

```swift
struct SummarizeFileIntent: AppIntent {
    static var title: LocalizedStringResource = "Summarize File"
    
    @Parameter(title: "File Name")
    var fileName: String
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let summarizer = AIFileSummarizer()
        // Load file content
        let summary = try await summarizer.summarizeFile(fileContent)
        return .result(dialog: "Summary: \(summary)")
    }
}

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SummarizeFileIntent(),
            phrases: ["Summarize file \(\.$fileName)"],
            systemImageName: "doc.text"
        )
    }
}
```

**Usage:** "Hey Siri, summarize file MyDocument.txt"

### Add Spotlight Search (5 minutes)

```swift
func indexFiles(_ files: [VirtualFile]) async throws {
    let items = files.map { file in
        let attributes = CSSearchableItemAttributeSet(contentType: .data)
        attributes.title = file.name
        attributes.contentDescription = "File: \(file.name)"
        
        return CSSearchableItem(
            uniqueIdentifier: file.id.uuidString,
            domainIdentifier: "com.yourapp.files",
            attributeSet: attributes
        )
    }
    
    try await CSSearchableIndex.default().indexSearchableItems(items)
}
```

**Usage:** Users can now find your app's files in system-wide search!

### Add Structured AI Output (5 minutes)

```swift
@Generable(description: "File analysis results")
struct FileAnalysis {
    @Guide(description: "Type of file")
    var fileType: String
    
    @Guide(description: "Key topics", .count(3...5))
    var topics: [String]
    
    @Guide(description: "One-sentence summary")
    var summary: String
}

// Use it:
let response = try await session.respond(
    to: "Analyze this file: \(content)",
    generating: FileAnalysis.self
)

let analysis = response.content
print("Type: \(analysis.fileType)")
print("Topics: \(analysis.topics)")
print("Summary: \(analysis.summary)")
```

---

## 📚 Full Examples Available

See `QuickReferenceExamples.swift` for 14 complete examples:

1. **Example 9**: AI File Summarizer
2. **Example 10**: Smart File Organizer with Tool Calling
3. **Example 11**: Visual Intelligence Integration
4. **Example 12**: Siri & App Intents
5. **Example 13**: Spotlight Integration
6. **Example 14**: Streaming AI Responses

## 🎓 Learn More

- **Detailed Guide**: `APPLE_INTELLIGENCE_INTEGRATION_GUIDE.md`
- **Architecture**: `APPLE_INTELLIGENCE_ARCHITECTURE.md`
- **Error Handling**: `FileAccessErrorHandling.swift`

---

## 🛠️ Troubleshooting

### "Model not available"
- Check device: iPhone 15 Pro+, iPad with M1+, or Mac with M1+
- Check iOS version: 18.2 or later
- Enable: Settings → Apple Intelligence & Siri → Apple Intelligence

### "Permission denied"
- Use `FileAccessManager` to request directory access
- Grant permission in system dialog
- Check sandboxing and entitlements

### "Context window exceeded"
- Limit file content to ~16KB
- Split large files into chunks
- Use multiple sessions for batch processing

### Slow performance
- Check token count (max 4,096)
- Reduce instruction length
- Cache session results
- Use streaming for long responses

---

## 💡 Tips for Success

### DO ✅
- Always check model availability
- Provide fallbacks for unsupported devices
- Keep prompts focused and specific
- Use structured output (@Generable) for complex data
- Test on devices without Apple Intelligence
- Stream responses for better UX

### DON'T ❌
- Assume AI is always available
- Send huge files to the model
- Ignore token limits
- Forget error handling
- Send sensitive data (it's on-device, but still)
- Block UI while processing

---

## 🎉 You're Ready!

You now have a working Apple Intelligence integration. Copy examples from `QuickReferenceExamples.swift` and adapt them to your needs.

**Questions?** Check the full guides or file an issue.

**Happy coding!** 🚀

---

*Built with ❤️ using Apple Intelligence*
*Last updated: October 31, 2025*
