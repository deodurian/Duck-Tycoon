import SwiftUI

/// Onglet « Usines » : un vrai poste de pilotage.
///
/// Trois étages, tous dans le design system néon :
/// 1. la barre de commande (Niveau / Perks / Boost pub) ;
/// 2. le tableau de bord de production (état en marche/à l'arrêt, jauge, total /s qui morphe) ;
/// 3. la grille des cartes d'usine, qui entrent en scène en cascade à l'ouverture de l'onglet.
struct FactoryView: View {
    @Environment(GameManager.self) private var gameManager

    @State private var showingLevelSheet = false
    @State private var showingPerkSheet = false
    /// Entrée en scène échelonnée des cartes (remise à zéro à chaque ouverture de l'onglet).
    @State private var appeared = false

    private let columns = [GridItem(.flexible(), spacing: 15)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                FactoryCommandBar(showingLevelSheet: $showingLevelSheet,
                                  showingPerkSheet: $showingPerkSheet)
                    .padding(.horizontal)
                    .padding(.top, 8)

                FactoryDashboardHeader()
                    .padding(.horizontal)

                factoryGrid
            }
            .padding(.bottom, 10)
        }
        .background(Color.clear)
        .onAppear {
            guard !appeared else { return }
            appeared = true
        }
        .sheet(isPresented: $showingLevelSheet) {
            // Une sheet n'hérite pas du colorScheme du parent : on le remet explicitement.
            LevelSheetView()
                .environment(gameManager)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingPerkSheet) {
            PerkSheetView()
                .environment(gameManager)
                .preferredColorScheme(.dark)
                .onAppear { gameManager.hasUnseenPerk = false }
        }
    }

    /// Grille des usines. Chaque carte glisse et apparaît avec un décalage croissant (plafonné,
    /// pour que la 40ᵉ usine n'attende pas trois secondes).
    private var factoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(Array(gameManager.factories.enumerated()), id: \.element.id) { index, factory in
                FactoryRow(factory: factory)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 26)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.85)
                            .delay(Double(min(index, 6)) * 0.06),
                        value: appeared
                    )
            }

            // Bouton Ajouter Usine (leaf isolée : seule à lire gameManager.money)
            NewFactoryButton()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 26)
                .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.42), value: appeared)
        }
        .padding(.horizontal)
    }
}

// MARK: - Barre de commande (Niveau / Perks / Boost)

/// Les trois raccourcis du haut, refaits dans le design system : verre néon, écrasement à ressort
/// et haptique à l'appui. Le bouton Boost devient doré quand la pub est offerte, et affiche son
/// décompte quand le boost tourne.
private struct FactoryCommandBar: View {
    @Environment(GameManager.self) private var gameManager
    @Binding var showingLevelSheet: Bool
    @Binding var showingPerkSheet: Bool

    var body: some View {
        HStack(spacing: 10) {
            levelButton
            perksButton
            boostButton
        }
    }

    // MARK: Niveau

    private var levelButton: some View {
        Button {
            showingLevelSheet = true
        } label: {
            chipLabel(icon: "star.fill", title: "\(tr("Niv.")) \(gameManager.playerLevel)", color: Neon.yellow)
        }
        .buttonStyle(NeonButtonStyle(color: Neon.yellow, cornerRadius: 14, compact: true))
    }

    // MARK: Perks

    private var perksButton: some View {
        Button {
            showingPerkSheet = true
        } label: {
            chipLabel(icon: "puzzlepiece.extension.fill", title: tr("Perks"), color: Neon.purple)
        }
        .buttonStyle(NeonButtonStyle(color: Neon.purple, cornerRadius: 14, compact: true))
        .overlay(alignment: .topTrailing) {
            // Un perk jamais consulté : point rouge qui pulse (même pastille que la barre d'onglets).
            if gameManager.hasUnseenPerk {
                NotificationDot()
                    .offset(x: -3, y: 3)
            }
        }
    }

    /// Gabarit commun des deux pastilles néon : hauteur fixe pour que la rangée reste alignée
    /// avec le bouton doré (36 + 2×7 de rembourrage = 50, comme 24 + 2×13).
    private func chipLabel(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.75), radius: 6)
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }

    // MARK: Boost pub

    /// CE QUI COÛTAIT : le TimelineView périodique était monté EN PERMANENCE. Hors boost, il
    /// réveillait donc la vue chaque seconde pour reconstruire et re-diffuser un bouton doré
    /// rigoureusement identique — c'est-à-dire 3 600 réévaluations par heure pour zéro pixel changé,
    /// alors que l'onglet Usines reste souvent affiché longtemps.
    ///
    /// POURQUOI LE RENDU RESTE IDENTIQUE : le décompte a besoin du TimelineView UNIQUEMENT pendant
    /// un boost ; le test interne est conservé tel quel, donc la bascule vers le bouton doré se fait
    /// exactement au même instant (au tick où `timeline.date` dépasse la fin du boost). Hors boost,
    /// c'est le même `availableBoostButton`, au même endroit, avec le même style.
    @ViewBuilder
    private var boostButton: some View {
        if let end = gameManager.adBoostEndTime, Date() < end {
            TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                if timeline.date < end {
                    activeBoostButton(secondsLeft: Int(end.timeIntervalSince(timeline.date)))
                } else {
                    availableBoostButton
                }
            }
        } else {
            availableBoostButton
        }
    }

    private func activeBoostButton(secondsLeft: Int) -> some View {
        let clamped = max(0, secondsLeft)
        return Button {
            gameManager.watchAdForBoost()
        } label: {
            VStack(spacing: 2) {
                Text(String(format: "×%.0f", gameManager.currentAdMultiplier))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Neon.red)
                    .shadow(color: Neon.red.opacity(0.8), radius: 7)
                Text(String(format: "%02d:%02d", clamped / 60, clamped % 60))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .foregroundStyle(.white.opacity(0.8))
                    .animation(.snappy(duration: 0.25), value: clamped)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(NeonButtonStyle(color: Neon.red, cornerRadius: 14, compact: true))
    }

    /// Boost disponible : bouton doré (le plus voyant du jeu) pour rendre l'offre désirable.
    private var availableBoostButton: some View {
        Button {
            gameManager.watchAdForBoost()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .black))
                Text(tr("Boost x2"))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
        }
        .buttonStyle(GoldenAdButtonStyle(cornerRadius: 14))
        .shadow(color: Color(hex: 0xFFB01F).opacity(0.45), radius: 12)
    }
}

// MARK: - Tableau de bord de production

/// En-tête transformé en console de production : état de la chaîne, jauge d'usines occupées et
/// total /s qui morphe et palpite dès qu'il change.
private struct FactoryDashboardHeader: View {
    @Environment(GameManager.self) private var gameManager

    /// `cachedEarningsPerSecond` repasse brièvement à `nil` à chaque invalidation (assignation,
    /// amélioration…). Sans ce relais, le compteur retomberait à 0 le temps d'un tick.
    @State private var lastEPS: BigNumber = .zero
    @State private var badgePulse: CGFloat = 1
    @State private var beacon = false

    var body: some View {
        let factories = gameManager.factories
        let total = factories.count
        let active = factories.reduce(into: 0) { $0 += $1.assignedDuckIds.isEmpty ? 0 : 1 }
        let eps = gameManager.cachedEarningsPerSecond ?? lastEPS
        let boosted = isBoostActive

        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 8) {
                titleBlock(active: active)
                Spacer(minLength: 4)
                productionBadge(eps: eps, boosted: boosted)
            }
            gauge(active: active, total: total)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .neonPanel(color: Neon.green, cornerRadius: 22)
        .onAppear { beacon = true }
        .onChange(of: gameManager.cachedEarningsPerSecond) { _, newValue in
            guard let newValue, newValue != lastEPS else { return }
            lastEPS = newValue
            pulseBadge()
        }
    }

    /// Un boost expiré laisse `adBoostMultiplier` à 2 : on vérifie aussi la date de fin pour ne pas
    /// afficher un tableau de bord « boosté » en permanence.
    private var isBoostActive: Bool {
        guard gameManager.adBoostMultiplier > 1.0, let end = gameManager.adBoostEndTime else { return false }
        return Date() < end
    }

    private func titleBlock(active: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tr("Usines"))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .neonTitle(Neon.green)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 6) {
                stateChip(running: active > 0)

                Text("\(active) \(tr(active > 1 ? "usines actives" : "usine active"))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    /// Voyant d'état : vert clignotant quand ça produit, rouge fixe quand tout est à l'arrêt.
    private func stateChip(running: Bool) -> some View {
        let color: Color = running ? Neon.green : Neon.red
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.9), radius: 4)
                .opacity(running ? (beacon ? 1.0 : 0.3) : 0.85)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: beacon)

            Text(running ? tr("En marche") : tr("À l'arrêt"))
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.5)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.13)))
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }

    private func productionBadge(eps: BigNumber, boosted: Bool) -> some View {
        let color: Color = boosted ? Neon.red : Neon.yellow
        return VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .black))
                Text("+\(eps.formattedString())/s")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.7), radius: 9)

            if boosted {
                Text(String(format: "×%.0f", gameManager.currentAdMultiplier))
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Neon.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Neon.red.opacity(0.16)))
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.10))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
        .scaleEffect(badgePulse)
        .animation(.snappy(duration: 0.35), value: eps)
    }

    private func gauge(active: Int, total: Int) -> some View {
        let fraction = total > 0 ? Double(active) / Double(total) : 0
        return VStack(spacing: 5) {
            NeonProgressBar(fraction: fraction,
                            color: active > 0 ? Neon.green : Color.white.opacity(0.3),
                            height: 7,
                            animated: active > 0)

            HStack(spacing: 4) {
                Text(tr("Usines en production"))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 4)

                Text("\(active)/\(total)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .animation(.snappy(duration: 0.4), value: active)
    }

    /// Palpitation courte du badge quand la production change (achat, canard assigné, boost…).
    private func pulseBadge() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.42)) { badgePulse = 1.14 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { badgePulse = 1.0 }
        }
    }
}

// MARK: - Bouton « Nouvelle Usine » (leaf isolée du tick d'argent)

/// Isolé pour que le tick d'argent (chaque seconde) ne réévalue pas tout le conteneur Usines
/// (ScrollView + en-tête + LazyVGrid) — seul ce bouton lit `gameManager.money`.
///
/// Deux états très différenciés : achetable → cadre plein, halo vert qui respire et reflet ;
/// trop cher → cadre pointillé sobre MAIS une jauge qui montre où en est la cagnotte.
private struct NewFactoryButton: View {
    @Environment(GameManager.self) private var gameManager

    @State private var halo = false
    @State private var buyBump: CGFloat = 1
    @State private var buyFlash: Double = 0
    /// Le voile de flash n'existe que le temps de la célébration d'achat (voir `label(...)`).
    @State private var isBuyFlashing = false

    var body: some View {
        let cost = gameManager.newFactoryCost
        let money = gameManager.money
        let canAfford = money >= cost

        return Button {
            gameManager.buyNewFactory()
        } label: {
            label(cost: cost, progress: affordFraction(money: money, cost: cost), canAfford: canAfford)
        }
        .buttonStyle(BouncyButtonStyle(scale: 0.96))
        .disabled(!canAfford)
        .scaleEffect(buyBump)
        .shadow(color: Neon.green.opacity(canAfford ? (halo ? 0.55 : 0.18) : 0), radius: halo ? 20 : 8)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: halo)
        .onAppear { halo = true }
        .onChange(of: gameManager.factories.count) { oldValue, newValue in
            if newValue > oldValue { celebratePurchase() }
        }
    }

    private func label(cost: BigNumber, progress: Double, canAfford: Bool) -> some View {
        VStack(spacing: 11) {
            emblem(canAfford: canAfford)

            VStack(spacing: 5) {
                Text(tr("Nouvelle Usine"))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(canAfford ? .white : .white.opacity(0.55))

                HStack(spacing: 4) {
                    Text("💰")
                        .font(.system(size: 10))
                    Text(cost.formattedString())
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .foregroundStyle(canAfford ? Neon.green : .white.opacity(0.5))
                .shadow(color: Neon.green.opacity(canAfford ? 0.5 : 0), radius: 6)

                // Trop cher : on montre où en est la cagnotte plutôt qu'un bouton mort.
                if !canAfford {
                    NeonProgressBar(fraction: progress, color: Neon.green.opacity(0.8),
                                    height: 5, animated: false)
                        .frame(width: 120)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(canAfford ? Neon.green.opacity(0.10) : Color.white.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    canAfford ? Neon.green.opacity(0.85) : Color.white.opacity(0.16),
                    style: StrokeStyle(lineWidth: canAfford ? 2 : 1.5,
                                       dash: canAfford ? [] : [10, 6])
                )
        }
        // CE QUI COÛTAIT : ce voile en `.blendMode(.plusLighter)` était monté en permanence, à
        // opacité 0. Un enfant en blend mode force SwiftUI/Core Animation à isoler tout le bouton
        // dans un groupe de composition hors écran EN CONTINU (le calque ne peut plus être mis en
        // cache), et ce bouton se réévalue chaque seconde puisqu'il lit `money`.
        //
        // POURQUOI LE RENDU RESTE IDENTIQUE : le voile n'est monté que pendant la célébration
        // d'achat, au même rang dans la pile de modificateurs, avec la même forme, la même couleur
        // et le même blend mode. Les deux animations d'opacité sont déplacées telles quelles dans
        // son `onAppear` : le calque est donc bien présent à opacité 0 avant qu'elles ne démarrent,
        // ce qui conserve la montée 0 → 0,45 en 0,1 s puis la retombée 0,45 → 0 en 0,4 s.
        .overlay {
            if isBuyFlashing {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .opacity(buyFlash)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.1)) { buyFlash = 0.45 }
                        withAnimation(.easeOut(duration: 0.4).delay(0.1)) { buyFlash = 0 }
                    }
            }
        }
        .neonSheen(cornerRadius: 20, active: canAfford, pause: 2.0, travel: 0.9, opacity: 0.26)
        .animation(.easeInOut(duration: 0.3), value: canAfford)
    }

    private func emblem(canAfford: Bool) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Neon.green, .clear],
                                     center: .center, startRadius: 2, endRadius: 42))
                .frame(width: 84, height: 84)
                .opacity(canAfford ? (halo ? 0.35 : 0.14) : 0.05)
                .scaleEffect(canAfford ? (halo ? 1.05 : 0.9) : 0.85)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: halo)

            Circle()
                .strokeBorder(canAfford ? Neon.green.opacity(0.7) : Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: 56, height: 56)

            Image(systemName: "plus")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(canAfford ? Neon.green : Color.white.opacity(0.35))
                .shadow(color: Neon.green.opacity(canAfford ? 0.8 : 0), radius: 9)
        }
        .frame(width: 84, height: 84)
    }

    /// Fraction de la cagnotte déjà réunie (0 → 1). Utilise BigNumber : le prix explose vite.
    private func affordFraction(money: BigNumber, cost: BigNumber) -> Double {
        guard !cost.isZero else { return 1 }
        let ratio = (money / cost).doubleValue
        guard ratio.isFinite, ratio > 0 else { return 0 }
        return min(ratio, 1)
    }

    /// Nouvelle usine posée : flash blanc, rebond et vibration de réussite.
    private func celebratePurchase() {
        NeonHaptics.success()
        // Le voile est monté à opacité 0 ; ses deux animations partent de son `onAppear` pour que
        // la montée s'anime bien depuis 0 (chorégraphie et durées inchangées).
        buyFlash = 0
        isBuyFlashing = true
        withAnimation(.spring(response: 0.28, dampingFraction: 0.4)) { buyBump = 1.08 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { buyBump = 1.0 }
        }
        // 0,1 s de montée + 0,4 s de retombée = 0,5 s : le voile est déjà à opacité 0 depuis
        // 0,1 s quand on le démonte, le démontage est donc invisible.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isBuyFlashing = false
        }
    }
}
