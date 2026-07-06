//
//  Category.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import Foundation
import SwiftData
import FSRS

/// A LeetCode problem category — the unit FSRS schedules.
@Model
final class Category {
    var id: UUID
    var name: String
    /// Preserves the PRD's fixed 22-item ordering for stable display.
    var sortIndex: Int
    /// Whether the user is actively tracking this category. Inactive categories
    /// can't be logged and show no due date. Defaults off; opt-in per category.
    var isActive: Bool = false

    var easyReps: Int = 0
    var mediumReps: Int = 0
    var hardReps: Int = 0

    var totalReps: Int {
        return easyReps + mediumReps + hardReps
    }

    var card: Card?

    init(id: UUID = UUID(), name: String, sortIndex: Int) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
    }
}
