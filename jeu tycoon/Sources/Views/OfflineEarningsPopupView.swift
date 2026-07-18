import SwiftUI

struct OfflineEarningsPopupView: View {
    @Environment(GameManager.self) private var gameManager
    
    var body: some View {
        if let earnings = gameManager.pendingOfflineEarnings {
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .highPriorityGesture(DragGesture(minimumDistance: 0))
                
                VStack(spacing: 25) {
                    Text(tr("De Retour !"))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue, radius: 5)
                    
                    Text("\(tr("Pendant votre absence"))\n(\(formatTime(earnings.seconds)))")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 15) {
                        HStack {
                            Text(tr("💰"))
                                .font(.title)
                            Text(earnings.money.formattedString())
                                .font(.title2.bold())
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack {
                            Text(tr("🧬"))
                                .font(.title)
                            Text(earnings.dna.formattedString())
                                .font(.title2.bold())
                                .foregroundColor(.purple)
                            Spacer()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack {
                            Text(tr("⭐"))
                                .font(.title)
                            Text("\(earnings.xp)\(tr(" XP"))")
                                .font(.title2.bold())
                                .foregroundColor(.yellow)
                            Spacer()
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        Button(action: {
                            AdManager.shared.showRewardedAd { earned in
                                if earned {
                                    withAnimation {
                                        gameManager.claimOfflineEarnings(multiplier: 2.0)
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Text(tr("Récupérer X2"))
                                    .font(.headline.bold())
                                Spacer()
                                Image(systemName: "play.tv.fill")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .orange.opacity(0.5), radius: 5)
                        }
                        
                        Button(action: {
                            withAnimation {
                                gameManager.claimOfflineEarnings(multiplier: 1.0)
                            }
                        }) {
                            Text(tr("Récupérer"))
                                .font(.subheadline.bold())
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 30)
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                .padding(30)
                .shadow(radius: 20)
            }
            .transition(.scale.combined(with: .opacity))
            .zIndex(100)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(max(1, minutes)) minutes"
        }
    }
}
