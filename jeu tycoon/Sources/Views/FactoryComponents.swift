import SwiftUI

struct FactoryRow: View {
    @Environment(GameManager.self) private var gameManager
    let factory: DuckFactory
    
    @State private var showingDuckSelection = false
    @State private var showingPerkSelection = false
    @State private var glowPulse = false
    
    private var assignedDucks: [Duck] {
        return factory.assignedDuckIds.compactMap { gameManager.getAssignedDuck(id: $0) }
    }
    
    private var isMaxLevel: Bool {
        return factory.level >= 100
    }
    
    // Couleur de l'évolution
    private var evolutionColor: Color {
        switch factory.evolution {
        case 0: return .cyan
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        case 5: return .pink
        case 6: return .red
        default: return .yellow
        }
    }
    
    // Icône de l'évolution
    private var evolutionIcon: String {
        switch factory.evolution {
        case 0: return "gearshape.fill"
        case 1: return "bolt.fill"
        case 2: return "flame.fill"
        case 3: return "sparkles"
        case 4: return "star.fill"
        case 5: return "crown.fill"
        case 6: return "diamond.fill"
        case 7: return "wand.and.stars"
        default: return "gearshape.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // === Header bar ===
            HStack(spacing: 10) {
                // Factory icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [evolutionColor.opacity(glowPulse ? 0.35 : 0.15), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: evolutionIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [evolutionColor, evolutionColor.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: evolutionColor.opacity(0.5), radius: 4)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(factory.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        // Level pill
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 8))
                            Text("Nv. \(factory.level)")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(isMaxLevel ? .yellow : .white.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isMaxLevel ? Color.yellow.opacity(0.15) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        
                        // Evolution pill
                        if factory.evolution > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 7))
                                Text("Évo. \(factory.evolution)")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(evolutionColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(evolutionColor.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        // Perk pills (up to 2)
                        Button(action: {
                            showingPerkSelection = true
                        }) {
                            HStack(spacing: 4) {
                                let perks = factory.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
                                if perks.isEmpty {
                                    HStack(spacing: 3) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 7))
                                        Text("Perk")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.12))
                                    .clipShape(Capsule())
                                } else {
                                    ForEach(perks) { perk in
                                        HStack(spacing: 3) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 7))
                                            Text(perk.name)
                                                .font(.system(size: 10, weight: .semibold))
                                        }
                                        .foregroundColor(perk.rarity.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(perk.rarity.color.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                // Duck slots
                HStack(spacing: 8) {
                    let factoryPerks = factory.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
                    let hasExtraSlot = factoryPerks.contains(where: { $0.factoryExtraDuckSlot })
                    let maxDucks = max(assignedDucks.count, hasExtraSlot ? 2 : 1)
                    
                    ForEach(0..<maxDucks, id: \.self) { index in
                        Button(action: { showingDuckSelection = true }) {
                            if index < assignedDucks.count {
                                DuckGridCard(
                                    duck: assignedDucks[index],
                                    displayValue: gameManager.displaySellValue(for: assignedDucks[index]).formattedString(),
                                    isAssigned: false
                                )
                            } else {
                                VStack(spacing: 3) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Canard")
                                        .font(.system(size: 7, weight: .medium))
                                }
                                .frame(width: 52, height: 52)
                                .foregroundColor(.gray.opacity(0.6))
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            
            // === Separator ===
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, evolutionColor.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            // === Stats row ===
            HStack {
                // Earnings
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("💰")
                            .font(.system(size: 11))
                        let factoryPerks = factory.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
                        let displayValues = assignedDucks.map { gameManager.displaySellValue(for: $0) }
                        Text("+\(factory.calculateEarningsPerSecond(assignedDucks: assignedDucks, duckDisplayValues: displayValues, factoryPerks: factoryPerks).formattedString())/s")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    
                    if factory.evolution > 0 {
                        HStack(spacing: 4) {
                            Text("🧬")
                                .font(.system(size: 11))
                            Text("+\(factory.calculateMutationsPerSecond(assignedDucks: assignedDucks, globalBonus: gameManager.mutationMultiplier).formattedString())/s")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.purple)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                }
                
                Spacer()
                
                // Level progress
                if !isMaxLevel {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(factory.level)/100")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.08))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [evolutionColor, evolutionColor.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(factory.level) / 100.0)
                            }
                        }
                        .frame(width: 70, height: 4)
                    }
                } else {
                    Text("MAX")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.yellow.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            // === Separator ===
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 14)
            
            // === Action buttons row ===
            HStack(spacing: 8) {
                if isMaxLevel {
                    if factory.evolution < 7 {
                        let factoryPerks = factory.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
                        let cost = factory.evolveCost(factoryPerks: factoryPerks, baseDiscount: gameManager.factoryCostDiscount)
                        let canEvolve = gameManager.money >= cost
                        Button(action: { gameManager.evolveFactory(factoryId: factory.id) }) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                VStack(spacing: 1) {
                                    Text("Évoluer")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                    Text(cost.formattedString())
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .opacity(0.7)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                canEvolve
                                ? AnyShapeStyle(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color.white.opacity(0.06))
                            )
                            .foregroundColor(canEvolve ? .white : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(canEvolve ? Color.purple.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                            .shadow(color: canEvolve ? .purple.opacity(0.3) : .clear, radius: 6, y: 2)
                        }
                        .disabled(!canEvolve)
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                            Text("MAXIMUM")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(
                            AngularGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]), center: .center)
                        )
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                } else {
                    upgradeButton(label: "+1", levels: 1)
                    
                    let amount10 = min(10, 100 - factory.level)
                    upgradeButton(label: "+\(amount10)", levels: amount10)
                    
                    let factoryPerks = factory.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
                    let maxUpgrades = factory.maxUpgrades(with: gameManager.money, factoryPerks: factoryPerks, baseDiscount: gameManager.factoryCostDiscount)
                    let maxAmount = max(1, min(maxUpgrades, 100 - factory.level))
                    upgradeButton(label: "Max", levels: maxAmount, isMax: true, maxUpgrades: maxUpgrades)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                
                // Inner highlight
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.12), .white.opacity(0.02), evolutionColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .overlay(
            // Evolution border for evo > 0
            factory.evolution > 0
            ? AnyView(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        factory.evolution == 7
                        ? AnyShapeStyle(AngularGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]), center: .center))
                        : AnyShapeStyle(evolutionColor.opacity(0.4)),
                        lineWidth: factory.evolution == 7 ? 2.5 : 1.5
                    )
                    .shadow(color: evolutionColor.opacity(0.3), radius: 6)
            )
            : AnyView(EmptyView())
        )
        .shadow(color: evolutionColor.opacity(factory.evolution > 0 ? 0.15 : 0.05), radius: 10, y: 4)
        .sheet(isPresented: $showingDuckSelection) {
            DuckSelectionSheet(factoryId: factory.id)
                .environment(gameManager)
        }
        .sheet(isPresented: $showingPerkSelection) {
            PerkSelectionSheet(targetId: factory.id, targetType: .factory)
                .environment(gameManager)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    @ViewBuilder
    private func upgradeButton(label: String, levels: Int, isMax: Bool = false, maxUpgrades: Int = 1) -> some View {
        let factoryPerks = factory.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
        let cost = factory.upgradeCost(levels: levels, factoryPerks: factoryPerks, baseDiscount: gameManager.factoryCostDiscount)
        let canAfford = isMax ? (maxUpgrades > 0 && gameManager.money >= cost) : (gameManager.money >= cost && levels > 0)
        
        Button(action: {
            gameManager.upgradeFactoryLevel(factoryId: factory.id, levels: levels)
        }) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text(cost.formattedString())
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .opacity(0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                canAfford
                ? AnyShapeStyle(LinearGradient(colors: [Color(hue: 0.55, saturation: 0.7, brightness: 0.8), Color(hue: 0.58, saturation: 0.6, brightness: 0.6)], startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(Color.white.opacity(0.06))
            )
            .foregroundColor(canAfford ? .white : .gray)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(canAfford ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(!canAfford)
        .buttonStyle(PlainButtonStyle())
    }
}


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
            ScrollView {
                if isLoading {
                    ProgressView("Chargement...")
                        .padding(.top, 50)
                } else if displayInventory.isEmpty {
                    Text("Aucun canard disponible.")
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(displayInventory) { duck in
                            DuckGridCard(
                                duck: duck,
                                displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                isAssigned: gameManager.isDuckAssigned(duckId: duck.id)
                            )
                        .onTapGesture {
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
            .navigationTitle("Choisir un canard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Menu {
                            Picker("Trier par", selection: $sortOption) {
                                ForEach(InventorySortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        
                        Button("Fermer") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retirer") {
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
}
