import SwiftUI

struct PerkSelectionSheet: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss
    
    let targetId: UUID
    let targetType: TargetType
    enum TargetType { case factory, duck }
    
    var body: some View {
        NavigationStack {
            ZStack {
                NeonBackground()

                ScrollView {
                    VStack(spacing: 20) {

                        // --- SECTION : PERKS ÉQUIPÉS ---
                        // Toutes ces valeurs étaient re-calculées DANS chaque ligne de la liste,
                        // chacune avec un balayage complet de l'inventaire (jusqu'à 10 000 canards).
                        // On les résout une seule fois ici : mêmes valeurs, donc affichage identique.
                        let targetDuck: Duck? = targetType == .duck ? gameManager.inventory.first(where: { $0.id == targetId }) : nil
                        let targetDuckStats = targetDuck.map { gameManager.getDynamicStats(for: $0) }
                        // Ensemble des perks équipés partout (usines + canards) : remplace à la fois
                        // `isPerkEquippedAnywhere` (1 balayage par ligne) et le badge « ÉQUIPÉ » de
                        // PerkCardView (2 balayages par carte). `contains` donne le même booléen.
                        let allEquippedPerkIds: Set<UUID> = Set(gameManager.factories.flatMap { $0.equippedPerkIds })
                            .union(gameManager.inventory.flatMap { $0.equippedPerkIds })
                        // Réutilise la cible déjà résolue au lieu d'un second scan de l'inventaire.
                        let equippedIds: [UUID] = targetType == .duck ? (targetDuck?.equippedPerkIds ?? []) : getEquippedPerks()
                        // Le nombre d'emplacements ne dépend pas de la ligne affichée : il était
                        // pourtant recalculé pour CHAQUE perk de la liste.
                        let maxSlots = getMaxSlots()
                        let isSlotFull = equippedIds.count >= maxSlots

                        if !equippedIds.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text(tr("Perks Équipés"))
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal)

                                ForEach(equippedIds, id: \.self) { perkId in
                                    if let perk = gameManager.perksInventory.first(where: { $0.id == perkId }) {
                                        PerkCardView(perk: perk, allEquippedPerkIds: allEquippedPerkIds)
                                            .overlay(alignment: .topTrailing) {
                                                Button(action: {
                                                    gameManager.unequipPerk(perk.id, from: targetId)
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.title2)
                                                        .foregroundColor(.red)
                                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // --- SECTION : PERKS DISPONIBLES ---
                        let perkType: PerkType = targetType == .factory ? .factory : .duck
                        let allTypePerks = gameManager.perks(for: perkType)
                        let selectionPerks = allTypePerks.filter { !equippedIds.contains($0.id) }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundColor(.purple)
                                    Text(tr("Perks Disponibles"))
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()

                                let isFull = isSlotFull   // même expression qu'avant : equippedIds.count >= maxSlots
                                Text("\(equippedIds.count)/\(maxSlots) \(tr("emplacements"))")
                                    .font(.caption.bold())
                                    .foregroundColor(isFull ? .red : .green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill((isFull ? Color.red : Color.green).opacity(0.12)))
                                    .overlay(Capsule().stroke((isFull ? Color.red : Color.green).opacity(0.35), lineWidth: 1))
                            }
                            .padding(.horizontal)

                            if selectionPerks.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles.rectangle.stack")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.2))
                                    Text(tr("Aucun perk disponible de ce type."))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(selectionPerks) { perk in
                                        let isEquippedAnywhere = allEquippedPerkIds.contains(perk.id)

                                        let overflowMessages = getOverflowMessages(for: perk, duck: targetDuck, stats: targetDuckStats, isEquippedAnywhere: isEquippedAnywhere, isSlotFull: isSlotFull)

                                        VStack(spacing: 4) {
                                            if !overflowMessages.isEmpty {
                                                Text("\(tr("dépassement de")) \(overflowMessages.joined(separator: ", "))")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.red)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal, 4)
                                            }
                                            
                                            PerkCardView(perk: perk, showRecycle: false, allEquippedPerkIds: allEquippedPerkIds)
                                                .opacity(isEquippedAnywhere || isSlotFull ? 0.4 : 1.0)
                                                .overlay(
                                                    Group {
                                                        if isEquippedAnywhere {
                                                            RoundedRectangle(cornerRadius: 14)
                                                                .fill(Color.black.opacity(0.3))
                                                            Image(systemName: "lock.fill")
                                                                .font(.largeTitle)
                                                                .foregroundColor(.white.opacity(0.8))
                                                        }
                                                    }
                                                )
                                        }
                                        .onTapGesture {
                                            if !isEquippedAnywhere && !isSlotFull {
                                                gameManager.equipPerk(perk, to: targetId)
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(tr("Sélectionner un Perk"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Le canard cible et ses stats dynamiques sont désormais fournis par l'appelant (résolus une
    /// seule fois pour toute la liste) au lieu d'être re-cherchés dans l'inventaire à chaque ligne.
    /// Les conditions de dépassement sont inchangées, donc les messages affichés sont identiques.
    private func getOverflowMessages(for perk: Perk,
                                     duck: Duck?,
                                     stats: (level: Int, size: DuckSize, mutation: DuckMutation)?,
                                     isEquippedAnywhere: Bool,
                                     isSlotFull: Bool) -> [String] {
        var overflowMessages: [String] = []
        if !isEquippedAnywhere && !isSlotFull {
            if targetType == .duck, let duck = duck, let dynamicStats = stats {
                if dynamicStats.level + perk.duckConditionalLevels(duckRarity: duck.rarity) > 100 {
                    overflowMessages.append(tr("niveau"))
                }
                if dynamicStats.size.index + perk.duckSizeIncrease > DuckSize.geant.index {
                    overflowMessages.append(tr("taille"))
                }
                if dynamicStats.mutation.index + perk.duckMutationIncrease > DuckMutation.cristallise.index {
                    overflowMessages.append(tr("mutation"))
                }
            }
            // Cas usine : les perks d'usine n'ajoutent aucun niveau, l'ancienne branche ne
            // produisait aucun message (elle ne faisait qu'un scan inutile des usines).
        }
        return overflowMessages
    }
    
    private func getEquippedPerks() -> [UUID] {
        if targetType == .factory {
            return gameManager.factories.first(where: { $0.id == targetId })?.equippedPerkIds ?? []
        } else {
            return gameManager.inventory.first(where: { $0.id == targetId })?.equippedPerkIds ?? []
        }
    }
    
    private func getMaxSlots() -> Int {
        if targetType == .factory {
            if let factory = gameManager.factories.first(where: { $0.id == targetId }) {
                return gameManager.maxPerkSlots(for: factory)
            }
        } else {
            if let duck = gameManager.inventory.first(where: { $0.id == targetId }) {
                return gameManager.maxDuckPerkSlots(for: duck)
            }
        }
        return 1
    }
}
