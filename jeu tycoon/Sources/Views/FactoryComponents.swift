import SwiftUI

// MARK: - Identité visuelle des évolutions

/// Couleur / icône par palier d'évolution, partagées par la carte et sa barre d'action.
/// Déclaré `private` au fichier : aucun risque de collision avec les autres menus.
private enum FactoryEvolutionStyle {
    /// Bleu/Cyan → Vert acide → Orange cuivré → Violet → Or → Magenta → Rouge → Platine (évo 7).
    static func color(_ evolution: Int) -> Color {
        switch evolution {
        case 0: return Neon.cyan
        case 1: return Neon.green
        case 2: return .orange
        case 3: return Neon.purple
        case 4: return Neon.yellow
        case 5: return Neon.magenta
        case 6: return Neon.red
        default: return Color(white: 0.92) // évo 7 : platine (l'arc-en-ciel reste sur la bordure)
        }
    }

    static func icon(_ evolution: Int) -> String {
        switch evolution {
        case 0: return "gearshape.fill"
        case 1: return "bolt.fill"
        case 2: return "flame.fill"
        case 3: return "sparkles"
        case 4: return "star.fill"
        case 5: return "crown.fill"
        case 6: return "diamond.fill"
        default: return "wand.and.stars"
        }
    }

    /// Propriétés calculées (et non `static let`) : aucun état global partagé à faire valider
    /// par le compilateur en concurrence stricte.
    static var rainbow: Gradient {
        Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red])
    }

    static var gold: Color { Color(hex: 0xFFB01F) }

    static var goldFill: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xFFE9A3), Color(hex: 0xFFC53F)],
                       startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Carte d'usine

/// Carte d'usine = tableau de bord miniature d'une chaîne de production.
///
/// Parti pris « game feel » (aligné sur l'écran de gains hors-ligne) :
/// - on voit d'un coup d'œil si l'usine TOURNE (halo qui respire, pièces qui montent, canard qui
///   flotte dans sa cuve) ou si elle est À L'ARRÊT (pastille rouge + slot pointillé qui appelle) ;
/// - chaque palier franchi est célébré localement : bump du niveau + « +N » qui s'envole + flash de
///   bordure à l'amélioration, bandeau doré au niveau 100, flash blanc + onde de choc + confettis
///   à l'évolution.
struct FactoryRow: View {
    @Environment(GameManager.self) private var gameManager
    let factory: DuckFactory

    @State private var showingDuckSelection = false
    @State private var showingPerkSelection = false

    /// UNIQUE animation continue de la carte : pilote le halo de l'emblème, le flottement du canard
    /// et la pulsation du slot vide. Un booléen animé en `repeatForever` n'entraîne aucune
    /// ré-évaluation de `body` par image (contrairement à un TimelineView/KeyframeAnimator).
    @State private var lifePulse = false

    // Célébration « amélioration »
    @State private var levelBump: CGFloat = 1
    @State private var borderFlash: Double = 0
    @State private var gainText: String?
    @State private var gainId: Int = 0

    // Célébration « évolution »
    @State private var isCelebrating = false
    @State private var evoFlash: Double = 0
    @State private var evoWave: CGFloat = 0
    @State private var iconBump: CGFloat = 1
    @State private var iconSpin: Double = 0

    // MARK: Données dérivées

    private var assignedDucks: [Duck] {
        factory.assignedDuckIds.compactMap { gameManager.getAssignedDuck(id: $0) }
    }

    private var factoryPerks: [Perk] {
        gameManager.perks(for: factory.equippedPerkIds)
    }

    private var isMaxLevel: Bool { factory.level >= 100 }

    /// Une usine sans canard ne produit rien : tout le vocabulaire visuel de la carte en dépend.
    private var isRunning: Bool { !factory.assignedDuckIds.isEmpty }

    private var evolutionColor: Color { FactoryEvolutionStyle.color(factory.evolution) }
    private var evolutionIcon: String { FactoryEvolutionStyle.icon(factory.evolution) }

    private var displayName: String {
        factory.name.replacingOccurrences(of: "Usine", with: tr("Usine"))
    }

    // MARK: Corps

    var body: some View {
        // CE QUI COÛTAIT : `assignedDucks` et `factoryPerks` sont des propriétés CALCULÉES, donc
        // refaites à chaque accès — les canards étaient résolus 2 fois et les perks 3 fois par
        // évaluation du corps (autant de tableaux alloués et de recherches dans les index).
        // POURQUOI LE RENDU RESTE IDENTIQUE : les deux résolutions sont déterministes et les caches
        // ne bougent pas pendant une même évaluation ; on calcule donc exactement les mêmes valeurs,
        // une seule fois, et on les passe aux mêmes sous-vues.
        let ducks = assignedDucks
        let perks = factoryPerks

        return VStack(spacing: 0) {
            headerSection(ducks: ducks, perks: perks)

            perkRow(perks: perks)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)

            gradientDivider

            statsSection(ducks: ducks, perks: perks)

            hairline

            // Sous-vue feuille : SEULE partie qui lit gameManager.money → seule à se re-rendre
            // chaque seconde. Le reste de la carte ne s'invalide plus au tick d'argent.
            FactoryActionRow(factory: factory)
        }
        .neonPanel(color: evolutionColor, cornerRadius: 20)
        .overlay { evolutionBorder }
        .overlay { celebrationLayer }
        .overlay(alignment: .bottom) { gainLayer }
        // Reflet lent réservé aux usines évoluées EN MARCHE : la carte « brille » d'elle-même.
        .neonSheen(cornerRadius: 20, active: isRunning && factory.evolution > 0,
                   pause: 3.4, travel: 1.0, opacity: 0.12)
        .shadow(color: evolutionColor.opacity(isRunning ? 0.22 : 0.05), radius: 10, y: 4)
        .onAppear { lifePulse = true }
        .onChange(of: factory.level) { oldValue, newValue in
            handleLevelChange(from: oldValue, to: newValue)
        }
        .onChange(of: factory.evolution) { oldValue, newValue in
            if newValue > oldValue { celebrateEvolution() }
        }
        .sheet(isPresented: $showingDuckSelection) {
            // Une sheet n'hérite pas du colorScheme du parent : on le remet pour que le verre
            // néon ne vire pas au blanc laiteux sur un iPhone en mode clair.
            DuckSelectionSheet(factoryId: factory.id)
                .environment(gameManager)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingPerkSelection) {
            PerkSelectionSheet(targetId: factory.id, targetType: .factory)
                .environment(gameManager)
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - En-tête de la carte

    private func headerSection(ducks: [Duck], perks: [Perk]) -> some View {
        HStack(spacing: 10) {
            factoryEmblem

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                statusPills
            }

            Spacer(minLength: 4)

            duckSlots(ducks: ducks, perks: perks)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    /// Emblème : halo qui respire quand ça produit, icône qui fait un tour complet à l'évolution.
    private var factoryEmblem: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [evolutionColor, .clear],
                                     center: .center, startRadius: 1, endRadius: 26))
                .frame(width: 52, height: 52)
                .opacity(isRunning ? (lifePulse ? 0.45 : 0.18) : 0.07)
                .scaleEffect(isRunning ? (lifePulse ? 1.05 : 0.88) : 0.8)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: lifePulse)

            Circle()
                .stroke(evolutionColor.opacity(isRunning ? 0.45 : 0.18), lineWidth: 1)
                .frame(width: 40, height: 40)

            Image(systemName: evolutionIcon)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(colors: [evolutionColor, evolutionColor.opacity(0.65)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: evolutionColor.opacity(isRunning ? 0.75 : 0.2), radius: 5)
                .rotationEffect(.degrees(iconSpin))
                .animation(.spring(response: 0.7, dampingFraction: 0.55), value: iconSpin)
                .scaleEffect(iconBump)
                .saturation(isRunning ? 1.0 : 0.45)
        }
        .frame(width: 52, height: 52)
    }

    /// Pastilles d'état : niveau, évolution, et « à l'arrêt » quand aucun canard ne bosse.
    private var statusPills: some View {
        HStack(spacing: 5) {
            levelPill

            if factory.evolution > 0 {
                pill(icon: "star.fill", text: "\(tr("Évo.")) \(factory.evolution)",
                     color: evolutionColor, iconSize: 7)
            }

            if !isRunning {
                pill(icon: "pause.fill", text: tr("À l'arrêt"), color: Neon.red, iconSize: 7)
            }
        }
    }

    private var levelPill: some View {
        HStack(spacing: 3) {
            Image(systemName: isMaxLevel ? "checkmark.seal.fill" : "arrow.up.circle.fill")
                .font(.system(size: 8, weight: .black))
            Text("\(tr("Nv.")) \(factory.level)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .foregroundStyle(isMaxLevel ? Color(hex: 0x3F1D00) : .white.opacity(0.85))
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background {
            if isMaxLevel {
                Capsule().fill(FactoryEvolutionStyle.goldFill)
            } else {
                Capsule().fill(Color.white.opacity(0.09))
            }
        }
        .overlay {
            Capsule().stroke(isMaxLevel ? Color.white.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: isMaxLevel ? FactoryEvolutionStyle.gold.opacity(0.6) : .clear, radius: 6)
        .scaleEffect(levelBump)
        .animation(.snappy(duration: 0.3), value: factory.level)
    }

    private func pill(icon: String, text: String, color: Color, iconSize: CGFloat) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .black))
            Text(text)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Emplacements de canard

    @ViewBuilder
    private func duckSlots(ducks: [Duck], perks: [Perk]) -> some View {
        let hasExtraSlot = perks.contains(where: { $0.factoryExtraDuckSlot })
        let slotCount = max(ducks.count, hasExtraSlot ? 2 : 1)

        HStack(spacing: 8) {
            ForEach(0..<slotCount, id: \.self) { index in
                Button {
                    NeonHaptics.tick()
                    showingDuckSelection = true
                } label: {
                    if index < ducks.count {
                        occupiedSlot(ducks[index])
                    } else {
                        emptySlot
                    }
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
    }

    /// Canard assigné : il flotte doucement dans sa cuve d'incubation, teintée par sa rareté.
    private func occupiedSlot(_ duck: Duck) -> some View {
        IncubationTube(color: duck.rarity.color) {
            DuckGridCard(
                duck: duck,
                displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                isAssigned: false,
                dynamicLevel: gameManager.getDynamicStats(for: duck).level
            )
        }
        .offset(y: lifePulse ? -2.5 : 2.5)
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: lifePulse)
    }

    /// Slot vide : bordure pointillée qui pulse pour appeler l'action.
    private var emptySlot: some View {
        VStack(spacing: 3) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .heavy))
            Text(tr("Canard"))
                .font(.system(size: 7, weight: .heavy))
        }
        .foregroundStyle(Neon.green.opacity(0.9))
        .frame(width: 55, height: 55)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Neon.green.opacity(lifePulse ? 0.16 : 0.04))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Neon.green.opacity(lifePulse ? 0.9 : 0.28),
                              style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
        }
        .shadow(color: Neon.green.opacity(lifePulse ? 0.45 : 0), radius: 7)
        .animation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true), value: lifePulse)
    }

    // MARK: - Perks

    /// Ligne de perks dédiée : pleine largeur, chaque pastille garde son texte à l'horizontale.
    @ViewBuilder
    private func perkRow(perks: [Perk]) -> some View {
        Button {
            NeonHaptics.tick()
            showingPerkSelection = true
        } label: {
            HStack(spacing: 6) {
                if perks.isEmpty {
                    emptyPerkChip
                } else {
                    ForEach(perks) { perk in
                        perkChip(perk)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(BouncyButtonStyle(scale: 0.97))
    }

    private var emptyPerkChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 9))
            Text(tr("Ajouter un perk"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(.white.opacity(0.55))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.05)))
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.22),
                                   style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    private func perkChip(_ perk: Perk) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text(tr(perk.name))
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(perk.rarity.color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(perk.rarity.color.opacity(0.14)))
        .overlay(Capsule().stroke(perk.rarity.color.opacity(0.45), lineWidth: 1))
        .shadow(color: perk.rarity.color.opacity(0.35), radius: 4)
    }

    // MARK: - Séparateurs

    private var gradientDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(colors: [.clear, evolutionColor.opacity(isRunning ? 0.5 : 0.18), .clear],
                               startPoint: .leading, endPoint: .trailing)
            )
            .frame(height: 1)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }

    // MARK: - Statistiques

    private func statsSection(ducks: [Duck], perks: [Perk]) -> some View {
        HStack(alignment: .center, spacing: 8) {
            productionBlock(ducks: ducks, perks: perks)
            Spacer(minLength: 4)
            levelProgressBlock
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// Revenus (et mutations) par seconde. Les pièces qui montent disent « ça produit MAINTENANT ».
    private func productionBlock(ducks: [Duck], perks: [Perk]) -> some View {
        let displayValues = ducks.map { gameManager.displaySellValue(for: $0) }
        let earnings = factory.calculateEarningsPerSecond(
            assignedDucks: ducks,
            duckDisplayValues: displayValues,
            factoryPerks: perks
        )

        return HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text("💰")
                        .font(.system(size: 11))
                    Text("+\(earnings.formattedString())/s")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(isRunning ? Neon.yellow : Color.white.opacity(0.35))
                        .shadow(color: Neon.yellow.opacity(isRunning ? 0.45 : 0), radius: 6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .animation(.snappy(duration: 0.35), value: earnings)
                }

                if factory.evolution > 0 {
                    let mutations = factory.calculateMutationsPerSecond(
                        assignedDucks: ducks,
                        globalBonus: gameManager.mutationMultiplier
                    )
                    HStack(spacing: 4) {
                        Text("🧬")
                            .font(.system(size: 10))
                        Text("+\(mutations.formattedString())/s")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(isRunning ? Neon.purple : Color.white.opacity(0.3))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .animation(.snappy(duration: 0.35), value: mutations)
                    }
                }
            }

            if isRunning {
                FactoryProductionCoins(color: Neon.yellow)
            }
        }
    }

    /// À droite : la jauge de niveau, ou le bandeau doré MAX quand l'usine est prête à évoluer.
    @ViewBuilder
    private var levelProgressBlock: some View {
        if isMaxLevel {
            maxBanner
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(factory.level)/100")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(.white.opacity(0.55))
                    .animation(.snappy(duration: 0.3), value: factory.level)

                // `animated: false` : pas de reflet mobile dans une longue liste de cartes.
                // Le remplissage reste animé à ressort quand le niveau change (NeonProgressBar).
                NeonProgressBar(fraction: Double(factory.level) / 100.0,
                                color: evolutionColor, height: 6, animated: false)
                    .frame(width: 88)
            }
        }
    }

    /// Niveau 100 : bandeau doré balayé par un reflet — impossible de le manquer.
    private var maxBanner: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10, weight: .black))
            Text(tr("MAX"))
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundStyle(Color(hex: 0x3F1D00))
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(Capsule().fill(FactoryEvolutionStyle.goldFill))
        .neonSheen(cornerRadius: 20, pause: 2.2, travel: 0.7, opacity: 0.6)
        .clipShape(Capsule())
        .shadow(color: FactoryEvolutionStyle.gold.opacity(0.65), radius: 9)
        .scaleEffect(levelBump)
    }

    // MARK: - Bordures et célébrations

    @ViewBuilder
    private var evolutionBorder: some View {
        if factory.evolution == 7 {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AngularGradient(gradient: FactoryEvolutionStyle.rainbow, center: .center),
                        lineWidth: 2.5)
                .shadow(color: evolutionColor.opacity(0.35), radius: 6)
                .allowsHitTesting(false)
        } else if factory.evolution > 0 {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(evolutionColor.opacity(0.45), lineWidth: 1.5)
                .shadow(color: evolutionColor.opacity(0.3), radius: 6)
                .allowsHitTesting(false)
        }
    }

    /// Flash d'amélioration, onde de choc et flash blanc d'évolution — tout est local à la carte.
    private var celebrationLayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(evolutionColor, lineWidth: 2)
                .shadow(color: evolutionColor.opacity(0.9), radius: 8)
                .opacity(borderFlash)

            if isCelebrating {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(evolutionColor, lineWidth: 4)
                    .scaleEffect(1 + evoWave * 0.16)
                    .opacity(max(0, 0.85 - Double(evoWave) * 0.85))
                    .blur(radius: 1.5)
            }

            // CE QUI COÛTAIT : un enfant en `blendMode` force SwiftUI à isoler son parent dans un
            // groupe de composition hors écran EN PERMANENCE — donc pour chaque carte d'usine
            // affichée, en continu, alors que ce calque est totalement transparent 99,9 % du temps.
            // POURQUOI LE RENDU RESTE IDENTIQUE : `isCelebrating` couvre toute la durée du flash
            // (mis à vrai avant l'animation, remis à faux 0,9 s plus tard, alors que le flash est
            // terminé à 0,57 s). Pendant la célébration, le calque est exactement le même.
            if isCelebrating {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .opacity(evoFlash)
                    .blendMode(.plusLighter)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var gainLayer: some View {
        if let gainText {
            FactoryGainPop(text: gainText, color: evolutionColor)
                .id(gainId)
                .padding(.bottom, 52)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Chorégraphies

    /// Une amélioration réussie a forcément fait monter `factory.level` : on ne célèbre donc que
    /// le vrai succès (l'évolution remet le niveau à 1 → `newValue < oldValue`, on ignore).
    private func handleLevelChange(from oldValue: Int, to newValue: Int) {
        guard newValue > oldValue else { return }
        let gained = newValue - oldValue
        let reachedMax = newValue >= 100

        if reachedMax {
            NeonHaptics.success()
        } else {
            NeonHaptics.impact()
        }

        gainId &+= 1
        gainText = "+\(gained)"

        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { levelBump = 1.35 }
        withAnimation(.easeOut(duration: 0.12)) { borderFlash = reachedMax ? 1.0 : 0.8 }
        withAnimation(.easeOut(duration: 0.55).delay(0.12)) { borderFlash = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { levelBump = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            gainText = nil
        }
    }

    /// Le grand moment du menu : flash blanc, onde de choc, icône qui fait un tour, confettis.
    private func celebrateEvolution() {
        NeonHaptics.success()
        gameManager.triggerConfetti()

        isCelebrating = true
        evoWave = 0
        iconSpin += 360

        withAnimation(.easeOut(duration: 0.12)) { evoFlash = 0.55 }
        withAnimation(.easeOut(duration: 0.45).delay(0.12)) { evoFlash = 0 }
        withAnimation(.easeOut(duration: 0.75)) { evoWave = 1 }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.35)) { iconBump = 1.55 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { iconBump = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            isCelebrating = false
            evoWave = 0
        }
    }
}

// MARK: - Pièces de production

/// Pièces qui montent et s'évanouissent en boucle : la preuve visuelle qu'une usine PRODUIT.
/// Une seule bascule booléenne pilote les trois pièces (chacune avec son délai) : aucune
/// ré-évaluation de vue par image, et l'effet reste strictement local à la carte.
private struct FactoryProductionCoins: View {
    var color: Color

    @State private var rise = false

    private let xOffsets: [CGFloat] = [0, 8, -7]
    private let delays: [Double] = [0, 0.8, 1.55]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Text("💰")
                    .font(.system(size: 9))
                    .shadow(color: color.opacity(0.8), radius: 4)
                    .offset(x: xOffsets[index], y: rise ? -24 : 8)
                    .opacity(rise ? 0 : 0.95)
                    .animation(
                        .easeOut(duration: 2.3)
                            .repeatForever(autoreverses: false)
                            .delay(delays[index]),
                        value: rise
                    )
            }
        }
        .frame(width: 20, height: 34)
        .allowsHitTesting(false)
        .onAppear { rise = true }
    }
}

// MARK: - « +N » qui s'envole

/// Récompense visuelle d'une amélioration : le nombre de niveaux gagnés décolle de la barre
/// d'action puis s'évanouit.
private struct FactoryGainPop: View {
    let text: String
    let color: Color

    @State private var rise = false
    @State private var fade = false

    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .shadow(color: color.opacity(0.95), radius: 10)
            .shadow(color: color.opacity(0.5), radius: 22)
            .scaleEffect(rise ? 1.0 : 0.4)
            .offset(y: rise ? -46 : 0)
            .opacity(fade ? 0 : 1)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { rise = true }
                withAnimation(.easeIn(duration: 0.35).delay(0.45)) { fade = true }
            }
    }
}

// MARK: - Bouton « Évoluer » (rempli, teinté par la PROCHAINE évolution)

/// Le seul bouton « héroïque » de la carte : base sombre + tint fort de la couleur que l'usine
/// va devenir, reflet qui balaye, écrasement à ressort et haptique instantanée à l'appui.
/// Le fond reste sombre pour que le libellé blanc reste lisible sur les teintes claires (or, platine).
private struct FactoryEvolveButtonStyle: ButtonStyle {
    var color: Color
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background {
                ZStack {
                    shape.fill(LinearGradient(colors: [Color(hex: 0x161628), Color(hex: 0x0A0A14)],
                                              startPoint: .top, endPoint: .bottom))
                    shape.fill(LinearGradient(colors: [color.opacity(0.55), color.opacity(0.14)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .neonSheen(cornerRadius: cornerRadius, pause: 1.5, travel: 0.8, opacity: 0.45)
            .overlay {
                shape.stroke(
                    LinearGradient(colors: [.white.opacity(0.75), color.opacity(0.6)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.4
                )
            }
            .clipShape(shape)
            .shadow(color: color.opacity(configuration.isPressed ? 0.95 : 0.6),
                    radius: configuration.isPressed ? 16 : 10)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.5), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { NeonHaptics.impact() }
            }
    }
}

// MARK: - Barre d'action d'usine (leaf isolée du tick d'argent)

/// Contient les seuls contrôles qui dépendent de `gameManager.money` (+1 / +10 / Max / Évoluer).
/// En les isolant dans leur propre `View`, la carte d'usine complète (header, tubes, stats, perks)
/// ne se réévalue plus à chaque seconde — seule cette petite barre le fait.
private struct FactoryActionRow: View {
    @Environment(GameManager.self) private var gameManager
    let factory: DuckFactory

    /// Halo qui respire sur « Évoluer » quand il est enfin payable : c'est l'appel à l'action.
    @State private var evolveGlow = false

    private var isMaxLevel: Bool { factory.level >= 100 }
    private var evolutionColor: Color { FactoryEvolutionStyle.color(factory.evolution) }
    private var nextEvolutionColor: Color { FactoryEvolutionStyle.color(factory.evolution + 1) }

    var body: some View {
        HStack(spacing: 8) {
            if isMaxLevel {
                if factory.evolution < 7 {
                    evolveButton
                } else {
                    maximumBanner
                }
            } else {
                upgradeButtons
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: Améliorations

    @ViewBuilder
    private var upgradeButtons: some View {
        let factoryPerks = gameManager.perks(for: factory.equippedPerkIds)
        let money = gameManager.money
        let discount = gameManager.factoryCostDiscount

        upgradeButton(label: "+1", levels: 1, perks: factoryPerks, money: money, discount: discount)

        let amount10 = min(10, 100 - factory.level)
        upgradeButton(label: "+\(amount10)", levels: amount10, perks: factoryPerks, money: money, discount: discount)

        let maxUpgrades = factory.maxUpgrades(with: money, factoryPerks: factoryPerks, baseDiscount: discount)
        let maxAmount = max(1, min(maxUpgrades, 100 - factory.level))
        upgradeButton(label: "Max", levels: maxAmount, perks: factoryPerks, money: money,
                      discount: discount, isMax: true, maxUpgrades: maxUpgrades)
    }

    private func upgradeButton(label: String, levels: Int, perks: [Perk], money: BigNumber,
                               discount: Double, isMax: Bool = false, maxUpgrades: Int = 1) -> some View {
        let cost = factory.upgradeCost(levels: levels, factoryPerks: perks, baseDiscount: discount)
        let canAfford = isMax ? (maxUpgrades > 0 && money >= cost) : (money >= cost && levels > 0)

        return Button {
            gameManager.upgradeFactoryLevel(factoryId: factory.id, levels: levels)
        } label: {
            VStack(spacing: 1) {
                Text(tr(label))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(canAfford ? .white : .white.opacity(0.65))
                HStack(spacing: 2) {
                    Text("💰")
                        .font(.system(size: 7))
                    Text(cost.formattedString())
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .foregroundStyle(canAfford ? Neon.yellow.opacity(0.95) : .white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
        }
        .buttonStyle(NeonButtonStyle(color: canAfford ? evolutionColor : Color.white.opacity(0.18),
                                     cornerRadius: 12, compact: true))
        .opacity(canAfford ? 1.0 : 0.65)
        .disabled(!canAfford)
    }

    // MARK: Évolution

    /// La 1ʳᵉ évolution exige l'upgrade de prestige « p3_usine_evo ». La condition d'activation du
    /// bouton reste inchangée (l'argent) : on ajoute seulement l'indication du verrou, qui manquait.
    private var isEvolutionLocked: Bool {
        factory.evolution == 0 && !gameManager.hasPrestigeUpgrade("p3_usine_evo")
    }

    private var evolveButton: some View {
        let factoryPerks = gameManager.perks(for: factory.equippedPerkIds)
        let cost = factory.evolveCost(factoryPerks: factoryPerks,
                                      baseDiscount: gameManager.factoryEvolutionCostDiscount)
        let canEvolve = gameManager.money >= cost
        let highlight = canEvolve && !isEvolutionLocked

        return Button {
            gameManager.evolveFactory(factoryId: factory.id)
        } label: {
            evolveLabel(cost: cost, canEvolve: canEvolve)
        }
        .buttonStyle(FactoryEvolveButtonStyle(color: highlight ? nextEvolutionColor : Color.white.opacity(0.16)))
        .opacity(canEvolve ? 1.0 : 0.7)
        .disabled(!canEvolve)
        .shadow(color: nextEvolutionColor.opacity(highlight ? (evolveGlow ? 0.75 : 0.25) : 0),
                radius: evolveGlow ? 18 : 8)
        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: evolveGlow)
        .onAppear { evolveGlow = true }
    }

    private func evolveLabel(cost: BigNumber, canEvolve: Bool) -> some View {
        HStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(nextEvolutionColor.opacity(0.22))
                    .frame(width: 30, height: 30)
                Image(systemName: FactoryEvolutionStyle.icon(factory.evolution + 1))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(nextEvolutionColor)
                    .shadow(color: nextEvolutionColor.opacity(0.9), radius: 5)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(tr("Évoluer"))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                if isEvolutionLocked {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7, weight: .black))
                        Text(tr("Prestige requis"))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Neon.red.opacity(0.9))
                } else {
                    Text("\(tr("Évo.")) \(factory.evolution) → \(factory.evolution + 1)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                Text("💰")
                    .font(.system(size: 9))
                Text(cost.formattedString())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .foregroundStyle(canEvolve ? Neon.yellow : .white.opacity(0.5))
        }
        .frame(height: 32)
    }

    /// Évolution 7 : rien à acheter, on affiche un trophée arc-en-ciel.
    private var maximumBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: 13, weight: .black))
            Text(tr("MAXIMUM"))
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .foregroundStyle(AngularGradient(gradient: FactoryEvolutionStyle.rainbow, center: .center))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AngularGradient(gradient: FactoryEvolutionStyle.rainbow, center: .center),
                        lineWidth: 1.2)
                .opacity(0.7)
        }
        .neonSheen(cornerRadius: 12, pause: 2.6, travel: 0.9, opacity: 0.35)
    }
}

// MARK: - Choix du canard

struct DuckSelectionSheet: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    let factoryId: UUID

    let columns = [
        GridItem(.adaptive(minimum: 55), spacing: 8)
    ]

    @State private var sortOption: InventorySortOption = .sellValueDesc

    @State private var displayInventory: [Duck] = []
    @State private var sortedAll: [Duck] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var currentPage = 0
    @State private var hasMore = false
    private let pageSize = 100

    private func updateDisplayInventory() {
        isLoading = true
        currentPage = 0
        displayInventory = []
        Task {
            let all = await gameManager.getSortedInventoryAsync(by: sortOption, limit: Int.max, filterAssigned: true)
            await MainActor.run {
                self.sortedAll = all
                let first = Array(all.prefix(pageSize))
                self.displayInventory = first
                self.hasMore = all.count > pageSize
                self.currentPage = 1
                self.isLoading = false
            }
        }
    }

    private func loadMoreIfNeeded() {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        Task {
            let nextSlice = Array(sortedAll.dropFirst(currentPage * pageSize).prefix(pageSize))
            await MainActor.run {
                self.displayInventory.append(contentsOf: nextSlice)
                self.currentPage += 1
                self.hasMore = (currentPage * pageSize) < sortedAll.count
                self.isLoadingMore = false
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NeonBackground(accent: Neon.green)
                content
            }
            .navigationTitle(tr("Choisir un canard"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Menu {
                            Picker(tr("Trier par"), selection: $sortOption) {
                                ForEach(InventorySortOption.allCases, id: \.self) { option in
                                    Text(tr(option.rawValue)).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }

                        Button(tr("Fermer")) {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(tr("Retirer")) {
                        gameManager.unassignDuck(from: factoryId)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                updateDisplayInventory()
            }
            .onChange(of: sortOption) { _, _ in
                updateDisplayInventory()
            }
            .onChange(of: gameManager.inventory.count) { _, _ in
                updateDisplayInventory()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            if isLoading {
                ProgressView(tr("Chargement..."))
                    .tint(.white)
                    .padding(.top, 60)
            } else if displayInventory.isEmpty {
                emptyState
            } else {
                grid
            }
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bird")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Neon.green.opacity(0.6))
                .shadow(color: Neon.green.opacity(0.5), radius: 10)
            Text(tr("Aucun canard disponible."))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .neonPanel(color: Neon.green, cornerRadius: 20)
        .padding(.horizontal, 24)
        .padding(.top, 50)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(displayInventory) { duck in
                DuckGridCard(
                    duck: duck,
                    displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                    isAssigned: gameManager.isDuckAssigned(duckId: duck.id),
                    dynamicLevel: gameManager.getDynamicStats(for: duck).level
                )
                .onTapGesture {
                    NeonHaptics.impact()
                    gameManager.assignDuck(duck, to: factoryId)
                    dismiss()
                }
            }

            // Sentinelle de chargement progressif
            if hasMore {
                Color.clear
                    .frame(height: 1)
                    .onAppear { loadMoreIfNeeded() }

                if isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
    }
}
