//
//  LeetcodeTrackerView.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI
import SwiftData
import FSRS

struct LeetcodeTrackerView: View {
    @Environment(ReviewStore.self) private var store

    // Observes the model context directly, so toggling `isActive` or adding a
    // log re-runs the body without any manual refresh signal.
    @Query(sort: [SortDescriptor(\Category.sortIndex)]) private var categories: [Category]

    // Default: NEW pinned top, then ascending retrievability (weakest first).
    @State private var sortOrder = [KeyPathComparator(\CategoryRow.retrievabilitySortKey)]

    // Which row's Log popover is open, and the difficulty chosen inside it.
    @State private var loggingRowID: UUID?
    @State private var logProblemDifficulty: ProblemDifficulty = .medium

    private var sortedRows: [CategoryRow] {
        // Active categories pin to the top; the user's chosen sort is the tiebreaker.
        categories
            .map { store.row(for: $0) }
            .sorted(using: [KeyPathComparator(\.activeSortKey)] + sortOrder)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            table
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("LeetCode Tracker")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Spacer()
        }
    }

    private var table: some View {
        Table(sortedRows, sortOrder: $sortOrder) {
            TableColumn("") { row in
                Toggle("Track \(row.name)", isOn: Bindable(row.category).isActive)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    // Table reuses row views (NSTableView). Pinning identity to the
                    // row makes SwiftUI rebuild the switch fresh on reuse instead of
                    // animating the underlying NSSwitch into its new state as it
                    // scrolls in (which looks like the toggle flipping on by itself).
                    .id(row.id)
            }
            .width(44)

            TableColumn("Category", value: \.name) { row in
                Text(row.name)
                    .fontWeight(.medium)
            }

            TableColumn("Retrievability", value: \.retrievabilitySortKey) { row in
                RetrievabilityCell(value: row.retrievability, color: row.retrievabilityColor)
            }

            TableColumn("Due Date", value: \.dueUrgency) { row in
                Text(row.dueText)
                    .foregroundStyle(row.dueUrgency.color)
            }

            TableColumn("Easy Reps", value: \.easyReps) { row in
                Text(row.easyReps, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TableColumn("Medium Reps", value: \.mediumReps) { row in
                Text(row.mediumReps, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TableColumn("Hard Reps", value: \.hardReps) { row in
                Text(row.hardReps, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TableColumn("TotalReps", value: \.reps) { row in
                Text(row.reps, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TableColumn("") { row in
                Button("Log") { loggingRowID = row.id }
                    .disabled(!row.isActive)
                    .popover(isPresented: logPopoverBinding(for: row.id)) {
                        LogPopover(categoryName: row.name, problemDifficulty: $logProblemDifficulty) { rating in
                            store.log(category: row.category, rating: rating, problemDifficulty: logProblemDifficulty)
                            loggingRowID = nil
                        }
                    }
            }
            .width(64)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .font(.title2)
    }

    private func logPopoverBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { loggingRowID == id },
            set: { if !$0, loggingRowID == id { loggingRowID = nil } }
        )
    }
}

/// Quick rating + difficulty capture for logging one problem-solving event.
private struct LogPopover: View {
    let categoryName: String
    @Binding var problemDifficulty: ProblemDifficulty
    let onLog: (Rating) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text(categoryName)
                .font(.largeTitle)
                .fontWeight(.bold)

            section("Problem Difficulty") {
                HStack(spacing: 14) {
                    ForEach(ProblemDifficulty.allCases, id: \.self) { level in
                        Button {
                            problemDifficulty = level
                        } label: {
                            pillLabel(level.rawValue.capitalized)
                        }
                        .buttonStyle(.bordered)
                        .tint(problemDifficulty == level ? .accentColor : nil)
                    }
                }
            }

            section("Rating") {
                HStack(spacing: 14) {
                    ForEach([Rating.again, .hard, .good, .easy], id: \.self) { rating in
                        Button {
                            onLog(rating)
                        } label: {
                            pillLabel(rating.stringValue.capitalized)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(28)
        .frame(width: 460)
    }

    private func pillLabel(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

/// Compact memory-strength indicator: a colored fill bar plus the percentage,
/// so weak categories are visible at a glance instead of read one by one.
/// Never-logged categories show NEW instead of a bar.
private struct RetrievabilityCell: View {
    let value: Double?
    let color: Color

    var body: some View {
        if let value {
            HStack(spacing: 8) {
                Capsule()
                    .fill(.quaternary)
                    .frame(width: 56, height: 6)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(color)
                            .frame(width: 56 * value, height: 6)
                    }

                Text(value, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("NEW")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Category.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = ReviewStore(modelContext: container.mainContext)
    store.seedIfNeeded()
    return LeetcodeTrackerView()
        .modelContainer(container)
        .environment(store)
}
