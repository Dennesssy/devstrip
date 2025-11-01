import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: FileCategory?
    @State private var scannerViewModel = FileScannerViewModel()
    @State private var organizerViewModel = OrganizerViewModel()
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with categories
            CategorySidebar(
                categories: organizerViewModel.categories,
                selectedCategory: $selectedCategory
            )
        } detail: {
            // Main content area
            Group {
                if scannerViewModel.isScanning {
                    ScanningProgressView(scannerViewModel: scannerViewModel)
                } else if let category = selectedCategory {
                    VirtualFolderView(
                        category: category,
                        files: organizerViewModel.filesForCategory(category)
                    )
                } else {
                    WelcomeView(
                        onStartScan: {
                            scannerViewModel.startScan()
                        }
                    )
                }
            }
            .navigationTitle("Virtual File Organizer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Scan", systemImage: "magnifyingglass") {
                        scannerViewModel.startScan()
                    }
                }
            }
        }
        .onReceive(scannerViewModel.$scanResults) { results in
            organizerViewModel.processScanResults(results)
        }
    }
}

struct WelcomeView: View {
    let onStartScan: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Virtual File Organizer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Organize scattered development files into logical virtual groups without moving them.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Start Scanning", systemImage: "magnifyingglass") {
                onStartScan()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
