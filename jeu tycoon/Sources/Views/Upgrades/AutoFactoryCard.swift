import SwiftUI
import Foundation

// MARK: - Carte Auto-Factory
struct AutoFactoryCard: View {
    @Environment(GameManager.self) private var gameManager
    let factory: DuckFactory
    
    var level: Int { gameManager.autoFactoryLevels[factory.id] ?? 0 }
    let maxLevel = 5

    var cost: BigNumber {
        switch level {
        case 0: return BigNumber(25000.0)
        case 1: return BigNumber(100000.0)
        case 2: return BigNumber(500000.0)
        case 3: return BigNumber(2500000.0)
        case 4: return BigNumber(10000000.0)
        default: return .zero
        }
    }

    var canAfford: Bool {
        gameManager.mutationPoints >= cost
    }

    var effectText: String {
        switch level {
        case 0: return "Auto: Désactivé"
        case 1: return "1 niv / 10s"
        case 2: return "1 niv / 3s"
        case 3: return "1 niv / 1s"
        case 4: return "1 niv / 0.5s"
        case 5: return "1 niv / 0.2s"
        default: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            level == maxLevel
                            ? LinearGradient(colors: [.green.opacity(0.2), .green.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [.orange.opacity(0.2), .orange.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15))
                        .foregroundColor(level == maxLevel ? .green : .orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(factory.name.replacingOccurrences(of: "Usine", with: tr("Usine")))
                        .font(.caption.bold())
                        .lineLimit(1)
                    
                    // Jauge de niveau
                    HStack(spacing: 3) {
                        ForEach(0..<maxLevel, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i < level ? Color.orange : Color.gray.opacity(0.2))
                                .frame(height: 4)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            
            Text(effectText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(level > 0 ? .orange : .gray)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
            
            if level >= maxLevel {
                UpgradeMaxedButton(text: tr("MAX"), color: .green, iconName: "checkmark.circle.fill")
            } else {
                UpgradeSinglePurchaseButton(
                    costStr: cost.formattedString(),
                    currencyIcon: "🧬",
                    canAfford: canAfford,
                    color: .orange,
                    action: {
                        if gameManager.mutationPoints >= cost {
                            gameManager.mutationPoints -= cost
                            gameManager.autoFactoryLevels[factory.id] = level + 1
                            gameManager.saveGame()
                        }
                    }
                )
            }
        }
        .padding(10)
        .frame(height: 140)
        .neonPanel(color: level == maxLevel ? Neon.green : .orange, cornerRadius: 14)
    }
}
