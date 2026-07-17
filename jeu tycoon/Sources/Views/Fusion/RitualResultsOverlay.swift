import SwiftUI
import Foundation

struct RitualResultOverlay: View {
    let success: Bool
    let isGolden: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 16) {
                if isGolden {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .yellow, radius: 20)
                    
                    Text(tr("RITUEL DORÉ !"))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, Color(hue: 0.10, saturation: 0.9, brightness: 1.0)], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .yellow.opacity(0.8), radius: 15)
                    
                    Text(tr("×10"))
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow, radius: 10)
                } else if success {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .green, radius: 20)
                    
                    Text(tr("RITUEL RÉUSSI !"))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .green.opacity(0.8), radius: 15)
                    
                    Text(tr("×2"))
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                        .shadow(color: .green, radius: 10)
                } else {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                        .shadow(color: .red, radius: 20)
                    
                    Text(tr("DÉTRUIT..."))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                        .shadow(color: .red.opacity(0.8), radius: 15)
                    
                    Text(tr("💀"))
                        .font(.system(size: 60))
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
