import SwiftUI

struct FusionAnimationView: View {
    let ducksToAnimate: [(rarity: DuckRarity, level: Int)]
    let resultingDuck: (rarity: DuckRarity, level: Int)?
    let onComplete: () -> Void
    
    @State private var rotation: Double = 0
    @State private var radius: CGFloat = 120
    @State private var isFlashing = false
    @State private var flashScale: CGFloat = 0.1
    @State private var flashOpacity: Double = 0
    @State private var appearOpacity: Double = 0
    
    @State private var showResultDuck = false
    @State private var resultDuckScale: CGFloat = 0.1
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Spinning ducks
            if !showResultDuck {
                ZStack {
                    ForEach(0..<ducksToAnimate.count, id: \.self) { index in
                        let duck = ducksToAnimate[index]
                        let baseAngle = (Double(index) / Double(ducksToAnimate.count)) * 360.0
                        
                        ZStack {
                            VStack(spacing: 2) {
                                Image(duck.rarity.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                Text("Lv.\(duck.level)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            }
                            .frame(width: 60, height: 60)
                            .background(duck.rarity.color.opacity(0.8))
                            .cornerRadius(8)
                            .fusionBorder(level: duck.level, rarityColor: duck.rarity.color)
                        }
                        // 1. Contre-balancer la rotation globale et la position de base pour rester droit
                        .rotationEffect(.degrees(-rotation - baseAngle))
                        // 2. S'éloigner du centre
                        .offset(y: -radius)
                        // 3. Se positionner sur le cercle
                        .rotationEffect(.degrees(baseAngle))
                    }
                }
                // 4. Rotation globale de tout le groupe
                .rotationEffect(.degrees(rotation))
            }
            
            // Resulting Duck
            if showResultDuck, let resDuck = resultingDuck {
                ZStack {
                    VStack(spacing: 2) {
                        Image(resDuck.rarity.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("Lv.\(resDuck.level)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .background(resDuck.rarity.color.opacity(0.9))
                    .cornerRadius(8)
                    .fusionBorder(level: resDuck.level, rarityColor: resDuck.rarity.color)
                    .shadow(color: resDuck.rarity.color, radius: 10)
                }
                .scaleEffect(resultDuckScale)
            }
            
            // Flash effect
            if isFlashing {
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .scaleEffect(flashScale)
                    .opacity(flashOpacity)
            }
        }
        .opacity(appearOpacity)
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.3)) {
                appearOpacity = 1.0
            }
            
            // Lancer la première phase de rotation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 1. Tourner d'un tour complet (360 degrés) en 1 seconde
                withAnimation(.linear(duration: 1.0)) {
                    rotation = 360
                }
                
                // 2. Converger vers le centre (et faire un tour de plus)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        radius = 0
                        rotation = 720
                    }
                    
                    // 3. Flasher
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFlashing = true
                        flashOpacity = 1.0
                        
                        if resultingDuck != nil {
                            showResultDuck = true
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                                resultDuckScale = 2.5
                            }
                        }
                        
                        withAnimation(.easeOut(duration: 0.5)) {
                            flashScale = 20.0
                            flashOpacity = 0.0
                        }
                        
                        // 4. Finir l'animation
                        let delay = resultingDuck != nil ? 1.5 : 0.5
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            onComplete()
                        }
                    }
                }
            }
        }
    }
    
}
