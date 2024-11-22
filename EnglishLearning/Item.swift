//
//  Item.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/11/22.
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
