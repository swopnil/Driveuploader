//
//  LoginView.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//

import Foundation
import SwiftUI
struct LoginView: View {
    @Binding var isSignedIn: Bool
    var driveManager: GoogleDriveManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Currency Drive Uploader")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Sign in with your Google account to start uploading currency images")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            SignInButton()
                .frame(width: 280, height: 50)
                .onTapGesture {
                    driveManager.signIn { success in
                        isSignedIn = success
                    }
                }
        }
        .padding()
    }
}
