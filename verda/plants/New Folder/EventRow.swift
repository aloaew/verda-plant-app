//
//  EventRow.swift
//  plants
//
//  Created by Aya on 29.03.2025.
//


import SwiftUI

struct EventRow: View {
    let event: EventItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.icon)
                .foregroundColor(event.color)
                .frame(width: 24, height: 24)
                .padding(8)
                .background(event.color.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(event.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy"
        return df.string(from: date)
    }
    
    private func daysAgo(_ date: Date) -> Int {
        let diff = Date().timeIntervalSince(date)
        return max(0, Int(diff / (24 * 3600)))
    }
}
