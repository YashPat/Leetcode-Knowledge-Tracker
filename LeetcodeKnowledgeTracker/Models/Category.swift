//
//  Category.swift
//  LeetcodeKnowledgeTracker
//
//  Created by Yash Patil on 6/28/26.
//

import Foundation
import SwiftData

/// A LeetCode problem category — the unit FSRS schedules. Its memory state is
/// not stored here: it is recomputed by replaying `logs` (see `FSRSScheduler`).
@Model
final class Category {
    var id: UUID
    var name: String
    /// Preserves the PRD's fixed 22-item ordering for stable display.
    var sortIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.category)
    var logs: [ReviewLog]

    init(id: UUID = UUID(), name: String, sortIndex: Int) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.logs = []
    }
}
