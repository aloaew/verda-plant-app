import SwiftUI
import EventKit
import Foundation
struct DayDetailView: View {
    let date: Date
    var events: [EventItem]
    @State private var showingAddEvent = false
    @Binding var allEvents: [EventItem]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.title2)
                    .padding()
                
                
                if events.isEmpty {
                    Text("No events scheduled for this day")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(events) { event in
                            EventRow(event: event)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            
           
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(events: $allEvents, date: date)
        }
        .navigationTitle("Day Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
