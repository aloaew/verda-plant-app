import SwiftUI

struct MicrogreenBatch: Identifiable {
    let id = UUID()
    let name: String
    let sowingDate: Date
    let substrateType: String
    let harvestTime: Int
    let color: Color
}

struct MyPlantsView: View {
    @State private var batches: [MicrogreenBatch] = [
        MicrogreenBatch(name: "Брокколи", sowingDate: Date().addingTimeInterval(-86400*3), substrateType: "Кокосовый субстрат", harvestTime: 7, color: .green),
        MicrogreenBatch(name: "Горох", sowingDate: Date().addingTimeInterval(-86400*5), substrateType: "Биопочва", harvestTime: 10, color: .mint),
        MicrogreenBatch(name: "Подсолнух", sowingDate: Date().addingTimeInterval(-86400), substrateType: "Минеральная вата", harvestTime: 12, color: .yellow)
    ]
    
    @State private var showAddBatchView = false
    @State private var searchText = ""
    
    var filteredBatches: [MicrogreenBatch] {
        if searchText.isEmpty {
            return batches
        } else {
            return batches.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновый градиент
                LinearGradient(gradient: Gradient(colors: [Color(red: 0.95, green: 0.98, blue: 0.92), Color(red: 0.88, green: 0.95, blue: 0.85)]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Поиск
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        // Статистика
                        HStack(spacing: 16) {
                            StatsCard(value: batches.count, label: "Всего", icon: "leaf.fill", color: .green)
                            StatsCard(value: batches.filter { Calendar.current.dateComponents([.day], from: $0.sowingDate, to: Date()).day! < $0.harvestTime }.count,
                                     label: "Растут", icon: "arrow.up.circle.fill", color: .blue)
                            StatsCard(value: batches.filter { Calendar.current.dateComponents([.day], from: $0.sowingDate, to: Date()).day! >= $0.harvestTime }.count,
                                     label: "Готовы", icon: "checkmark.circle.fill", color: .orange)
                        }
                        .padding(.horizontal)
                        
                        // Список партий
                        ForEach(filteredBatches) { batch in
                            BatchCardView(batch: batch)
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Подсказка при пустом списке
                        if batches.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "leaf.arrow.triangle.circlepath")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("Добавьте свою первую партию микрозелени")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Кнопка добавления
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddButton {
                            withAnimation(.spring()) {
                                showAddBatchView.toggle()
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Моя микрозелень")
            .sheet(isPresented: $showAddBatchView) {
                AddBatchView(batches: $batches)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(.green)
                }
            }
        }
        .accentColor(.green)
    }
    
    private func deleteBatch(at offsets: IndexSet) {
        withAnimation {
            batches.remove(atOffsets: offsets)
        }
    }
}

// MARK: - Компоненты

struct BatchCardView: View {
    let batch: MicrogreenBatch
    @State private var isPressed = false
    
    var daysPassed: Int {
        Calendar.current.dateComponents([.day], from: batch.sowingDate, to: Date()).day ?? 0
    }
    
    var progress: CGFloat {
        min(CGFloat(daysPassed) / CGFloat(batch.harvestTime), 1.0)
    }
    
    var isReady: Bool {
        daysPassed >= batch.harvestTime
    }
    
    var body: some View {
        NavigationLink(destination: BatchDetailView(batch: batch)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(batch.name)
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    if isReady {
                        Label("Готово", systemImage: "checkmark.seal.fill")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text("Посев: \(batch.sowingDate, formatter: dateFormatter)")
                        .foregroundColor(.black)
                }
                .font(.subheadline)
                
                HStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.gray)
                    Text("Субстрат: \(batch.substrateType)")
                        .foregroundColor(.black)
                }
                .font(.subheadline)
                
                ProgressView(value: progress, total: 1.0)
                    .tint(isReady ? .green : batch.color)
                    .animation(.easeInOut, value: progress)
                
                HStack {
                    Text(isReady ? "Готово к сбору!" : "Осталось \(batch.harvestTime - daysPassed) дней")
                        .font(.caption.bold())
                        .foregroundColor(isReady ? .green : .gray)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(isReady ? .green : batch.color)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        isPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false
                        }
                    }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatsCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
            
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(.black)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}



struct AddButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.mint]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                .contentShape(Circle())
        }
    }
}

// MARK: - Вспомогательные виды



struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}



// MARK: - Вспомогательные переменные

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "ru_RU")
    return formatter
}()

// MARK: - Предпросмотр

#Preview {
    MyPlantsView()
}
