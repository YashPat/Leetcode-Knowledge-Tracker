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

    func updateCard(card: Card, rating: Rating) -> Card?{
        let record = try? fsrs.next(card: card,now: Date.now,grade: rating)
        return record?.card
    }

    /// Live recall probability in `0...1` against `now`. `nil` card -> `nil`.
    func retrievability(_ card: Card?, now: Date) -> Double? {
        guard let card else { return nil }
        return fsrs.getRetrievability(card: card, now: now).number
    }
}
