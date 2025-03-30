import SwiftUI

struct AddBatchView: View {
    @Binding var batches: [MicrogreenBatch]
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var sowingDate = Date()
    @State private var substrateType = "Кокосовый"
    @State private var harvestTime = ""
    @State private var selectedColor: Color = .green
    
    let substrateOptions = ["Кокосовый", "Почвосмесь", "Гидропоника"]
    let colors: [Color] = [.green, .mint, .yellow, .orange, .purple, .blue]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновый градиент
                LinearGradient(gradient: Gradient(colors: [Color(red: 0.95, green: 0.98, blue: 0.92), Color(red: 0.88, green: 0.95, blue: 0.85)]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Форма ввода
                        VStack(spacing: 0) {
                            // Название
                            InputField(title: "Название микрозелени", placeholder: "Например: Брокколи", text: $name)
                            
                            // Дата посева
                            DateInputField(date: $sowingDate)
                            
                            // Тип субстрата
                            SubstratePicker(selection: $substrateType)
                            
                            // Срок до сбора
                            NumberInputField(title: "Срок до сбора (дней)", placeholder: "7-14 дней", text: $harvestTime)
                            
                            // Выбор цвета
                            ColorSelectionView(colors: colors, selectedColor: $selectedColor)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Подсказка
                        Text("Микрозелень обычно готова к сбору через 7-14 дней после посева")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Новая партия")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveBatch) {
                        Text("Сохранить")
                            .bold()
                    }
                    .disabled(name.isEmpty || harvestTime.isEmpty)
                }
            }
        }
    }
    
    private func saveBatch() {
        guard let harvestDays = Int(harvestTime), !name.isEmpty else { return }
        
        let newBatch = MicrogreenBatch(
            name: name,
            sowingDate: sowingDate,
            substrateType: substrateType,
            harvestTime: harvestDays,
            color: selectedColor
        )
        
        withAnimation {
            batches.append(newBatch)
        }
        
        dismiss()
    }
}

// MARK: - Компоненты формы

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.vertical, 8)
    }
}

struct DateInputField: View {
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Дата посева")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.vertical, 8)
    }
}

struct SubstratePicker: View {
    @Binding var selection: String
    let options = ["Кокосовый", "Почвосмесь", "Гидропоника"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Тип субстрата")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Picker("Тип субстрата", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 8)
    }
}

struct NumberInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.vertical, 8)
    }
}

struct ColorSelectionView: View {
    let colors: [Color]
    @Binding var selectedColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Цвет маркера")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedColor = color
                            }
                        }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Предпросмотр

struct AddBatchView_Previews: PreviewProvider {
    static var previews: some View {
        AddBatchView(batches: .constant([]))
    }
}
