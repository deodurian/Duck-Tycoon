import SwiftUI
import Foundation

// MARK: - Carte de Bonus Répétable
struct BonusCard: View {
    @Environment(GameManager.self) private var gameManager
    let def: UpgradeDefinition
    
    var currentLevel: Int  { gameManager.upgradeLevel(def.id) }
    var isMaxed: Bool      { currentLevel >= def.maxLevel }
    var nextCost: BigNumber { def.cost(forNextLevel: currentLevel) }
    
    var canAffordSingle: Bool {
        if def.currency == .money { return gameManager.money >= nextCost }
        else { return gameManager.mutationPoints >= nextCost }
    }
    
    var rarityColor: Color {
        switch def.id {
        case .bonusCommun:      return .gray
        case .bonusPeuCommun:   return .green
        case .bonusRare:        return .blue
        case .bonusEpique:      return .purple
        case .bonusLegendaire:  return .orange
        case .bonusMythique:    return .red
        default:                return .cyan
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // En-tête : Icône et Nom
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [rarityColor.opacity(0.2), rarityColor.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: def.icon)
                        .font(.system(size: 15))
                        .foregroundColor(rarityColor)
                }
                Text(def.name)
                    .font(.caption.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            
            // Effet et Niveau
            HStack {
                Text(def.effectDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 8))
                    if def.maxLevel >= 999999 {
                        Text("Niv \(currentLevel)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    } else {
                        Text("\(currentLevel)/\(def.maxLevel)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(rarityColor)
            }
            
            Spacer(minLength: 0)
            
            // Boutons
            if isMaxed {
                UpgradeMaxedButton(text: tr("MAX"), color: rarityColor, iconName: "crown.fill")
            } else {
                HStack(spacing: 6) {
                    // Bouton x1
                    Button(action: { gameManager.buyUpgrade(def) }) {
                        VStack(spacing: 1) {
                            Text("×1")
                                .font(.system(size: 8, weight: .heavy))
                            HStack(spacing: 2) {
                                Text(nextCost.formattedString())
                                    .font(.system(size: 10, weight: .bold))
                                Text(def.currency == .money ? "💰" : "🧬")
                                    .font(.system(size: 8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            canAffordSingle
                            ? LinearGradient(colors: [rarityColor, rarityColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(canAffordSingle ? .white : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!canAffordSingle)
                    
                    // Bouton MAX
                    let maxInfo = gameManager.calculateMaxUpgrades(for: def)
                    let canAffordMax = maxInfo.levels > 0
                    
                    Button(action: { gameManager.buyMaxUpgrade(def) }) {
                        VStack(spacing: 1) {
                            Text("MAX (+\(maxInfo.levels))")
                                .font(.system(size: 8, weight: .heavy))
                            HStack(spacing: 2) {
                                Text(maxInfo.cost.formattedString())
                                    .font(.system(size: 10, weight: .bold))
                                Text(def.currency == .money ? "💰" : "🧬")
                                    .font(.system(size: 8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            canAffordMax
                            ? LinearGradient(colors: [rarityColor.opacity(0.8), rarityColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(canAffordMax ? .white : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!canAffordMax)
                }
            }
        }
        .padding(10)
        .frame(height: 120)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(currentLevel > 0 ? rarityColor.opacity(0.15) : Color.clear, lineWidth: 1)
        )
    }
}
