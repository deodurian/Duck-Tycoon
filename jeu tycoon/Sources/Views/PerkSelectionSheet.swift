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
                Color(red: 0.05, green: 0.0, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // --- SECTION : PERKS ÉQUIPÉS ---
                        let equippedIds = getEquippedPerks()
                        if !equippedIds.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Perks Équipés")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                ForEach(equippedIds, id: \.self) { perkId in
                                    if let perk = gameManager.perksInventory.first(where: { $0.id == perkId }) {
                                        HStack {
                                            PerkCardView(perk: perk)
                                            
                                            Button(action: {
                                                gameManager.unequipPerk(perk.id, from: targetId)
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title)
                                                    .foregroundColor(.red)
                                                    .padding(.trailing)
                                            }
                                        }
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // --- SECTION : PERKS DISPONIBLES ---
                        let perkType: PerkType = targetType == .factory ? .factory : .duck
                        let allTypePerks = gameManager.perks(for: perkType)
                        let selectionPerks = allTypePerks.filter { !equippedIds.contains($0.id) }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Perks Disponibles")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                let maxSlots = getMaxSlots()
                                Text("\(equippedIds.count)/\(maxSlots) emplacements")
                                    .font(.caption)
                                    .foregroundColor(equippedIds.count >= maxSlots ? .red : .green)
                            }
                            .padding(.horizontal)
                            
                            if selectionPerks.isEmpty {
                                Text("Aucun perk disponible de ce type.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 15) {
                                    ForEach(selectionPerks) { perk in
                                        let isEquippedAnywhere = gameManager.isPerkEquippedAnywhere(perk.id)
                                        let isSlotFull = equippedIds.count >= getMaxSlots()
                                        
                                        PerkCardView(perk: perk, showRecycle: false)
                                            .opacity(isEquippedAnywhere || isSlotFull ? 0.4 : 1.0)
                                            .overlay(
                                                Group {
                                                    if isEquippedAnywhere {
                                                        Color.black.opacity(0.3)
                                                            .cornerRadius(10)
                                                        Image(systemName: "lock.fill")
                                                            .font(.largeTitle)
                                                            .foregroundColor(.white.opacity(0.8))
                                                    }
                                                }
                                            )
                                            .onTapGesture {
                                                if !isEquippedAnywhere && !isSlotFull {
                                                    gameManager.equipPerk(perk, to: targetId)
                                                    dismiss()
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Sélectionner un Perk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
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
