import SwiftUI

struct DuckDetailView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPerkSelection = false
    
    let duck: Duck
    
    var currentDuck: Duck {
        gameManager.inventory.first(where: { $0.id == duck.id }) ?? duck
    }
    
    func sizeUpgradeImpact() -> BigNumber? {
        guard let nextSize = currentDuck.size.next else { return nil }
        var mockDuck = currentDuck
        mockDuck.size = nextSize
        let currentDuckValue = gameManager.displaySellValue(for: currentDuck)
        let mockDuckValue = gameManager.displaySellValue(for: mockDuck)
        return mockDuckValue - currentDuckValue
    }
    
    func mutationUpgradeImpact() -> BigNumber? {
        guard let nextMut = currentDuck.mutation.next else { return nil }
        var mockDuck = currentDuck
        mockDuck.mutation = nextMut
        let currentDuckValue = gameManager.displaySellValue(for: currentDuck)
        let mockDuckValue = gameManager.displaySellValue(for: mockDuck)
        return mockDuckValue - currentDuckValue
    }
    
    func levelUpgradeImpact() -> BigNumber? {
        guard currentDuck.level < 100 else { return nil }
        var mockDuck = currentDuck
        mockDuck.level += 1
        let currentDuckValue = gameManager.displaySellValue(for: currentDuck)
        let mockDuckValue = gameManager.displaySellValue(for: mockDuck)
        return mockDuckValue - currentDuckValue
    }
    
    @State private var showingRecycleAlert = false
    
    var body: some View {
        let duckPerks = currentDuck.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
        let dynamicStats = currentDuck.getDynamicStats(with: duckPerks)
        
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
            Image(currentDuck.rarity.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding()
                .background(Circle().fill(currentDuck.rarity.color.opacity(0.3)))
            
            Text("\(tr("Canard "))\(currentDuck.rarity.localizedName)")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .foregroundColor(currentDuck.rarity.color)
            
            if currentDuck.fusionLevel > 0 {
                Text("\(tr("Niveau de Fusion "))\(currentDuck.fusionLevel)/4")
                    .font(.headline)
                    .foregroundColor(currentDuck.fusionLevel == 4 ? .purple : .yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            
            Text("\(tr("Lv.")) \(dynamicStats.level)")
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            
            Text("\(tr("Génère : "))\(gameManager.displaySellValue(for: currentDuck).formattedString()) 💰\(tr(" / sec"))")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            HStack {
                Text("\(tr("Taille:")) \(tr(dynamicStats.size.rawValue))")
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                
                Text("\(tr("Mutation:")) \(tr(dynamicStats.mutation.rawValue))")
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }
            .font(.caption)
            
            // Emplacement de Perk
            VStack(spacing: 5) {
                Text(tr("Perk Équipé"))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button(action: {
                    showingPerkSelection = true
                }) {
                    if let perkId = currentDuck.equippedPerkIds.first, let perk = gameManager.perksInventory.first(where: { $0.id == perkId }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(perk.rarity.color)
                            Text(tr(perk.name))
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(8)
                        .background(perk.rarity.color.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Text(tr("Aucun Perk équipé (Toucher pour choisir)"))
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 5)
            
            Divider()
            
            Text(tr("Améliorations (Coûte des 🧬)"))
                .font(.title2)
                .foregroundColor(.gray)
            
            HStack(spacing: 20) {
                // Bouton Taille
                DuckUpgradeButton(
                    title: tr("Améliorer Taille"),
                    cost: currentDuck.sizeUpgradeCost,
                    icon: "🧬",
                    color: .blue,
                    impact: sizeUpgradeImpact(),
                    canAfford: currentDuck.sizeUpgradeCost != nil && gameManager.mutationPoints >= (currentDuck.sizeUpgradeCost ?? BigNumber(1e100)),
                    maxLabel: tr("Niveau MAX"),
                    action: { gameManager.upgradeDuckSize(id: currentDuck.id) }
                )
                
                // Bouton Mutation
                DuckUpgradeButton(
                    title: tr("Muter"),
                    cost: currentDuck.mutationUpgradeCost,
                    icon: "🧬",
                    color: .purple,
                    impact: mutationUpgradeImpact(),
                    canAfford: currentDuck.mutationUpgradeCost != nil && gameManager.mutationPoints >= (currentDuck.mutationUpgradeCost ?? BigNumber(1e100)),
                    maxLabel: tr("Niveau MAX"),
                    action: { gameManager.upgradeDuckMutation(id: currentDuck.id) }
                )
            }
            
            Divider()
            
            Text(tr("Niveau (Coûte des 💰)"))
                .font(.title2)
                .foregroundColor(.gray)
            
            DuckUpgradeButton(
                title: tr("Augmenter Niveau"),
                cost: currentDuck.levelUpgradeCost,
                icon: "💰",
                color: .yellow,
                impact: levelUpgradeImpact(),
                canAfford: currentDuck.levelUpgradeCost != nil && gameManager.money >= (currentDuck.levelUpgradeCost ?? BigNumber(Double.greatestFiniteMagnitude)),
                maxLabel: tr("Niveau MAX (100)"),
                action: { gameManager.upgradeDuckLevel(id: currentDuck.id) }
            )
            
            Spacer()
            
            let isAssigned = gameManager.isDuckAssigned(duckId: currentDuck.id)
            
            Button(action: {
                showingRecycleAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("\(tr("Recycler (+ "))\(gameManager.displayRecycleValue(for: currentDuck).formattedString()) 🧬)")
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isAssigned ? Color.gray : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if isAssigned {
                Text(tr("Ce canard sera retiré de l'usine si vous le recyclez."))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            }
            .padding()
            }
        }
        .alert(tr("Confirmer le recyclage"), isPresented: $showingRecycleAlert) {
            Button(tr("Annuler"), role: .cancel) { }
            Button(tr("Oui, Recycler"), role: .destructive) {
                gameManager.recycleDucks(ids: [currentDuck.id])
                dismiss()
            }
        } message: {
            Text("\(tr("Voulez-vous vraiment recycler ce canard de rareté "))\(currentDuck.rarity.localizedName)\(tr(" ? Cette action est définitive."))")
        }
        .sheet(isPresented: $showingPerkSelection) {
            PerkSelectionSheet(targetId: currentDuck.id, targetType: .duck)
                .environment(gameManager)
        }
    }
    
}

struct BulkRecycleSheet: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRarity: DuckRarity = .commun
    @State private var selectedLevel: Int = 0
    @State private var showInfo = false
    
    var matchingDucks: Int {
        gameManager.countBulkRecycle(rarity: selectedRarity, level: selectedLevel)
    }
    
    var potentialYield: BigNumber {
        gameManager.potentialBulkRecycleYield(rarity: selectedRarity, level: selectedLevel)
    }
    

    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                    HStack {
                        Text(tr("Recyclage"))
                            .font(.largeTitle.bold())
                        Button(action: { showInfo = true }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top)
                    
                    VStack(spacing: 24) {
                        // Selection section
                        VStack(alignment: .leading, spacing: 15) {
                            Text(tr("Filtres"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                    ForEach(DuckRarity.allCases, id: \.self) { rarity in
                                        RaritySelectionButton(rarity: rarity, selectedRarity: $selectedRarity)
                                    }
                                }
                                Picker(tr("Niveau"), selection: $selectedLevel) {
                                    ForEach(0...4, id: \.self) { level in
                                        Text("\(tr("Niveau "))\(level)").tag(level)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // Result section
                        VStack(spacing: 15) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(tr("Canards ciblés"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("\(matchingDucks)")
                                        .font(.title2.bold())
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text(tr("Gain Total"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("+\(potentialYield.formattedString()) 🧬")
                                        .font(.title2.bold())
                                        .foregroundColor(.green)
                                }
                            }
                            
                            if matchingDucks > 0 {
                                Button(action: {
                                    gameManager.recycleBulkDucks(rarity: selectedRarity, level: selectedLevel)
                                    dismiss()
                                }) {
                                    Text(tr("RECYCLER EN LOT"))
                                        .font(.headline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(selectedRarity.color)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .shadow(color: selectedRarity.color.opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Annihilation section -> Recycler la rareté
                        if gameManager.isUnlocked(.annihilation) {
                            let totalMatching = gameManager.countUnassigned(rarity: selectedRarity)
                            let totalYield = gameManager.potentialRecycleYield(rarity: selectedRarity) * gameManager.mutationMultiplier
                            
                            VStack(alignment: .leading, spacing: 15) {
                                Text(tr("Recycler la rareté"))
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                HStack {
                                    Text("\(totalMatching)\(tr(" ciblés"))")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("+\(totalYield.formattedString()) 🧬")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.green)
                                }
                                
                                if totalMatching > 0 {
                                    Button(action: {
                                        gameManager.recycleAllUnassigned(rarity: selectedRarity)
                                        dismiss()
                                    }) {
                                        Text(tr("RECYCLER LA RARETÉ"))
                                            .font(.headline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
            .alert(tr("Comment ça marche ?"), isPresented: $showInfo) {
                Button(tr("OK"), role: .cancel) { }
            } message: {
                Text(tr("Recyclage en Lot : S'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s'applique au niveau choisi et à ses niveaux inférieurs.\n\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau."))
            }
        }
    }
}
}

struct InventorySummaryView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRarity: DuckRarity? = nil
    
    @State private var cachedRarityCounts: [(DuckRarity, Int)] = []
    
    var maxCount: Int {
        cachedRarityCounts.map { $0.1 }.max() ?? 1
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Total
                VStack(spacing: 4) {
                    Text("\(gameManager.inventory.count)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                    Text(tr("canards au total"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Bulle de détail si sélectionné
                if let selected = selectedRarity {
                    let count = cachedRarityCounts.first(where: { $0.0 == selected })?.1 ?? 0
                    HStack(spacing: 12) {
                        Circle()
                            .fill(selected.color)
                            .frame(width: 14, height: 14)
                        Text(tr(selected.rawValue))
                            .font(.headline)
                            .foregroundColor(selected.color)
                        Spacer()
                        Text("\(count) \(tr(count > 1 ? "canards" : "canard"))")
                            .font(.headline)
                            .bold()
                        
                        let percent = gameManager.inventory.count > 0 ? Double(count) / Double(gameManager.inventory.count) * 100 : 0
                        Text(String(format: "(%.1f%%)", percent))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(selected.color.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text(tr("Appuie sur une barre pour voir les détails"))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                        .transition(.opacity)
                }
                
                // Graphe à barres
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(cachedRarityCounts, id: \.0) { rarity, count in
                            let barHeight = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) * (geo.size.height - 40) : 0
                            let isSelected = selectedRarity == rarity
                            
                            VStack(spacing: 4) {
                                // Valeur au dessus de la barre
                                Text(count > 0 ? "\(count)" : "")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isSelected ? rarity.color : .gray)
                                    .opacity(count > 0 ? 1 : 0)
                                
                                // Barre
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [rarity.color.opacity(0.6), rarity.color],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(height: max(barHeight, count > 0 ? 4 : 2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? rarity.color : Color.clear, lineWidth: 2)
                                    )
                                    .scaleEffect(isSelected ? 1.05 : 1.0, anchor: .bottom)
                                    .animation(.spring(response: 0.3), value: isSelected)
                                
                                // Label rareté
                                Text(tr(rarity.shortName))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(isSelected ? rarity.color : .gray)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedRarity == rarity {
                                        selectedRarity = nil
                                    } else {
                                        selectedRarity = rarity
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                Divider()
                
                // Note
                Text(tr("💡 L'inventaire affiche les 100 meilleurs canards. L'Auto-Fusion et le Recyclage accèdent à toute la collection."))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .navigationTitle(tr("Statistiques"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("Fermer")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                var counts: [DuckRarity: Int] = [:]
                for duck in gameManager.inventory {
                    counts[duck.rarity, default: 0] += 1
                }
                let result = DuckRarity.allCases.map { ($0, counts[$0] ?? 0) }
                DispatchQueue.main.async {
                    self.cachedRarityCounts = result
                }
            }
        }
    }

    
}

struct RaritySelectionButton: View {
    let rarity: DuckRarity
    @Binding var selectedRarity: DuckRarity
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedRarity = rarity
            }
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(rarity.color.opacity(selectedRarity == rarity ? 1.0 : 0.2))
                        .frame(width: 24, height: 24)
                    
                    Image(rarity.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .opacity(selectedRarity == rarity ? 1.0 : 0.7)
                }
                
                Text(tr(rarity.rawValue))
                    .font(.subheadline)
                    .fontWeight(selectedRarity == rarity ? .bold : .medium)
                    .foregroundColor(selectedRarity == rarity ? rarity.color : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedRarity == rarity ? rarity.color.opacity(0.1) : Color(UIColor.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedRarity == rarity ? rarity.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DuckUpgradeButton: View {
    let title: String
    let cost: BigNumber?
    let icon: String
    let color: Color
    let impact: BigNumber?
    let canAfford: Bool
    let maxLabel: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(tr(title))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let cost = cost, let impact = impact {
                    Text("\(tr("Coût : "))\(cost.formattedString()) \(icon)")
                        .font(.subheadline)
                        .foregroundColor(color)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("+\(impact.formattedString()) 💰/s")
                        .font(.caption)
                        .foregroundColor(.green)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text(tr(maxLabel))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(cost != nil && canAfford ? color : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(cost == nil || !canAfford)
    }
}
