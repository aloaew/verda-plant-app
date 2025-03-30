//
//  ChatMessage.swift
//  plants
//
//  Created by zhanel on 29.03.2025.
//


// MARK: - ChatMessage.swift
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
