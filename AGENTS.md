# AGENTS.md

Personal macOS app for spaced-repetition over LeetCode problem *categories* (FSRS-scheduled).
Swift + SwiftUI + SwiftData + [swift-fsrs](https://github.com/open-spaced-repetition/swift-fsrs). macOS 26 target.

## PRD

`PRD.md` is the product context — read it to understand intent and the locked decisions.
Treat it as a **guide, not gospel**: it reflects the plan at a point in time, the code may have
moved on, and pragmatic deviations are fine. When code and PRD disagree, trust the code and flag
the drift rather than blindly "fixing" code to match the doc.

## Layout

- `LeetcodeKnowledgeTracker/Engine/` — `FSRSScheduler`: pure FSRS wrapper, no SwiftData/UI.
- `LeetcodeKnowledgeTracker/Store/` — `ReviewStore`: owns `ModelContext`, seeds categories, holds the derived `Card` cache.
- `LeetcodeKnowledgeTracker/Models/` — `Category`, `ReviewLog` (`@Model`s).
- `LeetcodeKnowledgeTracker/*.swift` — app entry + views (`ContentView`, `CategoryRow`).

## Build

Open `LeetcodeKnowledgeTracker.xcodeproj` in Xcode, or `xcodebuild -scheme LeetcodeKnowledgeTracker`.
No test target exists yet — `FSRSScheduler.replay` is the natural first thing to unit-test.

## Core invariants

- `ReviewLog` is the source of truth; a `Card` is a **derived projection** = `replay(sortedLogs)`.
  Never mutate a card forward in place. Any change to a category's logs recomputes its card.
- `difficulty` (Easy/Med/Hard) is data-capture only — **never** fed to FSRS. Only `grade` drives scheduling.
- The `Card` cache is in-memory and disposable; it is not persisted.
