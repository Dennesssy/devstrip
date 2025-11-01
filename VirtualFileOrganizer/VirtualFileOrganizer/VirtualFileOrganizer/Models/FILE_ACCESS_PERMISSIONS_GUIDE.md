# File Access Permissions Setup Guide

## Overview
This guide explains how to properly configure file access permissions for your macOS app to prevent crashes and access files outside the app sandbox.

## 1. Enable Required Entitlements

Add these entitlements to your app's entitlements file (e.g., `VirtualFileOrganizer.entitlements`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Allow user-selected file access -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    
    <!-- Optional: If you need write access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- App Sandbox (required for App Store) -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Security-scoped bookmarks -->
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
</dict>
</plist>
```

## 2. Key Features Implemented

### VirtualFile.swift
- **Security-scoped resource access**: Properly starts/stops accessing security-scoped resources
- **Bookmark persistence**: Creates and stores security-scoped bookmarks for future access
- **Safe file operations**: Uses `path(percentEncoded: false)` for better compatibility
- **Helper methods**:
  - `accessSecurely(_:)` - Execute a block with proper security scoping
  - `resolveURL()` - Resolve URL from stored bookmark data

### FileAccessManager.swift
- **Centralized permission management**: Single source for handling file access
- **Bookmark persistence**: Saves bookmarks to UserDefaults for app restarts
- **NSOpenPanel integration**: User-friendly directory selection
- **Bookmark lifecycle**: Handles stale bookmarks automatically

### FileAccessPermissionView.swift
- **Permission request UI**: Clean interface for requesting access
- **User guidance**: Clear messaging about why permissions are needed

## 3. Usage Examples

### Basic Usage in Your App

```swift
import SwiftUI

@main
struct VirtualFileOrganizerApp: App {
    @State private var fileAccessManager = FileAccessManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(fileAccessManager)
        }
    }
}
```

### Request Directory Access

```swift
Button("Select Directory") {
    fileAccessManager.requestDirectoryAccess { urls in
        // Use the selected URLs
        for url in urls {
            print("Access granted to: \(url.path)")
        }
    }
}
```

### Access Files Securely

```swift
// Using VirtualFile
let file = VirtualFile(url: fileURL)
file.accessSecurely { url in
    // Access the file safely
    let data = try Data(contentsOf: url)
    return data
}

// Using FileAccessManager
fileAccessManager.accessSecurely(fileURL) { url in
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return attributes
}
```

## 4. Important Concepts

### Security-Scoped Resources
When accessing files outside your app's container, you must:
1. Call `startAccessingSecurityScopedResource()` before accessing
2. Call `stopAccessingSecurityScopedResource()` when done
3. Always use `defer` to ensure proper cleanup

```swift
let didStartAccessing = url.startAccessingSecurityScopedResource()
defer {
    if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
    }
}
// ... access the file
```

### Security-Scoped Bookmarks
Bookmarks allow persistent access across app launches:

```swift
// Create bookmark
let bookmarkData = try url.bookmarkData(
    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)

// Resolve bookmark later
var isStale = false
let resolvedURL = try URL(
    resolvingBookmarkData: bookmarkData,
    options: .withSecurityScope,
    relativeTo: nil,
    bookmarkDataIsStale: &isStale
)
```

## 5. Xcode Project Settings

### Signing & Capabilities
1. Open your project in Xcode
2. Select your target
3. Go to "Signing & Capabilities"
4. Add "App Sandbox" capability
5. Under "File Access", check:
   - ☑️ User Selected File (Read Only)
   - ☑️ User Selected File (Read/Write) - if needed

### Info.plist
Add usage descriptions (optional but recommended):

```xml
<key>NSDesktopFolderUsageDescription</key>
<string>This app needs access to scan files for organization.</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>This app needs access to scan your documents.</string>
```

## 6. Testing File Access

### Test Checklist
- [ ] App launches without crashes
- [ ] NSOpenPanel appears when requesting directory access
- [ ] Files can be scanned after granting access
- [ ] Bookmarks persist after app restart
- [ ] Stale bookmarks are properly refreshed
- [ ] Error messages are user-friendly
- [ ] Files outside granted directories show permission errors

### Debug Tips

```swift
// Enable security debug logging
// Add to your scheme's environment variables:
// SQLITE_DEBUG_LOG = 1

// Log all bookmark operations
#if DEBUG
print("Creating bookmark for: \(url.path)")
#endif
```

## 7. Common Issues and Solutions

### Issue: EXC_BAD_ACCESS Crash
**Solution**: 
- Always use security-scoped resource access
- Check if files exist before accessing
- Use proper error handling

### Issue: Permission Denied
**Solution**:
- Request access using NSOpenPanel
- Verify entitlements are properly configured
- Check bookmark data is valid

### Issue: Bookmarks Don't Persist
**Solution**:
- Use `.withSecurityScope` option when creating bookmarks
- Properly save to UserDefaults or Core Data
- Handle stale bookmarks

## 8. Best Practices

1. **Always Use Security Scoping**: Never access files without proper scoping
2. **Handle Errors Gracefully**: Show user-friendly error messages
3. **Minimize Access Scope**: Only request access to necessary directories
4. **Check File Existence**: Verify files exist before accessing
5. **Clean Up Resources**: Use `defer` to ensure cleanup
6. **Persist Bookmarks**: Save bookmarks for future access
7. **Handle Stale Bookmarks**: Recreate them when detected
8. **User Communication**: Clearly explain why access is needed

## 9. App Store Submission

Before submitting to the App Store:

1. ✅ App Sandbox enabled
2. ✅ Only necessary entitlements included
3. ✅ All file access uses security-scoped resources
4. ✅ Clear user messages for permission requests
5. ✅ Graceful handling of denied permissions
6. ✅ No hardcoded file paths
7. ✅ Bookmarks properly managed

## 10. Additional Resources

- [App Sandbox Documentation](https://developer.apple.com/documentation/security/app_sandbox)
- [Security-Scoped Bookmarks](https://developer.apple.com/documentation/foundation/url/2143023-bookmarkdata)
- [Entitlements Documentation](https://developer.apple.com/documentation/bundleresources/entitlements)
