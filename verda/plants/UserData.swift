//
//  UserData.swift
//  plants
//
//  Created by zhanel on 29.03.2025.
//


// UserData.swift
import SwiftUI
import Foundation


class UserData: ObservableObject {
    @Published var username: String = ""
    @Published var experienceLevel: String = ""
    @Published var dailyTime: String = ""
    @Published var plantsCount: Int = 3
    @Published var points: Int = 150
    @Published var streakDays: Int = 3
    @Published var isLoggedIn: Bool = true
    @Published var lastLoginDate: Date = Date()
    @Published var completedDailyTasks: [DailyTask] = []
    @Published var collectedBadges: [Badge] = [
        Badge(name: "Первый шаг", description: "Зарегистрировался в приложении", icon: "person.fill", color: .blue)
    ]
    
    
    func checkDailyLogin() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastLoginDate) {
            if calendar.isDateInYesterday(lastLoginDate) {
                streakDays += 1
                addPoints(10)
            } else {
                streakDays = 1
            }
            lastLoginDate = Date()
        }
    }
    
    func addPoints(_ amount: Int) {
        points += amount
        checkForNewBadges()
    }
    
    private func checkForNewBadges() {
        
        let newBadges = [
            (points >= 100, Badge(name: "Стартовый набор", description: "Заработал 100 очков", icon: "star.fill", color: .yellow)),
            (points >= 300, Badge(name: "Опытный садовод", description: "Заработал 300 очков", icon: "leaf.fill", color: .green)),
            (streakDays >= 7, Badge(name: "Неделя заботы", description: "7 дней подряд", icon: "flame.fill", color: .orange))
        ]
        
        newBadges.forEach { condition, badge in
            if condition && !collectedBadges.contains(where: { $0.name == badge.name }) {
                collectedBadges.append(badge)
            }
        }
    }
    
    func completeTask(_ task: DailyTask) {
        if !completedDailyTasks.contains(where: { $0.id == task.id }) {
            completedDailyTasks.append(task)
            addPoints(task.pointReward)
        }
    }
}

struct Badge: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let description: String
        let icon: String
        let color: Color
    }
    
    struct DailyTask: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let icon: String
        let pointReward: Int
        var isCompleted: Bool = false
    }
