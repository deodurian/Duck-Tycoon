import SwiftUI

struct UpgradeView: View {
    @Environment(GameManager.self) private var gameManager
    
    private let bonuses  = UpgradeDefinition.all.filter { $0.category == .bonus }
    
    private let unlockChains: [[UpgradeID]] = [
        [.multipleOpenX5, .multipleOpenX10, .multipleOpenMax],
        [.holdToOpen],
        [.inventory1000, .inventory5000, .inventory10000],
        [.autoRecycleFilter],
        [.genesCroissants],
        [.occultePenalty, .occultePenalty2, .occultePenalty3, .occultePenalty4, .occultePenalty5],
        [.goldenRitual, .goldenRitual2, .goldenRitual3, .goldenRitual4, .goldenRitual5],
        [.mutationSpontanee, .mutationSpontanee2, .mutationSpontanee3, .mutationSpontanee4],
        [.expertiseRecyclage],
        [.annihilation]
    ]
    
    var visibleUnlockChains: [[UpgradeID]] {
        var chains = unlockChains
        chains.insert([.manualFusion, .autoFusion, .megaFusion], at: 0)
        chains.insert([.bulkRecycle], at: 4) // Position doesn't matter too much
        return chains
    }
    
    private let automatisationChains: [[UpgradeID]] = [
        [.autoOuvrier, .autoOuvrier2, .autoOuvrier3, .autoOuvrier4]
    ]
    
    @State private var selectedTab: UpgradeTabType = .repetable
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(tr("Améliorations"))
                    .font(.largeTitle.bold())
                Spacer()
            }
            .padding([.horizontal, .top])
            
            // Onglets stylisés
                HStack(spacing: 4) {
                    ForEach(UpgradeTabType.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14))
                                Text(tr(tab.rawValue))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedTab == tab
                                ? tab.color.opacity(0.15)
                                : Color.clear
                            )
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedTab == tab ? tab.color.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.clear)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == .deblocage {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(0..<visibleUnlockChains.count, id: \.self) { index in
                                    let chain = visibleUnlockChains[index]
                                    let displayData = getDisplayUnlock(for: chain)
                                    UnlockCard(def: displayData.def, isPurchased: displayData.isPurchased)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        } else if selectedTab == .repetable {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(bonuses, id: \.id) { def in
                                    BonusCard(def: def)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        } else if selectedTab == .automatisation {
                            if gameManager.hasPrestigeUpgrade("p1_auto") {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(0..<automatisationChains.count, id: \.self) { index in
                                        let chain = automatisationChains[index]
                                        let displayData = getDisplayUnlock(for: chain)
                                        UnlockCard(def: displayData.def, isPurchased: displayData.isPurchased)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 24)
                                
                                // Section des Auto-Usines
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "gearshape.2.fill")
                                            .foregroundColor(.orange)
                                        Text(tr("Auto-Amélioration Usine"))
                                            .font(.headline.weight(.bold))
                                    }
                                    .padding(.horizontal)
                                    
                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(gameManager.factories) { factory in
                                            AutoFactoryCard(factory: factory)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.bottom, 24)
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 44))
                                        .foregroundStyle(
                                            LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                        )
                                    Text(tr("Débloqué via l'Arbre Stellaire"))
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Text(tr("Achetez « Automatisation Initiale » dans le Prestige."))
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(30)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                                .padding(.top, 20)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 50)
                }
                .background(Color.clear)
            }
    }

    private func getDisplayUnlock(for chain: [UpgradeID]) -> (def: UpgradeDefinition, isPurchased: Bool) {
        for id in chain {
            if !gameManager.isUnlocked(id) {
                return (UpgradeDefinition.all.first(where: { $0.id == id }) ?? UpgradeDefinition.all[0], false)
            }
        }
        let lastId = chain.last ?? chain[0]
        return (UpgradeDefinition.all.first(where: { $0.id == lastId }) ?? UpgradeDefinition.all[0], true)
    }
}

struct UpgradeMaxedButton: View {
    let text: String
    let color: Color
    let iconName: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10))
            Text(text)
                .font(.caption2.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct UpgradeSinglePurchaseButton: View {
    let costStr: String
    let currencyIcon: String
    let canAfford: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(costStr)
                    .font(.caption2.bold())
                Text(currencyIcon)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                canAfford
                ? LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(canAfford ? .white : .gray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!canAfford)
    }
}
