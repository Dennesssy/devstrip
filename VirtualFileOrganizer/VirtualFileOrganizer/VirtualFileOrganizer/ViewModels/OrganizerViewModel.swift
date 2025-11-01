import Foundation
import SwiftUI

@Observable
class OrganizerViewModel {
    var allFiles: [VirtualFile] = []
    var selectedFiles: Set<VirtualFile.ID> = []
    var searchQuery = ""
    var selectedCategory: FileCategory?
    var selectedTag: String?
    var sortBy: SortOption = .name
    var sortOrder: SortOrder = .ascending
    var viewMode: ViewMode = .list
    
    private var scanResults: [VirtualFile] = []
    
    // MARK: - Computed Properties
    
    var categories: [FileCategory] {
        let allCategories = Set(allFiles.flatMap { $0.categories })
        return FileCategory.allCases.filter { allCategories.contains($0) }
    }
    
    var availableTags: [String] {
        let allTags = Set(allFiles.flatMap { $0.tags })
        return Array(allTags).sorted()
    }
    
    var filteredFiles: [VirtualFile] {
        var files = allFiles
        
        // Apply search filter
        if !searchQuery.isEmpty {
            files = files.filter { file in
                file.name.localizedCaseInsensitiveContains(searchQuery) ||
                file.originalPath.localizedCaseInsensitiveContains(searchQuery) ||
                file.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            files = files.filter { $0.categories.contains(category) }
        }
        
        // Apply tag filter
        if let tag = selectedTag {
            files = files.filter { $0.tags.contains(tag) }
        }
        
        // Apply sorting
        files = sortFiles(files, by: sortBy, order: sortOrder)
        
        return files
    }
    
    var selectedFilesArray: [VirtualFile] {
        allFiles.filter { selectedFiles.contains($0.id) }
    }
    
    var selectedFilesSize: Int64 {
        selectedFilesArray.reduce(0) { $0 + $1.size }
    }
    
    var formattedSelectedFilesSize: String {
        FileSizeFormatter.formattedString(fromBytes: selectedFilesSize)
    }
    
    // MARK: - File Management
    
    func processScanResults(_ results: [VirtualFile]) {
        self.scanResults = results
        self.allFiles = results
        self.selectedFiles.removeAll()
        self.searchQuery = ""
        self.selectedCategory = nil
        self.selectedTag = nil
    }
    
    func toggleFileSelection(_ file: VirtualFile) {
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }
    
    func selectAllFiles() {
        selectedFiles = Set(filteredFiles.map { $0.id })
    }
    
    func deselectAllFiles() {
        selectedFiles.removeAll()
    }
    
    func deleteSelectedFiles() -> [CleanupResult] {
        var results: [CleanupResult] = []
        
        for fileId in selectedFiles {
            guard let file = allFiles.first(where: { $0.id == fileId }) else { continue }
            
            do {
                try FileManager.default.removeItem(at: file.url)
                results.append(.success(file))
                
                // Remove from all files
                allFiles.removeAll { $0.id == fileId }
            } catch {
                results.append(.failure(file, error))
            }
        }
        
        selectedFiles.removeAll()
        return results
    }
    
    func moveSelectedFilesToTrash() -> [CleanupResult] {
        var results: [CleanupResult] = []
        
        for fileId in selectedFiles {
            guard let file = allFiles.first(where: { $0.id == fileId }) else { continue }
            
            do {
                try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                results.append(.success(file))
                
                // Remove from all files
                allFiles.removeAll { $0.id == fileId }
            } catch {
                results.append(.failure(file, error))
            }
        }
        
        selectedFiles.removeAll()
        return results
    }
    
    func revealInFinder(_ file: VirtualFile) {
        NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: "")
    }
    
    func openFile(_ file: VirtualFile) {
        NSWorkspace.shared.open(file.url)
    }
    
    func showFileInQuickLook(_ file: VirtualFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }
    
    // MARK: - Category Management
    
    func addFileToCategory(_ file: VirtualFile, category: FileCategory) {
        if let index = allFiles.firstIndex(where: { $0.id == file.id }) {
            allFiles[index].addToCategory(category)
        }
    }
    
    func removeFileFromCategory(_ file: VirtualFile, category: FileCategory) {
        if let index = allFiles.firstIndex(where: { $0.id == file.id }) {
            allFiles[index].removeFromCategory(category)
        }
    }
    
    func moveSelectedFilesToCategory(_ category: FileCategory) {
        for fileId in selectedFiles {
            guard let file = allFiles.first(where: { $0.id == fileId }) else { continue }
            addFileToCategory(file, category: category)
        }
    }
    
    // MARK: - Tag Management
    
    func addTagToSelectedFiles(_ tag: String) {
        let cleanTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTag.isEmpty else { return }
        
        for fileId in selectedFiles {
            guard let file = allFiles.first(where: { $0.id == fileId }) else { continue }
            file.addTag(cleanTag)
        }
    }
    
    func removeTagFromSelectedFiles(_ tag: String) {
        for fileId in selectedFiles {
            guard let file = allFiles.first(where: { $0.id == fileId }) else { continue }
            file.removeTag(tag)
        }
    }
    
    func renameTag(_ oldTag: String, to newTag: String) {
        let cleanNewTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNewTag.isEmpty && cleanNewTag != oldTag else { return }
        
        for file in allFiles {
            if file.tags.contains(oldTag) {
                file.removeTag(oldTag)
                file.addTag(cleanNewTag)
            }
        }
    }
    
    func deleteTag(_ tag: String) {
        for file in allFiles {
            file.removeTag(tag)
        }
    }
    
    // MARK: - Sorting and Filtering
    
    private func sortFiles(_ files: [VirtualFile], by option: SortOption, order: SortOrder) -> [VirtualFile] {
        let sorted = files.sorted { file1, file2 in
            let comparison: Bool
            
            switch option {
            case .name:
                comparison = file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
            case .size:
                comparison = file1.size < file2.size
            case .dateModified:
                guard let date1 = file1.modificationDate, let date2 = file2.modificationDate else {
                    comparison = true
                    break
                }
                comparison = date1 < date2
            case .dateCreated:
                guard let date1 = file1.creationDate, let date2 = file2.creationDate else {
                    comparison = true
                    break
                }
                comparison = date1 < date2
            case .path:
                comparison = file1.originalPath.localizedCaseInsensitiveCompare(file2.originalPath) == .orderedAscending
            case .type:
                comparison = file1.fileExtension.localizedCaseInsensitiveCompare(file2.fileExtension) == .orderedAscending
            }
            
            return order == .ascending ? comparison : !comparison
        }
        
        return sorted
    }
    
    func filesForCategory(_ category: FileCategory) -> [VirtualFile] {
        return allFiles.filter { $0.categories.contains(category) }
    }
    
    // MARK: - Statistics
    
    var statistics: OrganizerStatistics {
        OrganizerStatistics(files: allFiles)
    }
    
    func statisticsForCategory(_ category: FileCategory) -> FileCategory.Statistics {
        let categoryFiles = allFiles.filter { $0.categories.contains(category) }
        let totalSize = categoryFiles.reduce(0) { $0 + $1.size }
        let fileCount = categoryFiles.count
        let lastModified = categoryFiles
            .compactMap { $0.modificationDate }
            .max()
        
        return FileCategory.Statistics(
            fileCount: fileCount,
            totalSize: totalSize,
            lastModified: lastModified
        )
    }
    
    // MARK: - Export/Import
    
    func exportOrganization(to url: URL) throws {
        let exportData = OrganizationExportData(
            files: allFiles.map { file in
                FileOrganizationExport(
                    url: file.url,
                    name: file.name,
                    categories: Array(file.categories.map { $0.rawValue }),
                    tags: Array(file.tags)
                )
            },
            exportDate: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(exportData)
        try data.write(to: url)
    }
    
    func importOrganization(from url: URL, baseFiles: [VirtualFile]) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(OrganizationExportData.self, from: data)
        
        for exportFile in importData.files {
            if let file = baseFiles.first(where: { $0.url == exportFile.url }) {
                // Apply imported categories and tags
                for categoryString in exportFile.categories {
                    if let category = FileCategory(rawValue: categoryString) {
                        file.addToCategory(category)
                    }
                }
                
                for tag in exportFile.tags {
                    file.addTag(tag)
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case size = "Size"
    case dateModified = "Date Modified"
    case dateCreated = "Date Created"
    case path = "Path"
    case type = "Type"
    
    var id: String { rawValue }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case ascending = "Ascending"
    case descending = "Descending"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }
}

enum ViewMode: String, CaseIterable, Identifiable {
    case list = "List"
    case grid = "Grid"
    case table = "Table"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .list:
            return "list.bullet"
        case .grid:
            return "square.grid.2x2"
        case .table:
            return "tablecells"
        }
    }
}

// MARK: - Statistics

struct OrganizerStatistics {
    let files: [VirtualFile]
    
    var totalFiles: Int {
        files.count
    }
    
    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSize: String {
        FileSizeFormatter.formattedString(fromBytes: totalSize)
    }
    
    var categoryDistribution: [(FileCategory, Int)] {
        let categoryCounts = Dictionary(grouping: files) { file in
            file.categories.first ?? .unknown
        }.mapValues { $0.count }
        
        return FileCategory.allCases.compactMap { category in
            categoryCounts[category].map { count in
                (category, count)
            }
        }.sorted { $0.1 > $1.1 }
    }
    
    var tagDistribution: [(String, Int)] {
        let tagCounts = Dictionary(grouping: files.flatMap { $0.tags }) { tag in tag }
            .mapValues { $0.count }
        
        return tagCounts.sorted { $0.1 > $1.1 }.prefix(20).map { ($0.key, $0.value) }
    }
    
    var averageFileSize: Double {
        guard !files.isEmpty else { return 0 }
        return Double(totalSize) / Double(files.count)
    }
    
    var formattedAverageFileSize: String {
        FileSizeFormatter.formattedString(fromBytes: Int64(averageFileSize))
    }
    
    var largestFileSize: Int64 {
        files.map { $0.size }.max() ?? 0
    }
    
    var formattedLargestFileSize: String {
        FileSizeFormatter.formattedString(fromBytes: largestFileSize)
    }
    
    var oldestFile: VirtualFile? {
        files.min { file1, file2 in
            guard let date1 = file1.creationDate, let date2 = file2.creationDate else {
                return false
            }
            return date1 < date2
        }
    }
    
    var newestFile: VirtualFile? {
        files.max { file1, file2 in
            guard let date1 = file1.creationDate, let date2 = file2.creationDate else {
                return false
            }
            return date1 < date2
        }
    }
}

// MARK: - Export Data Types

struct OrganizationExportData: Codable {
    let files: [FileOrganizationExport]
    let exportDate: Date
}

struct FileOrganizationExport: Codable {
    let url: URL
    let name: String
    let categories: [String]
    let tags: [String]
}
