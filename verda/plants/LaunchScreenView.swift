//
//  LaunchScreenView.swift
//  plants
//
//  Created by zhanel on 30.03.2025.
//


import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack {
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                scale = 1.0
                                opacity = 1.0
                                rotation = 360
                            }
                        }
                    
                   
                    Text("PlantCare")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.green)
                        .opacity(opacity)
                        .padding(.top, 20)
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
