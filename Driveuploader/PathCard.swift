//
//  PathCard.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//
import SwiftUI
import Foundation
struct PathCard: View {
    let currency: String
    let side: String
    let location: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upload Path")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("\(currency)/\(currency)\(side)/\(location)")
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5)
        )
    }
}

