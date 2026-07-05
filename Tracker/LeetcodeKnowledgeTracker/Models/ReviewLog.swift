//
//  ReviewLog.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import Foundation
import SwiftData
import FSRS

/// A single problem-solving event: the source of truth for a category's FSRS
/// state. The library's value type is referenced as `FSRS.ReviewLog` where the
/// two would otherwise collide.
@Model
final class ReviewLog {
    var timestamp: Date
    /// Per-category monotonic insertion order; stable secondary sort key so a
    /// replay fold is deterministic when two logs share a timestamp.
    var sequence: Int
    var gradeRaw: String
    var difficultyRaw: String
    var category: Category?

    init(
        timestamp: Date,
        sequence: Int,
        grade: Grade,
        difficulty: Difficulty,
        category: Category? = nil
    ) {
        self.timestamp = timestamp
        self.sequence = sequence
        self.gradeRaw = grade.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.category = category
    }

    var grade: Grade { Grade(rawValue: gradeRaw) ?? .good }
    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .medium }
}

/// The recall grade fed to FSRS. Maps directly onto the library's `Rating`.
enum Grade: String, Codable, CaseIterable {
    case again, hard, good, easy

    var rating: Rating {
        switch self {
        case .again: .again
        case .hard: .hard
        case .good: .good
        case .easy: .easy
        }
    }
}

/// Self-reported problem difficulty. Captured for later insight only; never
/// touches the FSRS algorithm.
enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard
}
