import SwiftUI

struct PerkSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab = 0
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    let factoryPerksCount = gameManager.perksInventory.filter { $0.type == .factory }.count
                    let duckPerksCount = gameManager.perksInventory.filter { $0.type == .duck }.count

                    // Sélecteur de type
                    HStack(spacing: 8) {
                        PerkTypeTabButton(
                            icon: "building.2.fill",
                            title: tr("Usines"),
                            count: factoryPerksCount,
                            color: .cyan,
                            isSelected: selectedTab == 0
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 0 }
                        }

                        PerkTypeTabButton(
                            icon: "bird.fill",
                            title: tr("Canards"),
                            count: duckPerksCount,
                            color: .green,
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 1 }
                        }
                    }
                    .padding()

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            let typeFilter: PerkType = selectedTab == 0 ? .factory : .duck
                            let filteredPerks = gameManager.perksInventory.filter { $0.type == typeFilter }
                            ForEach(filteredPerks) { perk in
                                PerkCardView(perk: perk, showRecycle: true)
                            }
                            if filteredPerks.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles.rectangle.stack")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.2))
                                    Text(tr("Aucun perk de ce type."))
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 60)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("\(tr("Inventaire de Perks")) (\(gameManager.perksInventory.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.cyan)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
            .alert(tr("Que sont les Perks ?"), isPresented: $showInfo) {
                Button(tr("Compris"), role: .cancel) { }
            } message: {
                Text(tr("Les Perks sont des bonus d'équipement que vous gagnez via les missions et les passages de niveaux. Vous pouvez équiper un Perk d'Usine sur une usine (dans le menu Usines) ou un Perk de Canard sur un canard (dans son profil détaillé) pour augmenter sa rentabilité !"))
            }
        }
    }
}

// MARK: - Onglet de type de perk

private struct PerkTypeTabButton: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(isSelected ? color.opacity(0.3) : Color.white.opacity(0.08)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? color : .gray)
        }
    }
}

// MARK: - Carte de Perk

struct PerkCardView: View {
    let perk: Perk
    var showRecycle: Bool = false

    @Environment(GameManager.self) private var gameManager
    @State private var showingRecycleAlert = false

    var isEquipped: Bool {
        if gameManager.factories.contains(where: { $0.equippedPerkIds.contains(perk.id) }) { return true }
        if gameManager.inventory.contains(where: { $0.equippedPerkIds.contains(perk.id) }) { return true }
        return false
    }

    var recycleYield: Int {
        switch perk.rarity {
        case .commun: return 50
        case .peuCommun: return 200
        case .rare: return 1000
        case .epique: return 5000
        case .legendaire: return 25000
        case .mythique: return 100000
        case .exotique: return 400000
        case .celeste: return 1600000
        case .primordiale: return 6400000
        }
    }

    private var typeIcon: String {
        perk.type == .factory ? "building.2.fill" : "bird.fill"
    }

    private var typeColor: Color {
        perk.type == .factory ? .cyan : .green
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icône du type dans un halo aux couleurs de la rareté
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [perk.rarity.color.opacity(0.35), perk.rarity.color.opacity(0.05)], center: .center, startRadius: 2, endRadius: 24))
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(perk.rarity.color.opacity(0.5), lineWidth: 1)
                    .frame(width: 44, height: 44)
                Image(systemName: typeIcon)
                    .font(.system(size: 17))
                    .foregroundColor(typeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(tr(perk.name))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if isEquipped {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .black))
                            Text(tr("ÉQUIPÉ"))
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)))
                    }
                }

                Text(tr(perk.description))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 8) {
                Text(tr(perk.rarity.rawValue))
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(perk.rarity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(perk.rarity.color.opacity(0.15)))
                    .overlay(Capsule().stroke(perk.rarity.color.opacity(0.4), lineWidth: 1))

                if showRecycle && !isEquipped {
                    Button(action: { showingRecycleAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(7)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .alert(tr("Recycler ce Perk ?"), isPresented: $showingRecycleAlert) {
                        Button(tr("Annuler"), role: .cancel) { }
                        Button(tr("Recycler"), role: .destructive) {
                            gameManager.recyclePerk(id: perk.id)
                        }
                    } message: {
                        Text("\(tr("Vous obtiendrez")) \(recycleYield) 🧬")
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), perk.rarity.color.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [perk.rarity.color.opacity(0.7), perk.rarity.color.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: perk.rarity.color.opacity(0.15), radius: 6, y: 2)
    }
}
