import SwiftUI
import Foundation

// MARK: - Champ d'étoiles
struct StarFieldView: View {
    @State private var stars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double, speed: Double)] = []
    @State private var animateTick = false
    
    var body: some View {
        Canvas { context, size in
            for star in stars {
                let phase = animateTick ? 1.0 : 0.0
                let flicker = star.opacity * (0.5 + 0.5 * sin(phase * .pi * 2 * star.speed))
                let rect = CGRect(
                    x: star.x * size.width,
                    y: star.y * size.height,
                    width: star.size,
                    height: star.size
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(flicker))
                )
            }
        }
        .onAppear {
            stars = (0..<60).map { _ in
                (
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    size: CGFloat.random(in: 1...3),
                    opacity: Double.random(in: 0.2...0.7),
                    speed: Double.random(in: 0.3...1.5)
                )
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: true)) {
                animateTick = true
            }
        }
    }
}
