import SwiftUI
import Foundation

/// Carte de bonus permanent affichée dans l'onglet Déblocables : même style visuel
/// que UnlockCard (icône ronde orange + bouton d'achat unique en dégradé orange),
/// mais achète 1 niveau à la fois avec un compteur "n/max".
struct LeveledUnlockCard: View {
    @Environment(GameManager.self) private var gameManager
    let def: UpgradeDefinition

    var currentLevel: Int { gameManager.upgradeLevel(def.id) }
    var isMaxed: Bool { currentLevel >= def.maxLevel }
    var nextCost: BigNumber { def.cost(forNextLevel: currentLevel) }

    var canAfford: Bool {
        if def.currency == .money { return gameManager.money >= nextCost }
        else { return gameManager.mutationPoints >= nextCost }
    }

    var body: some View {
        VStack(spacing: 8) {
            // En-tête : icône ronde + nom
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isMaxed
                            ? LinearGradient(colors: [.green.opacity(0.2), .green.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [.orange.opacity(0.2), .orange.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: isMaxed ? "checkmark.seal.fill" : def.icon)
                        .font(.system(size: 15))
                        .foregroundColor(isMaxed ? .green : .orange)
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
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            // Bouton d'achat
            if isMaxed {
                UpgradeMaxedButton(text: tr("MAX"), color: .green, iconName: "checkmark.circle.fill")
            } else {
                UpgradeSinglePurchaseButton(
                    costStr: nextCost.formattedString(),
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
                .stroke(isMaxed ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: isMaxed ? Color.green.opacity(0.1) : .clear, radius: 4)
    }
}
