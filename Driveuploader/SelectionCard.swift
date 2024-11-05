//
//  SelectionCard.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//
import SwiftUI
import Foundation
struct SelectionCard: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        withAnimation {
                            selection = option
                        }
                    }) {
                        Text(option)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selection == option ? Color.blue : Color.gray.opacity(0.1))
                            )
                            .foregroundColor(selection == option ? .white : .primary)
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
    }
}
