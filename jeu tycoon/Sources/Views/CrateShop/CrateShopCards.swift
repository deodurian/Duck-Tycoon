import SwiftUI
import Foundation

// MARK: - Hexagone (silhouette de cryo-capsule)
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.25))
        p.addLine(to: CGPoint(x: w, y: h * 0.75))
        p.addLine(to: CGPoint(x: w * 0.5, y: h))
        p.addLine(to: CGPoint(x: 0, y: h * 0.75))
        p.addLine(to: CGPoint(x: 0, y: h * 0.25))
        p.closeSubpath()
        return p
    }
}

// MARK: - Cryo-Capsule (visuel futuriste remplaçant l'icône carton)
struct CryoCapsuleIcon: View {
    let type: CrateType
    var glow: Bool = false
    var size: CGFloat = 62
    /// Lévitation lente + anneau hexagonal qui tourne : la capsule « vit » dans la boutique.
    var alive: Bool = false

    @State private var float = false
    @State private var spin = false

    /// Symbole tech par palier de capsule.
    private var techIcon: String {
        switch type {
        case .bois:    return "cube.transparent"
        case .fer:     return "shield.lefthalf.filled"
        case .or:      return "atom"
        case .platine: return "waveform.path.ecg"
        case .saphir:  return "snowflake"
        case .rubis:   return "cube.transparent.fill"
        case .diamant: return "sparkles"
        case .secrete: return "questionmark.diamond.fill"
        }
    }

    var body: some View {
        ZStack {
            // Aura lumineuse de la rareté
            Hexagon()
                .fill(
                    RadialGradient(colors: [type.accentColor.opacity(glow ? 0.65 : 0.4), .clear],
                                   center: .center, startRadius: 2, endRadius: size * 0.85)
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 7)

            // Anneau de confinement en rotation lente
            if alive {
                Hexagon()
                    .stroke(type.accentColor.opacity(0.38), style: StrokeStyle(lineWidth: 1, dash: [7, 5]))
                    .frame(width: size * 1.22, height: size * 1.22)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 16).repeatForever(autoreverses: false), value: spin)
            }

            // Corps de la capsule (dégradé intérieur + reflet + bordure lumineuse)
            Hexagon()
                .fill(LinearGradient(colors: type.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    Hexagon()
                        .fill(LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center))
                )
                .overlay(
                    Hexagon()
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.75), type.accentColor.opacity(0.55)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5
                        )
                )
                .frame(width: size, height: size)
                .shadow(color: type.accentColor.opacity(glow ? 0.9 : 0.6), radius: glow ? 14 : 9)

            // Symbole tech central
            Image(systemName: techIcon)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: type.accentColor.opacity(0.8), radius: 4)
        }
        .frame(width: size, height: size)
        .offset(y: alive ? (float ? -3.5 : 3.5) : 0)
        .animation(alive ? .easeInOut(duration: 2.6).repeatForever(autoreverses: true) : nil, value: float)
        .onAppear {
            guard alive else { return }
            float = true
            spin = true
        }
    }
}

// MARK: - Premium Crate Card
struct PremiumCrateCard: View {
    @Environment(GameManager.self) private var gameManager
    let crate: Crate
    /// Position dans la grille : sert à échelonner l'entrée en scène.
    var appearIndex: Int = 0
    @Binding var openingState: CrateOpeningState?
    @Binding var infoCrate: Crate?

    @State private var showingBulkSheet = false
    @State private var holdTimer: Timer?
    @State private var openedCount: Int = 0
    @State private var isGenerating = false
    @State private var holdDidTrigger = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var glowPulse = false
    /// Recul de la capsule au moment de l'achat (micro-célébration avant l'écran d'ouverture).
    @State private var punch: CGFloat = 0
    @State private var buyFlash: Double = 0
    @State private var appeared = false

    /// La rareté la plus élevée que cette capsule peut donner
    private var bestRarity: DuckRarity? {
        crate.probabilities.chances.filter { $0.value > 0 }.keys.max()
    }


    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon and name
            ZStack {
                // Animated glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [crate.type.accentColor.opacity(glowPulse ? 0.4 : 0.15), .clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .offset(y: -5)
                
                VStack(spacing: 6) {
                    // Cryo-capsule futuriste (hexagone + symbole tech + aura de rareté)
                    CryoCapsuleIcon(type: crate.type, glow: glowPulse, alive: true)
                        .scaleEffect(1 - punch * 0.14)
                        .rotationEffect(.degrees(Double(punch) * -7))

                    Text(tr(crate.type.shortName))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(crate.type.textColor)

                    // Meilleure rareté obtenable dans cette capsule
                    if let bestRarity = bestRarity {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                            Text(tr(bestRarity.rawValue))
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundColor(bestRarity.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.35)))
                        .overlay(Capsule().stroke(bestRarity.color.opacity(0.5), lineWidth: 1))
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 4)

            Spacer(minLength: 4)
            
            // Buy buttons section
            VStack(spacing: 5) {
                if let moneyCost = crate.costMoney {
                    moneyButtons(cost: moneyCost)
                }
                
                if let mutationCost = crate.costMutationPoints {
                    mutationButtons(cost: mutationCost)
                }
                
                // Multiple button
                multipleButton
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
            
            if openedCount > 0 {
                // Compteur de série pendant le maintien : on voit la boucle tourner.
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8, weight: .black))
                    Text("×\(openedCount)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.92)))
                .padding(.bottom, 6)
                .transition(.scale.combined(with: .opacity))
            } else if gameManager.isUnlocked(.holdToOpen) {
                Text(tr("Maintenir = boucle"))
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(crate.type.textColor.opacity(0.5))
                    .padding(.bottom, 6)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .overlay(alignment: .topTrailing) {
            Button(action: { withAnimation { infoCrate = crate } }) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(crate.type.textColor.opacity(0.55))
                    .padding(8)
            }
        }
        .frame(minHeight: 220)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: crate.type.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                
                // Inner highlight
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1), crate.type.accentColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                
                // Shimmer sweep
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.12), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.5, height: geo.size.height * 2)
                    .rotationEffect(.degrees(20))
                    .offset(x: shimmerOffset * geo.size.width * 2 - geo.size.width * 0.5, y: -geo.size.height * 0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .shadow(color: crate.type.accentColor.opacity(0.35), radius: 10, y: 5)
        )
        // Éclair d'achat : la carte "encaisse" le coup avant l'écran d'ouverture.
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .opacity(buyFlash)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
        .scaleEffect(1 - punch * 0.035)
        // Entrée en scène échelonnée
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            // Periodic shimmer
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false).delay(Double.random(in: 0...2))) {
                shimmerOffset = 1.5
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85).delay(Double(appearIndex) * 0.05)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showingBulkSheet) {
            BulkCrateOpeningSheet(crate: crate, onBuy: { amount in
                handleBulkBuy(amount: amount)
            })
            .environment(gameManager)
        }
        .overlay {
            if isGenerating {
                ZStack {
                    Color.black.opacity(0.5)
                        .cornerRadius(18)
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text(tr("Génération..."))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .allowsHitTesting(!isGenerating)
        .onDisappear {
            stopHold()
        }
    }
    
    // MARK: - Money Buttons
    @ViewBuilder
    private func moneyButtons(cost: BigNumber) -> some View {
        let amountMultiplier = gameManager.isUnlocked(.multipleOpenX10) ? 10 : 5
        let amountLabel = gameManager.isUnlocked(.multipleOpenX10) ? "x10" : "x5"
        let isMultipleUnlocked = gameManager.isUnlocked(.multipleOpenX5) || gameManager.isUnlocked(.multipleOpenX10)
        
        let key1 = "\(crate.type.rawValue)_money_1"
        let canAfford1 = gameManager.affordableCrateKeys.contains(key1)
        
        HStack(spacing: 4) {
            CratePurchaseButton(
                amountLabel: "x1",
                costStr: cost.formattedString(),
                icon: "💰",
                isUnlocked: true,
                canAfford: canAfford1,
                textColor: crate.type.textColor,
                isHoldUnlocked: gameManager.isUnlocked(.holdToOpen),
                action: { buyCrateWithMoney(amount: 1) },
                startHold: { if holdTimer == nil { startHold(amount: 1) } },
                stopHold: { stopHold() }
            )
            
            if let multiCost = gameManager.calculateCrateCostMoney(crate: crate, amount: amountMultiplier) {
                let keyM = "\(crate.type.rawValue)_money_multi"
                let canAffordM = gameManager.affordableCrateKeys.contains(keyM)
                CratePurchaseButton(
                    amountLabel: amountLabel,
                    costStr: multiCost.formattedString(),
                    icon: "💰",
                    isUnlocked: isMultipleUnlocked,
                    canAfford: canAffordM,
                    textColor: crate.type.textColor,
                    isHoldUnlocked: gameManager.isUnlocked(.holdToOpen),
                    action: { if isMultipleUnlocked { buyCrateWithMoney(amount: amountMultiplier) } },
                    startHold: { if holdTimer == nil { startHold(amount: amountMultiplier) } },
                    stopHold: { stopHold() }
                )
            }
        }
    }
    
    // MARK: - Mutation Buttons
    @ViewBuilder
    private func mutationButtons(cost: BigNumber) -> some View {
        let amountMultiplier = gameManager.isUnlocked(.multipleOpenX10) ? 10 : 5
        let amountLabel = gameManager.isUnlocked(.multipleOpenX10) ? "x10" : "x5"
        let isMultipleUnlocked = gameManager.isUnlocked(.multipleOpenX5) || gameManager.isUnlocked(.multipleOpenX10)
        
        let key1Mut = "\(crate.type.rawValue)_mutation_1"
        let canAfford1Mut = gameManager.affordableCrateKeys.contains(key1Mut)
        
        HStack(spacing: 4) {
            CratePurchaseButton(
                amountLabel: "x1",
                costStr: cost.formattedString(),
                icon: "🧬",
                isUnlocked: true,
                canAfford: canAfford1Mut,
                textColor: crate.type.textColor,
                isHoldUnlocked: gameManager.isUnlocked(.holdToOpen),
                action: { buyCrateWithMutationPoints(amount: 1) },
                startHold: { if holdTimer == nil { startHold(amount: 1) } },
                stopHold: { stopHold() }
            )
            
            if let multiCost = gameManager.calculateCrateCostMutation(crate: crate, amount: amountMultiplier) {
                let keyMMut = "\(crate.type.rawValue)_mutation_multi"
                let canAffordMMut = gameManager.affordableCrateKeys.contains(keyMMut)
                CratePurchaseButton(
                    amountLabel: amountLabel,
                    costStr: multiCost.formattedString(),
                    icon: "🧬",
                    isUnlocked: isMultipleUnlocked,
                    canAfford: canAffordMMut,
                    textColor: crate.type.textColor,
                    isHoldUnlocked: gameManager.isUnlocked(.holdToOpen),
                    action: { if isMultipleUnlocked { buyCrateWithMutationPoints(amount: amountMultiplier) } },
                    startHold: { if holdTimer == nil { startHold(amount: amountMultiplier) } },
                    stopHold: { stopHold() }
                )
            }
        }
    }
    
    // MARK: - Multiple Button
    private var multipleButton: some View {
        let keyMax = "\(crate.type.rawValue)_max"
        let canBuyMax = gameManager.affordableCrateKeys.contains(keyMax)
        
        let unlocked = gameManager.isUnlocked(.multipleOpenMax)
        let active = canBuyMax && unlocked

        return Button(action: {
            if unlocked {
                NeonHaptics.impact()
                showingBulkSheet = true
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: unlocked ? "square.stack.3d.up.fill" : "lock.fill")
                    .font(.system(size: 9, weight: .black))
                Text(tr("Multiple"))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? Color.white.opacity(0.16) : Color.black.opacity(0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(active ? Color.white.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(active ? Color.white : crate.type.textColor.opacity(0.4))
        }
        .disabled(!unlocked)
    }
    
    // MARK: - Réaction d'achat

    /// Micro-célébration locale : la capsule recule, la carte encaisse un éclair.
    /// Se déclenche AVANT l'écran d'ouverture plein écran, pour que l'appui rende quelque chose
    /// même quand la génération des canards prend un instant.
    private func reactToPurchase(strong: Bool = true) {
        punch = 1
        buyFlash = strong ? 0.32 : 0.16
        withAnimation(.spring(response: 0.42, dampingFraction: 0.45)) { punch = 0 }
        withAnimation(.easeOut(duration: strong ? 0.28 : 0.16)) { buyFlash = 0 }
    }

    // MARK: - Buy Logic
    private func handleBulkBuy(amount: Int) {
        guard !isGenerating else { return }
        if let _ = crate.costMoney, let cost = gameManager.calculateCrateCostMoney(crate: crate, amount: amount) {
            if gameManager.money >= cost {
                gameManager.money -= cost
                gameManager.evaluateAffordableCrates(reset: true)
                openCrate(amount: amount)
            }
        } else if let _ = crate.costMutationPoints, let cost = gameManager.calculateCrateCostMutation(crate: crate, amount: amount) {
            if gameManager.mutationPoints >= cost {
                gameManager.mutationPoints -= cost
                gameManager.evaluateAffordableCrates(reset: true)
                openCrate(amount: amount)
            }
        }
    }
    
    private func buyCrateWithMoney(amount: Int) {
        if holdDidTrigger {
            holdDidTrigger = false
            return
        }
        guard !isGenerating else { return }
        guard let cost = gameManager.calculateCrateCostMoney(crate: crate, amount: amount), gameManager.money >= cost else { return }
        gameManager.money -= cost
        
        if crate.type == .bois && amount == 1 {
            gameManager.storyFlags["firstWoodenCrateOpened"] = true
        }
        
        gameManager.evaluateAffordableCrates(reset: true)
        reactToPurchase()
        openCrate(amount: amount)
    }
    
    private func buyCrateWithMutationPoints(amount: Int) {
        if holdDidTrigger {
            holdDidTrigger = false
            return
        }
        guard !isGenerating else { return }
        guard let cost = gameManager.calculateCrateCostMutation(crate: crate, amount: amount), gameManager.mutationPoints >= cost else { return }
        gameManager.mutationPoints -= cost
        gameManager.evaluateAffordableCrates(reset: true)
        reactToPurchase()
        openCrate(amount: amount)
    }
    
    private func openCrate(amount: Int) {
        guard !isGenerating else { return }
        
        if amount <= 5 {
            var generatedDucks = [Duck]()
            generatedDucks.reserveCapacity(amount)
            let hasGenes = gameManager.isUnlocked(.genesCroissants)
            for _ in 0..<amount {
                let rarity = crate.probabilities.rollRarity()
                let size = DuckSize.rollRandom(genesCroissants: hasGenes)
                let mutation = DuckMutation.rollRandom()
                generatedDucks.append(Duck(rarity: rarity, size: size, mutation: mutation))
            }
            gameManager.setGamePaused(true)
            openingState = CrateOpeningState(crate: crate, ducks: generatedDucks)
            return
        }

        // Grand nombre : générer en arrière-plan
        isGenerating = true
        let probabilities = crate.probabilities
        let crateRef = crate
        let hasGenes = gameManager.isUnlocked(.genesCroissants)

        DispatchQueue.global(qos: .userInitiated).async {
            var generatedDucks = [Duck]()
            generatedDucks.reserveCapacity(amount)
            var rarityCounts: [DuckRarity: Int] = [:]

            for _ in 0..<amount {
                let rarity = probabilities.rollRarity()
                let size = DuckSize.rollRandom(genesCroissants: hasGenes)
                let mutation = DuckMutation.rollRandom()
                generatedDucks.append(Duck(rarity: rarity, size: size, mutation: mutation))
                rarityCounts[rarity, default: 0] += 1
            }
            
            let summary = rarityCounts
                .map { (rarity: $0.key, count: $0.value) }
                .sorted { $0.rarity.multiplier > $1.rarity.multiplier }
            
            DispatchQueue.main.async {
                isGenerating = false
                gameManager.setGamePaused(true)
                openingState = CrateOpeningState(crate: crateRef, ducks: generatedDucks, summary: summary, totalCount: amount)
            }
        }
    }
    
    // MARK: - Hold Logic
    private func startHold(amount: Int) {
        openedCount = 0
        holdDidTrigger = false
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            holdDidTrigger = true
            if silentBuyCrate(amount: amount) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { openedCount += 1 }
                NeonHaptics.tick()
                reactToPurchase(strong: false)
                triggerFlashAndShake()
            } else {
                stopHold()
            }
        }
    }
    
    private func stopHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.2)) { openedCount = 0 }
        withAnimation {
            gameManager.globalFlashOpacity = 0
            gameManager.globalShakeOffset = .zero
        }
    }
    
    private func triggerFlashAndShake() {
        let currentIntensity = min(0.6, 0.2 + Double(openedCount) * 0.02)
        let currentShake = min(15.0, CGFloat(openedCount))
        
        let randomX = CGFloat.random(in: -currentShake...currentShake)
        let randomY = CGFloat.random(in: -currentShake...currentShake)
        
        withAnimation(.easeOut(duration: 0.1)) {
            gameManager.globalFlashOpacity = currentIntensity
            gameManager.globalShakeOffset = CGSize(width: randomX, height: randomY)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.15)) {
                gameManager.globalFlashOpacity = 0
                gameManager.globalShakeOffset = .zero
            }
        }
    }
    
    private func silentBuyCrate(amount: Int) -> Bool {
        if let moneyCost = gameManager.calculateCrateCostMoney(crate: crate, amount: amount), gameManager.money >= moneyCost {
            gameManager.money -= moneyCost
        } else if let mutCost = gameManager.calculateCrateCostMutation(crate: crate, amount: amount), gameManager.mutationPoints >= mutCost {
            gameManager.mutationPoints -= mutCost
        } else {
            return false
        }
        
        var generatedDucks = [Duck]()
        generatedDucks.reserveCapacity(amount)
        let hasGenes = gameManager.isUnlocked(.genesCroissants)
        for _ in 0..<amount {
            let rarity = crate.probabilities.rollRarity()
            let size = DuckSize.rollRandom(genesCroissants: hasGenes)
            let mutation = DuckMutation.rollRandom()
            generatedDucks.append(Duck(rarity: rarity, size: size, mutation: mutation))
        }

        gameManager.processNewDucks(generatedDucks)
        gameManager.evaluateAffordableCrates(reset: true)
        return true
    }
}

// MARK: - Probability Popup
struct ProbabilityPopup: View {
    let crate: Crate
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(tr("Probabilités -")) \(tr(crate.type.displayName))")
                    .font(.headline.bold())
                Spacer()
                Button(action: { withAnimation { isPresented = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Rareté
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tr("Rareté"))
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(allProbabilities, id: \.rarity) { item in
                                if item.percentage > 0 {
                                    HStack {
                                        Circle()
                                            .fill(item.rarity.color)
                                            .frame(width: 10, height: 10)
                                        Text(tr(item.rarity.rawValue))
                                            .bold()
                                            .foregroundColor(item.rarity.color)
                                        Text("(x\(String(format: "%g", item.rarity.multiplier)))")
                                            .foregroundColor(item.rarity.color.opacity(0.8))
                                            .font(.caption.bold())
                                        Spacer()
                                        Text("\(String(format: "%g", item.percentage))%")
                                            .foregroundColor(.gray)
                                            .font(.subheadline.monospacedDigit())
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    Divider().padding(.leading)
                                }
                            }
                        }
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Taille
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tr("Taille"))
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(DuckSize.allCases.enumerated()), id: \.element) { index, size in
                                probRow(name: size.rawValue, percentage: size.baseProbability, color: .primary, multiplier: size.multiplier, isLast: index == DuckSize.allCases.count - 1)
                            }
                        }
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Mutation
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tr("Mutation"))
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(DuckMutation.allCases.enumerated()), id: \.element) { index, mutation in
                                probRow(name: mutation.rawValue, percentage: mutation.baseProbability, color: mutation.color, multiplier: mutation.multiplier, isLast: index == DuckMutation.allCases.count - 1)
                            }
                        }
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(maxWidth: 340, maxHeight: 500)
        .background(Color(hex: 0x0E0E1A))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(crate.type.accentColor.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: crate.type.accentColor.opacity(0.35), radius: 20)
    }
    
    private func probRow(name: String, percentage: Double, color: Color, multiplier: Double? = nil, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(tr(name))
                    .foregroundColor(color)
                    .bold(color != .primary)
                if let m = multiplier {
                    Text("(x\(String(format: "%g", m)))")
                        .foregroundColor(color.opacity(0.8))
                        .font(.caption.bold())
                }
                Spacer()
                Text("\(String(format: "%g", percentage))%")
                    .foregroundColor(.gray)
                    .font(.subheadline.monospacedDigit())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if !isLast {
                Divider().padding(.leading)
            }
        }
    }
    
    private var allProbabilities: [(rarity: DuckRarity, percentage: Double)] {
        DuckRarity.allCases.compactMap { rarity in
            if let chance = crate.probabilities.chances[rarity], chance > 0 {
                return (rarity, chance)
            }
            return nil
        }
    }
}

// MARK: - Bulk Crate Opening Sheet
struct BulkCrateOpeningSheet: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    let crate: Crate
    let onBuy: (Int) -> Void
    
    @State private var selectedAmount: Int = 100
    
    var maxAmount: Int {
        return max(1, gameManager.maxAffordableCrates(crate: crate))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    CryoCapsuleIcon(type: crate.type, glow: true, size: 76)
                    Text(tr("Ouverture Multiple"))
                        .font(.title2.bold())
                    Text(tr(crate.type.displayName))
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 30)
                
                // Selection Info
                VStack(spacing: 5) {
                    Text(tr("Quantité sélectionnée"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    let actualSelected = selectedAmount == 0 ? maxAmount : selectedAmount
                    Text("x \(actualSelected.formattedString())")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Options
                let options = [100, 1000, 5000]
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(options, id: \.self) { val in
                            Button(action: {
                                selectedAmount = val
                            }) {
                            let label = val.formattedString()
                            let isSelected = selectedAmount == val
                            Text(tr(label))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(isSelected ? AnyShapeStyle(Color.blue) : AnyShapeStyle(.ultraThinMaterial))
                                    .foregroundColor(selectedAmount == val ? .white : .primary)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedAmount == val ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(val > maxAmount)
                            .opacity(val > maxAmount ? 0.4 : 1.0)
                        }
                    }
                    
                    Button(action: {
                        selectedAmount = 0 // 0 means MAX
                    }) {
                        Text(tr("MAXIMUM"))
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedAmount == 0 ? AnyShapeStyle(Color.orange) : AnyShapeStyle(.ultraThinMaterial))
                            .foregroundColor(selectedAmount == 0 ? .white : .orange)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedAmount == 0 ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(maxAmount == 0)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Button
                let actualSelected = selectedAmount == 0 ? maxAmount : selectedAmount
                let canBuy = actualSelected > 0 && actualSelected <= maxAmount
                Button(action: {
                    if canBuy {
                        onBuy(actualSelected)
                        dismiss()
                    }
                }) {
                    Text(tr("CONFIRMER L'ACHAT"))
                }
                .neonButton(Neon.green)
                .opacity(canBuy ? 1.0 : 0.45)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .disabled(!canBuy)
            }
            .background(NeonBackground())
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("Fermer")) {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }
}

/// Le bouton le plus tapé du jeu : il doit s'enfoncer, claquer et se lire d'un coup d'œil.
struct CratePurchaseButton: View {
    let amountLabel: String
    let costStr: String
    let icon: String
    let isUnlocked: Bool
    let canAfford: Bool
    let textColor: Color
    let isHoldUnlocked: Bool
    let action: () -> Void
    let startHold: () -> Void
    let stopHold: () -> Void

    @State private var isPressing = false

    private var isActive: Bool { isUnlocked && canAfford }

    private let shape = RoundedRectangle(cornerRadius: 11, style: .continuous)

    var body: some View {
        Button(action: {
            if isUnlocked { action() }
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 3) {
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .black))
                    }
                    Text(amountLabel.replacingOccurrences(of: "x", with: "×"))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }

                if isUnlocked {
                    HStack(spacing: 2) {
                        Text(icon)
                            .font(.system(size: 8))
                        Text(costStr)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .opacity(isActive ? 0.62 : 0.75)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .padding(.horizontal, 4)
            .background {
                if isActive {
                    // Pastille "physique" : bombée, avec une arête claire en haut.
                    shape.fill(
                        LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xD8D8E4)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                } else {
                    shape.fill(Color.black.opacity(0.34))
                }
            }
            .foregroundStyle(isActive ? Color(hex: 0x14121C) : textColor.opacity(0.45))
            .overlay {
                shape.stroke(
                    isActive ? Color.white.opacity(0.95) : Color.white.opacity(0.10),
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            // Ombre portée sombre : la pastille se détache aussi bien sur les capsules
            // claires (Plasma, Diamant) que sur les sombres.
            .shadow(color: .black.opacity(isActive ? 0.45 : 0), radius: 4, y: 2)
            .scaleEffect(isPressing ? 0.9 : 1.0)
            .animation(.interactiveSpring(response: 0.16, dampingFraction: 0.55), value: isPressing)
        }
        .disabled(!isUnlocked || !canAfford)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        NeonHaptics.impact()
                        if isHoldUnlocked { startHold() }
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    stopHold()
                }
        )
    }
}
