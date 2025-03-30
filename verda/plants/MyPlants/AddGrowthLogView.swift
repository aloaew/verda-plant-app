import SwiftUI
import PhotosUI

struct AddGrowthLogView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var logs: [GrowthLog]
    
    @State private var date = Date()
    @State private var changes = ""
    @State private var height = ""
    @State private var wateringNotes = ""
    @State private var lightingNotes = ""
    @State private var humidityNotes = ""
    
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showCamera = false
    
    let storageKey: String
    
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
                    VStack(spacing: 20) {
                        // Основная форма
                        VStack(spacing: 0) {
                            // Дата
                            InputSection(title: "Дата записи", icon: "calendar") {
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .labelsHidden()
                                    .frame(maxHeight: 400)
                            }
                            
                            // Высота
                            InputSection(title: "Высота растений (см)", icon: "ruler.fill") {
                                TextField("3.5", text: $height)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.body)
                            }
                            
                            // Изменения
                            InputSection(title: "Наблюдения", icon: "note.text") {
                                TextEditor(text: $changes)
                                    .frame(minHeight: 100)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                    .shadow(radius: 1)
                            }
                            
                            // Уход
                            VStack(spacing: 12) {
                                InputSection(title: "Полив", icon: "drop.fill") {
                                    TextField("Описание полива", text: $wateringNotes)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                InputSection(title: "Освещение", icon: "sun.max.fill") {
                                    TextField("Описание освещения", text: $lightingNotes)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                InputSection(title: "Влажность", icon: "humidity.fill") {
                                    TextField("Описание влажности", text: $humidityNotes)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            
                            // Фото
                            InputSection(title: "Фотография", icon: "photo.fill") {
                                VStack(spacing: 15) {
                                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .cornerRadius(12)
                                            .overlay(
                                                Button {
                                                    self.selectedImageData = nil
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.title)
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.7))
                                                        .clipShape(Circle())
                                                }
                                                .padding(8),
                                                alignment: .topTrailing
                                            )
                                    }
                                    
                                    HStack(spacing: 15) {
                                        Button {
                                            showCamera.toggle()
                                        } label: {
                                            Label("Камера", systemImage: "camera.fill")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        PhotosPicker(
                                            selection: $selectedImage,
                                            matching: .images,
                                            photoLibrary: .shared()
                                        ) {
                                            Label("Галерея", systemImage: "photo.fill.on.rectangle.fill")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Подсказки
                        Text("Рекомендуется делать записи ежедневно для точного отслеживания роста")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 30)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Новая запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveLog) {
                        Text("Сохранить")
                            .bold()
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                    .disabled(height.isEmpty || changes.isEmpty)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    self.selectedImageData = image.jpegData(compressionQuality: 0.8)
                }
            }
        }
        .onChange(of: selectedImage) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
    
    private func saveLog() {
        if let heightValue = Double(height) {
            let newLog = GrowthLog(
                id: UUID(),
                date: date,
                changes: changes,
                height: heightValue,
                wateringNotes: wateringNotes,
                lightingNotes: lightingNotes,
                humidityNotes: humidityNotes,
                imageData: selectedImageData
            )
            
            withAnimation {
                logs.append(newLog)
            }
            
            saveLogs()
            dismiss()
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

// MARK: - Компоненты

struct InputSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "4CAF50"))
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.gray)
            }
            
            content()
        }
        .padding(.vertical, 10)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Расширение для Color


// MARK: - Предпросмотр

struct AddGrowthLogView_Previews: PreviewProvider {
    static var previews: some View {
        AddGrowthLogView(logs: .constant([]), storageKey: "test")
    }
}
