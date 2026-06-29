//
//  ContentView.swift
//  LeetcodeKnowledgeTracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI

struct ContentView: View {
    private let rows = CategoryRow.mockRows
    @State private var sortOrder = [KeyPathComparator(\CategoryRow.retrievability)]

    private var sortedRows: [CategoryRow] {
        rows.sorted(using: sortOrder)
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

            DueForecast()
        }
    }

    private var table: some View {
        Table(sortedRows, sortOrder: $sortOrder) {
            TableColumn("Category", value: \.name) { row in
                Text(row.name)
                    .fontWeight(.medium)
            }

            TableColumn("Retrievability", value: \.retrievability) { row in
                RetrievabilityCell(value: row.retrievability, color: row.retrievabilityColor)
            }

            TableColumn("Due Date", value: \.dueUrgency) { row in
                Text(row.dueDate)
                    .foregroundStyle(row.dueUrgency.color)
                    .fontWeight(row.dueUrgency <= .today ? .semibold : .regular)
            }

            TableColumn("Reps", value: \.reps) { row in
                Text(row.reps, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .alignment(.numeric)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }
}

/// Compact memory-strength indicator: a colored fill bar plus the percentage,
/// so weak categories are visible at a glance instead of read one by one.
private struct RetrievabilityCell: View {
    let value: Double
    let color: Color

    var body: some View {
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
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

/// Placeholder forecast widget shown in the header. Real "next 7 days due" data arrives later.
private struct DueForecast: View {
    private let barHeights: [CGFloat] = [10, 18, 8, 24, 14, 20, 12]

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("Next 7 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { _, height in
                    Capsule()
                        .fill(.tint.opacity(0.6))
                        .frame(width: 6, height: height)
                }
            }
            .frame(height: 24, alignment: .bottom)
        }
        .accessibilityElement()
        .accessibilityLabel("Due forecast for the next 7 days")
        .help("Due forecast (placeholder)")
    }
}

#Preview {
    ContentView()
}
