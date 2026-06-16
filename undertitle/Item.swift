//
//  Item.swift
//  undertitle
//
//  Created by Carlos Laguna Medina on 15/6/26.
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
