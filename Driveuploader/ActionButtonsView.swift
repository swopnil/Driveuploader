import SwiftUI
import UIKit
import AVFoundation

struct ActionButtonsView: View {
    @Binding var isImagePickerPresented: Bool
    var driveManager: GoogleDriveManager
    var folderPath: String
    
    @State private var showingPermissionAlert = false
    
    var body: some View {
        // Only Camera Button
        Button(action: { checkCameraPermission() }) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.title2)
                Text("Take Photo")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text("Please allow camera access in Settings to take photos.")
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isImagePickerPresented = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isImagePickerPresented = true
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            showingPermissionAlert = true
        }
    }
}
