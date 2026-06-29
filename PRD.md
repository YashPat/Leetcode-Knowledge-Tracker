# PRD — LeetCode Spaced-Repetition Tracker

> Status: **MVP scope locked.** Personal tool. Decisions below are locked unless under "Deferred / Post-MVP."

## 1. Overview

A personal macOS app to manage **spaced repetition for LeetCode problem *categories*** (e.g. Dynamic Programming, Graphs), not individual problems. When a category is due, the user reviews it by solving problems and rating each one; the tool uses **FSRS** to schedule the next review and to surface what's "due today."

## 2. Goals

- Log problem-solving as spaced-repetition review events, per category.
- Tell the user each day which categories are **due**.
- Handle missed/overdue reviews gracefully, according to the FSRS learning algorithm.
- Lay the **data foundation** for stats & retention insights over time (full review history is stored from day one). Rich stats are post-MVP; see §10 and §12.
- Unify the *learning* and *retention* phases under a single mechanism (FSRS).

## 3. Non-Goals (current scope)

- Not tracking a library of individual problems (no problem numbers/titles/URLs).
- No multi-user support (single personal user).
- FSRS parameter *personalization* is deferred (defaults used initially).
- No iOS/iPadOS in MVP (macOS only; SwiftUI keeps a future port open).

## 4. Tech Stack (locked)

- **Language/UI:** Swift + SwiftUI.
- **Platform:** macOS only (MVP). **Deployment target: macOS 26 (Tahoe)** — enables Liquid Glass and the latest SwiftUI/SwiftData APIs.
- **Persistence:** SwiftData (SQLite-backed). Schema kept export-friendly so a JSON backup/restore can be added post-MVP.
- **Scheduling library:** [swift-fsrs](https://github.com/open-spaced-repetition/swift-fsrs).
  - **FSRS-6** (21-weight, `FSRSDefaults.defaultWv6`) with `enableShortTerm = true`.
  - **Learning/relearning steps are empty** (`learningSteps: []`, `relearningSteps: []`) — see §7.

## 5. Core Concepts & Model

- **Category = the FSRS-scheduled unit.** There is exactly one FSRS memory state (stability/difficulty/state/due) per category, expressed as a swift-fsrs `Card`.
- **A "review event" = solving one problem in that category.** Every problem solved is logged and feeds the category's FSRS state.
- **`ReviewLog` is the source of truth; the `Card` is a derived cache (locked).** A category's FSRS state is defined as the result of **replaying** its `ReviewLog` history through FSRS in timestamp order — never as a value mutated forward in place. The `Card` stored on the `Category` is a cached projection of that fold, recomputed on any change to the category's logs (see §7, §9). This is an architectural decision made now so undo/edit/delete and history-based re-optimization remain possible; the *UI* for editing logs is **not** in MVP (see §12).
- **Per-problem rating** (not per-session). The user rates each problem as they finish it.
- **Learning and retention are unified.** FSRS's short-term/same-day behavior covers the learning grind; no separate learning phase or manual status. A new or just-failed category *may* come due again the same day (drill-while-learning); a mature category rides long intervals. Same-day repeats are **offered, never forced**.
- **The due list is a menu, not a mandate.** It shows what's available to review, prioritized. The user chooses how much to do. No streaks, no quotas, no guilt UI. Volume per day is entirely user-controlled.
- **Difficulty escalation (Medium → Hard):** *deferred to post-MVP.* MVP records the difficulty actually solved but does not prescribe escalation.
- **Difficulty is a pure data-capture field (locked).** The recorded `difficulty` (Easy / Medium / Hard) has **zero effect on FSRS scheduling** in MVP — it is **never** passed to swift-fsrs and never influences the `Card`, intervals, retrievability, or the due list. Only the FSRS `grade` (Again / Hard / Good / Easy) drives scheduling. Difficulty is stored solely as history to enable post-MVP escalation and stats.

## 6. Rating Scale

- FSRS native **4-grade** scale: **Again / Hard / Good / Easy**.

## 7. Scheduling Algorithm: FSRS

- Algorithm: **FSRS-6** via swift-fsrs, `enableShortTerm = true`.
- **Empty learning/relearning steps (locked):** `learningSteps: []` and `relearningSteps: []`. The two settings are deliberately separated:
  - **`enableShortTerm = true`** is kept on so that *voluntary* same-day repeats are scored with FSRS's same-day stability math (dampened, not over-rewarded) instead of being mis-modeled as day-scale events. This is what §5/§7's "same-day bursts are handled by FSRS's short-term model" relies on.
  - **Empty steps** mean a new or just-lapsed category graduates to a multi-day interval after a **single** solve — FSRS never forces a same-day "grind ladder." This matches the product philosophy: one genuine problem-solve (20–40 min of real engagement, not a flashcard glance) is treated as sufficient evidence; a category leaves the due list the moment it's reviewed once, and the user is never pressured to repeat it the same day. Waiting days between reviews is fine and is *rewarded* by intrinsic overdue handling.
  - **Self-correction over up-front confirmation:** the (small) risk of empty steps — a single shaky pass earning a generous first interval — is accepted because (a) the user expresses uncertainty through the **grade** (a rough pass → **Hard**, which already yields a shorter first interval than **Good**), and (b) FSRS contracts intervals automatically on the next lower grade. No permanent mis-scheduling results.
- **Desired retention:** fixed at **0.85** in MVP (hardcoded). A user-facing slider is **deferred to post-MVP**.
- **Day boundary (locked):** "due" / "overdue" is evaluated against the exact FSRS `due` timestamp — a category is **overdue** when `due <= now`. Anything shown in *calendar-day* terms (the Due Date column's relative wording and the due-forecast buckets) is grouped by the user's **local calendar day** (local-midnight boundaries, device time zone). So "due today" = `due` falls within today's local day.
- **Parameters/weights:** start on **FSRS defaults** (works from the first log). Full review history is stored so **personalized re-optimization** can be added later (post-MVP).
- **Overdue handling is intrinsic.** FSRS schedules from *actual elapsed time*. A late-but-passed review is automatically rewarded; a skipped day simply leaves the item sitting as "due" until done. Reset/penalty only comes from a genuine low grade (Again), never from lateness.
- **Early / redundant practice is self-regulating.** FSRS dampens stability gains when retrievability is already high. **Same-day bursts** are handled by FSRS's short-term model.
- **Operating rule:** log *every* problem as a review event and feed them all to FSRS; trust the algorithm (no manual per-day aggregation, no early/late special-casing).
- **State is always a replay, never a one-way mutation (locked).** A category's `Card` is computed as `fold(next, over: logs sorted by timestamp)` starting from a fresh `Card`. Replay advances the card using each log's **own timestamp** (retrievability shown in the UI is a separate computation against `now`). Determinism: logs are ordered by `timestamp`, with a stable secondary key (insertion sequence) to break ties. Cache rule: **any mutation to a category's logs invalidates and recomputes that category's cached `Card`.** Backdated / out-of-order logs are handled intrinsically because the fold always sorts first.
- **Logging is unrestricted:** the user can log a problem for **any** category at any time, not just ones currently due. The due list is only the suggested starting point.

## 8. Categories

- MVP ships a **fixed seeded list of 22** categories. Add/rename/retire is **deferred to post-MVP**.
- Seed list (22):
  1. Array / String
  2. Two Pointers
  3. Sliding Window
  4. Prefix Sum
  5. Hash Map / Set
  6. Stack
  7. Queue
  8. Linked List
  9. Binary Tree - DFS
  10. Binary Tree - BFS
  11. Binary Search Tree
  12. Graphs - DFS
  13. Graphs - BFS
  14. Heap / Priority Queue
  15. Binary Search
  16. Backtracking
  17. DP - 1D
  18. DP - Multidimensional
  19. Bit Manipulation
  20. Trie
  21. Intervals
  22. Monotonic Stack

## 9. Data Model

**Category** (`@Model`)

- `id`
- `name`
- **Cached** FSRS memory state (a swift-fsrs `Card`: `stability`, `difficulty`, `state`, `due`, `lastReview`, `scheduledDays`, `reps`, `lapses`, `learningSteps`). This is a **derived projection** of the category's `ReviewLog`s (see §5/§7), persisted only as a read cache so the table doesn't re-fold on every render. It must always equal `replay(sortedLogs)`; treat it as disposable.

**ReviewLog** (`@Model`, one per problem solved) — **source of truth**

- `category` (ref)
- `timestamp`
- `sequence` (monotonic insertion order; secondary sort key for deterministic replay on timestamp ties)
- `grade` (Again / Hard / Good / Easy) — **the only field fed to FSRS.**
- `difficulty` (Easy / Medium / Hard) — **data-capture only; never affects scheduling in MVP** (see §5).

*(No problem identity, no time-taken, no notes — by decision.)*

> `Reps` (the table column) = **count of `ReviewLog` rows** for the category (lifetime review events), not the FSRS `Card.reps` field (which can reset on lapse).

## 10. UI (MVP)

**One screen. One table.** No sidebar, no separate Stats/Settings/Categories screens. All 22 categories are present from day one (no on/off — see §12). A category that has never been logged shows as **NEW** until its first review event creates an FSRS `Card`.

### 10.1 Main view

**Header**

- App title.
- **Due forecast** (compact): an at-a-glance summary of upcoming workload — how many categories come due over the next stretch of days (e.g. a small sparkline / "next 7 days" mini-bar). It lives in the header, not a separate screen.
- A **Log** button (primary action) that opens the log flow.

**Table** — one row per category. Columns:


| Column             | Meaning                                                                                                                   |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| **Category**       | Category name.                                                                                                            |
| **Retrievability** | Live recall probability % (derived from FSRS stability + elapsed time). Shows **NEW** (no %) for never-logged categories. |
| **Due Date**       | FSRS-scheduled next review date; overdue shown distinctly (e.g. red/orange).                                              |
| **Reps**           | Total review events logged for this category.                                                                             |


- **Default sort:** lowest retrievability first (most at risk on top); **NEW** categories pinned to the top.
- It's a **menu, not a mandate** — no cap, no streaks, no quotas. The table shows everything; the user decides what to practice.
- **"What's due" is conveyed by the Due Date column alone** (overdue styled distinctly). There is intentionally no separate "due today" filter, badge, or section in MVP — the date column plus the risk-ordered sort is enough.
- *(Stability and lapses are tracked internally by FSRS but not shown as columns in MVP.)*

> **On stats:** MVP deliberately ships only this table + header forecast. Because full review history and FSRS state are persisted from day one, richer insight is purely additive later — either by **adding columns** to this table (e.g. stability, lapses) or by letting the user **tap a row to expand into a per-category stats view**. Neither is built in MVP; see §12.

### 10.2 Log flow

Opened via the **Log** button (and optionally by selecting a row to prefill the category):

- Pick **any** category.
- Four grade buttons (**Again / Hard / Good / Easy**), each showing the **predicted next interval** (via swift-fsrs `repeat`/preview).
- Pick the **difficulty solved** (Easy / Medium / Hard).
- Save → creates a `ReviewLog` and advances the category's FSRS `Card` via `next(card:now:grade:)`.

## 11. Phasing

1. **Core engine** — SwiftData store + swift-fsrs (v6, short-term) scheduling + "due today" logic, UI-agnostic and testable. Centerpiece is a pure **`replay([ReviewLog]) -> Card`** fold plus recompute-on-write of the cached `Card`; this is the primary unit-tested surface (no SwiftData/UI needed to test it).
2. **MVP UI** — the single-table main view + log flow above.
3. **Post-MVP** (see below).

## 12. Deferred / Post-MVP

- **Edit / undo / delete review events.** The replay architecture (§5/§7) already makes this safe and cheap — delete/edit/insert a `ReviewLog`, then recompute the cached `Card`. MVP ships the architecture but **no editing UI**; this item is the UI (e.g. delete/undo last log, edit a past grade).
- **Difficulty escalation** Medium → Hard (trigger TBD: candidates = stability/interval threshold + min successful reps, or manual graduation).
- **Category management:** add / rename / retire via soft `isActive`, with `isSeeded` for "reset to default 22"; never hard-delete (would orphan logs).
- **Desired-retention slider** (user-adjustable; MVP hardcodes 0.85).
- **On/off per category** (activate/deactivate tracking) — considered and **cut from MVP**; all 22 are always active. May return as part of category management.
- **Expanded stats** (two complementary paths, see §10.1): (a) **more columns** on the main table — stability, lapses; (b) **tap a category row to expand into a dedicated per-category stats view**. Plus a fuller due-forecast / history view beyond the header summary.
- **Backup:** one-button JSON **export + import** of all categories, full review history, and FSRS state.
- **Advanced stats:** per-category forgetting curves, overall mastery score/heatmap, activity history & grade distribution, measured retention (predicted vs actual pass rate).
- **FSRS parameter personalization** (optimizer over stored history).
- **iOS/iPadOS** port + iCloud sync.

