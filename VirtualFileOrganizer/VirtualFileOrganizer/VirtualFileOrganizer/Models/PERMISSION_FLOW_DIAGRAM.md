# File Access Permission Flow

This document explains the complete flow of file access permissions in your Virtual File Organizer app.

## 📊 Permission Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Launches                              │
│                             │                                    │
│                             ▼                                    │
│              ┌──────────────────────────┐                       │
│              │ Check for Saved Bookmarks │                       │
│              └──────────┬───────────────┘                       │
│                         │                                        │
│           ┌─────────────┴─────────────┐                        │
│           │                           │                         │
│           ▼                           ▼                         │
│   ┌──────────────┐          ┌──────────────┐                 │
│   │   Bookmarks  │          │  No Bookmarks │                 │
│   │    Found     │          │    Found      │                 │
│   └──────┬───────┘          └──────┬────────┘                 │
│          │                          │                          │
│          │                          ▼                          │
│          │              ┌──────────────────────┐             │
│          │              │ Show Welcome Screen  │             │
│          │              │  + Permission Request│             │
│          │              └──────────┬───────────┘             │
│          │                         │                          │
│          │                         ▼                          │
│          │              ┌──────────────────────┐             │
│          │              │ User Clicks "Select  │             │
│          │              │    Directories"      │             │
│          │              └──────────┬───────────┘             │
│          │                         │                          │
│          │                         ▼                          │
│          │              ┌──────────────────────┐             │
│          │              │   NSOpenPanel Opens  │             │
│          │              └──────────┬───────────┘             │
│          │                         │                          │
│          │              ┌──────────┴─────────┐              │
│          │              │                    │               │
│          │              ▼                    ▼               │
│          │      ┌────────────┐      ┌────────────┐         │
│          │      │User Grants │      │User Cancels│         │
│          │      │  Access    │      │            │         │
│          │      └──────┬─────┘      └──────┬─────┘         │
│          │             │                   │                │
│          │             ▼                   ▼                │
│          │   ┌──────────────────┐  ┌──────────────┐       │
│          │   │  Create Bookmarks│  │Show Retry UI │       │
│          │   │  Save to Storage │  └──────────────┘       │
│          │   └──────┬───────────┘                          │
│          │          │                                       │
│          └──────────┴───────────────┐                      │
│                     │                │                      │
│                     ▼                │                      │
│          ┌──────────────────────┐  │                      │
│          │ Resolve URL from     │  │                      │
│          │ Bookmark (if needed) │  │                      │
│          └──────────┬───────────┘  │                      │
│                     │                │                      │
│                     ▼                │                      │
│          ┌──────────────────────┐  │                      │
│          │ Start Security-Scoped│  │                      │
│          │   Resource Access    │  │                      │
│          └──────────┬───────────┘  │                      │
│                     │                │                      │
│                     ▼                │                      │
│          ┌──────────────────────┐  │                      │
│          │   Perform File       │  │                      │
│          │   Operations         │  │                      │
│          └──────────┬───────────┘  │                      │
│                     │                │                      │
│                     ▼                │                      │
│          ┌──────────────────────┐  │                      │
│          │ Stop Security-Scoped │  │                      │
│          │   Resource Access    │  │                      │
│          └──────────┬───────────┘  │                      │
│                     │                │                      │
│                     ▼                │                      │
│              ┌──────────────┐      │                      │
│              │   Success!   │      │                      │
│              └──────────────┘      │                      │
│                                     │                      │
│                     ┌───────────────┘                      │
│                     │                                       │
│                     ▼                                       │
│          ┌──────────────────────┐                         │
│          │  Handle Error        │                         │
│          │  Show Error View     │                         │
│          │  Offer Recovery      │                         │
│          └──────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Detailed Flow Breakdown

### 1. App Launch
```swift
// Check for existing bookmarks
if fileAccessManager.savedURLs.isEmpty {
    // Show permission request UI
} else {
    // Proceed with main app content
}
```

### 2. Permission Request
```swift
func requestAccess() {
    fileAccessManager.requestDirectoryAccess { urls in
        // Save bookmarks for future use
        for url in urls {
            fileAccessManager.saveBookmark(for: url)
        }
    }
}
```

### 3. File Access
```swift
// Every time you access a file
let didStartAccessing = url.startAccessingSecurityScopedResource()
defer {
    if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
    }
}
// ... perform operations
```

### 4. Bookmark Resolution
```swift
if let resolvedURL = fileAccessManager.resolveBookmark(for: url) {
    // Use resolved URL
    let didStartAccessing = resolvedURL.startAccessingSecurityScopedResource()
    // ...
}
```

## 🎯 State Diagram

```
                    ┌──────────────┐
         ┌──────────┤   No Access  ├──────────┐
         │          └──────────────┘          │
         │                                    │
         │                                    │
    User Denies                          User Grants
         │                                    │
         │                                    │
         ▼                                    ▼
┌─────────────────┐                  ┌──────────────┐
│  Show Error &   │                  │  Bookmarks   │
│  Retry Option   │                  │    Saved     │
└────────┬────────┘                  └──────┬───────┘
         │                                   │
         │                                   │
    User Retries                       App Restart
         │                                   │
         │                                   │
         └────────────┐          ┌───────────┘
                      │          │
                      ▼          ▼
               ┌──────────────────────┐
               │  Resolve Bookmarks   │
               └──────────┬───────────┘
                          │
                          ▼
                  ┌───────────────┐
                  │  Bookmark     │
                  │   Valid?      │
                  └───────┬───────┘
                          │
              ┌───────────┴──────────┐
              │                      │
              ▼                      ▼
        ┌──────────┐          ┌──────────┐
        │  Stale   │          │  Valid   │
        └────┬─────┘          └────┬─────┘
             │                     │
             │                     │
      Recreate                 Use It
       Bookmark                    │
             │                     │
             └──────────┬──────────┘
                        │
                        ▼
                ┌───────────────┐
                │ Access Files  │
                └───────────────┘
```

## 📝 Component Interaction

```
┌─────────────────────────────────────────────────────────┐
│                  ContentView                             │
│  ┌────────────────────────────────────────────────┐    │
│  │          FileAccessManager                      │    │
│  │  • Manages bookmarks                            │    │
│  │  • Persists to UserDefaults                     │    │
│  │  • Resolves stale bookmarks                     │    │
│  └────────────┬───────────────────────────────────┘    │
│               │                                          │
│               ▼                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │       FileScannerViewModel                      │    │
│  │  • Uses FileAccessManager                       │    │
│  │  • Requests access when needed                  │    │
│  │  • Scans directories                            │    │
│  └────────────┬───────────────────────────────────┘    │
│               │                                          │
│               ▼                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │            VirtualFile                          │    │
│  │  • Stores bookmark data                         │    │
│  │  • Handles security-scoped access              │    │
│  │  • Provides safe access methods                 │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
└─────────────────────────────────────────────────────────┘

                        ▼
        
        ┌──────────────────────────┐
        │    macOS Security        │
        │  • Enforces sandbox      │
        │  • Validates bookmarks   │
        │  • Grants/denies access  │
        └──────────────────────────┘
```

## 🔍 Error Handling Flow

```
┌──────────────────────────────────────────────┐
│         Attempt File Access                   │
└──────────────┬───────────────────────────────┘
               │
               ▼
        ┌──────────────┐
        │  Try Access  │
        └──────┬───────┘
               │
    ┌──────────┴──────────┐
    │                     │
    ▼                     ▼
┌─────────┐         ┌─────────┐
│ Success │         │  Error  │
└────┬────┘         └────┬────┘
     │                   │
     │                   ▼
     │          ┌────────────────┐
     │          │  Classify Error│
     │          └────────┬───────┘
     │                   │
     │        ┌──────────┴──────────────────┬─────────────┐
     │        │                             │             │
     │        ▼                             ▼             ▼
     │  ┌────────────┐              ┌────────────┐  ┌────────────┐
     │  │ Permission │              │ File Not   │  │  Other     │
     │  │  Denied    │              │  Found     │  │  Error     │
     │  └─────┬──────┘              └─────┬──────┘  └─────┬──────┘
     │        │                           │               │
     │        ▼                           ▼               ▼
     │  ┌────────────┐              ┌────────────┐  ┌────────────┐
     │  │Show Error  │              │Show Error  │  │Show Error  │
     │  │+ Request   │              │+ Retry     │  │+ Support   │
     │  │  Access    │              │            │  │  Info      │
     │  └─────┬──────┘              └─────┬──────┘  └─────┬──────┘
     │        │                           │               │
     │        ▼                           │               │
     │  ┌────────────┐                   │               │
     │  │User Grants │                   │               │
     │  │  Access?   │                   │               │
     │  └─────┬──────┘                   │               │
     │        │                           │               │
     │   ┌────┴────┐                     │               │
     │   │         │                     │               │
     │   ▼         ▼                     │               │
     │ ┌───┐    ┌───┐                  │               │
     │ │Yes│    │No │                  │               │
     │ └─┬─┘    └─┬─┘                  │               │
     │   │        │                     │               │
     └───┼────────┼─────────────────────┴───────────────┘
         │        │
         │        ▼
         │   ┌────────┐
         │   │  Give  │
         │   │   Up   │
         │   └────────┘
         │
         ▼
    ┌─────────┐
    │ Process │
    │  File   │
    └─────────┘
```

## 🎬 User Journey

### Happy Path ✅
1. User launches app
2. Sees welcome screen with "Select Directories" button
3. Clicks button → NSOpenPanel appears
4. Selects directories → Access granted
5. App scans files successfully
6. User quits and relaunches app
7. Previous access still works (bookmarks restored)

### Permission Denied Path ❌
1. User launches app
2. Clicks "Select Directories"
3. NSOpenPanel appears
4. User clicks "Cancel"
5. App shows retry message
6. User clicks "Try Again"
7. Grants access this time
8. Scanning proceeds normally

### Bookmark Stale Path 🔄
1. User launches app after system update
2. App tries to resolve bookmarks
3. Bookmarks are stale
4. App automatically recreates them
5. If recreation fails, prompts user
6. User re-grants access
7. New bookmarks saved

## 🛠️ Implementation Checklist by Flow

### For Each File Access Operation:
```swift
// 1. Start security-scoped access
let didStartAccessing = url.startAccessingSecurityScopedResource()

// 2. Always use defer for cleanup
defer {
    if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
    }
}

// 3. Check file exists
guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
    return .failure(.fileNotFound(url))
}

// 4. Perform operation with error handling
do {
    let result = try performOperation(url)
    return .success(result)
} catch {
    return .failure(.unknown(error))
}
```

### For Bookmark Persistence:
```swift
// 1. Create bookmark when user grants access
let bookmarkData = try url.bookmarkData(
    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)

// 2. Save to persistent storage
UserDefaults.standard.set(bookmarkData, forKey: key)

// 3. On app launch, resolve bookmarks
var isStale = false
let resolvedURL = try URL(
    resolvingBookmarkData: bookmarkData,
    options: .withSecurityScope,
    relativeTo: nil,
    bookmarkDataIsStale: &isStale
)

// 4. Handle stale bookmarks
if isStale {
    let newBookmarkData = try resolvedURL.bookmarkData(...)
    UserDefaults.standard.set(newBookmarkData, forKey: key)
}
```

## 📚 Additional Resources

- **Apple Documentation**: [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
- **WWDC Sessions**: Search for "App Sandbox" and "Security-Scoped Bookmarks"
- **Sample Code**: Check QuickReferenceExamples.swift for working examples

---

**This flow ensures:**
- ✅ User privacy is respected
- ✅ Permissions persist across launches
- ✅ Errors are handled gracefully
- ✅ App Store requirements are met
