import SwiftUI

struct CrateOpeningState: Identifiable, Equatable {
    let id = UUID()
    let crate: Crate
    let ducks: [Duck]          // Pour 1 ou 5 caisses (affichage individuel)
    let summary: [(rarity: DuckRarity, count: Int)]  // Pour les ouvertures en masse
    let totalCount: Int
    
    /// Initialiser pour un petit nombre de canards (affichage individuel)
    init(crate: Crate, ducks: [Duck]) {
        self.crate = crate
        self.ducks = ducks
        self.summary = []
        self.totalCount = ducks.count
    }
    
    /// Initialiser pour les ouvertures en masse (affichage agrégé uniquement)
    init(crate: Crate, ducks: [Duck], summary: [(rarity: DuckRarity, count: Int)], totalCount: Int) {
        self.crate = crate
        self.ducks = ducks
        self.summary = summary
        self.totalCount = totalCount
    }
    
    static func == (lhs: CrateOpeningState, rhs: CrateOpeningState) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Crate Shop View
struct CrateShopView: View {
    @Environment(GameManager.self) private var gameManager
    
    let crates = Crate.allCrates
    
    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    @State private var openingState: CrateOpeningState?
    @State private var infoCrate: Crate?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack(alignment: .lastTextBaseline) {
                    Text(tr("Boutique"))
                        .font(.largeTitle.bold())
                    Spacer()
                    
                    // Inventory counter with pill badge
                    HStack(spacing: 4) {
                        Text(tr("🦆"))
                        Text("\(gameManager.inventory.count)")
                            .bold()
                        Text(tr("/"))
                            .foregroundColor(.gray)
                        Text("\(gameManager.maxInventoryCapacity)")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .foregroundColor(gameManager.inventory.count >= gameManager.maxInventoryCapacity ? .red : .white)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Crate Grid
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(crates, id: \.type.rawValue) { crate in
                        PremiumCrateCard(crate: crate, openingState: $openingState, infoCrate: $infoCrate)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 60)
        }
        .background(Color.clear)
        .fullScreenCover(item: $openingState) { state in
            CrateAnimationView(state: state) {
                gameManager.processNewDucks(state.ducks)
                gameManager.setGamePaused(false)
                openingState = nil
            }
            .presentationBackground(.clear)
        }
        .overlay {
            if let crate = infoCrate {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                        .onTapGesture { withAnimation { infoCrate = nil } }
                    
                    ProbabilityPopup(crate: crate, isPresented: Binding(
                        get: { infoCrate != nil },
                        set: { if !$0 { infoCrate = nil } }
                    ))
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                .zIndex(50)
            }
        }
    }
}

