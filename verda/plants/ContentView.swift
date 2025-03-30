import SwiftUI
struct ContentView: View {
    @StateObject private var userData = UserData()
    
    var body: some View {
        SplashScreenView()
            .environmentObject(userData)
    }
}


struct SplashScreenView: View {
    @EnvironmentObject var userData: UserData
    @State private var isActive = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Group {
            if isActive {
                if userData.isLoggedIn {
                    MainTabView()
                } else {
                    RegistrationView()
                }
            } else {
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    VStack {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .rotationEffect(.degrees(rotation))
                        
                        Text("Verda")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                            .opacity(opacity)
                            .padding(.top, 20)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                scale = 1.0
                opacity = 1.0
                rotation = 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = true
                }
            }
        }
    }
}

// Основное меню с табами
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house")
                }
            
            CalendarTab()
                .tabItem {
                    Label("Календарь", systemImage: "calendar")
                }
            
            ChatView()
                .tabItem {
                    Label("Чат", systemImage: "message")
                }
            
            MyPlantsView()
                .tabItem {
                    Label("Мои растения", systemImage: "leaf")
                }
            
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
    }
}

// Экран регистрации
struct RegistrationView: View {
    @EnvironmentObject var userData: UserData
    @State private var currentStep = 0
    @State private var username = ""
    @State private var selectedExperience = ""
    @State private var selectedTime = ""
    
    let experienceLevels = ["Новичок", "Любитель", "Опытный садовод"]
    let dailyTimes = ["Менее 30 минут", "30-60 минут", "Более часа"]
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentStep + 1) / 3.0)
                .padding()
            
            if currentStep == 0 {
                welcomeStep
            } else if currentStep == 1 {
                experienceStep
            } else if currentStep == 2 {
                timeStep
            }
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: currentStep)
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("Добро пожаловать!")
                .font(.largeTitle)
                .bold()
            
            TextField("Введите ваше имя", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Продолжить") {
                if !username.isEmpty {
                    currentStep += 1
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
    
    private var experienceStep: some View {
        VStack(spacing: 20) {
            Text("Какой у вас опыт в садоводстве?")
                .font(.title)
            
            ForEach(experienceLevels, id: \.self) { level in
                experienceLevelButton(level: level)
            }
            
            HStack {
                Button("Назад") {
                    currentStep -= 1
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Продолжить") {
                    if !selectedExperience.isEmpty {
                        currentStep += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }
    
    private var timeStep: some View {
        VStack(spacing: 20) {
            Text("Сколько времени вы готовы уделять растениям ежедневно?")
                .font(.title)
            
            ForEach(dailyTimes, id: \.self) { time in
                dailyTimeButton(time: time)
            }
            
            HStack {
                Button("Назад") {
                    currentStep -= 1
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Завершить") {
                    completeRegistration()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }
    
    private func experienceLevelButton(level: String) -> some View {
        Button(action: {
            selectedExperience = level
        }) {
            HStack {
                Text(level)
                Spacer()
                if selectedExperience == level {
                    Image(systemName: "checkmark")
                }
            }
            .padding()
            .background(selectedExperience == level ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func dailyTimeButton(time: String) -> some View {
        Button(action: {
            selectedTime = time
        }) {
            HStack {
                Text(time)
                Spacer()
                if selectedTime == time {
                    Image(systemName: "checkmark")
                }
            }
            .padding()
            .background(selectedTime == time ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func completeRegistration() {
        userData.username = username
        userData.experienceLevel = selectedExperience
        userData.dailyTime = selectedTime
        userData.isLoggedIn = true
    }
}

// Вспомогательные компоненты
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

// Стили кнопок
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.2))
            .foregroundColor(.red)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView()
}
