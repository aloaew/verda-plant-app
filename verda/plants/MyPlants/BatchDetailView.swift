import SwiftUI
import PhotosUI
import Charts

struct GrowthLog: Identifiable, Codable {
    let id: UUID
    let date: Date
    let changes: String
    let height: Double
    let wateringNotes: String
    let lightingNotes: String
    let humidityNotes: String
    let imageData: Data?
}

struct BatchDetailView: View {
    let batch: MicrogreenBatch
    @State private var logs: [GrowthLog] = []
    @State private var showAddLogView = false
    @State private var showStatisticsView = false
    @State private var selectedLog: GrowthLog?
    
    let storageKey: String
    
    // Вычисляемые свойства для статистики
    private var daysSinceSowing: Int {
        Calendar.current.dateComponents([.day], from: batch.sowingDate, to: Date()).day ?? 0
    }
    
    private var daysUntilHarvest: Int {
        max(0, batch.harvestTime - daysSinceSowing)
    }
    
    private var growthProgress: Double {
        min(Double(daysSinceSowing) / Double(batch.harvestTime), 1.0)
    }
    
    private var isReadyToHarvest: Bool {
        daysSinceSowing >= batch.harvestTime
    }

    init(batch: MicrogreenBatch) {
        self.batch = batch
        self.storageKey = "growthLogs_\(batch.id.uuidString)"
    }

    var body: some View {
        ZStack {
            // Фоновый градиент
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "F5FDF4"), Color(hex: "E8F5E9")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок с основной информацией
                    VStack(spacing: 16) {
                        Text(batch.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "2E7D32"))
                        
                        // Прогресс роста
                        VStack(spacing: 8) {
                            HStack {
                                Text("Прогресс роста")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(growthProgress * 100))%")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color(hex: "2E7D32"))
                            }
                            
                            ProgressView(value: growthProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "4CAF50")))
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        }
                        
                        // Статус готовности
                        if isReadyToHarvest {
                            Label("Готово к сбору!", systemImage: "checkmark.seal.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color(hex: "4CAF50")))
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Статистические карточки
                    HStack(spacing: 15) {
                        StatCard(icon: "calendar", value: "\(daysSinceSowing)", label: "Дней с посева", color: Color(hex: "2196F3"))
                        StatCard(icon: "clock", value: "\(daysUntilHarvest)", label: "Дней до сбора", color: Color(hex: "FF9800"))
                        StatCard(icon: "chart.bar", value: "\(logs.count)", label: "Записей", color: Color(hex: "9C27B0"))
                    }
                    .padding(.horizontal)
                    
                    // График роста (если есть данные)
                    if !logs.isEmpty {
                        GrowthChartView(logs: logs)
                            .frame(height: 220)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                            .onTapGesture {
                                showStatisticsView.toggle()
                            }
                    }
                    
                    // Раздел журнала роста
                    VStack(spacing: 15) {
                        HStack {
                            Text("Журнал роста")
                                .font(.title3.bold())
                                .foregroundColor(Color(hex: "2E7D32"))
                            
                            Spacer()
                            
                            Button {
                                showAddLogView.toggle()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "4CAF50"))
                            }
                        }
                        .padding(.horizontal, 25)
                        
                        if logs.isEmpty {
                            EmptyStateView()
                        } else {
                            ForEach(logs.sorted { $0.date > $1.date }) { log in
                                GrowthLogCard(log: log) {
                                    selectedLog = log
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteLog(log)
                                        }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Детали партии")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLogs()
        }
        .sheet(isPresented: $showAddLogView) {
            AddGrowthLogView(logs: $logs, storageKey: storageKey)
        }
        .sheet(isPresented: $showStatisticsView) {
            StatisticsView(logs: logs)
        }
        .sheet(item: $selectedLog) { log in
            LogDetailView(log: log)
        }
    }
    
    // MARK: - Вспомогательные функции
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadLogs() {
        if let savedData = UserDefaults.standard.data(forKey: storageKey),
           let decodedLogs = try? JSONDecoder().decode([GrowthLog].self, from: savedData) {
            logs = decodedLogs.sorted { $0.date > $1.date }
        }
    }
    
    private func deleteLog(_ log: GrowthLog) {
        logs.removeAll { $0.id == log.id }
        saveLogs()
    }
}

// MARK: - Компоненты

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct GrowthLogCard: View {
    let log: GrowthLog
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(log.date, style: .date)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", log.height)) см")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "4CAF50"))
                }
                
                if !log.changes.isEmpty {
                    Text(log.changes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let imageData = log.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GrowthChartView: View {
    let logs: [GrowthLog]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Динамика роста")
                .font(.subheadline.bold())
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            Chart {
                ForEach(logs.sorted { $0.date < $1.date }) { log in
                    LineMark(
                        x: .value("Дата", log.date, unit: .day),
                        y: .value("Высота", log.height)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color(hex: "4CAF50").gradient)
                    
                    PointMark(
                        x: .value("Дата", log.date, unit: .day),
                        y: .value("Высота", log.height)
                    )
                    .symbolSize(15)
                    .foregroundStyle(Color(hex: "2E7D32"))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("Нет записей о росте")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Добавьте первую запись, чтобы отслеживать прогресс")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(40)
    }
}

struct LogDetailView: View {
    let log: GrowthLog
    @Environment(\.dismiss) var dismiss
    @State private var isImageFullscreen = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновый градиент
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "F5FDF4"), Color(hex: "E8F5E9")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Заголовок с датой
                        VStack(spacing: 8) {
                            Text(log.date.formatted(date: .complete, time: .omitted))
                                .font(.title3.bold())
                                .foregroundColor(Color(hex: "2E7D32"))
                                .multilineTextAlignment(.center)
                            
                            Capsule()
                                .fill(Color(hex: "4CAF50").opacity(0.3))
                                .frame(width: 100, height: 4)
                        }
                        .padding(.top, 20)
                        
                        // Фотография (если есть)
                        if let imageData = log.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(18)
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .onTapGesture {
                                    isImageFullscreen = true
                                }
                                .padding(.horizontal)
                        }
                        
                        // Основная информация
                        VStack(spacing: 16) {
                            // Высота
                            InfoCard(
                                icon: "ruler.fill",
                                title: "Высота растений",
                                value: "\(String(format: "%.1f", log.height)) см",
                                color: Color(hex: "2196F3")
                            )
                            
                            // Наблюдения
                            if !log.changes.isEmpty {
                                InfoCard(
                                    icon: "note.text",
                                    title: "Наблюдения",
                                    value: log.changes,
                                    color: Color(hex: "FF9800")
                                )
                            }
                            
                            // Уход за растением
                            HStack(spacing: 12) {
                                if !log.wateringNotes.isEmpty {
                                    SmallInfoCard(
                                        icon: "drop.fill",
                                        title: "Полив",
                                        value: log.wateringNotes,
                                        color: Color(hex: "00BCD4")
                                    )
                                }
                                
                                if !log.lightingNotes.isEmpty {
                                    SmallInfoCard(
                                        icon: "sun.max.fill",
                                        title: "Освещение",
                                        value: log.lightingNotes,
                                        color: Color(hex: "FFC107")
                                    )
                                }
                                
                                if !log.humidityNotes.isEmpty {
                                    SmallInfoCard(
                                        icon: "humidity.fill",
                                        title: "Влажность",
                                        value: log.humidityNotes,
                                        color: Color(hex: "9C27B0")
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Детали записи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Text("Готово")
                            .bold()
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                }
            }
            .sheet(isPresented: $isImageFullscreen) {
                if let imageData = log.imageData, let uiImage = UIImage(data: imageData) {
                    ImageFullscreenView(image: uiImage)
                }
            }
        }
    }
}

// MARK: - Компоненты

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }
}

struct SmallInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ImageFullscreenView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            scale = min(max(delta * lastScale, 1.0), 5.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if scale != 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                    lastScale = 1.0
                                }
                            } else {
                                withAnimation {
                                    scale = 3.0
                                    lastScale = 3.0
                                }
                            }
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .gesture(
            TapGesture()
                .onEnded { _ in
                    dismiss()
                }
        )
    }
}

// MARK: - Предпросмотр

struct LogDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let log = GrowthLog(
            id: UUID(),
            date: Date(),
            changes: "Появились первые настоящие листья, цвет ярко-зеленый",
            height: 5.2,
            wateringNotes: "Полив 2 раза в день по 50 мл",
            lightingNotes: "12 часов под LED лампой",
            humidityNotes: "Влажность 65%",
            imageData: UIImage(named: "plant")?.jpegData(compressionQuality: 0.8)
        )
        
        LogDetailView(log: log)
    }
}

// MARK: - Расширение для Color

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Предпросмотр

struct BatchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let batch = MicrogreenBatch(
            name: "Брокколи",
            sowingDate: Date().addingTimeInterval(-86400 * 5),
            substrateType: "Кокосовый субстрат",
            harvestTime: 10,
            color: .green
        )
        
        BatchDetailView(batch: batch)
    }
}
