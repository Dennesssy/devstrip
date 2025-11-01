import SwiftUI

struct ScanningProgressView: View {
    @ObservedObject var scannerViewModel: FileScannerViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.blue)
                .symbolEffect(.pulse, isActive: scannerViewModel.isScanning)
            
            Text("Scanning Files...")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Current: \(scannerViewModel.currentScanPath)")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                ProgressView(value: scannerViewModel.scanProgress)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text("\(scannerViewModel.filesScanned) files scanned")
                    Spacer()
                    Text("\(Int(scannerViewModel.scanProgress * 100))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            
            if !scannerViewModel.scanErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Errors:")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(scannerViewModel.scanErrors.enumerated()), id: \.offset) { index, error in
                                Text("• \(error)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 40)
            }
            
            Button("Stop Scanning", role: .destructive) {
                scannerViewModel.stopScan()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ScanningProgressView(scannerViewModel: FileScannerViewModel())
}
