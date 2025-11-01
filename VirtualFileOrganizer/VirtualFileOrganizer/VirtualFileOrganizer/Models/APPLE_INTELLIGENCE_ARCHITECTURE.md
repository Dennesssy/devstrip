# Apple Intelligence Architecture Overview

This document shows how all Apple Intelligence components work together in your file access application.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR APP                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           FileAccessManager (Core)                       │   │
│  │  • Security-scoped bookmarks                            │   │
│  │  • Safe file operations                                 │   │
│  │  • Directory scanning                                   │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     │                                            │
│  ┌──────────────────┴──────────────────────────────────────┐   │
│  │                  VirtualFile                             │   │
│  │  • File metadata                                        │   │
│  │  • Security scoping                                     │   │
│  │  • Searchable attributes                                │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     │                                            │
└─────────────────────┼────────────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
┌───────────────────┐      ┌──────────────────┐
│  APPLE            │      │  SYSTEM          │
│  INTELLIGENCE     │      │  INTEGRATION     │
│  FRAMEWORKS       │      │  FRAMEWORKS      │
└───────────────────┘      └──────────────────┘
        │                           │
        ├─────────────┬─────────────┤
        │             │             │
        ▼             ▼             ▼
┌──────────┐  ┌─────────────┐  ┌──────────┐
│Foundation│  │ Visual      │  │  App     │
│  Models  │  │Intelligence │  │ Intents  │
└──────────┘  └─────────────┘  └──────────┘
        │             │             │
        ▼             ▼             ▼
┌──────────┐  ┌─────────────┐  ┌──────────┐
│ On-Device│  │  Camera &   │  │   Siri   │
│    LLM   │  │  Screenshot │  │ Shortcuts│
└──────────┘  └─────────────┘  └──────────┘
```

---

## Data Flow Examples

### 1. AI File Summarization Flow

```
┌────────────┐
│    User    │
│  Selects   │
│    File    │
└─────┬──────┘
      │
      ▼
┌────────────────────┐
│  FileAccessManager │
│  Reads file with   │
│  security scoping  │
└─────┬──────────────┘
      │ File content
      ▼
┌────────────────────┐
│  AIFileSummarizer  │
│  Creates session   │
└─────┬──────────────┘
      │ Prompt + content
      ▼
┌────────────────────┐
│  Foundation Models │
│  Processes locally │
└─────┬──────────────┘
      │ AI response
      ▼
┌────────────────────┐
│    SwiftUI View    │
│  Displays summary  │
└────────────────────┘
```

### 2. Visual Intelligence Flow

```
┌────────────┐
│    User    │
│  Takes     │
│  Photo     │
└─────┬──────┘
      │
      ▼
┌─────────────────────┐
│  Visual Intelligence│
│  Analyzes image     │
│  Returns labels     │
└─────┬───────────────┘
      │ ["document", "pdf"]
      ▼
┌──────────────────────┐
│ FileIntentValueQuery │
│ Searches files       │
└─────┬────────────────┘
      │ File list
      ▼
┌──────────────────────┐
│  System UI           │
│  Shows results       │
│  User taps → App opens
└──────────────────────┘
```

### 3. Siri Intent Flow

```
┌────────────┐
│    User    │
│  "Find my  │
│  Swift     │
│  files"    │
└─────┬──────┘
      │
      ▼
┌─────────────────────┐
│       Siri          │
│  Recognizes intent  │
└─────┬───────────────┘
      │
      ▼
┌──────────────────────┐
│ SearchFilesIntent    │
│ • Parse parameters   │
│ • Search files       │
└─────┬────────────────┘
      │
      ▼
┌──────────────────────┐
│  FileAccessManager   │
│  Scan directories    │
└─────┬────────────────┘
      │ Results
      ▼
┌──────────────────────┐
│       Siri           │
│  "Found 12 files"    │
│  Shows snippet       │
└──────────────────────┘
```

### 4. Spotlight Integration Flow

```
┌────────────────┐
│  App Indexes   │
│  Files         │
└────┬───────────┘
     │
     ▼
┌──────────────────────┐
│ SpotlightIndexManager│
│ • Creates items      │
│ • Sets attributes    │
└────┬─────────────────┘
     │
     ▼
┌──────────────────────┐
│  Core Spotlight      │
│  System-wide index   │
└────┬─────────────────┘
     │
     ▼
┌──────────────────────┐
│  User searches       │
│  in Spotlight        │
│  Results appear      │
│  Tap → App opens     │
└──────────────────────┘
```

---

## Component Interaction Matrix

| Component | Uses | Provides |
|-----------|------|----------|
| **FileAccessManager** | • FileManager<br>• Security-scoped resources | • Safe file access<br>• Directory scanning<br>• Bookmark management |
| **VirtualFile** | • FileAccessManager<br>• UniformTypeIdentifiers | • File metadata<br>• Security scoping<br>• Searchable attributes |
| **AIFileSummarizer** | • FoundationModels<br>• FileAccessManager | • Text summaries<br>• Structured analysis<br>• AI insights |
| **SmartFileOrganizer** | • FoundationModels<br>• Tool calling<br>• FileAccessManager | • Organization plans<br>• Category suggestions<br>• File search |
| **Visual Intelligence** | • VisualIntelligence<br>• AppIntents<br>• FileAccessManager | • Image-based search<br>• File discovery<br>• System integration |
| **App Intents** | • AppIntents<br>• FileAccessManager | • Siri integration<br>• Shortcuts<br>• System actions |
| **Spotlight** | • CoreSpotlight<br>• VirtualFile | • System-wide search<br>• File discovery<br>• Quick access |

---

## State Management

### Model Availability States

```swift
enum ModelAvailability {
    case available              // ✅ Ready to use
    case downloading            // ⏳ Model downloading
    case needsSettings          // ⚠️ User needs to enable
    case notSupported          // ❌ Device incompatible
}

// Example handling:
switch model.availability {
case .available:
    showAIFeatures()
case .unavailable(.appleIntelligenceNotEnabled):
    showSettingsPrompt()
case .unavailable(.deviceNotEligible):
    hideAIFeatures()
case .unavailable(.modelNotReady):
    showDownloadProgress()
default:
    showGenericUnavailableMessage()
}
```

### File Access States

```swift
enum FileAccessState {
    case noAccess              // Need to request
    case requesting            // Picker showing
    case hasAccess([URL])      // Have bookmarks
    case accessError(Error)    // Failed
}

// Example flow:
noAccess → requesting → hasAccess → [Use AI Features]
   ↓
accessError → [Show error] → [Retry]
```

### AI Session States

```swift
enum AISessionState {
    case idle                  // Not started
    case initializing          // Creating session
    case ready                 // Can send prompts
    case processing            // Generating response
    case streaming             // Receiving chunks
    case completed             // Done
    case error(Error)          // Failed
}
```

---

## Security & Privacy Architecture

```
┌──────────────────────────────────────────────────┐
│              USER'S DEVICE ONLY                  │
│  ┌────────────────────────────────────────────┐ │
│  │           SANDBOX BOUNDARY                 │ │
│  │  ┌──────────────────────────────────────┐ │ │
│  │  │  Your App                            │ │ │
│  │  │  • Security-scoped bookmarks         │ │ │
│  │  │  • File content in memory            │ │ │
│  │  └──────┬───────────────────────────────┘ │ │
│  │         │                                  │ │
│  │  ┌──────▼───────────────────────────────┐ │ │
│  │  │  Foundation Models                    │ │ │
│  │  │  • On-device processing ONLY         │ │ │
│  │  │  • No network requests               │ │ │
│  │  │  • Encrypted neural engine           │ │ │
│  │  └──────────────────────────────────────┘ │ │
│  │                                            │ │
│  │  ✅ All processing happens locally        │ │
│  │  ✅ No data sent to cloud                 │ │
│  │  ✅ User consent for file access          │ │
│  │  ✅ Respects privacy settings             │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ❌ NO EXTERNAL NETWORK                         │
│  ❌ NO DATA LEAVES DEVICE                       │
│  ❌ NO CLOUD PROCESSING                         │
└──────────────────────────────────────────────────┘
```

---

## Performance Considerations

### Token Limits

```
Foundation Models Context Window:
┌────────────────────────────────────┐
│  Total: 4,096 tokens (~16KB text)  │
├────────────────────────────────────┤
│  Instructions:    ~200 tokens      │
│  Prompt:          ~500 tokens      │
│  Response:        ~1,000 tokens    │
│  History:         ~2,396 tokens    │
└────────────────────────────────────┘

Strategy for large files:
1. Chunk content into smaller pieces
2. Use multiple sessions
3. Summarize progressively
4. Cache intermediate results
```

### Memory Management

```swift
// Good: Process files in batches
for batch in files.chunked(into: 10) {
    let results = await processFiles(batch)
    await updateUI(results)
}

// Bad: Load everything at once
let allResults = await processFiles(allFiles) // OOM risk!
```

### Concurrent Operations

```swift
// Good: Limit concurrent AI sessions
let semaphore = AsyncSemaphore(value: 2)
await withTaskGroup(of: Result.self) { group in
    for file in files {
        await semaphore.wait()
        group.addTask {
            defer { semaphore.signal() }
            return await analyzeFile(file)
        }
    }
}

// Bad: Unlimited parallelism
await withTaskGroup(of: Result.self) { group in
    for file in files {
        group.addTask { await analyzeFile(file) } // Crashes!
    }
}
```

---

## Testing Strategy

### Unit Tests

```swift
@Test("AI summarizer handles small files")
func testSmallFileSummary() async throws {
    let summarizer = AIFileSummarizer()
    
    // Skip if AI not available
    guard summarizer.isAvailable else { return }
    
    let content = "Hello world"
    let summary = try await summarizer.summarizeFileContent(content, fileName: "test.txt")
    
    #expect(!summary.isEmpty)
    #expect(summary.count < content.count * 3)
}

@Test("File search intent returns results")
func testSearchIntent() async throws {
    let intent = SearchFilesIntent()
    intent.searchTerm = "test"
    
    let result = try await intent.perform()
    #expect(result.value.count >= 0)
}
```

### Integration Tests

```swift
@Test("Complete AI workflow")
func testCompleteWorkflow() async throws {
    // 1. Request access
    let manager = FileAccessManager()
    // ... grant access in test
    
    // 2. Scan files
    let files = try await scanFiles(manager)
    #expect(!files.isEmpty)
    
    // 3. Index in Spotlight
    let spotlight = SpotlightIndexManager()
    try await spotlight.indexFiles(files)
    
    // 4. Search via intent
    let intent = SearchFilesIntent()
    let results = try await intent.perform()
    #expect(!results.value.isEmpty)
}
```

### UI Tests

```swift
@Test("AI features show when available")
func testUIAvailability() {
    let app = XCUIApplication()
    app.launch()
    
    if AIFeatureAvailable {
        #expect(app.buttons["AI Summarize"].exists)
    } else {
        #expect(!app.buttons["AI Summarize"].exists)
    }
}
```

---

## Debugging Tips

### Foundation Models Issues

```swift
// Enable detailed logging
let session = LanguageModelSession(instructions: "...")
print(session.transcript) // See all interactions

// Check token usage
if let error = error as? LanguageModelSession.GenerationError,
   case .exceededContextWindowSize = error {
    print("Context too large! Reduce prompt size.")
}
```

### Tool Calling Issues

```swift
do {
    let result = try await session.respond(to: prompt)
} catch let error as LanguageModelSession.ToolCallError {
    print("Tool failed: \(error.tool.name)")
    print("Arguments: \(error.tool.arguments)")
    print("Error: \(error.underlyingError)")
}
```

### File Access Issues

```swift
let result = fileAccessManager.safelyAccessFile(url) { url in
    // Set breakpoint here
    print("Accessing: \(url.path)")
    return try Data(contentsOf: url)
}

switch result {
case .success(let data):
    print("Success: \(data.count) bytes")
case .failure(let error):
    print("Error: \(error.localizedDescription)")
    print("Suggestion: \(error.recoverySuggestion ?? "None")")
}
```

---

## Deployment Checklist

### Before Submitting to App Store

- [ ] Test on devices WITHOUT Apple Intelligence
- [ ] Test with Apple Intelligence DISABLED in settings
- [ ] Test with file access permissions DENIED
- [ ] Test with Siri DISABLED
- [ ] Test on oldest supported iOS version
- [ ] Test with VoiceOver enabled
- [ ] Test with large files (>100MB)
- [ ] Test with thousands of files
- [ ] Verify no crashes when AI unavailable
- [ ] Verify graceful degradation
- [ ] Check all privacy strings in Info.plist
- [ ] Verify no network requests from AI code
- [ ] Test app shortcuts with Siri
- [ ] Test Spotlight integration
- [ ] Review error messages for clarity
- [ ] Ensure all features have fallbacks

### App Store Requirements

1. **Privacy Manifest**: Declare file access purposes
2. **Entitlements**: Request only needed capabilities
3. **Description**: Mention AI features are optional
4. **Screenshots**: Show both AI and non-AI modes
5. **Testing**: Provide test account with sample files

---

## Migration Path

### Adding AI to Existing App

```swift
// Phase 1: Add Foundation Models (1-2 days)
// - Check availability
// - Add simple summarization
// - Test thoroughly

// Phase 2: Add Tool Calling (2-3 days)
// - Define custom tools
// - Integrate with file system
// - Add organization features

// Phase 3: Add Visual Intelligence (2-3 days)
// - Define file entities
// - Implement query handler
// - Test visual search

// Phase 4: Add App Intents (3-5 days)
// - Define intents
// - Add Siri phrases
// - Implement shortcuts
// - Test voice commands

// Phase 5: Add Spotlight (1-2 days)
// - Make files indexable
// - Add update/delete logic
// - Test search results

Total: 9-15 days for complete integration
```

---

## Resources & Links

### Official Documentation
- [Foundation Models](https://developer.apple.com/documentation/FoundationModels)
- [App Intents](https://developer.apple.com/documentation/AppIntents)
- [Visual Intelligence](https://developer.apple.com/documentation/VisualIntelligence)
- [Core Spotlight](https://developer.apple.com/documentation/CoreSpotlight)

### Sample Code
- `QuickReferenceExamples.swift` - All examples
- `APPLE_INTELLIGENCE_INTEGRATION_GUIDE.md` - Detailed guide
- `FileAccessManager` - Core file operations

### Support
- File issues in your project repository
- Check Apple Developer Forums
- Review WWDC sessions on Apple Intelligence

---

**Architecture Version**: 1.0  
**Last Updated**: October 31, 2025  
**Swift Version**: 6.0  
**Minimum iOS**: 18.2 (for Foundation Models)
