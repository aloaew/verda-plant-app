import SwiftUI
import Charts

struct StatisticsView: View {
    let logs: [GrowthLog]

    var sortedLogs: [GrowthLog] {
        logs.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Статистика роста")
                        .font(.title)
                        .bold()
                        .padding()

                    if sortedLogs.isEmpty {
                        Text("Нет данных для отображения.")
                            .foregroundStyle(.gray)
                    } else {
                       
                        VStack(alignment: .leading) {
                            Text("Рост растения (см)")
                                .font(.headline)
                                .padding(.leading)

                            Chart {
                                ForEach(sortedLogs) { log in
                                    LineMark(
                                        x: .value("Дата", log.date),
                                        y: .value("Высота (см)", log.height)
                                    )
                                    .foregroundStyle(.blue)
                                }
                            }
                            .frame(height: 300)
                            .padding()
                        }

                        
                        VStack(alignment: .leading) {
                            Text("Влажность (%)")
                                .font(.headline)
                                .padding(.leading)

                            Chart {
                                ForEach(sortedLogs) { log in
                                    BarMark(
                                        x: .value("Дата", log.date),
                                        y: .value("Влажность (%)", Double(log.humidityNotes) ?? 0)
                                    )
                                    .foregroundStyle(.green)
                                    .opacity(0.5)
                                }

                                ForEach(sortedLogs) { log in
                                    AreaMark(
                                        x: .value("Дата", log.date),
                                        y: .value("Влажность (%)", Double(log.humidityNotes) ?? 0)
                                    )
                                    .foregroundStyle(.green.opacity(0.3))
                                }
                            }
                            .frame(height: 300)
                            .padding()
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Графики")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }

    @Environment(\.dismiss) var dismiss
}
