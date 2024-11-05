//
//  ActionButtonsView.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//
import SwiftUI
import PhotosUI
import UIKit
import Foundation
struct ActionButtonsView: View {
    @Binding var isImagePickerPresented: Bool
    @Binding var selectedImage: PhotosPickerItem?
    var driveManager: GoogleDriveManager
    var onImageSelected: (UIImage) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Camera Button
            Button(action: { isImagePickerPresented.toggle() }) {
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
            
            // Photo Library Button
            PhotosPicker(selection: $selectedImage,
                        matching: .images) {
                HStack {
                    Image(systemName: "photo.fill")
                        .font(.title2)
                    Text("Choose from Library")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .onChange(of: selectedImage) { newValue in
                handleImageSelection()
            }
        }
    }
    
    private func handleImageSelection() {
        guard let selectedImage = selectedImage else { return }
        
        Task {
            if let data = try? await selectedImage.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                onImageSelected(image)
            }
        }
    }
}
