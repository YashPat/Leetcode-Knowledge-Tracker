//
//  FSRSScheduler.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import Foundation
import FSRS

/// Pure FSRS wrapper: no SwiftData, no UI. Folds a category's review history
/// into an FSRS `Card` and reads live retrievability. Operates on lightweight
/// `Event` values so it stays unit-testable in isolation.
struct FSRSScheduler {
    /// One review event reduced to exactly what the fold needs.
    struct Event {
        let timestamp: Date
        let sequence: Int
        let rating: Rating
    }

    private let fsrs: FSRS

    init() {
        fsrs = FSRS(parameters: .init(
            requestRetention: 0.85,
            w: FSRSDefaults.defaultWv6,
            enableShortTerm: true,
            learningSteps: [],
            relearningSteps: []
        ))
    }

    /// Replay events in `(timestamp, sequence)` order, advancing the card using
    /// each event's own timestamp. Empty history -> `nil` (a NEW category).
    func replay(_ events: [Event]) -> Card? {
        let ordered = events.sorted { lhs, rhs in
            lhs.timestamp == rhs.timestamp
                ? lhs.sequence < rhs.sequence
                : lhs.timestamp < rhs.timestamp
        }
        guard !ordered.isEmpty else { return nil }

        var card = Card()
        for event in ordered {
            guard let next = try? fsrs.next(card: card, now: event.timestamp, grade: event.rating) else {
                continue
            }
            card = next.card
        }
        return card
    }

    /// Live recall probability in `0...1` against `now`. `nil` card -> `nil`.
    func retrievability(_ card: Card?, now: Date) -> Double? {
        guard let card else { return nil }
        return fsrs.getRetrievability(card: card, now: now).number
    }
}
