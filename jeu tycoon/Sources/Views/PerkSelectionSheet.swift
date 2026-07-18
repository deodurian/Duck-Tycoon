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
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // --- SECTION : PERKS ÉQUIPÉS ---
                        let equippedIds = getEquippedPerks()
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
                                        PerkCardView(perk: perk)
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

                                let maxSlots = getMaxSlots()
                                let isFull = equippedIds.count >= maxSlots
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
                                        let isEquippedAnywhere = gameManager.isPerkEquippedAnywhere(perk.id)
                                        let isSlotFull = equippedIds.count >= getMaxSlots()

                                        let overflowMessages = getOverflowMessages(for: perk, isEquippedAnywhere: isEquippedAnywhere, isSlotFull: isSlotFull)

                                        VStack(spacing: 4) {
                                            if !overflowMessages.isEmpty {
                                                Text("\(tr("dépassement de")) \(overflowMessages.joined(separator: ", "))")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.red)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal, 4)
                                            }
                                            
                                            PerkCardView(perk: perk, showRecycle: false)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getOverflowMessages(for perk: Perk, isEquippedAnywhere: Bool, isSlotFull: Bool) -> [String] {
        var overflowMessages: [String] = []
        if !isEquippedAnywhere && !isSlotFull {
            if targetType == .duck, let duck = gameManager.inventory.first(where: { $0.id == targetId }) {
                if duck.level + perk.duckConditionalLevels(duckRarity: duck.rarity) > 100 {
                    overflowMessages.append(tr("niveau"))
                }
                if duck.size.index + perk.duckSizeIncrease > DuckSize.geant.index {
                    overflowMessages.append(tr("taille"))
                }
                if duck.mutation.index + perk.duckMutationIncrease > DuckMutation.cristallise.index {
                    overflowMessages.append(tr("mutation"))
                }
            } else if targetType == .factory, let _ = gameManager.factories.first(where: { $0.id == targetId }) {
                // Currently perks don't explicitly add levels to factory, but if they did we'd catch it.
            }
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
