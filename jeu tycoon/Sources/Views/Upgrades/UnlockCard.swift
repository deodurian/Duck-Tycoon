import SwiftUI
import Foundation

// MARK: - Carte de Déblocage
struct UnlockCard: View {
    @Environment(GameManager.self) private var gameManager
    let def: UpgradeDefinition
    let isPurchased: Bool
    
    var canAfford: Bool {
        if def.currency == .money {
            return gameManager.money >= def.baseCost
        } else {
            return gameManager.mutationPoints >= BigNumber(def.baseCost)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // En-tête : Icône et Nom
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isPurchased
                            ? LinearGradient(colors: [.green.opacity(0.2), .green.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [.orange.opacity(0.2), .orange.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: isPurchased ? "checkmark.seal.fill" : def.icon)
                        .font(.system(size: 15))
                        .foregroundColor(isPurchased ? .green : .orange)
                }
                Text(tr(def.name))
                    .font(.caption.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            
            // Description
            Text(tr(def.effectDescription))
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Menu de filtre si c'est le autoRecycleFilter acheté
            if isPurchased && def.id == .autoRecycleFilter {
                AutoRecyclePicker()
            }
            
            // Menu de sélection de caisse si c'est l'Auto-Ouvrier
            if gameManager.isUnlocked(.autoOuvrier) && (def.id == .autoOuvrier || def.id == .autoOuvrier2 || def.id == .autoOuvrier3 || def.id == .autoOuvrier4) {
                AutoCratePicker()
            }
            
            Spacer(minLength: 0)
            
            // Bouton
            if isPurchased {
                UpgradeMaxedButton(text: tr("ACQUIS"), color: .green, iconName: "checkmark.circle.fill")
            } else {
                UpgradeSinglePurchaseButton(
                    costStr: BigNumber(def.baseCost).formattedString(),
                    currencyIcon: def.currency == .money ? "💰" : "🧬",
                    canAfford: canAfford,
                    color: .orange,
                    action: { gameManager.buyUpgrade(def) }
                )
            }
        }
        .padding(10)
        .frame(height: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isPurchased ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: isPurchased ? Color.green.opacity(0.1) : .clear, radius: 4)
    }
}
