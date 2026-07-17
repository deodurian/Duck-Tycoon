import SwiftUI
import Foundation

// MARK: - Feuille de détails de compétence
struct PrestigeUpgradeDetailSheet: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    let upgrade: PrestigeUpgrade
    
    var isPurchased: Bool { gameManager.hasPrestigeUpgrade(upgrade.id) }
    var isUnlocked: Bool { gameManager.spentStars >= upgrade.requiredSpentStars }
    var canAfford: Bool { gameManager.unspentStars >= upgrade.cost }
    
    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(tr(upgrade.name))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Text("Palier \(upgrade.tier)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.gray)
                        Text(tr("•"))
                            .foregroundColor(.gray)
                        Text("\(upgrade.cost) ⭐️")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.top, 24)
                
                // Description
                Text(tr(upgrade.description))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Status / Buy Button
                if isPurchased {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                        Text(tr("Compétence Acquise"))
                            .font(.headline.weight(.bold))
                    }
                    .foregroundColor(.green)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 24)
                } else if !isUnlocked {
                    VStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(.red.opacity(0.7))
                        Text("Nécessite \(upgrade.requiredSpentStars) étoiles dépensées")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .padding()
                } else {
                    VStack(spacing: 10) {
                        Button(action: {
                            if canAfford {
                                gameManager.buyPrestigeUpgrade(upgrade)
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.headline)
                                Text("Acheter pour \(upgrade.cost)")
                                    .font(.headline.weight(.bold))
                                Image(systemName: "star.fill")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                canAfford
                                ? AnyShapeStyle(LinearGradient(colors: [.yellow, Color(hue: 0.12, saturation: 0.8, brightness: 1.0)], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.gray.opacity(0.3))
                            )
                            .foregroundColor(canAfford ? .black : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: canAfford ? .yellow.opacity(0.3) : .clear, radius: 8, y: 4)
                        }
                        .disabled(!canAfford)
                        .padding(.horizontal, 24)
                        
                        if !canAfford {
                            Text(tr("Étoiles libres insuffisantes."))
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}
