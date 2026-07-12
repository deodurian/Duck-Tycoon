import SwiftUI
import Foundation

// MARK: - Reveal Duck Card (Premium)
struct RevealDuckCard: View {
    let duck: Duck
    var isCompact: Bool = false
    @State private var shimmerPhase: CGFloat = -1
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            duck.rarity.color,
                            duck.rarity.color.opacity(0.6),
                            duck.rarity.color.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: duck.rarity.color.opacity(0.6), radius: appeared ? 12 : 0)
            
            // Border glow
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), duck.rarity.color.opacity(0.3), .white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            VStack(spacing: isCompact ? 4 : 8) {
                Image(duck.rarity.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isCompact ? 45 : 80, height: isCompact ? 45 : 80)
                    .shadow(color: .white.opacity(0.5), radius: 5)
                
                Text(duck.rarity.rawValue)
                    .font(isCompact ? .caption.bold() : .headline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                if !isCompact {
                    // Show size and mutation if special
                    HStack(spacing: 4) {
                        if duck.size != .petit {
                            Text(duck.size.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if duck.mutation != .aucune {
                            Text(duck.mutation.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(isCompact ? 6 : 12)
            
                // Shimmer sweep
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.5, height: geo.size.height * 2)
                    .rotationEffect(.degrees(20))
                    .offset(x: shimmerPhase * geo.size.width * 2 - geo.size.width * 0.5, y: -geo.size.height * 0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            // Delayed shimmer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    shimmerPhase = 1.5
                }
            }
        }
    }
}

// MARK: - Aggregated Duck Card (Premium)
struct AggregatedDuckCard: View {
    let rarity: DuckRarity
    let count: Int
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 6) {
            Image(rarity.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .shadow(color: .white.opacity(0.4), radius: 3)
            
            Text(rarity.rawValue)
                .font(.caption2.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text("x\(count)")
                .font(.title3.bold())
                .foregroundColor(.white)
                .shadow(color: rarity.color, radius: 4)
        }
        .frame(width: 110, height: 125)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [rarity.color, rarity.color.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
            .shadow(color: rarity.color.opacity(appeared ? 0.5 : 0), radius: 8)
        )
        .scaleEffect(appeared ? 1.0 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}
