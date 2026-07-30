import SwiftUI

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct RitualView: View {
    @Environment(GameManager.self) var gameManager: GameManager
    
    @State private var selectedDuck: Duck? = nil
    @State private var showDuckPicker = false
    
    @State private var wheelRotation: Double = 0
    @State private var isSpinning = false
    @State private var showResult = false
    @State private var resultSuccess = false
    @State private var resultGolden = false
    
    // Animations
    @State private var flameFlicker = false
    @State private var glowPulse = false
    @State private var showInfoAlert = false
    
    @State private var showSaveAdAlert = false
    @State private var duckPendingDestruction: Duck? = nil

    // Rituel annulable : permet de « skip » l'animation de la roue.
    @State private var ritualTask: Task<Void, Never>? = nil
    @State private var pendingRitual: PendingRitual? = nil

    // Juice "Cuve d'expérimentation"
    @State private var redFlash: Double = 0
    @State private var spinPulse = false

    /// Paramètres du rituel en cours, conservés pour pouvoir conclure immédiatement en cas de skip.
    private struct PendingRitual {
        let duck: Duck
        let isSuccess: Bool
        let isGolden: Bool
        let targetAngle: Double
    }

    var successChance: Double {
        guard let duck = selectedDuck else { return 0.5 }
        return duck.ritualSuccessChance(occulteLevel: gameManager.occulteLevel)
    }
    
    var body: some View {
        ZStack {
            // Particules flottantes
            RitualParticlesView()
                .ignoresSafeArea()

            // Machine à sous fixe : pas de scroll. La roue occupe une région flexible qui
            // prend tout l'espace restant et s'auto-dimensionne → tout tient sur un seul écran (SE compris).
            VStack(spacing: 10) {
                // Titre
                HStack(spacing: 8) {
                    Text(tr("Le Rituel Canarifique"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [Neon.red, Neon.yellow], startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: Neon.red.opacity(0.6), radius: 8)
                    
                    Button(action: {
                        showInfoAlert = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(colors: [.purple.opacity(0.7), .blue.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                    }
                }
                .padding(.top, 8)
                
                // Roue de la fortune stylisée (occupe la région flexible restante)
                GeometryReader { wg in
                    let wheelScale = min(300, min(wg.size.width, wg.size.height)) / 300
                    ZStack {
                    // Glow "cœur instable" derrière le réacteur
                    Circle()
                        .fill(
                            RadialGradient(colors: [
                                Neon.red.opacity(glowPulse ? 0.35 : 0.15),
                                Neon.yellow.opacity(glowPulse ? 0.12 : 0.05),
                                .clear
                            ], center: .center, startRadius: 40, endRadius: 170)
                        )
                        .frame(width: 300, height: 300)

                    // Anneaux de confinement (statiques)
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Neon.red, Neon.yellow, Neon.red], startPoint: .top, endPoint: .bottom),
                            lineWidth: 3
                        )
                        .frame(width: 238, height: 238)
                        .shadow(color: Neon.red.opacity(0.7), radius: glowPulse ? 10 : 5)
                    Circle()
                        .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [4, 8]))
                        .frame(width: 224, height: 224)

                    // Roue
                    ZStack {
                        // Fond rouge
                        Circle()
                            .fill(
                                RadialGradient(colors: [Color(red: 0.7, green: 0.1, blue: 0.1), Color(red: 0.4, green: 0.05, blue: 0.05)], center: .center, startRadius: 20, endRadius: 100)
                            )
                        
                        let chance = successChance
                        let greenEnd = 360.0 * chance
                        
                        let goldenLevel = gameManager.goldenRitualLevel
                        if goldenLevel > 0 {
                            let goldenRatio = Double(goldenLevel) * 0.04
                            let goldenEnd = 360.0 * goldenRatio
                            
                            PieSlice(startAngle: .degrees(0), endAngle: .degrees(greenEnd))
                                .fill(
                                    LinearGradient(colors: [Color(hue: 0.35, saturation: 0.8, brightness: 0.7), Color(hue: 0.35, saturation: 0.9, brightness: 0.5)], startPoint: .top, endPoint: .bottom)
                                )
                            
                            let actualGoldenEnd = min(goldenEnd, greenEnd)
                            PieSlice(startAngle: .degrees(0), endAngle: .degrees(actualGoldenEnd))
                                .fill(
                                    LinearGradient(colors: [Color(hue: 0.13, saturation: 0.9, brightness: 1.0), Color(hue: 0.10, saturation: 0.8, brightness: 0.85)], startPoint: .top, endPoint: .bottom)
                                )
                        } else {
                            PieSlice(startAngle: .degrees(0), endAngle: .degrees(greenEnd))
                                .fill(
                                    LinearGradient(colors: [Color(hue: 0.35, saturation: 0.8, brightness: 0.7), Color(hue: 0.35, saturation: 0.9, brightness: 0.5)], startPoint: .top, endPoint: .bottom)
                                )
                        }
                        
                        // Noyau central du réacteur (lumineux)
                        Circle()
                            .fill(
                                RadialGradient(colors: [Neon.yellow, Neon.red, Color(red: 0.3, green: 0.02, blue: 0.02)], center: .center, startRadius: 0, endRadius: 18)
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: Neon.yellow.opacity(0.8), radius: glowPulse ? 8 : 4)

                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            .frame(width: 32, height: 32)
                    }
                    .rotationEffect(.degrees(wheelRotation))
                    .frame(width: 210, height: 210)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Neon.yellow.opacity(0.8), Neon.red.opacity(0.6), Neon.yellow.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: Neon.red.opacity(0.6), radius: 15)
                    
                    // Flèche stylisée
                    HStack {
                        Spacer()
                        ZStack {
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                                .shadow(color: .purple, radius: 6)
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(colors: [.white, Color(hue: 0.80, saturation: 0.3, brightness: 1.0)], startPoint: .top, endPoint: .bottom)
                                )
                        }
                        .offset(x: 18)
                    }
                    .frame(width: 260)
                }
                    .frame(width: 300, height: 300)
                    .scaleEffect(wheelScale)
                    .frame(width: wg.size.width, height: wg.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Toucher la roue pendant qu'elle tourne coupe l'animation et révèle le résultat.
                        if isSpinning {
                            skipRitual()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Sélection de canard
                Button(action: {
                    if !isSpinning {
                        showDuckPicker = true
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.4), .blue.opacity(0.2), .purple.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .frame(width: 105, height: 105)
                        
                        if let duck = selectedDuck {
                            DuckGridCard(
                                duck: duck,
                                displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                isAssigned: gameManager.isDuckAssigned(duckId: duck.id),
                                dynamicLevel: gameManager.getDynamicStats(for: duck).level
                            )
                            .scaleEffect(100.0 / 55.0)
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple.opacity(0.7), .blue.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                    )
                                Text(tr("Sélectionner"))
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showDuckPicker) {
                    RitualDuckPickerSheet(selectedDuck: $selectedDuck)
                        .environment(gameManager)
                }
                
                // Infos de prix
                if let duck = selectedDuck {
                    VStack(spacing: 10) {
                        // Barre de chance
                        VStack(spacing: 5) {
                            HStack {
                                Text(tr("Chance de réussite"))
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(successChance * 100))%")
                                    .font(.headline.weight(.bold).monospacedDigit())
                                    .foregroundColor(chanceColor)
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(colors: [chanceColor, chanceColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .frame(width: geo.size.width * min(CGFloat(successChance), 1.0))
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.horizontal, 20)
                        
                        // Valeurs
                        HStack(spacing: 12) {
                            VStack(spacing: 2) {
                                Text(tr("Actuelle"))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("\(gameManager.displaySellValue(for: duck).formattedString()) 💰")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            
                            VStack(spacing: 2) {
                                Text(tr("x2"))
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundColor(.green)
                                Text("\((gameManager.displaySellValue(for: duck) * 2.0).formattedString()) 💰")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.green)
                            }
                            
                            if gameManager.isUnlocked(.goldenRitual) {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.yellow.opacity(0.6))
                                
                                VStack(spacing: 2) {
                                    Text(tr("x10"))
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundColor(.yellow)
                                    Text(tr("Doré 🌟"))
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal)
                } else {
                    Text(tr("Sélectionnez un canard pour voir les détails"))
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding(.vertical, 14)
                }

                // Bouton Lancer
                Button(action: {
                    lancerRituel()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .scaleEffect(flameFlicker ? 1.15 : 1.0)
                        Text(tr("LANCER LE RITUEL"))
                        Image(systemName: "flame.fill")
                            .scaleEffect(flameFlicker ? 1.0 : 1.15)
                    }
                }
                .neonButton(Neon.red)
                .opacity(selectedDuck == nil || isSpinning ? 0.45 : 1.0)
                .disabled(selectedDuck == nil || isSpinning)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .scaleEffect(spinPulse ? 1.015 : 1.0)
        .overlay(Color.red.opacity(redFlash).ignoresSafeArea().allowsHitTesting(false))
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { spinPulse = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { spinPulse = false }
            }
        }
        .overlay {
            if showResult {
                RitualResultOverlay(success: resultSuccess, isGolden: resultGolden)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showResult = false
                            }
                        }
                    }
            }
        }
        .infoPopup(
            isPresented: $showInfoAlert,
            title: tr("Règles du Rituel"),
            message: tr("Sacrifiez un canard pour doubler sa valeur ! Mais attention : la chance de réussite diminue de 5% à chaque succès. En cas d'échec, le canard sera détruit à jamais !"),
            accent: Neon.red
        )
        .alert(tr("Rituel Échoué !"), isPresented: $showSaveAdAlert) {
            Button(tr("Sauver (Pub)"), role: .cancel) {
                AdManager.shared.showRewardedAd(for: .ritualSave) { earned in
                    if !earned {
                        if let d = duckPendingDestruction {
                            gameManager.destroyDuck(id: d.id)
                        }
                        selectedDuck = nil
                    }
                    duckPendingDestruction = nil
                }
            }
            if gameManager.canAffordRitualGemSave {
                Button(tr("Sauver") + " (100 💎)") {
                    if gameManager.saveRitualWithGems() {
                        // Canard sauvé : on le conserve tel quel.
                        duckPendingDestruction = nil
                    }
                }
            }
            Button(tr("Accepter la perte"), role: .destructive) {
                if let d = duckPendingDestruction {
                    gameManager.destroyDuck(id: d.id)
                }
                selectedDuck = nil
                duckPendingDestruction = nil
            }
        } message: {
            Text(tr("Le rituel a échoué. Votre canard va être détruit. Sauvez-le avec une publicité ou 100 gemmes."))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                flameFlicker = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    private var chanceColor: Color {
        if successChance > 0.7 { return .green }
        if successChance > 0.4 { return .yellow }
        return .red
    }
    
    private func lancerRituel() {
        guard let duck = selectedDuck else { return }

        isSpinning = true
        showResult = false
        let chance = successChance
        let goldenLevel = gameManager.goldenRitualLevel
        let goldenRatio = Double(goldenLevel) * 0.04
        let goldenDegrees = min(360.0 * goldenRatio, 360.0 * chance)
        let goldenChance = goldenDegrees / 360.0

        let roll = Double.random(in: 0.0..<1.0)
        let isGoldenResult = roll < goldenChance
        let isSuccess = roll < chance

        // Marge de sécurité : la flèche ne doit jamais tomber pile sur une bordure de couleur.
        let targetAngle: Double
        if isGoldenResult {
            // Zone dorée [0, goldenDegrees), bordée par le haut (rouge) et par le vert.
            targetAngle = paddedAngle(lower: 0, upper: goldenDegrees)
        } else if isSuccess {
            let maxAngle = 360 * chance
            targetAngle = paddedAngle(lower: goldenDegrees, upper: maxAngle)
        } else {
            let minAngle = min(360 * chance, 360.0)
            targetAngle = paddedAngle(lower: minAngle, upper: 360.0)
        }

        pendingRitual = PendingRitual(duck: duck, isSuccess: isSuccess, isGolden: isGoldenResult, targetAngle: targetAngle)

        // On veut que l'angle `targetAngle` tombe sur la flèche (à 0 degrés).
        // Donc on tourne de `-targetAngle` + 5 tours complets
        let totalRotation = -(targetAngle) - (360 * 5)

        withAnimation(.easeOut(duration: 3.0)) {
            wheelRotation = totalRotation
        }

        // Délai annulable : un tap sur la roue peut le couper pour révéler le résultat immédiatement.
        ritualTask = Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            if Task.isCancelled { return }
            finishRitual(duck: duck, isSuccess: isSuccess, isGoldenResult: isGoldenResult, targetAngle: targetAngle)
        }
    }

    /// Coupe l'animation en cours et conclut le rituel tout de suite (skip).
    private func skipRitual() {
        guard isSpinning, let pending = pendingRitual else { return }
        ritualTask?.cancel()
        ritualTask = nil

        // Arrêter net l'animation de la roue en la figeant à sa position finale.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            wheelRotation = -(pending.targetAngle)
        }

        finishRitual(duck: pending.duck, isSuccess: pending.isSuccess, isGoldenResult: pending.isGolden, targetAngle: pending.targetAngle)
    }

    /// Logique de fin de rituel : affichage du résultat, application métier, remise à zéro.
    /// Idempotente : le garde `isSpinning` évite une double exécution (timer + skip).
    private func finishRitual(duck: Duck, isSuccess: Bool, isGoldenResult: Bool, targetAngle: Double) {
        guard isSpinning else { return }

        resultSuccess = isSuccess
        resultGolden = isGoldenResult
        withAnimation {
            showResult = true
        }

        // Appliquer la logique métier
        gameManager.performRitual(on: duck.id, success: isSuccess, isGolden: isGoldenResult)

        // Mettre à jour l'UI + juice
        if isSuccess {
            // Succès : vibration forte + étincelles d'ADN
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            gameManager.triggerConfetti()
            // Le canard a gagné, on met à jour son instance locale pour voir la flamme
            if let updatedDuck = gameManager.inventory.first(where: { $0.id == duck.id }) {
                selectedDuck = updatedDuck
            }
        } else {
            // Échec : vibration d'erreur + flash rouge + secousse d'écran
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            gameManager.triggerScreenShake()
            withAnimation(.easeIn(duration: 0.08)) { redFlash = 0.55 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.35)) { redFlash = 0 }
            }
            // On met en attente de destruction
            duckPendingDestruction = duck
            showSaveAdAlert = true
        }

        // Réinitialiser la roue silencieusement (garder la position visuelle, enlever les tours)
        wheelRotation = -(targetAngle)
        isSpinning = false
        pendingRitual = nil
        ritualTask = nil
    }

    /// Angle aléatoire dans [lower, upper] en gardant une marge (padding) loin des bordures.
    /// Si la zone est trop fine pour la marge, on vise son milieu exact (toujours au centre d'une couleur).
    private func paddedAngle(lower: Double, upper: Double, padding: Double = 2.0) -> Double {
        let lo = lower + padding
        let hi = upper - padding
        guard lo < hi else { return (lower + upper) / 2.0 }
        return Double.random(in: lo..<hi)
    }
}



// MARK: - Particules rituelles
private struct RitualParticlesView: View {
    @State private var particles: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double, hue: Double)] = []
    @State private var animate = false
    
    var body: some View {
        Canvas { context, size in
            for p in particles {
                let yOffset = animate ? -30.0 : 30.0
                let rect = CGRect(
                    x: p.x * size.width,
                    y: p.y * size.height + yOffset,
                    width: p.size,
                    height: p.size
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color(hue: p.hue, saturation: 0.6, brightness: 0.8).opacity(p.opacity * (animate ? 0.7 : 0.3)))
                )
            }
        }
        .onAppear {
            particles = (0..<30).map { _ in
                (
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    size: CGFloat.random(in: 1.5...4),
                    opacity: Double.random(in: 0.15...0.5),
                    hue: Double.random(in: 0.7...0.9) // Purple range
                )
            }
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct RitualDuckPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(GameManager.self) var gameManager: GameManager
    @Binding var selectedDuck: Duck?
    
    @State private var displayDucks: [Duck] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var currentPage = 0
    @State private var sortedAll: [Duck] = []
    @State private var hasMore = false
    private let pageSize = 100
    
    private func updateDisplayInventory() {
        isLoading = true
        currentPage = 0
        displayDucks = []
        let gm = gameManager
        Task {
            let all = await gm.getSortedInventoryAsync(by: .sellValueDesc, limit: Int.max)
            let firstSlice = Array(all.prefix(pageSize))
            await MainActor.run {
                self.sortedAll = all
                self.displayDucks = firstSlice
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
                self.displayDucks.append(contentsOf: nextSlice)
                self.currentPage += 1
                self.hasMore = (self.currentPage * self.pageSize) < self.sortedAll.count
                self.isLoadingMore = false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                NeonBackground(accent: Neon.red)

                if isLoading {
                    ProgressView("Chargement des canards...")
                        .tint(.white)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 55), spacing: 8)], spacing: 8) {
                            ForEach(displayDucks) { duck in
                                DuckGridCard(
                                    duck: duck,
                                    displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                    isAssigned: gameManager.isDuckAssigned(duckId: duck.id),
                                    dynamicLevel: gameManager.getDynamicStats(for: duck).level
                                )
                                .onTapGesture {
                                    selectedDuck = duck
                                    dismiss()
                                }
                                .onAppear {
                                    if duck.id == displayDucks.last?.id {
                                        loadMoreIfNeeded()
                                    }
                                }
                            }

                            if isLoadingMore {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(tr("Sélectionner un canard"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            updateDisplayInventory()
        }
    }
}
