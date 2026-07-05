//
//  RootTabView.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            LeetcodeTrackerRootView()
                .tabItem {
                    Label("LeetCode", systemImage: "brain.head.profile")
                }

            HabitTrackerView()
                .tabItem {
                    Label("Habits", systemImage: "checklist")
                }
        }
    }
}

#Preview {
    RootTabView()
}
