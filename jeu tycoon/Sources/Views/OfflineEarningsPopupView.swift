import SwiftUI

/// Écran « De Retour ! » : le tout premier écran de la session du matin, donc celui qui
/// décide de la rétention. Tout y est réglé pour la satisfaction : panneau de verre massif,
/// compteurs qui défilent de 0 jusqu'au butin, bouton doré « pub ×2 » en héros et gros bouton
/// néon « Réclamer » juste en dessous, puis flash + confettis à l'encaissement.
struct OfflineEarningsPopupView: View {
    @Environment(GameManager.self) private var gameManager
    @ObservedObject private var adManager = AdManager.shared

    // MARK: Séquence d'entrée
    @State private var showCard = false
    @State private var showContent = false
    @State private var showButtons = false

    /// Fraction du butin affichée par les compteurs : 0 → 1 au décompte, puis 1 → 2 après la pub.
    @State private var countProgress: Double = 0
    /// Le canard dort (et ronfle) tant que le décompte n'a pas commencé.
    @State private var isCounting = false
    @State private var zzzFloat = false

    // MARK: Encaissement / célébration
    @State private var isClaiming = false
    @State private var exit = false
    @State private var flashOpacity: Double = 0
    @State private var shockwave: CGFloat = 0
    @State private var confettiBurst = 0

    // MARK: Décor
    @State private var mascotRarity: DuckRarity = .commun
    @State private var haloPulse = false
    @State private var ringAngle: Double = 0
    @State private var adGlow = false

    /// Durée du décompte : assez rapide pour ne pas retarder l'entrée en jeu, assez long
    /// pour qu'on ait le temps de voir les chiffres grimper.
    private let countDuration: Double = 1.15
    private let countSteps = 26

    private let gold = Color(hex: 0xFFB01F)

    var body: some View {
        if let earnings = gameManager.pendingOfflineEarnings {
            ZStack {
                backdrop

                GeometryReader { geo in
                    let compact = geo.size.height < 720
                    ScrollView {
                        panel(for: earnings, compact: compact)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                }

                celebrationLayer

                ConfettiView(trigger: confettiBurst)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            // Un fullScreenCover n'hérite PAS du colorScheme de ContentView : sans ça, le verre
            // (ultraThinMaterial) vire au blanc laiteux sur un iPhone en mode clair.
            .preferredColorScheme(.dark)
            .zIndex(100)
            .task { await runIntro() }
        }
    }

    // MARK: - Décor de fond

    private var backdrop: some View {
        ZStack {
            Color(hex: 0x06060E)
            RadialGradient(colors: [Neon.purple.opacity(0.38), .clear],
                           center: UnitPoint(x: 0.5, y: 0.26), startRadius: 10, endRadius: 460)
            RadialGradient(colors: [Neon.cyan.opacity(0.10), .clear],
                           center: .bottomTrailing, startRadius: 10, endRadius: 420)
            DustField()
                .opacity(0.7)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        // Le popup est bloquant : on absorbe tout geste qui tenterait d'atteindre le jeu derrière.
        .highPriorityGesture(DragGesture(minimumDistance: 0))
    }

    private var celebrationLayer: some View {
        ZStack {
            // Onde de choc : invisible tant qu'on n'a pas encaissé (sinon un anneau reste
            // affiché en plein milieu du panneau au repos).
            Circle()
                .stroke(Neon.cyan, lineWidth: 5)
                .frame(width: 140, height: 140)
                .scaleEffect(1 + shockwave * 4.5)
                .opacity(isClaiming ? max(0, 0.8 - Double(shockwave) * 0.8) : 0)
                .blur(radius: 1)

            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Panneau de verre

    private func panel(for earnings: GameManager.OfflineEarnings, compact: Bool) -> some View {
        VStack(spacing: compact ? 16 : 22) {
            mascot(compact: compact)
            header(for: earnings, compact: compact)
            rewards(for: earnings, compact: compact)
            buttons(for: earnings)
        }
        .padding(.vertical, compact ? 22 : 30)
        .padding(.horizontal, compact ? 16 : 20)
        .frame(maxWidth: 430)
        .neonPanel(color: Neon.purple, cornerRadius: 32)
        .overlay { glassSheen }
        .shadow(color: Neon.purple.opacity(0.45), radius: 34, y: 14)
        .scaleEffect(showCard ? (exit ? 1.07 : 1.0) : 0.86)
        .opacity(showCard ? (exit ? 0 : 1) : 0)
        .offset(y: exit ? -36 : 0)
    }

    /// Reflet de vitre : la lumière qui glisse sur le verre donne son épaisseur au panneau.
    private var glassSheen: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.13), location: 0),
                        .init(color: .white.opacity(0.02), location: 0.30),
                        .init(color: .clear, location: 0.60),
                        .init(color: .white.opacity(0.05), location: 1)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    // MARK: - Mascotte

    private func mascot(compact: Bool) -> some View {
        let size: CGFloat = compact ? 88 : 112
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [Neon.purple.opacity(0.55), Neon.cyan.opacity(0.10), .clear],
                                     center: .center, startRadius: 2, endRadius: size))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(haloPulse ? 1.06 : 0.9)
                .blur(radius: 8)

            Circle()
                .strokeBorder(
                    AngularGradient(colors: [.clear, Neon.cyan.opacity(0.9), Neon.purple.opacity(0.9), .clear],
                                    center: .center),
                    lineWidth: 1.5
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .rotationEffect(.degrees(ringAngle))
                .opacity(0.7)

            Image(mascotRarity.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: Neon.purple.opacity(0.75), radius: 16)
                // Penché et tassé tant qu'il dort, il se redresse quand le compteur démarre.
                .rotationEffect(.degrees(isCounting ? 0 : -8), anchor: .bottom)
                .scaleEffect(isCounting ? 1.0 : 0.96, anchor: .bottom)

            if !isCounting {
                sleepZzz
                    .offset(x: size * 0.44, y: -size * 0.40)
                    .transition(.opacity)
            }
        }
        .frame(height: size * 1.45)
    }

    private var sleepZzz: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Text("z")
                    .font(.system(size: CGFloat(13 + i * 5), weight: .black, design: .rounded))
                    .foregroundStyle(Neon.cyan.opacity(0.9))
                    .shadow(color: Neon.cyan.opacity(0.6), radius: 4)
                    .offset(x: CGFloat(i) * 9, y: zzzFloat ? CGFloat(-16 - i * 9) : CGFloat(2 - i * 2))
                    .opacity(zzzFloat ? 0 : 0.95)
                    .animation(
                        .easeInOut(duration: 1.9).repeatForever(autoreverses: false).delay(Double(i) * 0.45),
                        value: zzzFloat
                    )
            }
        }
    }

    // MARK: - Titre

    private func header(for earnings: GameManager.OfflineEarnings, compact: Bool) -> some View {
        VStack(spacing: 10) {
            Text(tr("De Retour !"))
                .font(.system(size: compact ? 30 : 37, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Neon.yellow.opacity(0.85), radius: 14)
                .shadow(color: Neon.magenta.opacity(0.35), radius: 26)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HStack(spacing: 7) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 11))
                Text("\(tr("Vos usines ont tourné pendant")) \(formatTime(earnings.seconds))")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.07)))
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
    }

    // MARK: - Butin

    @ViewBuilder
    private func rewards(for earnings: GameManager.OfflineEarnings, compact: Bool) -> some View {
        VStack(spacing: 10) {
            rewardCard(
                icon: "💰",
                label: tr("Argent"),
                value: earnings.money.countingString(progress: countProgress),
                color: Neon.yellow,
                fontSize: compact ? 29 : 35,
                index: 0
            )

            if earnings.dna > .zero {
                rewardCard(
                    icon: "🧬",
                    label: tr("ADN"),
                    value: earnings.dna.countingString(progress: countProgress),
                    color: Neon.green,
                    fontSize: compact ? 26 : 31,
                    index: 1
                )
            }

            if earnings.xp > 0 {
                let xp = Int((Double(earnings.xp) * countProgress).rounded())
                HStack(spacing: 7) {
                    Text("⭐")
                        .font(.system(size: 12))
                    Text("+\(xp)\(tr(" XP"))")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(xp)))
                }
                .foregroundStyle(Neon.cyan)
                .shadow(color: Neon.cyan.opacity(0.6), radius: 6)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Neon.cyan.opacity(0.10)))
                .overlay(Capsule().stroke(Neon.cyan.opacity(0.30), lineWidth: 1))
            }
        }
    }

    private func rewardCard(icon: String, label: String, value: String, color: Color, fontSize: CGFloat, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(color.opacity(0.16))
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 1)
                Text(icon)
                    .font(.system(size: 25))
            }
            .frame(width: 54, height: 54)
            .shadow(color: color.opacity(0.45), radius: 8)

            VStack(alignment: .leading, spacing: 0) {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.5))

                Text(value)
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: countProgress))
                    .foregroundStyle(.white)
                    .shadow(color: color.opacity(0.9), radius: 12)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background {
            // La cuve se remplit au rythme du compteur.
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Color.white.opacity(0.04)
                    LinearGradient(colors: [color.opacity(0.30), color.opacity(0.04)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: g.size.width * min(countProgress, 1.0))
                }
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(color.opacity(0.32), lineWidth: 1)
        }
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -22)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.10 + Double(index) * 0.08), value: showContent)
    }

    // MARK: - Boutons

    @ViewBuilder
    private func buttons(for earnings: GameManager.OfflineEarnings) -> some View {
        VStack(spacing: 12) {
            if adManager.isReady {
                Button(action: watchAdForDouble) {
                    adButtonLabel(for: earnings)
                }
                .buttonStyle(GoldenAdButtonStyle())
                .overlay(alignment: .topTrailing) {
                    freeBadge.offset(x: 8, y: -9)
                }
                .shadow(color: gold.opacity(adGlow ? 0.85 : 0.35), radius: adGlow ? 26 : 12)
                .scaleEffect(adGlow ? 1.015 : 0.995)
            } else {
                adLoadingSlot
            }

            Button(action: claimNow) {
                HStack(spacing: 10) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 17, weight: .bold))
                    Text(tr("Réclamer"))
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                }
                .padding(.vertical, 5)
            }
            .neonButton(Neon.cyan, cornerRadius: 20)
            .shadow(color: Neon.cyan.opacity(0.55), radius: 18)
        }
        .disabled(isClaiming)
        .opacity(showButtons ? 1 : 0)
        .offset(y: showButtons ? 0 : 18)
    }

    private func adButtonLabel(for earnings: GameManager.OfflineEarnings) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 40, height: 40)
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color(hex: 0xFFF0C2))
                    .offset(x: 1)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(tr("Regarder une pub"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                HStack(spacing: 9) {
                    Text("💰 \((earnings.money * 2.0).formattedString())")
                    if earnings.dna > .zero {
                        Text("🧬 \((earnings.dna * 2.0).formattedString())")
                    }
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .opacity(0.72)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            }

            Spacer(minLength: 0)

            Text("×2")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: 0x4A2400))
                .padding(.horizontal, 11)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.9)))
                .shadow(color: .white.opacity(0.55), radius: 7)
        }
    }

    private var freeBadge: some View {
        Text(tr("GRATUIT"))
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Capsule().fill(Neon.green))
            .shadow(color: Neon.green.opacity(0.85), radius: 7)
            .rotationEffect(.degrees(9))
    }

    /// Même gabarit que le bouton doré pour que rien ne saute quand la pub finit de charger.
    private var adLoadingSlot: some View {
        HStack(spacing: 11) {
            ProgressView()
                .tint(.white.opacity(0.8))
            Text(tr("Chargement de la pub..."))
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Spacer(minLength: 0)
            Text("×2")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .opacity(0.3)
        }
        .foregroundStyle(.white.opacity(0.55))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 19)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    // MARK: - Actions

    private func watchAdForDouble() {
        guard !isClaiming else { return }
        AdManager.shared.showRewardedAd(for: .offlineBoost) { earned in
            Task { @MainActor in
                guard earned else { return }
                await runDoubleUp()
            }
        }
    }

    private func claimNow() {
        guard !isClaiming else { return }
        Task { @MainActor in
            await celebrate(multiplier: 1.0)
        }
    }

    // MARK: - Chorégraphie

    @MainActor
    private func runIntro() async {
        mascotRarity = bestWorkerRarity()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { showCard = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) { showContent = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.55)) { showButtons = true }
        withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { haloPulse = true }
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) { ringAngle = 360 }
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { adGlow = true }
        zzzFloat = true

        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { isCounting = true }
        await runCountUp()
    }

    /// Défilement 0 → butin. Les paliers sont discrets et enchaînés en `.linear` :
    /// chaque pas déclenche le morphing `.numericText`, ce qui donne le compteur qui roule.
    @MainActor
    private func runCountUp() async {
        let stepDuration = countDuration / Double(countSteps)
        for step in 1...countSteps {
            guard !Task.isCancelled else { return }
            let t = Double(step) / Double(countSteps)
            // Ease-out : ça part très vite puis ça ralentit sur les derniers chiffres.
            let eased = 1 - pow(1 - t, 2.4)
            withAnimation(.linear(duration: stepDuration)) { countProgress = eased }
            if step % 3 == 0 { NeonHaptics.tick() }
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        countProgress = 1
    }

    /// Pub regardée : on rejoue le compteur de ×1 à ×2 avant la célébration, pour que le
    /// joueur *voie* ce que la pub lui a rapporté.
    @MainActor
    private func runDoubleUp() async {
        guard !isClaiming else { return }
        NeonHaptics.success()
        let steps = 12
        let stepDuration = 0.5 / Double(steps)
        for step in 1...steps {
            guard !Task.isCancelled else { break }
            let t = Double(step) / Double(steps)
            withAnimation(.linear(duration: stepDuration)) {
                countProgress = 1 + (1 - pow(1 - t, 2))
            }
            if step % 2 == 0 { NeonHaptics.tick() }
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        countProgress = 2
        await celebrate(multiplier: 2.0)
    }

    @MainActor
    private func celebrate(multiplier: Double) async {
        guard !isClaiming else { return }
        isClaiming = true

        // Réclamer pendant le décompte ne doit pas priver le joueur du chiffre final.
        if countProgress < 1 {
            withAnimation(.easeOut(duration: 0.18)) { countProgress = 1 }
        }

        NeonHaptics.success()
        confettiBurst &+= 1
        shockwave = 0
        withAnimation(.easeOut(duration: 0.14)) { flashOpacity = 0.5 }
        withAnimation(.easeOut(duration: 0.6)) { shockwave = 1 }
        withAnimation(.easeOut(duration: 0.3).delay(0.14)) { flashOpacity = 0 }
        // Le panneau part vers le HUD pendant que les confettis tombent.
        withAnimation(.easeIn(duration: 0.4).delay(0.2)) { exit = true }

        try? await Task.sleep(nanoseconds: 620_000_000)

        // Les confettis de ContentView continuent de tomber une fois le popup refermé.
        gameManager.triggerConfetti()
        gameManager.claimOfflineEarnings(multiplier: multiplier)
    }

    // MARK: - Helpers

    /// Le canard le plus rare qui a bossé cette nuit (assigné à une usine) — à défaut, le plus
    /// rare de l'inventaire. Un seul passage : l'inventaire peut être énorme.
    private func bestWorkerRarity() -> DuckRarity {
        let assignedIds = Set(gameManager.factories.flatMap { $0.assignedDuckIds })
        var working: DuckRarity?
        var owned: DuckRarity?
        for duck in gameManager.inventory {
            if assignedIds.contains(duck.id), working == nil || duck.rarity > working! {
                working = duck.rarity
            }
            if owned == nil || duck.rarity > owned! {
                owned = duck.rarity
            }
        }
        return working ?? owned ?? .commun
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(max(1, minutes)) \(tr("minutes"))"
        }
    }
}

// `GoldenAdButtonStyle` vit maintenant dans NeonUI.swift : il sert aussi à la Capsule Mystère
// de la boutique et à toute offre « pub » du jeu.

// MARK: - Poussière lumineuse

/// Particules qui montent lentement en fond : donne de la vie à l'écran sans bouffer la scène.
private struct DustField: View {
    private struct Mote {
        let x: Double
        let phase: Double
        let speed: Double
        let size: Double
        let color: Color
    }

    private static let motes: [Mote] = (0..<22).map { i in
        // Pseudo-aléatoire déterministe : pas de Random à chaque construction de vue.
        let f = Double(i)
        let colors = [Neon.cyan, Neon.purple, Color.white, Neon.green]
        return Mote(
            x: (sin(f * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1.0).magnitude,
            phase: (sin(f * 78.233) * 12345.6789).truncatingRemainder(dividingBy: 1.0).magnitude,
            speed: 0.012 + (sin(f * 3.17) * 0.5 + 0.5) * 0.028,
            size: 1.4 + (sin(f * 7.31) * 0.5 + 0.5) * 2.6,
            color: colors[i % colors.count]
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for mote in Self.motes {
                    var y = (mote.phase - t * mote.speed).truncatingRemainder(dividingBy: 1.0)
                    if y < 0 { y += 1 }
                    // Fondu en haut et en bas pour qu'aucune particule ne « pope ».
                    let fade = min(1.0, min(y, 1 - y) * 6.0)
                    let rect = CGRect(x: mote.x * size.width, y: y * size.height,
                                      width: mote.size, height: mote.size)
                    var ctx = context
                    ctx.opacity = 0.55 * fade
                    ctx.addFilter(.shadow(color: mote.color.opacity(0.8), radius: 3))
                    ctx.fill(Path(ellipseIn: rect), with: .color(mote.color))
                }
            }
        }
    }
}
