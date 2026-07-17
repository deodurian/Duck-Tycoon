import SwiftUI

struct PerkSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    @State private var showInfo = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.0, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    let factoryPerksCount = gameManager.perksInventory.filter { $0.type == .factory }.count
                    let duckPerksCount = gameManager.perksInventory.filter { $0.type == .duck }.count
                    
                    Picker(tr("Type de Perks"), selection: $selectedTab) {
                        Text("\(tr("Usines")) (\(factoryPerksCount))").tag(0)
                        Text("\(tr("Canards")) (\(duckPerksCount))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            let typeFilter: PerkType = selectedTab == 0 ? .factory : .duck
                            let filteredPerks = gameManager.perksInventory.filter { $0.type == typeFilter }
                            ForEach(filteredPerks) { perk in
                                PerkCardView(perk: perk, showRecycle: true)
                            }
                            if filteredPerks.isEmpty {
                                Text(tr("Aucun perk de ce type."))
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Inventaire de Perks (\(gameManager.perksInventory.count))")
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
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 18))
                .foregroundColor(perk.type == .factory ? .cyan : Color(red: 0.1, green: 0.5, blue: 0.1))
                .padding(8)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tr(perk.name))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    if isEquipped {
                        Text(tr("ÉQUIPÉ"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(tr(perk.description))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(tr(perk.rarity.rawValue))
                    .font(.caption.bold())
                    .foregroundColor(perk.rarity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(perk.rarity.color.opacity(0.2))
                    .cornerRadius(8)
                
                if showRecycle && !isEquipped {
                    Button(action: { showingRecycleAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
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
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), perk.rarity.color.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(perk.rarity.color.opacity(0.8), lineWidth: 3)
        )
    }
}
