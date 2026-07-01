//
//  ContentView.swift
//  LeetcodeKnowledgeTracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ReviewStore.self) private var store

    // Observes the model context directly, so toggling `isActive` or adding a
    // log re-runs the body without any manual refresh signal.
    @Query(sort: [SortDescriptor(\Category.sortIndex)]) private var categories: [Category]

    // Default: NEW pinned top, then ascending retrievability (weakest first).
    @State private var sortOrder = [KeyPathComparator(\CategoryRow.retrievabilitySortKey)]

    // Which row's Log popover is open, and the difficulty chosen inside it.
    @State private var loggingRowID: UUID?
    @State private var logDifficulty: Difficulty = .medium

    private var sortedRows: [CategoryRow] {
        // Active categories pin to the top; the user's chosen sort is the tiebreaker.
        categories
            .map { store.row(for: $0) }
            .sorted(using: [KeyPathComparator(\.isActive, order: .reverse)] + sortOrder)
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

            TableColumn("Reps", value: \.reps) { row in
                Text(row.reps, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TableColumn("") { row in
                Button("Log") { loggingRowID = row.id }
                    .disabled(!row.isActive)
                    .popover(isPresented: logPopoverBinding(for: row.id)) {
                        LogPopover(categoryName: row.name, difficulty: $logDifficulty) { grade in
                            store.log(row.category, grade: grade, difficulty: logDifficulty)
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

/// Quick grade + difficulty capture for logging one problem-solving event.
private struct LogPopover: View {
    let categoryName: String
    @Binding var difficulty: Difficulty
    let onLog: (Grade) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(categoryName)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Difficulty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Grade")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(Grade.allCases, id: \.self) { grade in
                        Button(grade.rawValue.capitalized) { onLog(grade) }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 300)
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
        for: Category.self, ReviewLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = ReviewStore(modelContext: container.mainContext)
    store.seedIfNeeded()
    return ContentView()
        .modelContainer(container)
        .environment(store)
}
