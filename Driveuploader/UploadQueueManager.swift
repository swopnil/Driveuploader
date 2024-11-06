//
//  UploadQueueManager.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/5/24.
//

// First, let's create a new Upload Queue Manager
import SwiftUI
class UploadQueueManager: ObservableObject {
    @Published var uploadQueue: [(UIImage, String)] = []
    @Published var isProcessing = false
    let driveManager: GoogleDriveManager
    
    init(driveManager: GoogleDriveManager) {
        self.driveManager = driveManager
    }
    
    func addToQueue(image: UIImage, path: String) {
        DispatchQueue.main.async {
            self.uploadQueue.append((image, path))
            if !self.isProcessing {
                self.processQueue()
            }
        }
    }
    
    private func processQueue() {
        guard !isProcessing, !uploadQueue.isEmpty else { return }
        
        isProcessing = true
        let (image, path) = uploadQueue.removeFirst()
        
        print("Processing upload: \(uploadQueue.count + 1) remaining") // Debug log
        
        driveManager.uploadImage(image, toPath: path) { [weak self] success in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let remainingUploads = self?.uploadQueue.count, remainingUploads > 0 {
                    self?.processQueue()
                }
                print("Upload completed. Success: \(success). Remaining: \(self?.uploadQueue.count ?? 0)") // Debug log
            }
        }
    }
}
