import Foundation
import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class GoogleDriveManager: ObservableObject {
    private let service = GTLRDriveService()
    @Published var isUploading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var uploadProgress: Double = 0
    @Published var currentFolderStats: FolderStats = FolderStats()
       
       struct FolderStats {
           var imageCount: Int = 0
           var folderPath: String = ""
           var isLoading: Bool = false
       }
       
       // Add this new method
       func getFolderStats(path: String) {
           currentFolderStats.isLoading = true
           currentFolderStats.folderPath = path
           
           findOrCreateFolderPath(path: path) { [weak self] folderId in
               guard let self = self,
                     let folderId = folderId else {
                   DispatchQueue.main.async {
                       self?.currentFolderStats.isLoading = false
                       self?.currentFolderStats.imageCount = 0
                   }
                   return
               }
               
               let query = GTLRDriveQuery_FilesList.query()
               query.q = "'\(folderId)' in parents and mimeType contains 'image/' and trashed=false"
               
               self.service.executeQuery(query) { [weak self] (ticket, result, error) in
                   DispatchQueue.main.async {
                       guard let fileList = result as? GTLRDrive_FileList else {
                           self?.currentFolderStats.imageCount = 0
                           self?.currentFolderStats.isLoading = false
                           return
                       }
                       
                       self?.currentFolderStats.imageCount = fileList.files?.count ?? 0
                       self?.currentFolderStats.isLoading = false
                   }
               }
           }
       }
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
        with: config,
        presenting: rootViewController,
        hint: nil,
        additionalScopes: scopes
    ) { [weak self] signInResult, error in
        if let error = error {
            self?.showAlert(message: "Sign in error: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        guard let user = signInResult?.user,
              let accessToken = user.accessToken else {
            self?.showAlert(message: "Failed to get access token")
            completion(false)
            return
        }
        
        // Configure Drive service with the user's authorization
        self?.service.authorizer = user.authentication.fetcherAuthorizer()
        
        // Check if we have proper scopes
        if !user.grantedScopes.contains("https://www.googleapis.com/auth/drive.file") {
            self?.showAlert(message: "Drive access not granted")
            completion(false)
            return
        }
        
        completion(true)
    }
}
func signOut() {
    GIDSignIn.sharedInstance.signOut()
    service.authorizer = nil
    showAlert(message: "Signed out successfully")
}
    
    // MARK: - Image Upload
    
    func uploadImage(_ image: UIImage, toPath path: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(message: "Failed to process image")
            return
        }
        
        isUploading = true
        uploadProgress = 0
        
        findOrCreateFolderPath(path: path) { [weak self] folderId in
            guard let self = self,
                  let folderId = folderId else {
                self?.handleUploadFailure(message: "Failed to create/find folders")
                return
            }
            
            let metadata = GTLRDrive_File()
            metadata.name = "IMG_\(Date().timeIntervalSince1970).jpg"
            metadata.parents = [folderId]
            
            let uploadParameters = GTLRUploadParameters(data: imageData, mimeType: "image/jpeg")
            uploadParameters.shouldUploadWithSingleRequest = false
            
            let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: uploadParameters)
            
            // Progress tracking
            query.uploadProgressBlock = { [weak self] _, totalBytesUploaded, totalBytesExpectedToUpload in
                DispatchQueue.main.async {
                    self?.uploadProgress = Double(totalBytesUploaded) / Double(totalBytesExpectedToUpload)
                }
            }
            
            self.service.executeQuery(query) { [weak self] (ticket, file, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.handleUploadFailure(message: "Upload failed: \(error.localizedDescription)")
                    } else {
                        self?.handleUploadSuccess()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func findOrCreateFolderPath(path: String, completion: @escaping (String?) -> Void) {
        let components = path.split(separator: "/")
        var currentParentId = "root"
        
        func createNextFolder(index: Int) {
            if index >= components.count {
                completion(currentParentId)
                return
            }
            
            let folderName = String(components[index])
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "mimeType='application/vnd.google-apps.folder' and name='\(folderName)' and '\(currentParentId)' in parents and trashed=false"
            
            service.executeQuery(query) { [weak self] (ticket, result, error) in
                guard let self = self else { return }
                
                if let error = error {
                    completion(nil)
                    return
                }
                
                guard let fileList = result as? GTLRDrive_FileList else {
                    completion(nil)
                    return
                }
                
                if let existingFolder = fileList.files?.first {
                    currentParentId = existingFolder.identifier ?? ""
                    createNextFolder(index: index + 1)
                } else {
                    self.createFolder(named: folderName, inParent: currentParentId) { newFolderId in
                        if let newFolderId = newFolderId {
                            currentParentId = newFolderId
                            createNextFolder(index: index + 1)
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
        }
        
        createNextFolder(index: 0)
    }
    
    private func createFolder(named name: String, inParent parentId: String, completion: @escaping (String?) -> Void) {
        let folderMetadata = GTLRDrive_File()
        folderMetadata.name = name
        folderMetadata.mimeType = "application/vnd.google-apps.folder"
        folderMetadata.parents = [parentId]
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folderMetadata, uploadParameters: nil)
        
        service.executeQuery(query) { (ticket, folder, error) in
            if let newFolder = folder as? GTLRDrive_File {
                completion(newFolder.identifier)
            } else {
                completion(nil)
            }
        }
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
