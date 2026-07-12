import SwiftUI
import Foundation

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: phase * geo.size.width * 1.5)
                    .onAppear {
                        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
                .mask(content)
            )
    }
}

extension View {
    func shimmer(duration: Double = 2.0) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}

// MARK: - Dynamic Background
struct DynamicBackgroundView: View {
    @State private var animate = false
    var baseColor: Color = .blue
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [baseColor.opacity(0.4), .purple.opacity(0.4), baseColor.opacity(0.3)],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            
            // Subtle radial pulse
            RadialGradient(
                colors: [baseColor.opacity(animate ? 0.3 : 0.1), .clear],
                center: .center,
                startRadius: animate ? 50 : 100,
                endRadius: animate ? 300 : 200
            )
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
