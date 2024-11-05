//
//  ImagePreviewView.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//
import UIKit
import SwiftUI
import Foundation
struct ImagePreviewView: View {
    let image: UIImage?
    let folderPath: String
    var driveManager: GoogleDriveManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                
                Text("Upload to: \(folderPath)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                
                Button(action: {
                    if let image = image {
                        driveManager.uploadImage(image, toPath: folderPath)
                        isPresented = false
                    }
                }) {
                    Text("Confirm Upload")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding()
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
