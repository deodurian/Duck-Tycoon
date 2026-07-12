import SwiftUI

struct StartScreenView: View {
    @State private var phase: StartPhase = .waitingForTap
    @State private var loadingProgress: CGFloat = 0.0
    @State private var loadingText = "Initialisation..."
    @State private var showGame = false
    
    enum StartPhase {
        case waitingForTap
        case loading
    }
    
    var body: some View {
        if showGame {
            ContentView()
                .transition(.opacity)
        } else {
            ZStack {
                Color(red: 0.05, green: 0.0, blue: 0.12)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("DUCK TYCOON")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 5, x: 0, y: 3)
                        .padding(.bottom, 20)
                    
                    if phase == .waitingForTap {
                        Text("Toucher pour continuer")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .modifier(BlinkEffect())
                    } else if phase == .loading {
                        VStack(spacing: 15) {
                            Text(loadingText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .animation(.none, value: loadingText)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 12)
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(0, min(geo.size.width * loadingProgress, geo.size.width)), height: 12)
                                }
                            }
                            .frame(width: 250, height: 12)
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("v1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if phase == .waitingForTap {
                    startLoading()
                }
            }
        }
    }
    
    private func startLoading() {
        withAnimation {
            phase = .loading
        }
        
        let loadingMessages = [
            "Initialisation du moteur...",
            "Génération des modèles 3D...",
            "Calibrage des incubateurs...",
            "Vérification des mutations ADN...",
            "Mise à jour de la boutique...",
            "Chargement des sauvegardes...",
            "Nettoyage des usines..."
        ]
        
        Task {
            let totalSteps = Int.random(in: 15...22)
            
            for i in 1...totalSteps {
                // Délai aléatoire pour simuler de vrais à-coups de chargement
                let delay = UInt64.random(in: 50_000_000...300_000_000)
                try? await Task.sleep(nanoseconds: delay)
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        loadingProgress = CGFloat(i) / CGFloat(totalSteps)
                    }
                    
                    if Int.random(in: 0...2) == 0 || i == 1 {
                        loadingText = loadingMessages.randomElement() ?? "Chargement..."
                    }
                }
            }
            
            await MainActor.run {
                loadingProgress = 1.0
                loadingText = "Terminé !"
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showGame = true
                }
            }
        }
    }
}

struct BlinkEffect: ViewModifier {
    @State private var isVisible = true
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.3)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
