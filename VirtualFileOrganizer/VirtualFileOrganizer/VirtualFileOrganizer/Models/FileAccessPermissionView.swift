import SwiftUI

/// A view that helps request file access permissions using NSOpenPanel
struct FileAccessPermissionView: View {
    @Binding var selectedDirectories: [URL]
    @State private var showingFileImporter = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("File Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This app needs permission to access files on your system. Select the directories you want to scan.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                requestDirectoryAccess()
            } label: {
                Label("Select Directories", systemImage: "folder.badge.plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
    
    private func requestDirectoryAccess() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select directories to scan for files"
        panel.prompt = "Select"
        panel.canCreateDirectories = false
        
        panel.begin { response in
            if response == .OK {
                selectedDirectories = panel.urls
            }
        }
    }
}

/// Manager for handling file access permissions and security-scoped bookmarks
@Observable
class FileAccessManager {
    private var bookmarks: [URL: Data] = [:]
    private let bookmarksKey = "SecurityScopedBookmarks"
    
    init() {
        loadBookmarks()
    }
    
    /// Request access to a directory using NSOpenPanel
    func requestDirectoryAccess(completion: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select directories to access"
        panel.prompt = "Grant Access"
        
        panel.begin { [weak self] response in
            guard response == .OK else {
                completion([])
                return
            }
            
            // Save bookmarks for selected directories
            for url in panel.urls {
                self?.saveBookmark(for: url)
            }
            
            completion(panel.urls)
        }
    }
    
    /// Save a security-scoped bookmark for a URL
    func saveBookmark(for url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            bookmarks[url] = bookmarkData
            persistBookmarks()
        } catch {
            print("Failed to create bookmark for \(url.path): \(error.localizedDescription)")
        }
    }
    
    /// Resolve a URL from its bookmark
    func resolveBookmark(for url: URL) -> URL? {
        guard let bookmarkData = bookmarks[url] else {
            return nil
        }
        
        var isStale = false
        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // Recreate stale bookmark
                saveBookmark(for: resolvedURL)
            }
            
            return resolvedURL
        } catch {
            print("Failed to resolve bookmark: \(error.localizedDescription)")
            bookmarks.removeValue(forKey: url)
            persistBookmarks()
            return nil
        }
    }
    
    /// Access a URL with proper security scoping
    func accessSecurely<T>(_ url: URL, block: (URL) throws -> T) rethrows -> T? {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        return try block(url)
    }
    
    /// Get all saved bookmark URLs
    var savedURLs: [URL] {
        Array(bookmarks.keys)
    }
    
    /// Remove a saved bookmark
    func removeBookmark(for url: URL) {
        bookmarks.removeValue(forKey: url)
        persistBookmarks()
    }
    
    /// Clear all saved bookmarks
    func clearAllBookmarks() {
        bookmarks.removeAll()
        persistBookmarks()
    }
    
    // MARK: - Persistence
    
    private func persistBookmarks() {
        let data = bookmarks.compactMap { url, bookmark -> [String: Data]? in
            return ["url": url.absoluteString.data(using: .utf8) ?? Data(), "bookmark": bookmark]
        }
        
        UserDefaults.standard.set(data, forKey: bookmarksKey)
    }
    
    private func loadBookmarks() {
        guard let data = UserDefaults.standard.array(forKey: bookmarksKey) as? [[String: Data]] else {
            return
        }
        
        for item in data {
            guard let urlData = item["url"],
                  let urlString = String(data: urlData, encoding: .utf8),
                  let url = URL(string: urlString),
                  let bookmarkData = item["bookmark"] else {
                continue
            }
            
            bookmarks[url] = bookmarkData
        }
    }
}

// MARK: - Preview

#Preview {
    FileAccessPermissionView(selectedDirectories: .constant([]))
}
