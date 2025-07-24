//
//  Item.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
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
