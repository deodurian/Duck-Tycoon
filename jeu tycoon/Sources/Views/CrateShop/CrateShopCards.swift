import SwiftUI
import Foundation

// MARK: - Premium Crate Card
struct PremiumCrateCard: View {
    @Environment(GameManager.self) private var gameManager
    let crate: Crate
    @Binding var openingState: CrateOpeningState?
    @Binding var infoCrate: Crate?
    
    @State private var showingBulkSheet = false
    @State private var holdTimer: Timer?
    @State private var openedCount: Int = 0
    @State private var isGenerating = false
    @State private var holdDidTrigger = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var glowPulse = false
    

    
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
                    // Crate icon
                    ZStack {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(LinearGradient(colors: crate.type.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: crate.type.accentColor.opacity(0.5), radius: 8)
                        
                        // Sparkle on premium crates
                        if crate.type == .diamant || crate.type == .rubis {
                            Image(systemName: "sparkle")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .offset(x: 18, y: -18)
                        }
                    }
                    
                    Text(tr(crate.type.shortName))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(crate.type.textColor)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 4)
            
            // Info button
            HStack {
                Spacer()
                Button(action: { withAnimation { infoCrate = crate } }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(crate.type.textColor.opacity(0.6))
                }
                .padding(.trailing, 8)
            }
            .padding(.top, -20)
            
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
            
            if gameManager.isUnlocked(.holdToOpen) {
                Text(tr("Maintenir = boucle"))
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(crate.type.textColor.opacity(0.5))
                    .padding(.bottom, 6)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
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
        .onAppear {
            // Periodic shimmer
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false).delay(Double.random(in: 0...2))) {
                shimmerOffset = 1.5
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = true
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
        
        return Button(action: {
            if gameManager.isUnlocked(.multipleOpenMax) {
                showingBulkSheet = true
            }
        }) {
            HStack(spacing: 4) {
                if !gameManager.isUnlocked(.multipleOpenMax) {
                    Image(systemName: "lock.fill").font(.system(size: 9))
                }
                Text(tr("Multiple"))
                    .font(.system(size: 11, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(canBuyMax && gameManager.isUnlocked(.multipleOpenMax) ? Color.white.opacity(0.7) : Color.black.opacity(0.2))
            .foregroundColor(canBuyMax && gameManager.isUnlocked(.multipleOpenMax) ? .black : crate.type.textColor.opacity(0.4))
            .cornerRadius(8)
        }
        .disabled(!gameManager.isUnlocked(.multipleOpenMax))
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
        gameManager.evaluateAffordableCrates(reset: true)
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
                openedCount += 1
                triggerFlashAndShake()
            } else {
                stopHold()
            }
        }
    }
    
    private func stopHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        openedCount = 0
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
                Text("\(tr("Probabilités -")) \(tr(crate.type.rawValue))")
                    .font(.headline.bold())
                Spacer()
                Button(action: { withAnimation { isPresented = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            
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
                        .background(Color(.tertiarySystemGroupedBackground))
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
                        .background(Color(.tertiarySystemGroupedBackground))
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
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(maxWidth: 340, maxHeight: 500)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
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
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 10)
                    Text(tr("Ouverture Multiple"))
                        .font(.title2.bold())
                    Text(tr(crate.type.rawValue))
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
                Button(action: {
                    if actualSelected > 0 && actualSelected <= maxAmount {
                        onBuy(actualSelected)
                        dismiss()
                    }
                }) {
                    Text(tr("CONFIRMER L'ACHAT"))
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(actualSelected > 0 && actualSelected <= maxAmount ? Color.green : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: actualSelected > 0 && actualSelected <= maxAmount ? Color.green.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .disabled(actualSelected == 0 || actualSelected > maxAmount)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
            )
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

    var body: some View {
        Button(action: {
            if isUnlocked { action() }
        }) {
            HStack(spacing: 3) {
                if !isUnlocked {
                    Image(systemName: "lock.fill").font(.system(size: 9))
                }
                Text(amountLabel)
                    .font(.system(size: 11, weight: .black))
                if isUnlocked {
                    Text(costStr)
                        .font(.system(size: 10, weight: .semibold))
                    Text(icon)
                        .font(.system(size: 10))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(isUnlocked && canAfford ? Color.white.opacity(0.95) : Color.black.opacity(0.3))
            .foregroundColor(isUnlocked && canAfford ? .black : textColor.opacity(0.5))
            .cornerRadius(8)
        }
        .disabled(!isUnlocked || !canAfford)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in 
                    if !isPressing && isHoldUnlocked {
                        isPressing = true
                        startHold() 
                    }
                }
                .onEnded { _ in 
                    isPressing = false
                    stopHold() 
                }
        )
    }
}
