import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userData: UserData
    @State private var showingEditProfile = false
    @State private var showingGame = false
    
    // Система уровней и рейтинга
    let ranks = [
        Rank(name: "Новичок", color: .orange, icon: "sparkles", requiredPoints: 0),
        Rank(name: "Садовод", color: .mint, icon: "leaf", requiredPoints: 100),
        Rank(name: "Эксперт", color: .pink, icon: "flower", requiredPoints: 300),
        Rank(name: "Мастер", color: .purple, icon: "tree", requiredPoints: 600)
    ]
    var currentRank: Rank {
        ranks.last(where: { $0.requiredPoints <= userData.points }) ?? ranks[0]
    }
    
    var nextRank: Rank? {
        ranks.first(where: { $0.requiredPoints > userData.points })
    }
    
    // Достижения
    let achievements = [
        Achievement(name: "Первый росток", description: "Добавьте первое растение", icon: "leaf", completed: true),
        Achievement(name: "Неделя заботы", description: "Ухаживайте за растениями 7 дней подряд", icon: "calendar", completed: false),
        Achievement(name: "Коллекционер", description: "Соберите 5 разных растений", icon: "square.grid.3x3.fill", completed: false),
        Achievement(name: "Эксперт по поливу", description: "Поливайте растения вовремя 10 раз", icon: "drop.fill", completed: false),
        Achievement(name: "Фотограф", description: "Сфотографируйте 30 растений", icon: "drop.fill", completed: false),
        Achievement(name: "Победитель", description: "Победите 3 раза в игре Space Garden", icon: "drop.fill", completed: true)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Аватар и имя
                profileHeader
                
                // Рейтинг и прогресс
                rankSection
                
                // Основная информация
                profileInfoSection
                
                Button(action: {
                                  showingGame = true
                              }) {
                                  Text("Играть")
                                      .frame(maxWidth: .infinity)
                                      .padding()
                                      .background(Color.green)
                                      .foregroundColor(.white)
                                      .cornerRadius(10)
                              }
                              .padding(.horizontal)
                              .sheet(isPresented: $showingGame) {
                                  SpaceGardenGame()
                                      .environmentObject(userData)
                              }
                
                // Достижения
                achievementsSection
                
                // Кнопки действий
                actionButtons
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Профиль")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(userData)
        }
    }
    
    // MARK: - Subviews
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                // Яркий градиентный фон
                LinearGradient(
                    gradient: Gradient(colors: [
                        currentRank.color.opacity(0.4),
                        currentRank.color.opacity(0.2),
                        currentRank.color.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    currentRank.color
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                
                // Яркие растения с тенью
                rankPlantIcon
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                currentRank.color,
                                currentRank.color.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: currentRank.color.opacity(0.5), radius: 10, x: 0, y: 5)
                    .symbolEffect(.bounce, options: .speed(0.3), value: currentRank)
                
                // Блестящий бейдж
                rankBadge
            }
            .shadow(color: currentRank.color.opacity(0.4), radius: 15, x: 0, y: 10)

            VStack(spacing: 6) {
                Text(userData.username)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
                Text(currentRank.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(currentRank.color.gradient)
                    .cornerRadius(20)
                    .shadow(color: currentRank.color.opacity(0.3), radius: 5, x: 0, y: 3)
            }
        }
        .padding(.top, 20)
    }
    
    private var rankBadge: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: currentRank.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(currentRank.color)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 8, y: 8)
            }
        }
        .frame(width: 120, height: 120)
    }
    
    private var rankPlantIcon: some View {
        Group {
            switch currentRank.name {
            case "Новичок":
                Image(systemName: "leaf")
                    .symbolEffect(.pulse)
                    .foregroundColor(.green)
            case "Садовод":
                Image(systemName: "leaf.fill")
                    .symbolEffect(.variableColor.iterative)
                    .foregroundColor(.mint)
            case "Эксперт":
                Image(systemName: "camera.macro")
                    .symbolEffect(.scale)
                    .foregroundColor(.orange)
            case "Мастер":
                Image(systemName: "tree.fill")
                    .symbolEffect(.bounce.up.byLayer)
                    .foregroundColor(.indigo)
            default:
                Image(systemName: "leaf")
                    .foregroundColor(.green)
            }
        }
    }
    
    private var rankSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ваш прогресс")
                    .font(.headline)
                
                Spacer()
                
                Text("\(userData.points) очков")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Прогресс-бар с растением
            ZStack(alignment: .leading) {
                ProgressView(value: Double(userData.points), total: Double(nextRank?.requiredPoints ?? 1000))
                    .tint(currentRank.color)
                    .scaleEffect(x: 1, y: 1.5, anchor: .leading)
                
                rankPlantIcon
                    .offset(x: CGFloat(Double(userData.points) / Double(nextRank?.requiredPoints ?? 1000)) * (UIScreen.main.bounds.width - 80) - 20)
                    .animation(.spring(), value: userData.points)
            }
            .frame(height: 30)
            
            if let nextRank = nextRank {
                Text("До \(nextRank.name): \(nextRank.requiredPoints - userData.points) очков")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    
    private var profileInfoSection: some View {
        VStack(spacing: 12) {
            InfoRow(
                title: "Уровень опыта",
                value: userData.experienceLevel,
                icon: "star.fill",
                color: Color(hex: "FFC107")
            )
            
            InfoRow(
                title: "Время для ухода",
                value: userData.dailyTime,
                icon: "clock.fill",
                color: Color(hex: "2196F3")
            )
            
            InfoRow(
                title: "Количество растений",
                value: "\(userData.plantsCount)",
                icon: "leaf.fill",
                color: Color(hex: "4CAF50")
            )
            
            InfoRow(
                title: "Дней подряд",
                value: "\(userData.streakDays)",
                icon: "flame.fill",
                color: Color(hex: "FF5722")
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // Добавляем структуру InfoRow, если она отсутствует
    struct InfoRow: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(value)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Достижения")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button("Редактировать профиль") {
                showingEditProfile = true
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button("Выйти") {
                userData.isLoggedIn = false
            }
            .buttonStyle(DestructiveButtonStyle())
        }
    }
}

// MARK: - Supporting Views

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(achievement.completed ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .foregroundColor(achievement.completed ? .green : .gray)
                    .font(.title)
            }
            
            Text(achievement.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 70)
        }
    }
}

// MARK: - Data Models

struct Rank: Equatable {
    let name: String
    let color: Color
    let icon: String
    let requiredPoints: Int
    
    // Реализация Equatable (можно не писать вручную, так как все свойства уже соответствуют Equatable)
    static func == (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.name == rhs.name &&
               lhs.icon == rhs.icon &&
               lhs.requiredPoints == rhs.requiredPoints
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let completed: Bool
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    TextField("Имя", text: $userData.username)
                }
                
                Section("Уровень опыта") {
                    Picker("Опыт", selection: $userData.experienceLevel) {
                        Text("Новичок").tag("Новичок")
                        Text("Любитель").tag("Любитель")
                        Text("Опытный").tag("Опытный")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Время для ухода") {
                    Picker("Время", selection: $userData.dailyTime) {
                        Text("<30 мин").tag("Менее 30 минут")
                        Text("30-60 мин").tag("30-60 минут")
                        Text(">1 часа").tag("Более часа")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(UserData())
}
