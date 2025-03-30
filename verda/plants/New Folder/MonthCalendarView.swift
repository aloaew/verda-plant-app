import SwiftUI

/// Represents an event with an icon and color
struct DayEvent: Identifiable {
    let id = UUID()
    let icon: String      // e.g. "drop.fill"
    let color: Color      // e.g. .blue
}


struct MonthCalendarView: View {
    @State private var displayedMonth: Date = Date()
    private let calendar = Calendar.current
    
    
    private let sampleEvents: [Date: [DayEvent]] = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        
        return [
            formatter.date(from: "2025-03-10")!: [
                DayEvent(icon: "drop.fill", color: .green),
                DayEvent(icon: "flame.fill", color: .teal)
            ],
            formatter.date(from: "2025-03-15")!: [
                DayEvent(icon: "leaf.fill", color: .green)
            ],
            formatter.date(from: "2025-03-20")!: [
                DayEvent(icon: "bandage.fill", color: .mint),
                DayEvent(icon: "drop.fill", color: .pink),
            ],
            formatter.date(from: "2025-03-06")!: [
                DayEvent(icon: "leaf.fill", color: .green),
                DayEvent(icon: "flame.fill", color: .red)
            ],
        ]
    }()
    
    var body: some View {
        VStack {
           
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
                Spacer()
                
                Text(monthTitle(displayedMonth))
                    .font(.title2)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                
                
                
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
           
            HStack {
                ForEach(weekdaySymbols(), id: \.self) { symbol in
                    Text(symbol)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.8))
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
            
            
            let days = generateDays(for: displayedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days.indices, id: \.self) { index in
                    if let dayDate = days[index] {
                       
                        let dayEvents = sampleEvents[calendar.startOfDay(for: dayDate)] ?? []
                        
                      
                        NavigationLink(destination: RecentsView()) {
                            DayCellView(dayDate: dayDate, events: dayEvents)
                        }
                    } else {
                        
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Day Cell View

struct DayCellView: View {
    let dayDate: Date
    let events: [DayEvent]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            
            Text("\(calendar.component(.day, from: dayDate))")
                .font(.body)
                .foregroundColor(.primary)
            
            
            if !events.isEmpty {
                HStack(spacing: 4) {
                    ForEach(events) { event in
                        Image(systemName: event.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundColor(event.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(4)
    }
}

// MARK: - Calendar Logic
extension MonthCalendarView {
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func monthTitle(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy" // e.g. "March 2025"
        return df.string(from: date)
    }
    
    private func weekdaySymbols() -> [String] {
        
        return calendar.shortWeekdaySymbols
    }
    
   
    private func generateDays(for date: Date) -> [Date?] {
        guard
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
            let rangeOfDays = calendar.range(of: .day, in: .month, for: startOfMonth)
        else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = firstWeekday - calendar.firstWeekday
        let leadingEmptyDays = offset < 0 ? offset + 7 : offset
        
        var daysArray: [Date?] = Array(repeating: nil, count: 42)
        
        for day in rangeOfDays { // e.g. 1..31
            let index = leadingEmptyDays + (day - 1)
            if index < 42 {
                daysArray[index] = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
            }
        }
        
        return daysArray
    }
}
