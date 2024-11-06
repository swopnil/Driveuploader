import Foundation
import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class GoogleDriveManager: ObservableObject {
    private let service = GTLRDriveService()
    @Published var isUploading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var uploadingCount: Int = 0
    @Published var uploadProgress: Double = 0
    @Published var currentFolderStats: FolderStats = FolderStats()
    private var mainCurrencyFolderId: String?

    struct FolderStats {
        var imageCount: Int = 0
        var folderPath: String = ""
        var isLoading: Bool = false
    }

    // MARK: - Authentication
    
    func signIn(completion: @escaping (Bool) -> Void) {
        let config = GIDConfiguration(clientID: "614622386041-dmtrqad4nqnrsf56lv0sek35lkiobm8t.apps.googleusercontent.com")
        let scopes = [
            "https://www.googleapis.com/auth/drive.file",
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://www.googleapis.com/auth/userinfo.email"
        ]
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            showAlert(message: "Cannot find root view controller")
            completion(false)
            return
        }
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: scopes
        ) { [weak self] (signInResult: GIDSignInResult?, error: Error?) in
            if let error = error {
                self?.showAlert(message: "Sign in error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let user = signInResult?.user else {
                self?.showAlert(message: "Failed to get user")
                completion(false)
                return
            }
            
            self?.service.authorizer = user.fetcherAuthorizer
            
            guard let grantedScopes = user.grantedScopes,
                  grantedScopes.contains("https://www.googleapis.com/auth/drive.file") else {
                self?.showAlert(message: "Drive access not granted")
                completion(false)
                return
            }
            
            self?.initializeCurrencyFolder { success in
                if success {
                    completion(true)
                } else {
                    self?.showAlert(message: "Failed to initialize currency folder")
                    completion(false)
                }
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        service.authorizer = nil
        mainCurrencyFolderId = nil
        showAlert(message: "Signed out successfully")
    }

    // MARK: - Folder Management
    
    private func initializeCurrencyFolder(completion: @escaping (Bool) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "mimeType='application/vnd.google-apps.folder' and name='currency' and 'root' in parents and trashed=false"
        
        service.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
            if let fileList = result as? GTLRDrive_FileList,
               let folder = fileList.files?.first {
                self?.mainCurrencyFolderId = folder.identifier
                completion(true)
            } else {
                self?.createFolder(named: "currency", inParent: "root") { folderId in
                    self?.mainCurrencyFolderId = folderId
                    completion(folderId != nil)
                }
            }
        }
    }
    
    
    private func createFolderIfNeeded(named name: String, inParent parentId: String, completion: @escaping (String?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "mimeType='application/vnd.google-apps.folder' and name='\(name)' and '\(parentId)' in parents and trashed=false"
        
        service.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
            if let fileList = result as? GTLRDrive_FileList,
               let folder = fileList.files?.first {
                completion(folder.identifier)
            } else {
                self?.createFolder(named: name, inParent: parentId, completion: completion)
            }
        }
    }
    
    private func createFolder(named name: String, inParent parentId: String, completion: @escaping (String?) -> Void) {
        let folderMetadata = GTLRDrive_File()
        folderMetadata.name = name
        folderMetadata.mimeType = "application/vnd.google-apps.folder"
        folderMetadata.parents = [parentId]
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folderMetadata, uploadParameters: nil)
        
        service.executeQuery(query) { (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
            if let newFolder = result as? GTLRDrive_File {
                completion(newFolder.identifier)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Folder Stats
    func getFolderStats(path: String) {
        print("\n=== Starting Folder Stats ===")
        print("Getting stats for path: \(path)")
        currentFolderStats.isLoading = true
        currentFolderStats.folderPath = path
        
        let cleanPath = path.replacingOccurrences(of: "currency/", with: "")
        let components = cleanPath.components(separatedBy: "/")
        
        print("Clean path components: \(components)")
        
        guard components.count >= 3 else {
            print("Invalid path structure")
            DispatchQueue.main.async {
                self.currentFolderStats.isLoading = false
                self.currentFolderStats.imageCount = 0
            }
            return
        }
        
        let currencyValue = components[0]
        let sideFolderName = components[1]
        let locationFolderName = components[2]
        
        print("Looking for: Currency=\(currencyValue), Side=\(sideFolderName), Location=\(locationFolderName)")
        
        findFolder(path: [currencyValue, sideFolderName, locationFolderName]) { [weak self] folderId in
            guard let self = self else { return }
            print("Final folder ID found: \(folderId ?? "not found")")
            
            guard let folderId = folderId else {
                print("Failed to find target folder")
                DispatchQueue.main.async {
                    self.currentFolderStats.isLoading = false
                    self.currentFolderStats.imageCount = 0
                }
                return
            }
            
            // Create query with explicit parameters
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "'\(folderId)' in parents and (mimeType contains 'image/jpeg' or mimeType contains 'image/png') and trashed=false"
            query.fields = "files(id, name, mimeType)"
            query.pageSize = 1000  // Set a large page size
            query.spaces = "drive"
            
            print("Executing query with pageSize=1000") // Debug log
            
            self.service.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
                if let error = error {
                    print("Error fetching files: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.currentFolderStats.isLoading = false
                        self?.currentFolderStats.imageCount = 0
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    guard let fileList = result as? GTLRDrive_FileList,
                          let files = fileList.files else {
                        print("No file list returned")
                        self?.currentFolderStats.imageCount = 0
                        self?.currentFolderStats.isLoading = false
                        return
                    }
                    
                    let count = files.count
                    print("\n=== Files in folder ===")
                    print("Total files found: \(count)")
                    if count > 0 {
                        print("First file: \(files[0].name ?? "unnamed"), Type: \(files[0].mimeType ?? "unknown")")
                        if count > 1 {
                            print("Last file: \(files[count-1].name ?? "unnamed"), Type: \(files[count-1].mimeType ?? "unknown")")
                        }
                    }
                    print("========================")
                    
                    self?.currentFolderStats.imageCount = count
                    self?.currentFolderStats.isLoading = false
                    
                    // If there might be more files (pageToken exists), fetch the next page
                    if let pageToken = fileList.nextPageToken {
                        print("More files exist (nextPageToken present). Fetching next page...")
                        self?.fetchNextPage(folderId: folderId, pageToken: pageToken, currentCount: count)
                    }
                }
            }
        }
    }

    // Add this new method to handle pagination
    private func fetchNextPage(folderId: String, pageToken: String, currentCount: Int) {
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "'\(folderId)' in parents and (mimeType contains 'image/jpeg' or mimeType contains 'image/png') and trashed=false"
        query.fields = "files(id, name, mimeType)"
        query.pageSize = 1000
        query.pageToken = pageToken
        query.spaces = "drive"
        
        service.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
            if let error = error {
                print("Error fetching next page: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                guard let fileList = result as? GTLRDrive_FileList,
                      let files = fileList.files else {
                    return
                }
                
                let newCount = currentCount + files.count
                print("Additional \(files.count) files found. New total: \(newCount)")
                
                self?.currentFolderStats.imageCount = newCount
                
                // Continue fetching if there are more pages
                if let nextPageToken = fileList.nextPageToken {
                    self?.fetchNextPage(folderId: folderId, pageToken: nextPageToken, currentCount: newCount)
                }
            }
        }
    }       // MARK: - Create Currency Structure
       
       func createCurrencyStructure(currencyValue: String, completion: @escaping (Bool) -> Void) {
           guard let mainFolderId = mainCurrencyFolderId else {
               initializeCurrencyFolder { [weak self] success in
                   if success {
                       self?.createCurrencyStructure(currencyValue: currencyValue, completion: completion)
                   } else {
                       completion(false)
                   }
               }
               return
           }

           // Create currency value folder (e.g., "1", "5", etc.)
           createFolderIfNeeded(named: currencyValue, inParent: mainFolderId) { [weak self] currencyFolderId in
               guard let self = self, let currencyFolderId = currencyFolderId else {
                   completion(false)
                   return
               }
               
               let group = DispatchGroup()
               var success = true
               
               // Create front and back folders
               for side in ["front", "back"] {
                   group.enter()
                   let sideFolderName = "\(currencyValue)\(side)"
                   
                   self.createFolderIfNeeded(named: sideFolderName, inParent: currencyFolderId) { sideFolderId in
                       guard let sideFolderId = sideFolderId else {
                           success = false
                           group.leave()
                           return
                       }
                       
                       let locationGroup = DispatchGroup()
                       
                       // Create test and train folders
                       for location in ["test", "train"] {
                           locationGroup.enter()
                           self.createFolderIfNeeded(named: location, inParent: sideFolderId) { _ in
                               locationGroup.leave()
                           }
                       }
                       
                       locationGroup.notify(queue: .main) {
                           group.leave()
                       }
                   }
               }
               
               group.notify(queue: .main) {
                   completion(success)
               }
           }
       }
       
    
    
    // MARK: - Image Upload
    func uploadImage(_ image: UIImage, toPath path: String, completion: @escaping (Bool) -> Void = { _ in }) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to process image data") // Debug log
                completion(false)
                return
            }
            
            let components = path.components(separatedBy: "/")
            guard components.count >= 3 else {
                print("Invalid path structure: \(path)") // Debug log
                completion(false)
                return
            }
            
            let currencyValue = components[0]
            let sideFolderName = components[1]
            let locationFolderName = components[2]
            
            print("Starting upload for path: \(path)") // Debug log
            
            isUploading = true
            uploadProgress = 0
            uploadingCount += 1
            
            createCurrencyStructure(currencyValue: currencyValue) { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    print("Currency structure created successfully") // Debug log
                    guard let mainFolderId = self.mainCurrencyFolderId else {
                        print("Main folder ID not found") // Debug log
                        self.uploadingCount -= 1
                        completion(false)
                        return
                    }

                    // Find the currency value folder (e.g., "1")
                    self.findFolderInParent(named: currencyValue, parentId: mainFolderId) { currencyFolderId in
                        guard let currencyFolderId = currencyFolderId else {
                            print("Currency folder not found") // Debug log
                            self.uploadingCount -= 1
                            completion(false)
                            return
                        }
                        
                        // Find the side folder (e.g., "1front")
                        self.findFolderInParent(named: sideFolderName, parentId: currencyFolderId) { sideFolderId in
                            guard let sideFolderId = sideFolderId else {
                                print("Side folder not found: \(sideFolderName)") // Debug log
                                self.uploadingCount -= 1
                                completion(false)
                                return
                            }
                            
                            // Find location folder (test/train)
                            self.findFolderInParent(named: locationFolderName, parentId: sideFolderId) { locationFolderId in
                                guard let locationFolderId = locationFolderId else {
                                    print("Location folder not found: \(locationFolderName)") // Debug log
                                    self.uploadingCount -= 1
                                    completion(false)
                                    return
                                }
                                
                                // Upload the image to the final folder
                                let metadata = GTLRDrive_File()
                                metadata.name = "IMG_\(Date().timeIntervalSince1970).jpg"
                                metadata.parents = [locationFolderId]
                                
                                let uploadParameters = GTLRUploadParameters(data: imageData, mimeType: "image/jpeg")
                                uploadParameters.shouldUploadWithSingleRequest = false
                                
                                let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: uploadParameters)
                                
                                // Add upload progress monitoring
                                self.service.uploadProgressBlock = { _, sent, total in
                                    DispatchQueue.main.async {
                                        self.uploadProgress = Double(sent) / Double(total)
                                    }
                                }
                                
                                print("Starting actual file upload") // Debug log
                                self.service.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("Upload error: \(error.localizedDescription)") // Debug log
                                        } else {
                                            print("Upload completed successfully") // Debug log
                                        }
                                        
                                        self?.uploadingCount -= 1
                                        self?.uploadProgress = 1.0
                                        if self?.uploadingCount == 0 {
                                            self?.isUploading = false
                                        }
                                        
                                        // Reset upload progress block
                                        self?.service.uploadProgressBlock = nil
                                        
                                        // Update folder stats
                                        self?.getFolderStats(path: path)
                                        
                                        completion(error == nil)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print("Failed to create folder structure") // Debug log
                    self.uploadingCount -= 1
                    completion(false)
                }
        }
    }


        // New helper method to find folder in parent
        private func findFolderInParent(named name: String, parentId: String, completion: @escaping (String?) -> Void) {
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "mimeType='application/vnd.google-apps.folder' and name='\(name)' and '\(parentId)' in parents and trashed=false"
            query.fields = "files(id, name)"
            
            service.executeQuery(query) { (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
                if let fileList = result as? GTLRDrive_FileList,
                   let folder = fileList.files?.first {
                    completion(folder.identifier)
                } else {
                    completion(nil)
                }
            }
        }
    // MARK: - Helper Methods
    
    private func findFolder(path components: [String], completion: @escaping (String?) -> Void) {
        guard let mainFolderId = mainCurrencyFolderId else {
            completion(nil)
            return
        }
        
        var currentParentId = mainFolderId
        
        func findNextFolder(index: Int) {
            if index >= components.count {
                completion(currentParentId)
                return
            }
            
            let folderName = components[index]
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "mimeType='application/vnd.google-apps.folder' and name='\(folderName)' and '\(currentParentId)' in parents and trashed=false"
            
            service.executeQuery(query) { (ticket: GTLRServiceTicket, result: Any?, error: Error?) in
                if let fileList = result as? GTLRDrive_FileList,
                   let folder = fileList.files?.first {
                    currentParentId = folder.identifier ?? ""
                    findNextFolder(index: index + 1)
                } else {
                    completion(nil)
                }
            }
        }
        
        findNextFolder(index: 0)
    }
    
    private func handleUploadSuccess() {
        isUploading = false
        uploadProgress = 1.0
        showAlert(message: "Image uploaded successfully")
    }
    
    private func handleUploadFailure(message: String) {
        isUploading = false
        uploadProgress = 0
        showAlert(message: message)
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
