import SwiftUI

struct DuckDetailView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPerkSelection = false
    
    let duck: Duck
    
    var currentDuck: Duck {
        gameManager.inventory.first(where: { $0.id == duck.id }) ?? duck
    }

    // Ces trois fonctions accédaient chacune 2 à 3 fois à `currentDuck` (donc autant de scans
    // linéaires de l'inventaire) et recalculaient à chaque fois la valeur de vente de référence.
    // Elles reçoivent maintenant le canard déjà résolu et sa valeur de vente déjà calculée :
    // le résultat est arithmétiquement identique, seul le travail redondant disparaît.
    func sizeUpgradeImpact(for resolvedDuck: Duck, baseValue: BigNumber) -> BigNumber? {
        guard let nextSize = resolvedDuck.size.next else { return nil }
        var mockDuck = resolvedDuck
        mockDuck.size = nextSize
        let mockDuckValue = gameManager.displaySellValue(for: mockDuck)
        return mockDuckValue - baseValue
    }

    func mutationUpgradeImpact(for resolvedDuck: Duck, baseValue: BigNumber) -> BigNumber? {
        guard let nextMut = resolvedDuck.mutation.next else { return nil }
        var mockDuck = resolvedDuck
        mockDuck.mutation = nextMut
        let mockDuckValue = gameManager.displaySellValue(for: mockDuck)
        return mockDuckValue - baseValue
    }

    func levelUpgradeImpact(for resolvedDuck: Duck, baseValue: BigNumber) -> BigNumber? {
        guard resolvedDuck.level < 100 else { return nil }
        var mockDuck = resolvedDuck
        mockDuck.level += 1
        let mockDuckValue = gameManager.displaySellValue(for: mockDuck)
        return mockDuckValue - baseValue
    }
    
    @State private var showingRecycleAlert = false
    
    var body: some View {
        // `currentDuck` est une propriété calculée qui balaye linéairement l'inventaire
        // (jusqu'à 10 000 canards) à CHAQUE accès, et le corps y accédait une trentaine de fois.
        // On la résout une seule fois : c'est rigoureusement la même valeur, rendu identique.
        let liveDuck = currentDuck
        // Résolution des perks par l'index O(1) déjà présent dans GameManager au lieu d'un scan
        // linéaire de perksInventory par perk équipé (mêmes perks, même ordre, ids inconnus ignorés).
        let duckPerks = gameManager.perks(for: liveDuck.equippedPerkIds)
        let dynamicStats = liveDuck.getDynamicStats(with: duckPerks)
        let rarityColor = liveDuck.rarity.color
        let isAssigned = gameManager.isDuckAssigned(duckId: liveDuck.id)
        // Valeur de vente et valeur de recyclage : calculs BigNumber lourds qui étaient refaits
        // respectivement 4 fois et 2 fois par reconstruction du corps. Mêmes chiffres affichés.
        let sellValue = gameManager.displaySellValue(for: liveDuck)
        let recycleValue = gameManager.displayRecycleValue(for: liveDuck)

        ZStack {
            NeonBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // --- HÉROS : image dans un halo de rareté ---
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [rarityColor.opacity(0.45), .clear], center: .center, startRadius: 20, endRadius: 95))
                            .frame(width: 190, height: 190)
                        Circle()
                            .stroke(
                                LinearGradient(colors: [rarityColor, rarityColor.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 3
                            )
                            .frame(width: 140, height: 140)
                        Image(liveDuck.rarity.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 105, height: 105)
                    }
                    .padding(.top, 4)

                    Text("\(tr("Canard "))\(liveDuck.rarity.localizedName)")
                        .font(.system(.title, design: .rounded).weight(.black))
                        .foregroundColor(rarityColor)

                    // --- BADGES : niveau, fusion, rituels, assignation ---
                    HStack(spacing: 8) {
                        DuckBadge(text: "\(tr("Lv.")) \(dynamicStats.level)", color: .white)

                        if liveDuck.fusionLevel > 0 {
                            DuckBadge(text: "\(tr("Niveau de Fusion "))\(liveDuck.fusionLevel)/4", color: liveDuck.fusionLevel == 4 ? .purple : .yellow)
                        }

                        if liveDuck.totalRituals > 0 {
                            DuckBadge(text: "🔥 \(liveDuck.totalRituals)", color: .pink)
                        }

                        if isAssigned {
                            DuckBadge(text: "🏭 " + tr("Assigné à une usine"), color: .blue)
                        }
                    }

                    // --- TUILES : revenus + recyclage ---
                    HStack(spacing: 12) {
                        DuckStatTile(
                            icon: "💰",
                            title: tr("Revenus"),
                            value: "\(sellValue.formattedString())/s",
                            color: .yellow
                        )
                        DuckStatTile(
                            icon: "🧬",
                            title: tr("Recyclage"),
                            value: "+\(recycleValue.formattedString())",
                            color: .green
                        )
                    }

                    // --- ATTRIBUTS : taille + mutation ---
                    HStack(spacing: 8) {
                        DuckBadge(text: "\(tr("Taille:")) \(tr(dynamicStats.size.rawValue))", color: .cyan)
                        DuckBadge(text: "\(tr("Mutation:")) \(tr(dynamicStats.mutation.rawValue))", color: dynamicStats.mutation.color)
                    }

                    // --- PERKS ÉQUIPÉS ---
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                                Text(tr("Perks Équipés"))
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            let maxSlots = gameManager.maxDuckPerkSlots(for: liveDuck)
                            Text("\(liveDuck.equippedPerkIds.count)/\(maxSlots) \(tr("emplacements"))")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }

                        Button(action: { showingPerkSelection = true }) {
                            VStack(spacing: 8) {
                                if duckPerks.isEmpty {
                                    Text(tr("Aucun Perk équipé (Toucher pour choisir)"))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    ForEach(duckPerks) { perk in
                                        HStack(spacing: 8) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(perk.rarity.color)
                                            Text(tr(perk.name))
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text(tr(perk.rarity.rawValue))
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(perk.rarity.color)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Capsule().fill(perk.rarity.color.opacity(0.15)))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(perk.rarity.color.opacity(0.08)))
                                    }
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // --- AMÉLIORATIONS ---
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.cyan)
                            Text(tr("Améliorations"))
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        let dynamicSizeCost = liveDuck.sizeUpgradeCost(with: duckPerks)
                        DuckUpgradeButton(
                            title: tr("Améliorer Taille"),
                            cost: dynamicSizeCost,
                            icon: "🧬",
                            color: .blue,
                            impact: sizeUpgradeImpact(for: liveDuck, baseValue: sellValue),
                            canAfford: dynamicSizeCost != nil && gameManager.mutationPoints >= (dynamicSizeCost ?? BigNumber(1e100)),
                            maxLabel: tr("Niveau MAX"),
                            action: { gameManager.upgradeDuckSize(id: liveDuck.id) }
                        )

                        let dynamicMutationCost = liveDuck.mutationUpgradeCost(with: duckPerks)
                        DuckUpgradeButton(
                            title: tr("Muter"),
                            cost: dynamicMutationCost,
                            icon: "🧬",
                            color: .purple,
                            impact: mutationUpgradeImpact(for: liveDuck, baseValue: sellValue),
                            canAfford: dynamicMutationCost != nil && gameManager.mutationPoints >= (dynamicMutationCost ?? BigNumber(1e100)),
                            maxLabel: tr("Niveau MAX"),
                            action: { gameManager.upgradeDuckMutation(id: liveDuck.id) }
                        )

                        let dynamicLevelCost = liveDuck.levelUpgradeCost(with: duckPerks)
                        DuckUpgradeButton(
                            title: tr("Augmenter Niveau"),
                            cost: dynamicLevelCost,
                            icon: "💰",
                            color: .yellow,
                            impact: levelUpgradeImpact(for: liveDuck, baseValue: sellValue),
                            canAfford: dynamicLevelCost != nil && gameManager.money >= (dynamicLevelCost ?? BigNumber(Double.greatestFiniteMagnitude)),
                            maxLabel: tr("Niveau MAX (100)"),
                            action: { gameManager.upgradeDuckLevel(id: liveDuck.id) }
                        )
                    }

                    // --- RECYCLAGE ---
                    Button(action: {
                        showingRecycleAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("\(tr("Recycler (+ "))\(recycleValue.formattedString()) 🧬)")
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isAssigned
                            ? AnyShapeStyle(Color.gray.opacity(0.6))
                            : AnyShapeStyle(LinearGradient(colors: [.red, Color(red: 0.6, green: 0.05, blue: 0.1)], startPoint: .top, endPoint: .bottom))
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: isAssigned ? .clear : .red.opacity(0.35), radius: 8, y: 4)
                    }
                    .padding(.top, 4)

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
                gameManager.recycleDucks(ids: [liveDuck.id])
                dismiss()
            }
        } message: {
            Text("\(tr("Voulez-vous vraiment recycler ce canard de rareté "))\(liveDuck.rarity.localizedName)\(tr(" ? Cette action est définitive."))")
        }
        .sheet(isPresented: $showingPerkSelection) {
            PerkSelectionSheet(targetId: liveDuck.id, targetType: .duck)
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
                NeonBackground()

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
                            // CE QUI COÛTAIT : `matchingDucks` et `potentialYield` sont des
                            // propriétés calculées qui refont chacune `getDucksToRecycle` — un
                            // filtrage complet de l'inventaire (jusqu'à 10 000 canards) avec
                            // allocation du tableau résultat. `matchingDucks` était lu DEUX fois
                            // (compteur affiché puis test `> 0`), soit trois balayages au lieu de
                            // deux. POURQUOI LE RENDU RESTE IDENTIQUE : ces fonctions sont de
                            // simples lectures déterministes, on affiche exactement les mêmes
                            // valeurs, juste calculées une seule fois chacune.
                            let matchingDucksCount = matchingDucks
                            let potentialYieldValue = potentialYield

                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(tr("Canards ciblés"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("\(matchingDucksCount)")
                                        .font(.title2.bold())
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text(tr("Gain Total"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("+\(potentialYieldValue.formattedString()) 🧬")
                                        .font(.title2.bold())
                                        .foregroundColor(.green)
                                }
                            }

                            if matchingDucksCount > 0 {
                                Button(action: {
                                    gameManager.recycleBulkDucks(rarity: selectedRarity, level: selectedLevel)
                                    dismiss()
                                }) {
                                    Text(tr("RECYCLER EN LOT"))
                                }
                                .buttonStyle(NeonButtonStyle(color: selectedRarity.color))
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
                                    }
                                    .buttonStyle(NeonButtonStyle(color: Neon.red, cornerRadius: 12))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
            .infoPopup(
                isPresented: $showInfo,
                title: tr("Comment ça marche ?"),
                message: tr("Recyclage en Lot : S'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s'applique au niveau choisi et à ses niveaux inférieurs.\n\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau."),
                accent: Neon.green
            )
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
            ZStack {
                NeonBackground(accent: Neon.cyan)

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
                .background(.ultraThinMaterial)

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
            }
            .navigationTitle(tr("Statistiques"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
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
                    .fill(selectedRarity == rarity ? rarity.color.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedRarity == rarity ? rarity.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Composants du détail de canard

struct DuckBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(color == .white ? .white : color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.15)))
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }
}

struct DuckStatTile: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
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
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [color.opacity(0.35), color.opacity(0.08)], center: .center, startRadius: 2, endRadius: 20))
                        .frame(width: 38, height: 38)
                    Text(icon)
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tr(title))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if cost != nil, let impact = impact {
                        Text("+\(impact.formattedString()) 💰/s")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else {
                        Text(tr(maxLabel))
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                    }
                }

                Spacer(minLength: 8)

                if let cost = cost {
                    HStack(spacing: 3) {
                        Text(cost.formattedString())
                            .font(.system(size: 13, weight: .bold))
                        Text(icon)
                            .font(.system(size: 11))
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            canAfford
                            ? AnyShapeStyle(LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.gray.opacity(0.2))
                        )
                    )
                    .foregroundColor(canAfford ? .white : .gray)
                } else {
                    Text(tr("MAX"))
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.gray.opacity(0.15)))
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cost != nil && canAfford ? color.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(cost == nil || !canAfford)
    }
}
