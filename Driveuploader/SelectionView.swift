//
//  SelectionView.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//
import SwiftUI
import Foundation
struct SelectionView: View {
    @Binding var selectedCurrency: String
    @Binding var selectedSide: String
    @Binding var selectedLocation: String
    let currencies: [String]
    let sides: [String]
    let locations: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            SelectionCard(title: "Currency",
                         options: currencies,
                         selection: $selectedCurrency)
            
            SelectionCard(title: "Side",
                         options: sides,
                         selection: $selectedSide)
            
            SelectionCard(title: "Location",
                         options: locations,
                         selection: $selectedLocation)
        }
    }
}

