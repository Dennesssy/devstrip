# Apple Intelligence Examples Visual Guide

A visual reference for all 14 examples in `QuickReferenceExamples.swift`.

## 📊 Examples Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                    File Access Examples (1-8)                       │
│                  Basic → Intermediate → Advanced                    │
└────────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
        ┌───────────▼────────┐   ┌──────────▼──────────┐
        │  Original Examples │   │ AI-Enhanced Examples │
        │     Examples 1-8   │   │    Examples 9-14     │
        └────────────────────┘   └──────────────────────┘
                                           │
                    ┌──────────────────────┴────────────────────┐
                    │                                           │
            ┌───────▼────────┐                         ┌────────▼────────┐
            │  Foundation    │                         │   System        │
            │    Models      │                         │  Integration    │
            │  (Examples     │                         │  (Examples      │
            │   9, 10, 14)   │                         │  11, 12, 13)    │
            └────────────────┘                         └─────────────────┘
```

---

## 🗂️ Example Categories

### Basic File Access (Examples 1-4)

```
Example 1          Example 2          Example 3          Example 4
┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│ Request  │      │   Read   │      │   Scan   │      │ Virtual  │
│Directory │      │   File   │      │Directory │      │   File   │
│  Access  │  →   │ Content  │  →   │   with   │  →   │  Usage   │
│          │      │          │      │ Progress │      │          │
└──────────┘      └──────────┘      └──────────┘      └──────────┘
   User              Safe              Async           Security
  Picker           Reading           Scanning          Scoping
```

### App Integration (Examples 5-8)

```
Example 5          Example 6          Example 7          Example 8
┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│Permission│      │  Batch   │      │ Settings │      │   File   │
│   Flow   │  →   │   File   │  →   │   View   │  →   │ Monitor  │
│          │      │Operations│      │          │      │          │
└──────────┘      └──────────┘      └──────────┘      └──────────┘
  Complete         Multiple         Manage All        Real-time
   Setup            Files            Access            Updates
```

### AI-Powered Features (Examples 9-14)

```
Example 9          Example 10         Example 11
┌──────────┐      ┌──────────┐      ┌──────────┐
│    AI    │      │  Smart   │      │  Visual  │
│   File   │      │   File   │      │Intelligence
│Summarizer│      │Organizer │      │  Search  │
└────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                  │
     └────────┬────────┴──────────┬───────┘
              │                   │
     ┌────────▼────────┐ ┌────────▼────────┐
     │ Foundation      │ │ Visual          │
     │ Models          │ │ Intelligence    │
     └─────────────────┘ └─────────────────┘

Example 12         Example 13         Example 14
┌──────────┐      ┌──────────┐      ┌──────────┐
│   Siri   │      │Spotlight │      │Streaming │
│   File   │      │  Index   │      │   AI     │
│  Search  │      │Integration      │ Analysis │
└────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                  │
     └────────┬────────┴──────────┬───────┘
              │                   │
     ┌────────▼────────┐ ┌────────▼────────┐
     │ App Intents     │ │ Core Spotlight  │
     │                 │ │ + Streaming     │
     └─────────────────┘ └─────────────────┘
```

---

## 🎯 Example Details

### Example 9: AI File Summarizer 🧠

**What it does:**
```
User selects file → AI analyzes → Summary displayed
```

**Key features:**
- ✅ Checks model availability
- ✅ Creates AI session with instructions
- ✅ Generates concise summaries
- ✅ Handles errors gracefully
- ✅ SwiftUI integration

**Visual Flow:**
```
┌──────────────┐
│   User       │
│  Taps Button │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ File Picker      │
│ Shows            │
└──────┬───────────┘
       │ Selected file
       ▼
┌──────────────────┐
│ Read File        │
│ Content          │
└──────┬───────────┘
       │ Text content
       ▼
┌──────────────────┐
│ Foundation       │
│ Models           │
│ Processes on     │
│ device           │
└──────┬───────────┘
       │ AI summary
       ▼
┌──────────────────┐
│ Display in UI    │
│ with nice card   │
└──────────────────┘
```

**Code snippet:**
```swift
let summarizer = AIFileSummarizer()
let summary = try await summarizer.summarizeFileContent(
    fileContent,
    fileName: "Document.txt"
)
```

---

### Example 10: Smart File Organizer 🗂️

**What it does:**
```
User requests organization → AI uses tools → Returns plan
```

**Key features:**
- ✅ Custom tool calling
- ✅ File search tool
- ✅ Categorization tool
- ✅ Structured output (@Generable)
- ✅ Organization suggestions

**Visual Flow:**
```
┌───────────────┐
│ User Requests │
│ Organization  │
└───────┬───────┘
        │
        ▼
┌─────────────────────┐
│ AI Session with     │
│ Custom Tools        │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ AI Calls            │
│ FileSearchTool      │
│ "Find all PDFs"     │
└───────┬─────────────┘
        │ Results
        ▼
┌─────────────────────┐
│ AI Calls            │
│ CategorizationTool  │
│ "Group by type"     │
└───────┬─────────────┘
        │ Categories
        ▼
┌─────────────────────┐
│ AI Generates        │
│ OrganizationPlan    │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ Display Plan        │
│ • Categories        │
│ • Rationale         │
│ • File Count        │
└─────────────────────┘
```

**Tool Architecture:**
```
┌──────────────────────────────┐
│   AI Session                 │
│   Instructions: "Organize"   │
└────────────┬─────────────────┘
             │
    ┌────────┴─────────┐
    │                  │
    ▼                  ▼
┌─────────┐      ┌──────────────┐
│  Tool 1 │      │    Tool 2    │
│ Search  │      │ Categorize   │
│  Files  │      │    Files     │
└────┬────┘      └──────┬───────┘
     │                  │
     └────────┬─────────┘
              │
              ▼
       ┌────────────┐
       │   Final    │
       │  Response  │
       └────────────┘
```

---

### Example 11: Visual Intelligence 📸

**What it does:**
```
User takes photo → System analyzes → Finds matching files
```

**Key features:**
- ✅ Camera integration
- ✅ Semantic labels
- ✅ File entity definitions
- ✅ System UI integration
- ✅ Deep linking

**Visual Flow:**
```
┌──────────────┐
│    User      │
│ Takes Photo  │
│ of Document  │
└──────┬───────┘
       │
       ▼
┌────────────────────┐
│ Visual Intelligence│
│ Framework          │
│ Analyzes:          │
│ • "document"       │
│ • "pdf"            │
│ • "text"           │
└──────┬─────────────┘
       │ SemanticContentDescriptor
       ▼
┌────────────────────────┐
│ Your App               │
│ FileIntentValueQuery   │
│ Searches for matching  │
│ files                  │
└──────┬─────────────────┘
       │ [FileEntity]
       ▼
┌────────────────────────┐
│ System Shows Results   │
│ ┌───────────────────┐ │
│ │ 📄 Report.pdf     │ │
│ │ 📄 Invoice.pdf    │ │
│ │ 📄 Notes.txt      │ │
│ └───────────────────┘ │
│                        │
│ User taps → App opens  │
└────────────────────────┘
```

**Label Matching Logic:**
```
Visual Labels:        File Extensions:
┌────────────┐       ┌────────────┐
│"photo"     │  →    │.jpg .png   │
│"image"     │       │.heic       │
└────────────┘       └────────────┘

┌────────────┐       ┌────────────┐
│"document"  │  →    │.pdf .doc   │
│"text"      │       │.txt .md    │
└────────────┘       └────────────┘

┌────────────┐       ┌────────────┐
│"code"      │  →    │.swift .py  │
│"programming"       │.js .java   │
└────────────┘       └────────────┘
```

---

### Example 12: Siri Integration 🗣️

**What it does:**
```
User says "Find my Swift files" → Siri calls your app → Returns results
```

**Key features:**
- ✅ App Intents framework
- ✅ Multiple execution modes
- ✅ Interactive dialogs
- ✅ App shortcuts
- ✅ Parameter handling

**Visual Flow:**
```
┌──────────────┐
│    User      │
│ "Hey Siri,   │
│  find Swift  │
│  files"      │
└──────┬───────┘
       │
       ▼
┌─────────────────┐
│     Siri        │
│ Recognizes      │
│ Intent          │
└──────┬──────────┘
       │
       ▼
┌───────────────────────┐
│ SearchFilesIntent     │
│ • searchTerm: "Swift" │
│ • fileType: nil       │
└──────┬────────────────┘
       │
       ▼
┌───────────────────────┐
│ perform() method      │
│ • Access files        │
│ • Search by term      │
│ • Filter results      │
└──────┬────────────────┘
       │ Results
       ▼
┌───────────────────────┐
│ Return Dialog         │
│ "Found 12 Swift files"│
└──────┬────────────────┘
       │
       ▼
┌───────────────────────┐
│ Siri Shows Results    │
│ ┌──────────────────┐  │
│ │ MyApp.swift      │  │
│ │ Model.swift      │  │
│ │ View.swift       │  │
│ └──────────────────┘  │
│                       │
│ Tap to open in app    │
└───────────────────────┘
```

**Intent Modes:**
```
Background Mode:
User → Siri → Intent runs → Results → User
              (App stays closed)

Foreground (Dynamic) Mode:
User → Siri → Intent starts → Needs more → Opens app → Completes
              (Background)                 (Foreground)

Foreground (Immediate) Mode:
User → Siri → Opens app → Intent runs → Results
              (Immediate)
```

---

### Example 13: Spotlight Integration 🔍

**What it does:**
```
App indexes files → User searches in Spotlight → Results appear
```

**Key features:**
- ✅ CSSearchableIndex
- ✅ Rich metadata
- ✅ Update tracking
- ✅ Deep linking
- ✅ System-wide search

**Visual Flow:**
```
┌──────────────────┐
│   Your App       │
│ Has 100 files    │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│ SpotlightIndexManager│
│ Creates searchable   │
│ items with metadata  │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  Core Spotlight      │
│  System Index        │
│  ┌────────────────┐  │
│  │ File 1         │  │
│  │ File 2         │  │
│  │ File 3         │  │
│  │ ...            │  │
│  └────────────────┘  │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  User Searches       │
│  "vacation photos"   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Spotlight Results    │
│ ┌─────────────────┐  │
│ │ 📱 Your App     │  │
│ │ vacation1.jpg   │  │
│ │ vacation2.jpg   │  │
│ └─────────────────┘  │
│                      │
│ Tap → Opens in app   │
└──────────────────────┘
```

**Metadata Flow:**
```
VirtualFile Properties:
┌──────────────────┐
│ • name           │
│ • size           │
│ • creationDate   │
│ • tags           │
│ • categories     │
└────────┬─────────┘
         │
         ▼
searchableAttributes:
┌──────────────────┐
│ • title          │
│ • displayName    │
│ • keywords       │
│ • contentType    │
│ • fileSize       │
│ • dates          │
└────────┬─────────┘
         │
         ▼
CSSearchableItem:
┌──────────────────┐
│ • uniqueID       │
│ • domainID       │
│ • attributes     │
└────────┬─────────┘
         │
         ▼
System Index
```

---

### Example 14: Streaming AI 🌊

**What it does:**
```
User requests analysis → AI streams response → UI updates in real-time
```

**Key features:**
- ✅ Progressive updates
- ✅ Snapshot streaming
- ✅ SwiftUI integration
- ✅ Structured output
- ✅ Better UX

**Visual Flow:**
```
Time →

t=0s   User Taps "Analyze"
       ┌─────────────┐
       │ Loading...  │
       └─────────────┘

t=0.5s AI starts generating
       ┌─────────────────┐
       │ Category:       │
       │ Documents ✓     │
       └─────────────────┘

t=1s   More content arrives
       ┌─────────────────┐
       │ Category:       │
       │ Documents ✓     │
       │                 │
       │ Key Findings:   │
       │ • Swift code ✓  │
       └─────────────────┘

t=1.5s Even more content
       ┌─────────────────┐
       │ Category:       │
       │ Documents ✓     │
       │                 │
       │ Key Findings:   │
       │ • Swift code ✓  │
       │ • iOS dev ✓     │
       └─────────────────┘

t=2s   Complete!
       ┌─────────────────┐
       │ Category:       │
       │ Documents ✓     │
       │                 │
       │ Key Findings:   │
       │ • Swift code ✓  │
       │ • iOS dev ✓     │
       │ • UI patterns ✓ │
       │                 │
       │ Suggestion:     │
       │ Organize by... ✓│
       └─────────────────┘
```

**Snapshot Architecture:**
```
@Generable struct FilesAnalysis {
    var primaryCategory: String
    var keyFindings: [String]
    var organizationSuggestion: String
}

Generates:
struct FilesAnalysis.PartiallyGenerated {
    var primaryCategory: String?        ← Nil initially
    var keyFindings: [String]?          ← Populates gradually
    var organizationSuggestion: String? ← Appears last
}

Stream:
for try await partial in stream {
    analysis = partial  // SwiftUI updates automatically!
}
```

---

## 🔄 Integration Patterns

### Pattern 1: Check, Initialize, Use

```
┌──────────────┐
│ Check Model  │
│ Availability │
└──────┬───────┘
       │
       ▼ Available?
┌──────────────┐
│ Initialize   │
│ Session      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Use Features │
└──────────────┘
```

### Pattern 2: Request, Access, Process

```
┌──────────────┐
│ Request File │
│ Access       │
└──────┬───────┘
       │
       ▼ Granted?
┌──────────────┐
│ Read File    │
│ Content      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Process with │
│ AI           │
└──────────────┘
```

### Pattern 3: Search, Filter, Display

```
┌──────────────┐
│ User Query   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Search Files │
│ or AI        │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Filter &     │
│ Sort Results │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Display in   │
│ UI or Siri   │
└──────────────┘
```

---

## 📱 UI Patterns

### Pattern A: Availability Banner

```
┌─────────────────────────────┐
│  ✅ Apple Intelligence Ready │
│                             │
│  [Use AI Features]          │
└─────────────────────────────┘

OR

┌─────────────────────────────┐
│  ⚠️ AI Unavailable          │
│  Enable in Settings         │
│                             │
│  [Go to Settings]           │
└─────────────────────────────┘
```

### Pattern B: Progressive Results

```
Loading:
┌─────────────┐
│ ⏳ Thinking...│
└─────────────┘

Streaming:
┌─────────────┐
│ ✨ Results  │
│ • Item 1 ✓  │
│ • Item 2... │
└─────────────┘

Complete:
┌─────────────┐
│ ✨ Results  │
│ • Item 1 ✓  │
│ • Item 2 ✓  │
│ • Item 3 ✓  │
└─────────────┘
```

### Pattern C: Error Recovery

```
Error:
┌──────────────────┐
│ ⚠️ Error         │
│ Description      │
│                  │
│ [Retry]  [Help]  │
└──────────────────┘

Recovered:
┌──────────────────┐
│ ✅ Success       │
│ Results shown    │
└──────────────────┘
```

---

## 🎯 Example Selection Guide

**Want to summarize files?** → Example 9  
**Need smart organization?** → Example 10  
**Want visual search?** → Example 11  
**Adding Siri support?** → Example 12  
**System-wide search?** → Example 13  
**Better UX with streaming?** → Example 14

**New to file access?** → Start with Examples 1-4  
**Building complete app?** → Examples 5-8  
**Adding AI features?** → Examples 9-14

---

## 📚 Complete Example Matrix

| # | Name | Category | Complexity | Time | Key APIs |
|---|------|----------|------------|------|----------|
| 1 | Request Access | Basic | ⭐ | 10 min | FileManager, NSOpenPanel |
| 2 | Read File | Basic | ⭐ | 10 min | Security Scoping |
| 3 | Scan Directory | Intermediate | ⭐⭐ | 15 min | FileManager, Recursion |
| 4 | Virtual File | Intermediate | ⭐⭐ | 15 min | URL, Bookmarks |
| 5 | Permission Flow | Intermediate | ⭐⭐ | 20 min | State Management |
| 6 | Batch Operations | Advanced | ⭐⭐⭐ | 30 min | Async/Await |
| 7 | Settings View | Intermediate | ⭐⭐ | 20 min | SwiftUI, Lists |
| 8 | File Monitor | Advanced | ⭐⭐⭐ | 30 min | Observation, Timer |
| 9 | AI Summarizer | Advanced | ⭐⭐⭐ | 30 min | FoundationModels |
| 10 | Smart Organizer | Expert | ⭐⭐⭐⭐ | 45 min | Tool Calling |
| 11 | Visual Search | Advanced | ⭐⭐⭐ | 40 min | VisualIntelligence |
| 12 | Siri Integration | Advanced | ⭐⭐⭐ | 35 min | AppIntents |
| 13 | Spotlight Index | Intermediate | ⭐⭐ | 25 min | CoreSpotlight |
| 14 | Streaming AI | Advanced | ⭐⭐⭐ | 35 min | Async Streams |

---

## 🚀 Quick Navigation

- **Start Here**: Example 1
- **Most Popular**: Example 9 (AI Summarizer)
- **Most Advanced**: Example 10 (Tool Calling)
- **Best for Siri**: Example 12
- **Best UX**: Example 14 (Streaming)

---

**Visual Guide Version**: 1.0  
**Last Updated**: October 31, 2025

For detailed code and implementation, see `QuickReferenceExamples.swift`
