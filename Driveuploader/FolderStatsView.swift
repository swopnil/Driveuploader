import SwiftUI
struct FolderStatsView: View {
    @ObservedObject var driveManager: GoogleDriveManager
    let currency: String
    let side: String
    let location: String
    
    @State private var currentPath: String = ""
    
    var folderPath: String {
        PathConstructor.getStatsPath(currency: currency, side: side, location: location)
    }
    
    private func calculateFillRatio(_ count: Int) -> Double {
        // Dynamic scaling based on count
        if count == 0 { return 0 }
        if count <= 10 { return Double(count) / 10.0 }
        if count <= 100 { return Double(count) / 100.0 }
        return Double(count) / Double(max(count, 1000))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Current Folder")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(folderPath)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if driveManager.currentFolderStats.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "photo.stack")
                        Text("\(driveManager.currentFolderStats.imageCount)")
                            .font(.headline)
                            .monospacedDigit()
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Progress bar with dynamic scaling
            GeometryReader { geometry in
                let fillWidth = geometry.size.width * calculateFillRatio(driveManager.currentFolderStats.imageCount)
                
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // Filled portion
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: fillWidth, height: 6)
                }
            }
            .frame(height: 6)
            
            // Image count details
            if !driveManager.currentFolderStats.isLoading {
                Text("\(driveManager.currentFolderStats.imageCount) total images")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5)
        )
        .onChange(of: currency) { _ in
            updateStats()
        }
        .onChange(of: side) { _ in
            updateStats()
        }
        .onChange(of: location) { _ in
            updateStats()
        }
        .onAppear {
            updateStats()
        }
        .id(folderPath)
    }
    
    private func updateStats() {
        let newPath = folderPath
        print("FolderStatsView: Path changed to \(newPath)")
        if currentPath != newPath {
            currentPath = newPath
            driveManager.getFolderStats(path: newPath)
        }
    }
}
