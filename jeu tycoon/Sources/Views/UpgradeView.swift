import SwiftUI

struct UpgradeView: View {
    @Environment(GameManager.self) private var gameManager
    
    // Bonus payés en ADN, affichés dans l'onglet Déblocables (pas Répétables)
    private let adnBonusIds: [UpgradeID] = [
        .bonusEvolutionCost, .bonusAutomationSpeed, .bonusPerkPower, .bonusPrestigeStars
    ]

    private var bonuses: [UpgradeDefinition] {
        UpgradeDefinition.all.filter { $0.category == .bonus && !adnBonusIds.contains($0.id) }
    }

    private var adnBonuses: [UpgradeDefinition] {
        adnBonusIds.compactMap { id in UpgradeDefinition.all.first { $0.id == id } }
    }
    
    // Seules les améliorations de probabilités/rendements restent achetables en ADN.
    // Les déblocages de fonctionnalités s'obtiennent via les Quêtes Secondaires.
    private let unlockChains: [[UpgradeID]] = [
        [.genesCroissants],
        [.occultePenalty, .occultePenalty2, .occultePenalty3, .occultePenalty4, .occultePenalty5],
        [.goldenRitual, .goldenRitual2, .goldenRitual3, .goldenRitual4, .goldenRitual5],
        [.mutationSpontanee, .mutationSpontanee2, .mutationSpontanee3, .mutationSpontanee4],
        [.expertiseRecyclage]
    ]

    // L'Auto-Ouvrier s'achète en ADN, palier par palier, dans l'onglet Automatisation.
    private let autoOuvrierChain: [UpgradeID] = [
        .autoOuvrier, .autoOuvrier2, .autoOuvrier3, .autoOuvrier4, .autoOuvrier5, .autoOuvrier6
    ]

    var visibleUnlockChains: [[UpgradeID]] {
        // Tri par prix d'entrée croissant (coût du premier palier de chaque chaîne),
        // pour un ordre stable qui ne change pas au fil des achats.
        return unlockChains.sorted { entryCost(for: $0) < entryCost(for: $1) }
    }

    private func entryCost(for chain: [UpgradeID]) -> Double {
        guard let firstId = chain.first,
              let def = UpgradeDefinition.all.first(where: { $0.id == firstId }) else { return .greatestFiniteMagnitude }
        return def.baseCost
    }
    
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
                                ForEach(adnBonuses, id: \.id) { def in
                                    LeveledUnlockCard(def: def)
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
                            // Achat de l'Auto-Ouvrier (payé en ADN, palier par palier)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.purple)
                                    Text(tr("Auto-Ouvrier"))
                                        .font(.headline.weight(.bold))
                                }
                                .padding(.horizontal)

                                let autoDisplay = getDisplayUnlock(for: autoOuvrierChain)
                                LazyVGrid(columns: columns, spacing: 12) {
                                    UnlockCard(def: autoDisplay.def, isPurchased: autoDisplay.isPurchased)
                                }
                                .padding(.horizontal)
                            }

                            // Réglage : quelle caisse ouvrir automatiquement (une fois l'Auto-Ouvrier acquis)
                            if gameManager.autoCrateInterval != nil {
                                AutomationToolCard(
                                    icon: "clock.fill",
                                    title: tr("Caisse Auto-Ouverte"),
                                    subtitle: tr("Choisis la caisse ouverte automatiquement."),
                                    color: .purple
                                ) {
                                    AutoCratePicker()
                                }
                                .padding(.horizontal)
                            }

                            if gameManager.isUnlocked(.autoRecycleFilter) {
                                AutomationToolCard(
                                    icon: "line.3.horizontal.decrease.circle.fill",
                                    title: tr("Filtre de Recyclage"),
                                    subtitle: tr("Recycle automatiquement les canards d'une rareté spécifiée."),
                                    color: .green
                                ) {
                                    AutoRecyclePicker()
                                }
                                .padding(.horizontal)
                            }

                            // Section des Auto-Usines (Arbre Stellaire)
                            if gameManager.hasPrestigeUpgrade("p1_auto") {
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

// MARK: - Carte de réglage d'automatisation (récompenses de Quêtes Secondaires)
struct AutomationToolCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [color.opacity(0.2), color.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.bold())
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
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
