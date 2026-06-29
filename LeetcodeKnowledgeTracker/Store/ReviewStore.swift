//
//  ReviewStore.swift
//  LeetcodeKnowledgeTracker
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
final class ReviewStore {
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let scheduler = FSRSScheduler()

    /// Derived cache: `Category.id -> replayed Card`. Absent key == NEW.
    private var cards: [UUID: Card] = [:]

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
            recomputeAll()
            return
        }
        for (index, name) in Self.seedCategories.enumerated() {
            modelContext.insert(Category(name: name, sortIndex: index))
        }
        try? modelContext.save()
        recomputeAll()
    }

    /// Re-folds every category's logs into its cached Card.
    func recomputeAll() {
        let categories = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        for category in categories { recompute(category) }
    }

    /// Re-runs `replay` for one category and updates the cache.
    func recompute(_ category: Category) {
        let events = category.logs.map {
            FSRSScheduler.Event(timestamp: $0.timestamp, sequence: $0.sequence, rating: $0.grade.rating)
        }
        cards[category.id] = scheduler.replay(events)
    }

    /// View-ready rows in display order. `nil` retrievability/due == NEW.
    func rows(now: Date = Date()) -> [CategoryRow] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortIndex)])
        let categories = (try? modelContext.fetch(descriptor)) ?? []
        return categories.map { category in
            let card = cards[category.id]
            return CategoryRow(
                id: category.id,
                name: category.name,
                retrievability: scheduler.retrievability(card, now: now),
                dueDate: card?.due,
                reps: category.logs.count
            )
        }
    }
}
