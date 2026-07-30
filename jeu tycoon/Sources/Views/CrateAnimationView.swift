import SwiftUI
import Combine
import UIKit




// MARK: - Main Animation View
struct CrateAnimationView: View {
    let state: CrateOpeningState
    let onComplete: () -> Void
    
    private var crate: Crate { state.crate }
    private var ducks: [Duck] { state.ducks }
    
    @State private var phase: AnimationPhase = .idle
    @State private var crateScale: CGFloat = 0.3
    @State private var crateRotation: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var glowScale: CGFloat = 1.0
    @State private var flashColor: Color = .clear
    @State private var particles: [Particle] = []
    @State private var revealedCards: Int = 0
    @State private var animationTask: Task<Void, Never>? = nil
    @State private var isJiggling = false
    @State private var jiggleIntensity: Double = 3.0
    @State private var particleTimer: Timer? = nil
    @State private var showTapHint = false
    
    private let haptics = HapticManager.shared
    
    enum AnimationPhase {
        case idle
        case anticipation   // Slow pulse, particles appear
        case intensifying   // Faster jiggle, glow grows
        case exploding      // Flash + burst
        case revealed       // Cards appear
    }
    
    var bestRarity: DuckRarity {
        if !state.summary.isEmpty {
            return state.summary.first?.rarity ?? .commun
        }
        return ducks.map(\.rarity).max() ?? .commun
    }
    
    var aggregatedDucks: [(rarity: DuckRarity, count: Int)] {
        if !state.summary.isEmpty {
            return state.summary
        }
        let grouped = Dictionary(grouping: ducks, by: { $0.rarity })
        return grouped.map { (key, value) in (key, value.count) }
            .sorted { $0.rarity.multiplier > $1.rarity.multiplier }
    }
    
    var body: some View {
        ZStack {
            // Background
            if phase == .revealed {
                revealBackground
            } else {
                DynamicBackgroundView(baseColor: crate.type.accentColor)
            }
            
            // Particles
            ForEach(particles) { particle in
                ParticleView(particle: particle)
            }
            
            if phase != .revealed {
                // Glow behind crate
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [crate.type.accentColor.opacity(glowOpacity), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(glowScale)
                
                // Crate
                crateView
                    .scaleEffect(crateScale)
                    .rotationEffect(.degrees(crateRotation))
            } else {
                // Revealed content
                revealContent
            }
            
            // Flash overlay
            flashColor
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Tap hint
            if showTapHint {
                VStack {
                    Spacer()
                    Text(tr("Appuyer pour continuer"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 60)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: phase)
        .onAppear {
            haptics.prepare()
            startAnimationSequence()
        }
        .onDisappear {
            animationTask?.cancel()
            particleTimer?.invalidate()
        }
        .onTapGesture {
            if phase == .revealed {
                onComplete()
            }
        }
    }
    
    // MARK: - Crate View
    private var crateView: some View {
        ZStack {
            // Outer glow ring
            if phase == .intensifying {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(crate.type.accentColor.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(180 + i * 40), height: CGFloat(180 + i * 40))
                        .scaleEffect(glowScale)
                }
            }
            
            if state.totalCount <= 5 && state.totalCount > 1 {
                // Multiple crates in a circle
                ForEach(0..<state.totalCount, id: \.self) { i in
                    singleCrateIcon(size: 50)
                        .offset(
                            x: 70 * cos(Double(i) * 2 * .pi / Double(state.totalCount) - .pi / 2),
                            y: 70 * sin(Double(i) * 2 * .pi / Double(state.totalCount) - .pi / 2)
                        )
                        .rotationEffect(.degrees(isJiggling ? jiggleIntensity : -jiggleIntensity))
                }
            } else {
                singleCrateIcon(size: 120)
                    .rotationEffect(.degrees(isJiggling ? jiggleIntensity : -jiggleIntensity))
            }
        }
    }
    
    private func singleCrateIcon(size: CGFloat) -> some View {
        ZStack {
            // Cryo-capsule cohérente avec les cartes de la boutique
            CryoCapsuleIcon(type: crate.type, glow: true, size: size)

            // Étincelle de révélation (pilotée par l'animation d'ouverture)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.25))
                .foregroundColor(.white.opacity(glowOpacity))
                .offset(x: -size * 0.15, y: -size * 0.15)
        }
    }
    

    
    // MARK: - Reveal Background
    private var revealBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    bestRarity.color.opacity(0.6),
                    Color(red: 0.05, green: 0.0, blue: 0.12),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Radial highlight
            RadialGradient(
                colors: [bestRarity.color.opacity(0.3), .clear],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Reveal Content
    private var revealContent: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Title with rarity-colored glow
            Text(tr(bestRarity.revealTitle))
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: bestRarity.color.opacity(0.8), radius: 10)
            
            if state.totalCount == 1, !ducks.isEmpty {
                // Single duck — big card with shimmer
                if revealedCards > 0 {
                        RevealDuckCard(duck: ducks[0])
                        .frame(width: 220, height: 260)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.3).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            } else if state.totalCount <= 5 && state.totalCount == ducks.count {
                // Small batch — staggered reveal
                let topCount = min(3, ducks.count)
                let bottomCount = ducks.count - topCount
                
                VStack(spacing: 15) {
                    HStack(spacing: 12) {
                        ForEach(0..<topCount, id: \.self) { i in
                            if revealedCards > i {
                                RevealDuckCard(duck: ducks[i], isCompact: true)
                                    .frame(width: 120, height: 150)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.3).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                        }
                    }
                    if bottomCount > 0 {
                        HStack(spacing: 12) {
                            ForEach(topCount..<ducks.count, id: \.self) { i in
                                if revealedCards > i {
                                    RevealDuckCard(duck: ducks[i], isCompact: true)
                                        .frame(width: 120, height: 150)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.3).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            }
                        }
                    }
                }
            } else {
                // Bulk — aggregated view
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(Array(aggregatedDucks.enumerated()), id: \.element.rarity.rawValue) { index, item in
                        if revealedCards > index {
                            AggregatedDuckCard(rarity: item.rarity, count: item.count)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.3).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
    

    // MARK: - Animation Sequence
    private func startAnimationSequence() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            do {
                // === Phase 1: Entrance (Snappy pop) ===
                phase = .anticipation
                crateScale = 0.1
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    crateScale = 1.0
                }
                haptics.lightTap()
                
                try await Task.sleep(nanoseconds: 250_000_000)
                
                // === Phase 2: Anticipation — Rapid pulses ===
                startOrbitingParticles()
                
                withAnimation(.easeInOut(duration: 0.15).repeatCount(3, autoreverses: true)) {
                    crateScale = 1.1
                    glowOpacity = 0.6
                }
                haptics.lightTap()
                
                try await Task.sleep(nanoseconds: 400_000_000)
                
                // === Phase 3: Intensifying — Violent shake & squash ===
                phase = .intensifying
                
                withAnimation(.easeInOut(duration: 0.04).repeatForever(autoreverses: true)) {
                    isJiggling = true
                }
                
                for i in 0..<4 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    let progress = Double(i + 1) / 4.0
                    withAnimation(.easeOut(duration: 0.1)) {
                        jiggleIntensity = 8.0 + progress * 20.0
                        crateScale = 1.0 - CGFloat(progress) * 0.15 // Squash down slightly
                        glowOpacity = 0.5 + progress * 0.5
                        glowScale = 1.0 + CGFloat(progress) * 0.4
                    }
                    if i % 2 == 0 { haptics.mediumTap() }
                }
                
                haptics.heavyTap()
                
                // === Phase 4: Explosion (BOOM!) ===
                phase = .exploding
                particleTimer?.invalidate()
                
                // Flash color based on best rarity
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    crateScale = 1.6 // Burst out
                }
                
                try await Task.sleep(nanoseconds: 80_000_000)
                
                withAnimation(.easeOut(duration: 0.1)) {
                    flashColor = bestRarity.color.opacity(0.9)
                    crateScale = 0.0
                }
                
                haptics.heavyTap()
                spawnExplosionParticles()
                
                try await Task.sleep(nanoseconds: 100_000_000)
                
                withAnimation(.easeOut(duration: 0.1)) {
                    flashColor = .white.opacity(0.95)
                }
                
                try await Task.sleep(nanoseconds: 150_000_000)
                
                withAnimation(.easeOut(duration: 0.3)) {
                    flashColor = .clear
                    phase = .revealed
                }
                
                // Haptic for rarity
                haptics.rarityReveal(bestRarity)
                
                try await Task.sleep(nanoseconds: 150_000_000)
                
                // === Phase 5: Staggered card reveal ===
                let totalCards: Int
                if state.totalCount == 1 {
                    totalCards = 1
                } else if state.totalCount <= 5 {
                    totalCards = ducks.count
                } else {
                    totalCards = aggregatedDucks.count
                }
                
                for i in 0..<totalCards {
                    try await Task.sleep(nanoseconds: 60_000_000) // Super fast staggered reveal
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        revealedCards = i + 1
                    }
                    haptics.lightTap()
                }
                
                // Show tap hint after a delay
                try await Task.sleep(nanoseconds: 500_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTapHint = true
                }
                
            } catch {
                // Task cancelled
            }
        }
    }
    
    // MARK: - Particle Effects
    private func startOrbitingParticles() {
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        var angle: Double = 0
        
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            let radius: CGFloat = CGFloat.random(in: 100...160)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            let particle = Particle(
                position: CGPoint(x: x, y: y),
                scale: CGFloat.random(in: 0.4...1.0),
                opacity: Double.random(in: 0.5...1.0),
                color: [crate.type.accentColor, .white, .yellow].randomElement()!,
                velocity: .zero,
                rotation: Double.random(in: 0...360)
            )
            
            withAnimation(.easeOut(duration: 0.3)) {
                particles.append(particle)
            }
            
            angle += 0.8
            
            // Fade out old particles
            let particleId = particle.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if let idx = particles.firstIndex(where: { $0.id == particleId }) {
                    _ = withAnimation(.easeOut(duration: 0.3)) {
                        particles.remove(at: idx)
                    }
                }
            }
        }
    }
    
    private func spawnExplosionParticles() {
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        let colors: [Color] = [bestRarity.color, .white, .yellow, bestRarity.color.opacity(0.7)]
        
        for _ in 0..<20 {
            let angle = Double.random(in: 0...2 * .pi)
            let distance: CGFloat = CGFloat.random(in: 80...250)
            let endPoint = CGPoint(
                x: center.x + distance * cos(angle),
                y: center.y + distance * sin(angle)
            )
            
            let particle = Particle(
                position: center,
                scale: CGFloat.random(in: 0.6...1.5),
                opacity: 1.0,
                color: colors.randomElement()!,
                velocity: CGPoint(x: endPoint.x - center.x, y: endPoint.y - center.y),
                rotation: Double.random(in: 0...360)
            )
            
            particles.append(particle)
            
            // Animate to end position
            let particleId = particle.id
            withAnimation(.easeOut(duration: 0.6)) {
                if let idx = particles.firstIndex(where: { $0.id == particleId }) {
                    particles[idx].position = endPoint
                    particles[idx].opacity = 0
                    particles[idx].scale = 0.1
                }
            }
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                particles.removeAll { $0.id == particleId }
            }
        }
    }
}

