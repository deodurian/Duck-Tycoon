import SwiftUI

struct CrateOpeningState: Identifiable, Equatable {
    let id = UUID()
    let crate: Crate
    let ducks: [Duck]          // Pour 1 ou 5 capsules (affichage individuel)
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

    // Capsules regroupées par monnaie pour une lecture immédiate
    var moneyCrates: [Crate] { gameManager.availableCrates.filter { $0.costMoney != nil } }
    var dnaCrates: [Crate] { gameManager.availableCrates.filter { $0.costMutationPoints != nil } }

    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    @State private var openingState: CrateOpeningState?
    @State private var infoCrate: Crate?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                // Offre gratuite : c'est l'élément le plus voyant de l'écran.
                MysteryCapsuleBanner()
                    .padding(.horizontal)

                // Capsules achetables en Argent
                VStack(spacing: 14) {
                    CrateSectionHeader(icon: "💰", title: tr("Capsules — Argent"), color: Neon.yellow)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(moneyCrates.enumerated()), id: \.element.type.rawValue) { index, crate in
                            PremiumCrateCard(crate: crate, appearIndex: index, openingState: $openingState, infoCrate: $infoCrate)
                        }
                    }
                    .padding(.horizontal)
                }

                // Capsules achetables en ADN
                VStack(spacing: 14) {
                    CrateSectionHeader(icon: "🧬", title: tr("Capsules — ADN"), color: Neon.green)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(dnaCrates.enumerated()), id: \.element.type.rawValue) { index, crate in
                            PremiumCrateCard(crate: crate, appearIndex: index, openingState: $openingState, infoCrate: $infoCrate)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 2)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                Text(tr("Boutique"))
                    .font(.largeTitle.bold())
                    .neonTitle(Neon.magenta)
                Spacer(minLength: 8)
                Text(tr("Cryo-capsules"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .textCase(.uppercase)
                    .kerning(1.2)
            }

            // Capacité : information critique (inventaire plein = achats bloqués).
            InventoryGauge()
        }
        .padding(14)
        .neonPanel(color: Neon.magenta, cornerRadius: 22)
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

// MARK: - Jauge de capacité d'inventaire

/// Feuille isolée : seule vue de l'en-tête à lire `gameManager.inventory`.
private struct InventoryGauge: View {
    @Environment(GameManager.self) private var gameManager
    @State private var fullPulse = false

    var body: some View {
        let count = gameManager.inventory.count
        let capacity = max(1, gameManager.maxInventoryCapacity)
        let fraction = Double(count) / Double(capacity)
        let isFull = count >= capacity
        let color: Color = isFull ? Neon.red : (fraction > 0.85 ? .orange : Neon.cyan)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("🦆")
                    .font(.system(size: 13))

                Text("\(count)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(color)

                Text("/ \(capacity)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))

                Spacer(minLength: 0)

                Text(isFull ? tr("INVENTAIRE PLEIN") : tr("Capacité"))
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(isFull ? Neon.red : .white.opacity(0.35))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(isFull ? Neon.red.opacity(0.16) : Color.white.opacity(0.05)))
                    .scaleEffect(isFull && fullPulse ? 1.06 : 1.0)
            }

            NeonProgressBar(fraction: fraction, color: color, height: 7)
        }
        .animation(.easeInOut(duration: 0.25), value: count)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { fullPulse = true }
        }
    }
}

// MARK: - Capsule Mystère (offre pub gratuite)

/// Bandeau doré : c'est la seule chose gratuite de l'écran, elle doit écraser le reste.
private struct MysteryCapsuleBanner: View {
    @Environment(GameManager.self) private var gameManager
    @State private var glow = false

    private let gold = Color(hex: 0xFFC53F)

    var body: some View {
        if gameManager.isMysteryCrateAvailable {
            Button(action: { gameManager.claimMysteryCrate() }) {
                HStack(spacing: 12) {
                    CryoCapsuleIcon(type: .secrete, glow: true, size: 40)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(tr("Capsule Mystère"))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        Text(tr("Contient un Canard Mythique !"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .opacity(0.72)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 22, weight: .black))
                }
            }
            .buttonStyle(GoldenAdButtonStyle(cornerRadius: 20))
            .overlay(alignment: .topTrailing) {
                Text(tr("GRATUIT"))
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Neon.green))
                    .shadow(color: Neon.green.opacity(0.85), radius: 7)
                    .rotationEffect(.degrees(9))
                    .offset(x: 8, y: -9)
            }
            .shadow(color: gold.opacity(glow ? 0.8 : 0.3), radius: glow ? 22 : 10)
            .scaleEffect(glow ? 1.012 : 0.996)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { glow = true }
            }
        } else if let nextDate = gameManager.nextMysteryCrateDate {
            TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                let timeLeft = max(0, Int(nextDate.timeIntervalSince(timeline.date)))
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 34, height: 34)
                        Image(systemName: "hourglass")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Neon.magenta.opacity(0.85))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(tr("Capsule Mystère"))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                        Text(tr("En recharge"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    Spacer(minLength: 0)

                    Text(timeLeft > 0 ? countdownText(timeLeft) : tr("Bientôt…"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Neon.magenta)
                        .shadow(color: Neon.magenta.opacity(0.6), radius: 6)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .neonPanel(color: Neon.magenta, cornerRadius: 18)
            }
        }
    }

    private func countdownText(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - En-tête de section de capsules
struct CrateSectionHeader: View {
    @Environment(GameManager.self) private var gameManager
    let icon: String
    let title: String
    let color: Color

    /// Solde de la monnaie concernée, pour savoir tout de suite ce qu'on peut se payer.
    private var balance: String? {
        if icon == "💰" { return gameManager.money.formattedString() }
        if icon == "🧬" { return gameManager.mutationPoints.formattedString() }
        return nil
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 13))
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color.opacity(0.14)))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(color.opacity(0.4), lineWidth: 1))

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 5)
                .fixedSize()

            // Trait dégradé qui prolonge le titre
            Rectangle()
                .fill(LinearGradient(colors: [color.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)

            if let balance {
                Text(balance)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                    .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
            }
        }
        .padding(.horizontal)
    }
}
