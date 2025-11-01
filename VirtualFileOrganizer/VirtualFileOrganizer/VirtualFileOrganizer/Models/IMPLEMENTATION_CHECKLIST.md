# Implementation Checklist

Follow this checklist to properly integrate file access permissions into your Virtual File Organizer app.

## Phase 1: Project Configuration ⚙️

### Xcode Setup
- [ ] Open your project in Xcode
- [ ] Select your target in the project navigator
- [ ] Go to "Signing & Capabilities" tab

### Add App Sandbox Capability
- [ ] Click the "+" button to add capability
- [ ] Select "App Sandbox"
- [ ] Under "File Access", check these options:
  - [ ] ☑️ User Selected File (Read Only)
  - [ ] ☑️ User Selected File (Read/Write)

### Add Entitlements File
- [ ] Verify `VirtualFileOrganizer.entitlements` exists in project
- [ ] Go to Build Settings
- [ ] Search for "Code Signing Entitlements"
- [ ] Set value to: `VirtualFileOrganizer.entitlements`
- [ ] Clean build folder (Cmd+Shift+K)

## Phase 2: Code Integration 🔧

### Update Existing Files
- [x] ✅ `VirtualFile.swift` - Already updated with security-scoped access
- [x] ✅ `FileScannerViewModel.swift` - Already integrated with FileAccessManager

### Add New Files to Project
- [ ] Add `FileAccessPermissionView.swift` to project
- [ ] Add `FileAccessErrorHandling.swift` to project
- [ ] Add `QuickReferenceExamples.swift` (optional, for reference)

### Update ContentView
- [ ] Add `@State private var fileAccessManager = FileAccessManager()`
- [ ] Pass fileAccessManager to FileScannerViewModel
- [ ] Consider showing permission request on first launch

Example:
```swift
struct ContentView: View {
    @State private var fileAccessManager = FileAccessManager()
    @State private var scannerViewModel = FileScannerViewModel()
    
    var body: some View {
        // ... your existing code
    }
    .onAppear {
        if fileAccessManager.savedURLs.isEmpty {
            // Show permission request
        }
    }
}
```

## Phase 3: Testing 🧪

### Basic Functionality
- [ ] App launches without crashes
- [ ] No immediate `EXC_BAD_ACCESS` errors
- [ ] Build succeeds with entitlements

### Permission Flow
- [ ] Click "Start Scan" button
- [ ] NSOpenPanel appears (file picker dialog)
- [ ] Select a test directory (e.g., ~/Downloads)
- [ ] Dialog dismisses and scanning begins
- [ ] Files are successfully scanned and displayed

### Permission Persistence
- [ ] Quit the app completely (Cmd+Q)
- [ ] Relaunch the app
- [ ] Previously granted access still works
- [ ] No need to re-grant permissions

### Error Handling
- [ ] Try accessing a file without permission
- [ ] Verify friendly error message appears
- [ ] "Grant Access" button works correctly
- [ ] Retrying after granting access succeeds

### Edge Cases
- [ ] Deny permission in file picker - app handles gracefully
- [ ] Select empty directory - no crashes
- [ ] Select directory with many files - performance is acceptable
- [ ] Select directory with special characters in path
- [ ] Move/delete file after scanning - proper error message

## Phase 4: User Experience 🎨

### First Launch Experience
- [ ] Show welcome screen explaining permissions
- [ ] Clear call-to-action for granting access
- [ ] Helpful messaging about why access is needed

### Settings/Preferences
- [ ] Add preference pane for managing access (optional)
- [ ] Show list of granted directories
- [ ] Allow removing access
- [ ] Option to clear all bookmarks

### Error Messages
- [ ] All error messages are user-friendly
- [ ] No technical jargon in user-facing text
- [ ] Clear next steps provided
- [ ] Option to retry or grant access

## Phase 5: Performance & Optimization ⚡

### Performance Checks
- [ ] Large directory scans don't freeze UI
- [ ] Progress indicator updates smoothly
- [ ] Memory usage is reasonable
- [ ] Can cancel long-running scans

### Optimization
- [ ] Bookmarks are cached in memory
- [ ] Security-scoped access is properly scoped (not held too long)
- [ ] File operations run on background queue
- [ ] UI updates happen on main thread

## Phase 6: App Store Preparation 📦

### Entitlements Review
- [ ] Only necessary entitlements included
- [ ] App Sandbox is enabled
- [ ] No overly-broad permissions requested

### Privacy
- [ ] All file access uses user-selected files
- [ ] No hardcoded paths to user directories
- [ ] Bookmarks are stored securely

### Testing in Sandbox
- [ ] Test in fully sandboxed environment
- [ ] Verify no sandbox violations in Console.app
- [ ] Check for any permission warnings

### Documentation
- [ ] Update app description with permission requirements
- [ ] Add screenshots showing permission flow
- [ ] Prepare App Review notes explaining file access

## Phase 7: Final Checks ✅

### Code Quality
- [ ] No compiler warnings
- [ ] All tests pass (if you have tests)
- [ ] Code follows Swift style guidelines
- [ ] Comments are clear and helpful

### Documentation
- [ ] README explains permission requirements
- [ ] Setup instructions are clear
- [ ] Known issues documented
- [ ] User guide covers permission flow

### Build & Archive
- [ ] Clean build succeeds
- [ ] Archive builds successfully
- [ ] Entitlements are included in archive
- [ ] Code signing is valid

## Troubleshooting Common Issues 🔍

### Issue: NSOpenPanel Doesn't Appear
**Solution:**
- Check App Sandbox is enabled
- Verify entitlements file is linked
- Ensure `user-selected.read-only` entitlement is set

### Issue: Files Still Show Permission Errors
**Solution:**
- Verify security-scoped access is started
- Check bookmark data is being saved
- Ensure `stopAccessingSecurityScopedResource()` is called

### Issue: Bookmarks Don't Persist
**Solution:**
- Use `.withSecurityScope` option
- Save to UserDefaults correctly
- Check for stale bookmarks

### Issue: Crashes on File Access
**Solution:**
- Always check file exists before accessing
- Use proper error handling
- Ensure defer block executes

## Quick Test Script

Run through this scenario to verify everything works:

1. **Fresh Install Test**
   - Delete app from Applications
   - Delete ~/Library/Containers/[your-bundle-id]
   - Build and run
   - Grant permissions
   - Scan a directory
   - Quit and relaunch
   - Verify access persists

2. **Permission Denial Test**
   - Start scan
   - Click "Cancel" in file picker
   - Verify app doesn't crash
   - Try again and grant access
   - Verify scanning works

3. **Large Directory Test**
   - Select a large directory (e.g., /usr/local)
   - Verify progress indicator works
   - Verify can cancel scan
   - Check memory usage in Activity Monitor

## Success Criteria 🎉

Your implementation is complete when:

- ✅ App launches without crashes
- ✅ File picker appears when needed
- ✅ Files can be scanned after granting access
- ✅ Permissions persist across launches
- ✅ Error messages are helpful
- ✅ App is sandbox-compliant
- ✅ Ready for App Store submission

## Next Steps After Completion

1. **User Testing**
   - Get feedback from beta testers
   - Identify any UX issues
   - Refine error messages

2. **Performance Tuning**
   - Profile with Instruments
   - Optimize file scanning
   - Reduce memory usage

3. **Documentation**
   - Write user guide
   - Create video tutorial
   - Update marketing materials

4. **App Store Submission**
   - Create screenshots
   - Write app description
   - Submit for review

---

**Need Help?**
- Review `FILE_ACCESS_PERMISSIONS_GUIDE.md`
- Check `QuickReferenceExamples.swift` for code samples
- Consult Apple's App Sandbox documentation

**Last Updated:** October 28, 2025
