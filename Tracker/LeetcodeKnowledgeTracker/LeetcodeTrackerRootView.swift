//
//  LeetcodeTrackerRootView.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftData
import SwiftUI

struct LeetcodeTrackerRootView: View {
    @State private var dependencies: LeetcodeTrackerDependencies

    init() {
        _dependencies = State(initialValue: LeetcodeTrackerDependencies())
    }

    var body: some View {
        LeetcodeTrackerView()
            .modelContainer(dependencies.modelContainer)
            .environment(dependencies.store)
    }
}

private struct LeetcodeTrackerDependencies {
    let modelContainer: ModelContainer
    let store: ReviewStore

    init(isStoredInMemoryOnly: Bool = false) {
        let schema = Schema([
            Category.self,
            ReviewLog.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        store = ReviewStore(modelContext: modelContainer.mainContext)
        store.seedIfNeeded()
    }
}

#Preview {
    let dependencies = LeetcodeTrackerDependencies(isStoredInMemoryOnly: true)

    return LeetcodeTrackerView()
        .modelContainer(dependencies.modelContainer)
        .environment(dependencies.store)
}
