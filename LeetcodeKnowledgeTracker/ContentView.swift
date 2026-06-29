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

    // Default: NEW pinned top, then ascending retrievability (weakest first).
    @State private var sortOrder = [KeyPathComparator(\CategoryRow.retrievabilitySortKey)]

    private var sortedRows: [CategoryRow] {
        store.rows().sorted(using: sortOrder)
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
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .font(.title2)
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
        .environment(store)
}
