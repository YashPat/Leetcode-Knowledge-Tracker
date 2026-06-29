//
//  CategoryRow.swift
//  LeetcodeKnowledgeTracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI

struct CategoryRow: Identifiable {
    let id = UUID()
    let name: String
    /// Retrievability as a fraction in 0...1 (rendered as a percentage).
    let retrievability: Double
    let dueDate: String
    let reps: Int
}

extension CategoryRow {
    /// Color encoding memory strength: stronger memories trend green, weaker ones red.
    var retrievabilityColor: Color {
        switch retrievability {
        case 0.8...: .green
        case 0.65..<0.8: .yellow
        case 0.5..<0.65: .orange
        default: .red
        }
    }

    /// How urgently this category needs review, derived from the (placeholder) due-date text.
    /// Lower `rank` sorts first, so the most overdue items lead when sorting by due date.
    enum DueUrgency: Int, Comparable {
        case overdue, today, tomorrow, soon, later

        static func < (lhs: DueUrgency, rhs: DueUrgency) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var color: Color {
            switch self {
            case .overdue, .today: .red
            case .tomorrow: .orange
            case .soon, .later: .secondary
            }
        }
    }

    var dueUrgency: DueUrgency {
        switch dueDate.lowercased() {
        case "overdue": .overdue
        case "today": .today
        case "tomorrow": .tomorrow
        case let value where value.contains("2 days") || value.contains("3 days"): .soon
        default: .later
        }
    }
}

extension CategoryRow {
    /// Mock data for the skeleton UI. Replaced by SwiftData-backed rows later.
    static let mockRows: [CategoryRow] = [
        CategoryRow(name: "Arrays & Hashing", retrievability: 0.92, dueDate: "in 5 days", reps: 18),
        CategoryRow(name: "Two Pointers", retrievability: 0.87, dueDate: "in 3 days", reps: 12),
        CategoryRow(name: "Sliding Window", retrievability: 0.74, dueDate: "tomorrow", reps: 9),
        CategoryRow(name: "Stack", retrievability: 0.81, dueDate: "in 4 days", reps: 7),
        CategoryRow(name: "Binary Search", retrievability: 0.66, dueDate: "today", reps: 11),
        CategoryRow(name: "Linked List", retrievability: 0.88, dueDate: "in 6 days", reps: 14),
        CategoryRow(name: "Trees", retrievability: 0.59, dueDate: "today", reps: 21),
        CategoryRow(name: "Tries", retrievability: 0.71, dueDate: "in 2 days", reps: 4),
        CategoryRow(name: "Heap / Priority Queue", retrievability: 0.63, dueDate: "tomorrow", reps: 6),
        CategoryRow(name: "Backtracking", retrievability: 0.55, dueDate: "today", reps: 8),
        CategoryRow(name: "Graphs", retrievability: 0.48, dueDate: "overdue", reps: 10),
        CategoryRow(name: "Dynamic Programming", retrievability: 0.42, dueDate: "overdue", reps: 16),
        CategoryRow(name: "Greedy", retrievability: 0.69, dueDate: "in 2 days", reps: 5),
        CategoryRow(name: "Intervals", retrievability: 0.77, dueDate: "in 3 days", reps: 6),
        CategoryRow(name: "Math & Geometry", retrievability: 0.83, dueDate: "in 5 days", reps: 7),
        CategoryRow(name: "Bit Manipulation", retrievability: 0.91, dueDate: "in 7 days", reps: 4),
    ]
}
