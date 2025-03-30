import SwiftUI

struct CalendarTab: View {
    var body: some View {
        NavigationView {
            MonthCalendarView()
                .navigationTitle("Календарь")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
