import SwiftUI
import Foundation

// MARK: - Particle System
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    var color: Color
    var velocity: CGPoint
    var rotation: Double
}

struct ParticleView: View {
    let particle: Particle
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12))
            .scaleEffect(particle.scale)
            .foregroundColor(particle.color)
            .opacity(particle.opacity)
            .rotationEffect(.degrees(particle.rotation))
            .position(particle.position)
    }
}
