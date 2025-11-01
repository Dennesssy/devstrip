import SwiftUI

struct VirtualFolderView: View {
    let category: FileCategory
    let files: [VirtualFile]
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @State private var selectedFiles: Set<VirtualFile.ID> = []
    
    private var filteredFiles: [VirtualFile] {
        if searchText.isEmpty {
            return files
        } else {
            return files.filter { file in
                file.name.localizedCaseInsensitiveContains(searchText) ||
                file.originalPath.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: category.iconName)
                        .foregroundColor(category.color)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(category.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("\(files.count) files • \(totalSize)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search files...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // File list
            Group {
                if filteredFiles.isEmpty {
                    EmptyStateView(
                        systemImage: category.iconName,
                        title: searchText.isEmpty ? "No Files" : "No Results",
                        subtitle: searchText.isEmpty ? 
                            "No files found in this category" : 
                            "No files match your search"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredFiles) { file in
                                FileRow(
                                    file: file,
                                    isSelected: selectedFiles.contains(file.id),
                                    onSelectionChange: { isSelected in
                                        if isSelected {
                                            selectedFiles.insert(file.id)
                                        } else {
                                            selectedFiles.remove(file.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color(.controlBackgroundColor))
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Select All") {
                        selectedFiles = Set(filteredFiles.map { $0.id })
                    }
                    .disabled(filteredFiles.isEmpty)
                    
                    Button("Deselect All") {
                        selectedFiles.removeAll()
                    }
                    .disabled(selectedFiles.isEmpty)
                    
                    Divider()
                    
                    Button("Delete Selected", role: .destructive) {
                        // Handle deletion
                    }
                    .disabled(selectedFiles.isEmpty)
                } label: {
                    Text("\(selectedFiles.count) selected")
                }
            }
        }
    }
    
    private var totalSize: String {
        let total = files.reduce(0) { $0 + $1.size }
        return FileSizeFormatter.formattedString(fromBytes: total)
    }
}

struct FileRow: View {
    let file: VirtualFile
    let isSelected: Bool
    let onSelectionChange: (Bool) -> Void
    
    var body: some View {
        HStack {
            // Selection checkbox
            Button {
                onSelectionChange(!isSelected)
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // File icon
            Image(systemName: file.iconName)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body)
                    .lineLimit(1)
                
                Text(file.originalPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(file.formattedSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let modifiedDate = file.formattedModificationDate {
                        Text("• \(modifiedDate)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.borderless)
                .font(.caption)
                
                Button("Open") {
                    NSWorkspace.shared.open(file.url)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 8)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NavigationView {
        VirtualFolderView(
            category: .developmentTools,
            files: [
                VirtualFile(url: URL(fileURLWithPath: "/Users/test/Projects/app/src/main.swift")),
                VirtualFile(url: URL(fileURLWithPath: "/Users/test/Projects/app/package.json"))
            ]
        )
    }
}
