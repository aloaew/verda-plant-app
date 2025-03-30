import SwiftUI
import UserNotifications

// MARK: - Notification Manager (In-File)
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var currentNotification: UNNotification?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
 
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DispatchQueue.main.async {
            self.currentNotification = notification
        }
        
        completionHandler([.banner, .sound])
    }
    
    func dismissNotification() {
        currentNotification = nil
    }
}

// MARK: - In-App Notification Banner (In-File)
struct InAppNotificationBanner: View {
    let notification: UNNotification
    let onDismiss: () -> Void
    
    var body: some View {
        let content = notification.request.content
        VStack(alignment: .leading, spacing: 8) {
            Text(content.title)
                .font(.headline)
            if !content.subtitle.isEmpty {
                Text(content.subtitle)
                    .font(.subheadline)
            }
            Text(content.body)
                .font(.body)
            HStack {
                Button("View") {
                    
                    onDismiss()
                }
                Spacer()
                Button("Dismiss") {
                    onDismiss()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

// MARK: - Main Calendar / RecentsView with Integrated Notifications
struct RecentsView: View {
    @State private var searchText: String = ""
    @State private var showingAddEvent = false
    @State private var events: [EventItem] = [
        EventItem(date: Date().addingTimeInterval(-14 * 24 * 3600),
                  name: "Полив",
                  description: "Regular watering",
                  icon: "drop.fill",
                  color: .blue),
        EventItem(date: Date().addingTimeInterval(-7 * 24 * 3600),
                  name: "Добавить удобрение",
                  description: "Fertilizing",
                  icon: "flame.fill",
                  color: .red),
        EventItem(date: Date().addingTimeInterval(-3 * 24 * 3600),
                  name: "Изменить субтракт и почистить листья",
                  description: "Leaf cleaning",
                  icon: "leaf.fill",
                  color: .orange)
    ]
    
    let featuredPlant = ""
    
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 35) {
                   
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: "https://as1.ftcdn.net/v2/jpg/10/30/62/62/1000_F_1030626238_klTIVgBr8YqZVfDgcXTMD6JnEW7D77kP.jpg")) { image in image.resizable()
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(height: 250)
                                        .cornerRadius(12)
                                        .clipped()
                        
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .cornerRadius(12)
                        
                        Text(featuredPlant)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding(EdgeInsets(top: 10, leading: 16, bottom: 0, trailing: 16))
                    
                  
                    Text("Задачи на сегодня:")
                        .font(.title3.bold())
                        .padding(.horizontal)
                    
                    
                    List {
                        ForEach(events) { event in
                            EventRow(event: event)
                        }
                        .onDelete(perform: deleteEvent)
                    }
                    .listStyle(PlainListStyle())
                    
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
                        .sheet(isPresented: $showingAddEvent) {
                            AddEventView(events: $events, date: Date())
                        }
                    }
                }
                
               
                if let notification = notificationManager.currentNotification {
                    InAppNotificationBanner(notification: notification) {
                        notificationManager.dismissNotification()
                    }
                    .transition(.move(edge: .top))
                    .zIndex(1)
                }
            }
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                requestNotificationPermission()
            }
        }
    }
    
    // MARK: - Delete function
    private func deleteEvent(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
    }
    
   
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Ошибка запроса уведомлений: \(error.localizedDescription)")
            } else if granted {
                print("Разрешение получено")
            } else {
                print("Разрешение не предоставлено")
            }
        }
    }
}

// MARK: - Add Event View with Notification Scheduling
struct AddEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var events: [EventItem]
    let date: Date
    
    enum ActionType: String, CaseIterable {
        case water = "Полив"
        case substrate = "Изменить почву"
        case medicine = "Добавить лекарства"
        case fertilize = "Удобрить"
        
        var icon: String {
            switch self {
            case .water: return "drop.fill"
            case .substrate: return "leaf.fill"
            case .medicine: return "cross.fill"
            case .fertilize: return "flame.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .water: return Color(hex: "3498db")
            case .substrate: return Color(hex: "2ecc71")
            case .medicine: return Color(hex: "e74c3c")
            case .fertilize: return Color(hex: "e67e22")
            }
        }
    }
    
    @State private var actionType: ActionType = .water
    @State private var plantName: String = ""
    @State private var description: String = ""
    @State private var time: Date = Date()
    @State private var enableNotification: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "f5f7fa"), Color(hex: "E4F5E1")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(actionType.color.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: actionType.icon)
                                    .font(.title2)
                                    .foregroundColor(actionType.color)
                            }
                            
                            Text("Новое напоминание")
                                .font(.title2.bold())
                                .foregroundColor(Color(hex: "2E7D32"))
                            
                            Text("Запланируйте уход за растением")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "5A8F5B"))
                        }
                        .padding(.top, 24)
                        
                        
                        VStack(spacing: 16) {
                          
                            ActionTypeSection
                            
                           
                            PlantNameSection
                            
                           
                            DescriptionSection
                            
                            
                            TimeSection
                            
                          
                            NotificationSection
                        }
                        .padding(.horizontal, 20)
                        
                       
                        SaveButton
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Отмена")
                        .foregroundColor(Color(hex: "3498db"))
                }
            )
        }
    }
    
    // MARK: - Subviews
    private var ActionTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ТИП ДЕЙСТВИЯ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "388E3C"))
                .padding(.leading, 4)
            
            Picker("Выберите тип", selection: $actionType) {
                ForEach(ActionType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                        .foregroundColor(type.color)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }

    private var PlantNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("НАЗВАНИЕ РАСТЕНИЯ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "388E3C"))
                .padding(.leading, 4)
            
            TextField("Монстера, фикус...", text: $plantName)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }

    private var DescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ОПИСАНИЕ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "388E3C"))
                .padding(.leading, 4)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $description)
                    .frame(height: 80) // Уменьшенная фиксированная высота
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .onAppear {
                        UITextView.appearance().textContainerInset = UIEdgeInsets(
                            top: 10,
                            left: 0,
                            bottom: 10,
                            right: 0
                        )
                    }
                
                if description.isEmpty {
                    Text("Добавьте заметки...")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 80)
        }
    }

    private var TimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ВРЕМЯ НАПОМИНАНИЯ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "388E3C"))
                .padding(.leading, 4)
            
            HStack {
                Spacer()
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(width: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                Spacer()
            }
        }
    }

    private var NotificationSection: some View {
        Toggle(isOn: $enableNotification) {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(Color(hex: "4CAF50"))
                Text("Включить уведомление")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "4CAF50")))
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var SaveButton: some View {
        Button(action: saveEvent) {
            HStack {
                Spacer()
                Text("СОХРАНИТЬ")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "2E7D32"), Color(hex: "4CAF50")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color(hex: "2E7D32").opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(plantName.isEmpty)
        .opacity(plantName.isEmpty ? 0.6 : 1.0)
    }
    
    private func SectionHeader(title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .padding(.leading, 4)
    }
    
    // MARK: - Methods 
    private func saveEvent() {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        guard let eventDate = calendar.date(byAdding: timeComponents, to: calendar.date(from: dateComponents)!) else {
            return
        }
        
        let newEvent = EventItem(
            date: eventDate,
            name: plantName,
            description: description,
            icon: actionType.icon,
            color: actionType.color
        )
        
        withAnimation {
            events.append(newEvent)
            events.sort { $0.date > $1.date }
        }
        
        if enableNotification {
            scheduleNotification(for: newEvent, actionType: actionType)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func scheduleNotification(for event: EventItem, actionType: ActionType) {
        let content = UNMutableNotificationContent()
        content.title = "🌱 \(actionType.rawValue) - \(event.name)"
        content.subtitle = "Время ухода за растением"
        content.body = event.description.isEmpty ? "Не забудьте выполнить уход за растением" : event.description
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: event.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка планирования уведомления: \(error.localizedDescription)")
            }
        }
    }
}


struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
// MARK: - Event Item Model
struct EventItem: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let description: String
    let icon: String
    let color: Color
}


// MARK: - Preview
struct RecentsView_Previews: PreviewProvider {
    static var previews: some View {
        RecentsView()
    }
}
