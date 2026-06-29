//
//  LeetcodeKnowledgeTrackerApp.swift
//  LeetcodeKnowledgeTracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI
import SwiftData

@main
struct LeetcodeKnowledgeTrackerApp: App {
    let sharedModelContainer: ModelContainer
    @State private var store: ReviewStore

    init() {
        let schema = Schema([
            Category.self,
            ReviewLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let store = ReviewStore(modelContext: container.mainContext)
        store.seedIfNeeded()

        sharedModelContainer = container
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 760, height: 520)
        .modelContainer(sharedModelContainer)
        .environment(store)
    }
}
