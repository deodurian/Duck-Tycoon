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

    // Caisses regroupées par monnaie pour une lecture immédiate
    let moneyCrates = Crate.allCrates.filter { $0.costMoney != nil }
    let dnaCrates = Crate.allCrates.filter { $0.costMutationPoints != nil }

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

                // Caisse Mystère (Pub)
                if gameManager.isMysteryCrateAvailable {
                    Button(action: {
                        gameManager.claimMysteryCrate()
                    }) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text(tr("Caisse Mystère"))
                                    .font(.headline)
                                Text(tr("Contient un Canard Mythique !"))
                                    .font(.caption)
                            }
                            Spacer()
                            Text("📺")
                                .font(.title2)
                        }
                        .padding()
                        .background(
                            LinearGradient(colors: [.red.opacity(0.8), .orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.5), radius: 5)
                    }
                    .padding(.horizontal)
                } else if let nextDate = gameManager.nextMysteryCrateDate {
                    TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                        let timeLeft = max(0, Int(nextDate.timeIntervalSince(timeline.date)))
                        if timeLeft > 0 {
                            let min = timeLeft / 60
                            let sec = timeLeft % 60
                            HStack {
                                Image(systemName: "clock.fill")
                                Text("\(tr("Prochaine Caisse dans")) \(String(format: "%02d:%02d", min, sec))")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                        } else {
                            // On pourrait afficher un bouton de refresh, ou compter sur le tick pour mettre à jour
                            Text(tr("Chargement..."))
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Caisses achetables en Argent
                CrateSectionHeader(icon: "💰", title: tr("Caisses en Argent"), color: .yellow)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(moneyCrates, id: \.type.rawValue) { crate in
                        PremiumCrateCard(crate: crate, openingState: $openingState, infoCrate: $infoCrate)
                    }
                }
                .padding(.horizontal)

                // Caisses achetables en ADN
                CrateSectionHeader(icon: "🧬", title: tr("Caisses en ADN"), color: .purple)
                    .padding(.top, 6)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(dnaCrates, id: \.type.rawValue) { crate in
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

// MARK: - En-tête de section de caisses
struct CrateSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 14))
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundColor(color)

            // Trait dégradé qui prolonge le titre
            Rectangle()
                .fill(LinearGradient(colors: [color.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
        .padding(.horizontal)
    }
}

