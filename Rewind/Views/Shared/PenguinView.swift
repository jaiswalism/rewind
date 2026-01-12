//
//  PenguinView.swift
//  Rewind
//
//  Created on 12/26/25.
//

import SwiftUI

struct PenguinView: View {
    let mood: Int
    let energy: Int
    let behaviorPolicy: BehaviorPolicy
    
    @State private var breathingScale: CGFloat = 1.0
    @State private var headTilt: Double = 0.0
    @State private var isBlinking: Bool = false
    @State private var blinkTimer: Timer?
    @State private var breathingTimer: Timer?
    @State private var breathingPhase: Double = 0.0
    
    @State private var leftWingRotation: Double = 0.0
    @State private var rightWingRotation: Double = 0.0
    @State private var isWaving: Bool = false
    @State private var waveTimer: Timer?
    @State private var verticalOffset: CGFloat = 0.0
    @State private var isJumping: Bool = false
    @State private var jumpTimer: Timer?
    @State private var horizontalOffset: CGFloat = 0.0
    @State private var isWalking: Bool = false
    @State private var walkTimer: Timer?
    @State private var walkDirection: CGFloat = 1.0
    
    private var breathingMaxScale: CGFloat {
        switch energy {
        case 0...30:
            return 1.02
        case 31...70:
            return 1.04
        case 71...100:
            return 1.06
        default:
            return 1.04
        }
    }
    
    private var breathingDuration: Double {
        let baseDuration = 3.0
        let energyFactor = Double(energy) / 100.0
        return baseDuration + (1.0 - energyFactor) * 1.5
    }
    
    private var targetHeadTilt: Double {
        switch mood {
        case 0...30:
            return -3.0
        case 31...70:
            return 0.0
        case 71...100:
            return 3.0
        default:
            return 0.0
        }
    }
    
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.25),
                            Color.black.opacity(0.08),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 15,
                        endRadius: 55
                    )
                )
                .frame(width: 130, height: 35)
                .blur(radius: 10)
                .offset(y: 100 + verticalOffset)
                .scaleEffect(breathingScale * 0.96)
            
            Ellipse()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black,
                            Color.black.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 160)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt))
                .offset(x: horizontalOffset, y: 30 + verticalOffset)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.white.opacity(0.98)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 140)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt))
                .offset(x: horizontalOffset, y: 35 + verticalOffset)
            
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black,
                            Color.black.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 90, height: 90)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt))
                .offset(x: horizontalOffset, y: -45 + verticalOffset)
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
            
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.white.opacity(0.98)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 75, height: 75)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt))
                .offset(x: horizontalOffset, y: -42 + verticalOffset)
            
            WingShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black,
                            Color.black.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 35, height: 85)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt + leftWingRotation))
                .offset(x: -60 + horizontalOffset, y: 15 + verticalOffset)
                .animation(.easeInOut(duration: 0.3), value: leftWingRotation)
                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 2, y: 2)
            
            WingShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black,
                            Color.black.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 35, height: 85)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt + rightWingRotation))
                .offset(x: 60 + horizontalOffset, y: 15 + verticalOffset)
                .animation(.easeInOut(duration: 0.3), value: rightWingRotation)
                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 2, y: 2)
            
            FootShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange,
                            Color(red: 1.0, green: 0.65, blue: 0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 32, height: 20)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt))
                .offset(x: -20 + horizontalOffset, y: 100 + verticalOffset)
                .shadow(color: Color.orange.opacity(0.3), radius: 3, x: 0, y: 2)
            
            FootShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange,
                            Color(red: 1.0, green: 0.65, blue: 0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 32, height: 20)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt))
                .offset(x: 20 + horizontalOffset, y: 100 + verticalOffset)
                .shadow(color: Color.orange.opacity(0.3), radius: 3, x: 0, y: 2)
            
            BeakShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange,
                            Color(red: 1.0, green: 0.6, blue: 0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 18, height: 14)
                .scaleEffect(breathingScale)
                .rotationEffect(.degrees(headTilt))
                .offset(x: horizontalOffset, y: -30 + verticalOffset)
                .shadow(color: Color.orange.opacity(0.4), radius: 2, x: 0, y: 1)
            
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 26, height: isBlinking ? 3 : 26)
                    .offset(x: 1, y: 1)
                    .blur(radius: 2)
                
                Circle()
                    .fill(Color.black)
                    .frame(width: 24, height: isBlinking ? 3 : 24)
                
                if !isBlinking {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.5),
                                    Color.clear
                                ]),
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 12
                            )
                        )
                        .frame(width: 14, height: 14)
                        .offset(x: -6, y: -6)
                }
            }
            .offset(x: -18 + horizontalOffset, y: -42 + verticalOffset)
            .scaleEffect(breathingScale)
            .rotationEffect(.degrees(headTilt))
            .animation(.easeInOut(duration: 0.1), value: isBlinking)
            
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 26, height: isBlinking ? 3 : 26)
                    .offset(x: 1, y: 1)
                    .blur(radius: 2)
                
                Circle()
                    .fill(Color.black)
                    .frame(width: 24, height: isBlinking ? 3 : 24)
                
                if !isBlinking {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.5),
                                    Color.clear
                                ]),
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 12
                            )
                        )
                        .frame(width: 14, height: 14)
                        .offset(x: -6, y: -6)
                }
            }
            .offset(x: 18 + horizontalOffset, y: -42 + verticalOffset)
            .scaleEffect(breathingScale)
            .rotationEffect(.degrees(headTilt))
            .animation(.easeInOut(duration: 0.1), value: isBlinking)
        }
        .onAppear {
            startBreathingAnimation()
            startHeadTiltAnimation()
            startBlinkingAnimation()
            startWavingAnimation()
            startJumpingAnimation()
            startWalkingAnimation()
        }
        .onChange(of: energy) { _ in
            updateBreathingAnimation()
        }
        .onChange(of: mood) { _ in
            updateHeadTiltAnimation()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    struct WingShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let centerX = rect.midX
            let topY = rect.minY + rect.height * 0.05
            let bottomY = rect.maxY - rect.height * 0.05
            
            path.move(to: CGPoint(x: centerX, y: topY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY),
                control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25)
            )
            path.addQuadCurve(
                to: CGPoint(x: centerX, y: bottomY),
                control: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY - rect.height * 0.15)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.midY),
                control: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.15)
            )
            path.addQuadCurve(
                to: CGPoint(x: centerX, y: topY),
                control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25)
            )
            path.closeSubpath()
            return path
        }
    }
    
    struct FootShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.2))
            path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.midY),
                control: CGPoint(x: rect.midX, y: rect.minY)
            )
            path.closeSubpath()
            return path
        }
    }
    
    struct BeakShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
    
    private func startBreathingAnimation() {
        let updateInterval = 0.016
        breathingTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            self.updateBreathingPhase(updateInterval: updateInterval)
        }
        if let timer = breathingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func updateBreathingPhase(updateInterval: Double) {
        let phaseIncrement = (updateInterval * 2.0 * .pi) / breathingDuration
        breathingPhase += phaseIncrement
        
        if breathingPhase >= 2.0 * .pi {
            breathingPhase -= 2.0 * .pi
        }
        
        let sineValue = sin(breathingPhase)
        let normalizedValue = (sineValue + 1.0) / 2.0
        let newScale = 1.0 + (breathingMaxScale - 1.0) * normalizedValue
        
        breathingScale = newScale
    }
    
    private func updateBreathingAnimation() {
    }
    
    private func startHeadTiltAnimation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            headTilt = targetHeadTilt
        }
    }
    
    private func updateHeadTiltAnimation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            headTilt = targetHeadTilt
        }
    }
    
    private func startBlinkingAnimation() {
        scheduleNextBlink()
    }
    
    private func scheduleNextBlink() {
        let randomInterval = Double.random(in: 6.0...10.0)
        
        blinkTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
            performBlink()
        }
    }
    
    private func performBlink() {
        withAnimation(.linear(duration: 0.03)) {
            isBlinking = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            withAnimation(.linear(duration: 0.03)) {
                isBlinking = false
            }
            
            scheduleNextBlink()
        }
    }
    
    private func startWavingAnimation() {
        scheduleNextWave()
    }
    
    private func scheduleNextWave() {
        let randomInterval = Double.random(in: 8.0...15.0)
        
        waveTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
            performWave()
        }
    }
    
    private func performWave() {
        isWaving = true
        
        let waveCount = 3
        var currentWave = 0
        
        func waveCycle() {
            withAnimation(.easeInOut(duration: 0.15)) {
                rightWingRotation = -60.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    rightWingRotation = -20.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    currentWave += 1
                    if currentWave < waveCount {
                        waveCycle()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            rightWingRotation = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isWaving = false
                            scheduleNextWave()
                        }
                    }
                }
            }
        }
        
        waveCycle()
    }
    
    private func startJumpingAnimation() {
        scheduleNextJump()
    }
    
    private func scheduleNextJump() {
        let randomInterval = Double.random(in: 10.0...20.0)
        
        jumpTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
            performJump()
        }
    }
    
    private func performJump() {
        isJumping = true
        
        withAnimation(.easeOut(duration: 0.3)) {
            verticalOffset = -40.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.3)) {
                verticalOffset = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isJumping = false
                scheduleNextJump()
            }
        }
    }
    
    private func startWalkingAnimation() {
        scheduleNextWalk()
    }
    
    private func scheduleNextWalk() {
        let randomInterval = Double.random(in: 12.0...25.0)
        
        walkTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
            performWalk()
        }
    }
    
    private func performWalk() {
        isWalking = true
        let walkDistance: CGFloat = 150.0
        let walkDuration: Double = 1.5
        
        withAnimation(.easeInOut(duration: walkDuration)) {
            horizontalOffset = walkDistance * walkDirection
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + walkDuration) {
            withAnimation(.easeInOut(duration: walkDuration)) {
                horizontalOffset = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + walkDuration) {
                walkDirection *= -1.0
                isWalking = false
                scheduleNextWalk()
            }
        }
    }
    
    private func stopAnimations() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        breathingTimer?.invalidate()
        breathingTimer = nil
        waveTimer?.invalidate()
        waveTimer = nil
        jumpTimer?.invalidate()
        jumpTimer = nil
        walkTimer?.invalidate()
        walkTimer = nil
    }
}
