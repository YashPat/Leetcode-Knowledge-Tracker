//
//  HabitTrackerView.swift
//  Tracker
//
//  Created by Yash Patil on 6/28/26.
//

import SwiftUI

struct HabitTrackerView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Habit Tracker")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Coming soon")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HabitTrackerView()
}
