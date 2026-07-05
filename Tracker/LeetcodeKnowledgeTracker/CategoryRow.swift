//
//  CategoryRow.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI

/// View model for one table row. Wraps the `Category` model so the on/off Toggle
/// can bind directly to it (SwiftData `@Model`s are observable). The card-derived
/// fields are snapshots supplied by the store. `nil` retrievability/dueDate means
/// the category has never been logged (NEW).
struct CategoryRow: Identifiable {
    /// The underlying model — the source of truth the Toggle binds into.
    let category: Category
    /// Retrievability as a fraction in 0...1 (rendered as a percentage). nil = NEW.
    let retrievability: Double?
    /// Next FSRS due date. nil = NEW.
    let dueDate: Date?
    let reps: Int
    let easyReps: Int
    let hardReps: Int
    let mediumReps: Int

    var id: UUID { category.id }
    var name: String { category.name }
    /// Whether the user is actively tracking this category. Inactive rows can't
    /// be logged and show no due date.
    var isActive: Bool { category.isActive }

    /// Comparable key that pins active categories to the top under an ascending
    /// sort (Bool itself isn't Comparable, so we can't sort on `isActive`).
    var activeSortKey: Int { isActive ? 0 : 1 }
}

extension CategoryRow {
    /// Color encoding memory strength: stronger memories trend green, weaker ones red.
    var retrievabilityColor: Color {
        guard let retrievability else { return .secondary }
        switch retrievability {
        case 0.8...: return .green
        case 0.65..<0.8: return .yellow
        case 0.5..<0.65: return .orange
        default: return .red
        }
    }

    /// Sort key that keeps NEW categories pinned to the top under an ascending
    /// sort, followed by the weakest (lowest retrievability) categories.
    var retrievabilitySortKey: Double {
        retrievability ?? -1
    }

    /// How urgently this category needs review, derived from the FSRS due date
    /// vs now. Lower `rawValue` sorts first, so NEW then overdue items lead.
    enum DueUrgency: Int, Comparable {
        case new, overdue, today, tomorrow, soon, later

        static func < (lhs: DueUrgency, rhs: DueUrgency) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var color: Color {
            switch self {
            case .new: return .secondary
            case .overdue, .today: return .red
            case .tomorrow: return .orange
            case .soon, .later: return .secondary
            }
        }
    }

    var dueUrgency: DueUrgency {
        // Inactive categories aren't scheduled, so they carry no urgency styling.
        guard isActive else { return .later }
        guard let dueDate else { return .new }
        let now = Date()
        // PRD §6: overdue is evaluated against the exact FSRS due timestamp.
        if dueDate <= now { return .overdue }

        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) { return .today }
        if calendar.isDateInTomorrow(dueDate) { return .tomorrow }

        let days = calendar.dateComponents([.day], from: now, to: dueDate).day ?? 0
        return days <= 3 ? .soon : .later
    }

    /// Display text for the Due Date column. NEW shows an em-dash (the NEW state
    /// is already conveyed by the Retrievability cell).
    var dueText: String {
        // Inactive categories show no due date.
        guard isActive else { return "—" }
        guard let dueDate else { return "—" }
        if dueDate <= Date() { return "Overdue" }
        return dueDate.formatted(.relative(presentation: .named))
    }
}
