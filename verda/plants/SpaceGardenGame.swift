import SwiftUI

struct SpaceGardenGame: View {
    enum PlantType: String, CaseIterable {
        case martianPotato = "🥔"
        case lunarLettuce = "🥬"
        case nebulaRose = "🌹"
        case quantumFern = "🌿"
        
        var name: String {
            switch self {
            case .martianPotato: return "Марсианский картофель"
            case .lunarLettuce: return "Лунный салат"
            case .nebulaRose: return "Туманная роза"
            case .quantumFern: return "Квантовый папоротник"
            }
        }
        
        var growthRate: Double {
            switch self {
            case .martianPotato: return 0.8
            case .lunarLettuce: return 1.5
            case .nebulaRose: return 0.5
            case .quantumFern: return 0.3
            }
        }
        
        var waterConsumption: Double {
            switch self {
            case .martianPotato: return 0.7
            case .lunarLettuce: return 1.2
            case .nebulaRose: return 0.9
            case .quantumFern: return 0.4
            }
        }
        
        var oxygenProduction: Int {
            switch self {
            case .martianPotato: return 5
            case .lunarLettuce: return 8
            case .nebulaRose: return 3
            case .quantumFern: return 10
            }
        }
        
        var price: Int {
            switch self {
            case .martianPotato: return 20
            case .lunarLettuce: return 30
            case .nebulaRose: return 50
            case .quantumFern: return 100
            }
        }
    }
    
    struct Plant {
        let type: PlantType
        var growth: Double = 0
        var health: Double = 100
        var plantedAt: Date = Date()
    }
    
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    // Ресурсы
    @State private var water: Double = 100
    @State private var nutrients: Double = 100
    @State private var energy: Double = 100
    @State private var oxygen: Int = 100
    @State private var credits: Int = 200
    
    // Растения
    @State private var plants: [Plant] = []
    @State private var selectedPlantType: PlantType?
    
    // Условия среды
    @State private var temperature: Double = 22
    @State private var gravity: Double = 0.38 // Марсианская гравитация
    
    // Игровые параметры
    @State private var day: Int = 1
    @State private var researchPoints: Int = 0
    @State private var showResearchView = false
    @State private var showShopView = false
    @State private var showEventAlert = false
    @State private var eventMessage = ""
    @State private var gameOver = false
    @State private var gameTimer: Timer?
    @State private var oxygenWarning = false
    
    // Улучшения
    @State private var upgrades: [String: Bool] = [
        "water_recycler": false,
        "solar_panels": false,
        "genetic_engine": false,
        "gravity_control": false
    ]
    
    let maxResources: Double = 200
    let maxOxygen: Int = 200
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Космический фон
                LinearGradient(gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.3)]),
                              startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                // Звезды
                ForEach(0..<50) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                 y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                        .opacity(Double.random(in: 0.5...1))
                }
                
                VStack {
                    // Панель статуса
                    HStack {
                        VStack(alignment: .leading) {
                            Text("День \(day)")
                                .font(.headline)
                            Text("Кислород: \(oxygen)%")
                                .foregroundColor(oxygenWarning ? .red : .white)
                            Text("Температура: \(Int(temperature))°C")
                                .foregroundColor(temperature > 30 ? .orange : .white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(credits) кредитов")
                                .font(.headline)
                            Text("Энергия: \(Int(energy))%")
                                .foregroundColor(energy < 30 ? .red : .white)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Индикаторы ресурсов
                    HStack(spacing: 10) {
                        ResourceIndicator(value: water, max: maxResources, color: .blue, icon: "💧")
                        ResourceIndicator(value: nutrients, max: maxResources, color: .green, icon: "🌱")
                    }
                    .padding(.horizontal)
                    
                    // Теплица
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                            ForEach(0..<6, id: \.self) { index in
                                if index < plants.count {
                                    PlantView(plant: plants[index],
                                             temperature: temperature,
                                             gravity: gravity)
                                        .contextMenu {
                                            Button(action: {
                                                removePlant(at: index)
                                            }) {
                                                Label("Удалить", systemImage: "trash")
                                            }
                                        }
                                } else {
                                    EmptyPlotView(selectedPlantType: $selectedPlantType)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Панель управления
                    HStack(spacing: 15) {
                        Button(action: { showShopView = true }) {
                            Image(systemName: "cart")
                                .padding(10)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        
                        Button(action: collectResources) {
                            Image(systemName: "leaf.arrow.circlepath")
                                .padding(10)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                        .disabled(plants.filter { $0.growth >= 100 }.isEmpty)
                        
                        Button(action: { showResearchView = true }) {
                            Image(systemName: "atom")
                                .padding(10)
                                .background(Color.purple)
                                .clipShape(Circle())
                        }
                        
                        Button(action: nextDay) {
                            Image(systemName: "forward.frame")
                                .padding(10)
                                .background(Color.orange)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top)
                    .font(.title2)
                }
                
                // Меню выбора растения
                if selectedPlantType != nil {
                    PlantSelectionMenu(selectedPlantType: $selectedPlantType,
                                     credits: credits,
                                     buyAction: buyPlant)
                }
                
                // Исследования
                if showResearchView {
                    ResearchView(isPresented: $showResearchView,
                                 researchPoints: $researchPoints,
                                 upgrades: $upgrades)
                }
                
                // Магазин
                if showShopView {
                    ShopView(isPresented: $showShopView,
                            credits: $credits,
                            water: $water,
                            nutrients: $nutrients,
                            energy: $energy)
                }
                
                // Событие
                if showEventAlert {
                    EventAlert(message: eventMessage, isPresented: $showEventAlert)
                }
                
                // Конец игры
                if gameOver {
                    GameOverView(day: day, restartAction: restartGame)
                }
            }
            .navigationTitle("Космический сад")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Выход") {
                        stopGame()
                        dismiss()
                    }
                }
            }
            .onAppear {
                startGame()
            }
            .onDisappear {
                stopGame()
            }
        }
    }
    
    // MARK: - Game Logic
    
    private func startGame() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            updatePlants()
            checkOxygenLevel()
        }
    }
    
    private func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func updatePlants() {
        for index in plants.indices {
            // Обновляем рост растений
            let growthRate = plants[index].type.growthRate * (1 + (gravity - 0.3))
            plants[index].growth = min(100, plants[index].growth + growthRate)
            
            // Потребление ресурсов
            let waterConsumption = plants[index].type.waterConsumption * (temperature / 20)
            water = max(0, water - waterConsumption)
            
            let nutrientConsumption = plants[index].type.waterConsumption * 0.5
            nutrients = max(0, nutrients - nutrientConsumption)
            
            // Влияние температуры на здоровье
            let tempEffect: Double
            if temperature < 10 {
                tempEffect = -0.5
            } else if temperature > 35 {
                tempEffect = -1.0
            } else {
                tempEffect = 0.1
            }
            
            plants[index].health = max(0, min(100, plants[index].health + tempEffect))
            
            // Производство кислорода
            if plants[index].growth >= 50 {
                oxygen = min(maxOxygen, oxygen + plants[index].type.oxygenProduction)
            }
        }
        
        // Потребление энергии системами
        let energyConsumption = 0.5 + Double(plants.count) * 0.2
        energy = max(0, energy - energyConsumption)
        
        // Восполнение ресурсов (если есть улучшения)
        if upgrades["water_recycler"] == true {
            water = min(maxResources, water + 0.3)
        }
        
        if upgrades["solar_panels"] == true {
            energy = min(100, energy + 1)
        }
    }
    
    private func checkOxygenLevel() {
        oxygenWarning = oxygen < 30
        if oxygen <= 0 {
            gameOver = true
        }
    }
    
    private func nextDay() {
        day += 1
        
        // Восполнение некоторых ресурсов
        if upgrades["solar_panels"] == true {
            energy = min(100, energy + 20)
        } else {
            energy = min(100, energy + 10)
        }
        
        // Случайное изменение температуры
        temperature += Double.random(in: -5...5)
        
        // Случайное событие (20% шанс)
        if Double.random(in: 0...1) < 0.2 {
            triggerRandomEvent()
        }
        
        // Начисление исследовательских очков
        researchPoints += plants.count
    }
    
    private func triggerRandomEvent() {
        let events = [
            ("🌡️ Колебания температуры! Температура изменилась на 10 градусов", {
                temperature += Double.random(in: 0...1) > 0.5 ? 10 : -10
            }),
            ("☀️ Солнечная вспышка! -30% энергии", {
                energy = max(0, energy * 0.7)
            }),
            ("💧 Утечка воды! Потеряно 20% воды", {
                water = max(0, water * 0.8)
            }),
            ("🛰️ Научная миссия! +10 исследовательских очков", {
                researchPoints += 10
            }),
            ("🌌 Космический мусор! Повреждение растений", {
                for index in plants.indices {
                    plants[index].health = max(0, plants[index].health - 20)
                }
            })
        ]
        
        let event = events.randomElement()!
        eventMessage = event.0
        event.1()
        showEventAlert = true
    }
    
    private func buyPlant() {
        guard let type = selectedPlantType, credits >= type.price else { return }
        
        credits -= type.price
        plants.append(Plant(type: type))
        selectedPlantType = nil
    }
    
    private func removePlant(at index: Int) {
        plants.remove(at: index)
    }
    
    private func collectResources() {
        var collectedCredits = 0
        var collectedOxygen = 0
        
        for plant in plants.filter({ $0.growth >= 100 }) {
            collectedCredits += plant.type.price * 2
            collectedOxygen += plant.type.oxygenProduction * 2
        }
        
        credits += collectedCredits
        oxygen = min(maxOxygen, oxygen + collectedOxygen)
        
        // Удаляем собранные растения
        plants = plants.filter { $0.growth < 100 }
    }
    
    private func restartGame() {
        water = 100
        nutrients = 100
        energy = 100
        oxygen = 100
        credits = 200
        plants = []
        day = 1
        researchPoints = 0
        temperature = 22
        gameOver = false
        upgrades = [
            "water_recycler": false,
            "solar_panels": false,
            "genetic_engine": false,
            "gravity_control": false
        ]
    }
}

// MARK: - Views

struct ResourceIndicator: View {
    let value: Double
    let max: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 5) {
            Text(icon)
            ProgressView(value: value, total: max)
                .tint(color)
            Text("\(Int(value))%")
                .font(.caption)
                .frame(width: 40)
        }
    }
}

struct PlantView: View {
    let plant: SpaceGardenGame.Plant
    let temperature: Double
    let gravity: Double
    
    var healthColor: Color {
        switch plant.health {
        case ..<30: return .red
        case 30..<70: return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        VStack {
            // Растение
            Text(plant.type.rawValue)
                .font(.system(size: 40))
                .rotationEffect(.degrees(gravity * 20))
            
            // Индикаторы
            VStack(alignment: .leading) {
                Text(plant.type.name)
                    .font(.caption)
                    .lineLimit(1)
                
                ProgressView(value: plant.growth, total: 100)
                    .tint(.blue)
                
                HStack {
                    Circle()
                        .fill(healthColor)
                        .frame(width: 8, height: 8)
                    Text("\(Int(plant.health))%")
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            plant.growth >= 100 ?
            Text("✓")
                .font(.title)
                .foregroundColor(.green)
                .offset(x: 10, y: -10) : nil,
            alignment: .topTrailing
        )
    }
}

struct EmptyPlotView: View {
    @Binding var selectedPlantType: SpaceGardenGame.PlantType?
    
    var body: some View {
        Button(action: {
            selectedPlantType = .martianPotato
        }) {
            VStack {
                Image(systemName: "plus")
                    .font(.title)
                Text("Добавить")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

struct PlantSelectionMenu: View {
    @Binding var selectedPlantType: SpaceGardenGame.PlantType?
    let credits: Int
    let buyAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 15) {
                Text("Выберите растение")
                    .font(.headline)
                
                ForEach(SpaceGardenGame.PlantType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedPlantType = type
                    }) {
                        HStack {
                            Text(type.rawValue)
                                .font(.system(size: 30))
                            VStack(alignment: .leading) {
                                Text(type.name)
                                Text("\(type.price) кредитов")
                                    .font(.caption)
                            }
                            Spacer()
                            if selectedPlantType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding()
                        .background(selectedPlantType == type ? Color.white.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 20) {
                    Button("Отмена") {
                        selectedPlantType = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(10)
                    
                    Button("Купить") {
                        buyAction()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(credits >= (selectedPlantType?.price ?? 0) ? Color.green : Color.gray)
                    .cornerRadius(10)
                    .disabled(credits < (selectedPlantType?.price ?? 0))
                }
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            .cornerRadius(15)
            .padding()
        }
        .background(Color.black.opacity(0.5).edgesIgnoringSafeArea(.all))
    }
}

struct ResearchView: View {
    @Binding var isPresented: Bool
    @Binding var researchPoints: Int
    @Binding var upgrades: [String: Bool]
    
    let upgradesList = [
        ("water_recycler", "Система рециклинга воды", 30, "♻️"),
        ("solar_panels", "Улучшенные солнечные панели", 50, "☀️"),
        ("genetic_engine", "Генетический инженер", 80, "🧬"),
        ("gravity_control", "Контроль гравитации", 120, "🌌")
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("Исследования")
                    .font(.title)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            Text("Доступно очков: \(researchPoints)")
                .font(.headline)
                .padding(.bottom)
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(upgradesList, id: \.0) { upgrade in
                        UpgradeCard(
                            id: upgrade.0,
                            name: upgrade.1,
                            cost: upgrade.2,
                            icon: upgrade.3,
                            isUnlocked: upgrades[upgrade.0] ?? false,
                            researchPoints: researchPoints,
                            buyAction: {
                                if researchPoints >= upgrade.2 {
                                    researchPoints -= upgrade.2
                                    upgrades[upgrade.0] = true
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1, green: 0.1, blue: 0.2))
        .cornerRadius(20)
        .padding()
    }
}

struct UpgradeCard: View {
    let id: String
    let name: String
    let cost: Int
    let icon: String
    let isUnlocked: Bool
    let researchPoints: Int
    let buyAction: () -> Void
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 30))
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                Text(isUnlocked ? "Разблокировано" : "Стоимость: \(cost) очков")
                    .font(.caption)
                    .foregroundColor(isUnlocked ? .green : .gray)
            }
            
            Spacer()
            
            if !isUnlocked {
                Button(action: buyAction) {
                    Text("Исследовать")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(researchPoints >= cost ? Color.blue : Color.gray)
                        .cornerRadius(5)
                }
                .disabled(researchPoints < cost)
            } else {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isUnlocked ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

struct ShopView: View {
    @Binding var isPresented: Bool
    @Binding var credits: Int
    @Binding var water: Double
    @Binding var nutrients: Double
    @Binding var energy: Double
    
    let items = [
        ("💧 Вода", 10, "Восполняет 20% воды"),
        ("🌱 Удобрения", 15, "Восполняет 20% питательных веществ"),
        ("⚡ Энергия", 20, "Восполняет 30% энергии")
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("Магазин")
                    .font(.title)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            Text("Доступно кредитов: \(credits)")
                .font(.headline)
                .padding(.bottom)
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(items, id: \.0) { item in
                        ShopItem(
                            name: item.0,
                            cost: item.1,
                            description: item.2,
                            credits: credits,
                            buyAction: {
                                if credits >= item.1 {
                                    credits -= item.1
                                    switch item.0 {
                                    case "💧 Вода": water = min(100, water + 20)
                                    case "🌱 Удобрения": nutrients = min(100, nutrients + 20)
                                    case "⚡ Энергия": energy = min(100, energy + 30)
                                    default: break
                                    }
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1, green: 0.1, blue: 0.2))
        .cornerRadius(20)
        .padding()
    }
}

struct ShopItem: View {
    let name: String
    let cost: Int
    let description: String
    let credits: Int
    let buyAction: () -> Void
    
    var body: some View {
        HStack {
            Text(name.components(separatedBy: " ").first ?? "")
                .font(.system(size: 30))
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: buyAction) {
                Text("\(cost) кредитов")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(credits >= cost ? Color.blue : Color.gray)
                    .cornerRadius(5)
            }
            .disabled(credits < cost)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct EventAlert: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text("Событие!")
                .font(.title)
                .padding(.bottom, 5)
            
            Text(message)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("OK") {
                isPresented = false
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
        .frame(width: 300)
        .background(Color(red: 0.1, green: 0.1, blue: 0.3))
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}

struct GameOverView: View {
    let day: Int
    let restartAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Конец игры")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Вы продержались \(day) дней")
                .font(.title2)
            
            Button(action: restartAction) {
                Text("Начать заново")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .frame(width: 200)
        }
        .padding()
        .frame(width: 300, height: 300)
        .background(Color(red: 0.1, green: 0.1, blue: 0.3))
        .cornerRadius(20)
        .shadow(radius: 20)
    }
}

struct SpaceGardenGame_Previews: PreviewProvider {
    static var previews: some View {
        SpaceGardenGame()
            .environmentObject(UserData())
    }
}
