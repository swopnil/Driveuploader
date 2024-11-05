//
//  SignInButton.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//
import SwiftUI
import GoogleSignIn

import Foundation
import SwiftUI
// SignInButton.swift
struct SignInButton: UIViewRepresentable {
    func makeUIView(context: Context) -> GIDSignInButton {
        return GIDSignInButton()
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
}
