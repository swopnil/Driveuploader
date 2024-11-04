//
//  Item.swift
//  Driveuploader
//
//  Created by Swopnil Panday on 11/4/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
