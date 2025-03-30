import SwiftUI

struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText: String = ""
    @State private var navigateToContent = false
    

    var body: some View {
        NavigationView {
            VStack {
             
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        Text(message.text)
                                            .padding()
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(16)
                                            .frame(
                                                maxWidth: UIScreen.main.bounds.width * 0.75,
                                                alignment: .trailing
                                            )
                                    } else {
                                        Text(message.text)
                                            .padding()
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(16)
                                            .frame(
                                                maxWidth: UIScreen.main.bounds.width * 0.75,
                                                alignment: .leading
                                            )
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                HStack {
                    TextField("Напишите сообщение...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Отправить") {
                        viewModel.sendMessage(inputText)
                        inputText = ""
                    }
                    .disabled(inputText.isEmpty)
                    .padding(.leading, 4)
                }
                .padding()
            }
            .navigationTitle("AI Ассистент")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
              
                hideKeyboard()
                
                navigateToContent = true
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Назад")
                }
            })
           
            .background(
                NavigationLink(destination: ContentView(), isActive: $navigateToContent) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
}

extension View {

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
