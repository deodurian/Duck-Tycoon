import SwiftUI

/// Pluie de confettis en SwiftUI pur (Canvas + TimelineView), sans dépendance SpriteKit.
/// Chaque incrément de `trigger` relance une salve qui retombe puis disparaît.
struct ConfettiView: View {
    /// Compteur monotone : incrémenté pour déclencher une nouvelle salve.
    let trigger: Int

    @State private var particles: [ConfettiParticle] = []
    @State private var startDate = Date()
    /// Hors salve, le `Canvas` ne dessinait rien mais le `TimelineView(.animation)` réclamait
    /// quand même une image à CHAQUE rafraîchissement d'écran (60–120 Hz), pendant toute la session,
    /// puisque cette vue est montée en permanence par ContentView. On coupe donc l'horloge
    /// entre deux salves : rendu strictement identique, écran au repos entre les célébrations.
    @State private var isRunning = false
    @State private var stopTask: Task<Void, Never>?

    // Palette Cyber-Génétique
    private let colors: [Color] = [Neon.green, Neon.yellow, Neon.magenta, Neon.cyan, Neon.purple]
    private let duration: Double = 2.4

    var body: some View {
        GeometryReader { geo in
            if isRunning {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    guard elapsed < duration else { return }

                    for p in particles {
                        let progress = elapsed
                        let x = p.startX * size.width + p.driftX * progress
                        let y = p.startY * size.height + (p.velocityY * progress + 0.5 * 900 * progress * progress)
                        guard y < size.height + 30 else { continue }

                        let angle = p.rotationSpeed * progress
                        let opacity = max(0, 1 - (elapsed / duration))

                        var ctx = context
                        ctx.opacity = opacity
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: .radians(angle))
                        ctx.addFilter(.shadow(color: p.color.opacity(0.8), radius: 2))

                        let s = p.size
                        switch p.shape {
                        case .helix:
                            // Brin d'ADN : capsule fine
                            ctx.fill(Path(roundedRect: CGRect(x: -s / 2, y: -s * 0.9, width: s, height: s * 1.8), cornerRadius: s / 2), with: .color(p.color))
                        case .orb:
                            // Orbe d'énergie
                            ctx.fill(Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s)), with: .color(p.color))
                        case .spark:
                            // Éclat / éclair
                            ctx.fill(Path(CGRect(x: -s * 0.12, y: -s, width: s * 0.24, height: s * 2)), with: .color(p.color))
                        }
                    }
                }
            }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            spawn()
        }
        .onDisappear {
            stopTask?.cancel()
            stopTask = nil
            isRunning = false
        }
    }

    private func spawn() {
        let shapes: [ConfettiParticle.Shape] = [.helix, .orb, .spark]
        var newParticles: [ConfettiParticle] = []
        for _ in 0..<70 {
            newParticles.append(
                ConfettiParticle(
                    startX: Double.random(in: 0.1...0.9),
                    startY: Double.random(in: -0.1...0.05),
                    driftX: Double.random(in: -60...60),
                    velocityY: Double.random(in: 60...200),
                    rotationSpeed: Double.random(in: -6...6),
                    size: Double.random(in: 6...11),
                    color: colors.randomElement() ?? Neon.green,
                    shape: shapes.randomElement() ?? .orb
                )
            )
        }
        particles = newParticles
        startDate = Date()
        isRunning = true

        // On relance l'horloge le temps de la salve, puis on la coupe.
        stopTask?.cancel()
        stopTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.15) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            isRunning = false
            particles = []
        }
    }
}

private struct ConfettiParticle: Identifiable {
    enum Shape { case helix, orb, spark }
    let id = UUID()
    let startX: Double
    let startY: Double
    let driftX: Double
    let velocityY: Double
    let rotationSpeed: Double
    let size: Double
    let color: Color
    let shape: Shape
}
