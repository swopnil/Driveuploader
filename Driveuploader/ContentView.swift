

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
    @State private var isSignedIn = false
    @StateObject private var uploadQueueManager: UploadQueueManager
        
    // Currency management states
    @State private var currencies = ["1", "10", "20", "50", "100"]
    @State private var showingAddCurrency = false
    @State private var newCurrencyValue = ""
       init() {
           let driveManager = GoogleDriveManager()
           _driveManager = StateObject(wrappedValue: driveManager)
           _uploadQueueManager = StateObject(wrappedValue: UploadQueueManager(driveManager: driveManager))
       }

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
                        
                        // Folder Stats View
                        FolderStatsView(driveManager: driveManager,
                                      currency: selectedCurrency,
                                      side: selectedSide,
                                      location: selectedLocation)
                        .padding(.horizontal)
                        
                        // Path Card
                        PathCard(currency: selectedCurrency,
                                side: selectedSide,
                                location: selectedLocation)
                        .padding(.horizontal)
                        
                  
                    
                        
                        // Selection Options with Add Currency Button
                        VStack(spacing: 20) {
                            // Currency Selection with Add Button
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Currency")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showingAddCurrency = true
                                    }) {
                                        Label("Add Currency", systemImage: "plus.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // Currency options grid
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80), spacing: 10)
                                ], spacing: 10) {
                                    ForEach(currencies, id: \.self) { currency in
                                        Button(action: {
                                            selectedCurrency = currency
                                            print("Currency changed to: \(currency)")  // Debug print
                                            // Force folder stats update
                                            driveManager.getFolderStats(path: "currency/\(currency)/\(currency)\(selectedSide)/\(selectedLocation)")
                                        }) {
                                            Text(currency)
                                                .fontWeight(.medium)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(selectedCurrency == currency ? Color.blue : Color.gray.opacity(0.1))
                                                )
                                                .foregroundColor(selectedCurrency == currency ? .white : .primary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .gray.opacity(0.2), radius: 5)
                            )
                            
                            // Other selection cards with explicit update calls
                            SelectionCard(title: "Side",
                                         options: sides,
                                         selection: $selectedSide)
                                .onChange(of: selectedSide) { newSide in
                                    print("Side changed to: \(newSide)")  // Debug print
                                    driveManager.getFolderStats(path: "currency/\(selectedCurrency)/\(selectedCurrency)\(newSide)/\(selectedLocation)")
                                }
                            
                            SelectionCard(title: "Location",
                                         options: locations,
                                         selection: $selectedLocation)
                                .onChange(of: selectedLocation) { newLocation in
                                    print("Location changed to: \(newLocation)")  // Debug print
                                    driveManager.getFolderStats(path: "currency/\(selectedCurrency)/\(selectedCurrency)\(selectedSide)/\(newLocation)")
                                }
                        }
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
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .gray.opacity(0.2), radius: 5)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        // Fix the spacing (there's an extra space after the colon)
                        
                        ActionButtonsView(isImagePickerPresented: $isImagePickerPresented,
                                         driveManager: driveManager,
                                         folderPath: "\(selectedCurrency)/\(selectedCurrency)\(selectedSide)/\(selectedLocation)")


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
                .sheet(isPresented: $showingAddCurrency) {
                    addCurrencySheet
                }
                .sheet(isPresented: $isImagePickerPresented) {
                        CameraView(
                            folderPath: "\(selectedCurrency)/\(selectedCurrency)\(selectedSide)/\(selectedLocation)",
                            queueManager: uploadQueueManager
                        )
                    }

            }
        }
            }
    
    // Add Currency Sheet
    private var addCurrencySheet: some View {
        NavigationView {
            Form {
                Section(header: Text("New Currency")) {
                    TextField("Currency Value", text: $newCurrencyValue)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddCurrency = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if !newCurrencyValue.isEmpty {
                            withAnimation {
                                currencies.append(newCurrencyValue)
                                currencies.sort { Int($0) ?? 0 < Int($1) ?? 0 }
                                selectedCurrency = newCurrencyValue
                                // Add this line to create folder structure
                                driveManager.createCurrencyStructure(currencyValue: newCurrencyValue) { _ in }
                            }
                            newCurrencyValue = ""
                            showingAddCurrency = false
                        }
                    }
                    .disabled(newCurrencyValue.isEmpty)
                }
            }
        }
    }
}
