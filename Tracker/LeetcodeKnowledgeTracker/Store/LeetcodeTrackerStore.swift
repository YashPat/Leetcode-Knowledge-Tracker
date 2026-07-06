//
//  LeetcodeTrackerStore.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import Foundation
import SwiftData
import FSRS

/// Owns the `ModelContext`, seeds the fixed category list, and holds the
/// in-memory derived FSRS `Card` cache (Card is never persisted — see PRD §5/§7).
/// Exposes view-ready rows to the table.
@Observable
final class LeetcodeTrackerStore {
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let scheduler = FSRSScheduler()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// The PRD's fixed seed list of 22 categories (order = sortIndex).
    static let seedCategories: [String] = [
        "Array / String",
        "Two Pointers",
        "Sliding Window",
        "Prefix Sum",
        "Hash Map / Set",
        "Stack",
        "Queue",
        "Linked List",
        "Binary Tree - DFS",
        "Binary Tree - BFS",
        "Binary Search Tree",
        "Graphs - DFS",
        "Graphs - BFS",
        "Heap / Priority Queue",
        "Binary Search",
        "Backtracking",
        "DP - 1D",
        "DP - Multidimensional",
        "Bit Manipulation",
        "Trie",
        "Intervals",
        "Monotonic Stack",
    ]

    /// Inserts the 22 categories on first launch only, then primes the cache.
    func seedIfNeeded() {
        let existing = (try? modelContext.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard existing == 0 else {
            return
        }
        for (index, name) in Self.seedCategories.enumerated() {
            modelContext.insert(Category(name: name, sortIndex: index))
        }
        try? modelContext.save()
    }

    /// Builds one view-ready row from its `Category`, layering the derived FSRS
    /// values (retrievability/due) on top of the model. The view supplies the
    /// categories via `@Query`, so it observes model changes directly. `nil`
    /// retrievability/due == NEW.
    func row(for category: Category, now: Date = Date()) -> CategoryRow {
        return CategoryRow(
            category: category,
            retrievability: scheduler.retrievability(category.card, now: now),
            dueDate: category.card?.due,
            reps: category.totalReps,
            easyReps: category.easyReps,
            hardReps: category.hardReps,
            mediumReps: category.mediumReps
        )
    }

    /// Records one problem-solving event, then re-folds the category's Card.
    /// `sequence` uses the current log count as the monotonic insertion key.
    func log(category: Category, rating: Rating, problemDifficulty: ProblemDifficulty) {
        let card = category.card ?? Card()
        category.card = scheduler.updateCard(card: card, rating: rating) ?? card
        switch problemDifficulty {
            case .easy: category.easyReps += 1
            case .medium: category.mediumReps += 1
            case .hard: category.hardReps += 1
        }
        try? modelContext.save()
    }
}
