//
//  ChatViewModel.swift
//  plants
//
//  Created by zhanel on 29.03.2025.
//


//
//  ChatViewModel.swift
//  YourApp
//
//  Handles sending messages to OpenAI and storing the conversation
//

import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(text: "Привет! Давай поговорим о растениях.", isUser: false)
    ]
    @Published var isLoading = false
    
    
    private let openaiAPIKey = "sk-proj-frfrfrfrfrfrfrfrfrfrfrfrfrfrfrfr"
    
    func sendMessage(_ messageText: String) {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        
        let userMessage = ChatMessage(text: trimmed, isUser: true)
        DispatchQueue.main.async {
            self.messages.append(userMessage)
        }
        
        
        let systemMessage: [String: String] = [
            "role": "system",
            "content": "Ты ассистент, который специализируется на растениях. Отвечай подробно и всегда включай советы по уходу за растениями."
        ]
        let userContent: [String: String] = [
            "role": "user",
            "content": trimmed
        ]
        
        
        let messagesForRequest = [systemMessage, userContent]
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messagesForRequest,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
              let httpBody = try? JSONSerialization.data(withJSONObject: parameters) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openaiAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        
        self.isLoading = true
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                print("Error: \(error)")
                return
            }
            guard let data = data else {
                print("No data")
                return
            }
            do {
               
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let messageDict = choices.first?["message"] as? [String: Any],
                   let content = messageDict["content"] as? String {
                    
                    let botMessage = ChatMessage(text: content, isUser: false)
                    DispatchQueue.main.async {
                        self.messages.append(botMessage)
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }.resume()
    }
}
