//
//  ContentView.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//

import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST
import PhotosUI

struct ContentView: View {
    @StateObject private var driveManager = GoogleDriveManager()
    @State private var selectedCurrency = "1"
    @State private var selectedSide = "front"
    @State private var selectedLocation = "train"
    @State private var isImagePickerPresented = false
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var isSignedIn = false
    @State private var previewImage: UIImage? = nil
    @State private var showPreview = false
    @Environment(\.colorScheme) var colorScheme
    
    let currencies = ["1", "10", "20", "50", "100"]
    let sides = ["front", "back"]
    let locations = ["train", "test"]
    
    var body: some View {
        NavigationStack {
            if !isSignedIn {
                LoginView(isSignedIn: $isSignedIn, driveManager: driveManager)
            } else {
                ScrollView {
                    VStack(spacing: 25) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upload Images")
                                .font(.largeTitle)
                                .bold()
                            Text("Select options and upload currency images")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        FolderStatsView(driveManager: driveManager,
                                      currency: selectedCurrency,
                                      side: selectedSide,
                                      location: selectedLocation)
                        .padding(.horizontal)
                        
                        // Current Selection Card
                        PathCard(currency: selectedCurrency,
                                side: selectedSide,
                                location: selectedLocation)
                        .padding(.horizontal)
                        // Current Selection Card
                        PathCard(currency: selectedCurrency,
                                side: selectedSide,
                                location: selectedLocation)
                        .padding(.horizontal)
                        
                        // Selection Options
                        SelectionView(selectedCurrency: $selectedCurrency,
                                    selectedSide: $selectedSide,
                                    selectedLocation: $selectedLocation,
                                    currencies: currencies,
                                    sides: sides,
                                    locations: locations)
                        .padding(.horizontal)
                        
                        // Upload Status (if uploading)
                        if driveManager.isUploading {
                            HStack(spacing: 15) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Uploading to Drive...")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(colorScheme == .dark ? Color.black : Color.white)
                                    .shadow(color: .gray.opacity(0.2), radius: 5)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        ActionButtonsView(isImagePickerPresented: $isImagePickerPresented,
                                        selectedImage: $selectedImage,
                                        driveManager: driveManager) { image in
                            previewImage = image
                            showPreview = true
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                withAnimation {
                                    isSignedIn = false
                                    driveManager.signOut()
                                }
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .sheet(isPresented: $showPreview) {
                    ImagePreviewView(image: previewImage,
                                   folderPath: "\(selectedCurrency)/\(selectedCurrency)\(selectedSide)/\(selectedLocation)",
                                   driveManager: driveManager,
                                   isPresented: $showPreview)
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    CameraView { image in
                        if let image = image {
                            previewImage = image
                            showPreview = true
                        }
                        isImagePickerPresented = false
                    }
                }
            }
        }
        .alert("Upload Status", isPresented: $driveManager.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(driveManager.alertMessage)
        }
    }
}

