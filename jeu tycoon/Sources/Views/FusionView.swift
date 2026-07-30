import SwiftUI

struct FusionView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    @Binding var sortOption: InventorySortOption
    @State private var selectedDuckIds: [UUID] = []
    
    // Auto-fusion state
    @State private var showingBulkFusion = false
    
    // Animation state
    @State private var animationData: [(rarity: DuckRarity, level: Int)]? = nil
    @State private var animationResultDuck: (rarity: DuckRarity, level: Int)? = nil
    @State private var pendingFusionAction: (() -> Void)? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 8)
    ]
    
    // Rareté actuellement verrouillée par la sélection
    var currentRarity: DuckRarity? {
        guard let firstId = selectedDuckIds.first,
              let firstDuck = gameManager.inventory.first(where: { $0.id == firstId }) else {
            return nil
        }
        return firstDuck.rarity
    }
    
    // Niveau de fusion verrouillé par la sélection
    var currentLevel: Int? {
        guard let firstId = selectedDuckIds.first,
              let firstDuck = gameManager.inventory.first(where: { $0.id == firstId }) else {
            return nil
        }
        return firstDuck.fusionLevel
    }
    
    @State private var displayInventory: [Duck] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var showingSummary = false
    
    private let pageSize = 100
    @State private var currentPage = 0
    @State private var sortedAll: [Duck] = []   // cache trié complet, en mémoire légère
    @State private var hasMore = false
    
    /// Charge et trie TOUS les canards une seule fois en arrière-plan, puis présente la première page.
    private func updateDisplayInventory() {
        isLoading = true
        currentPage = 0
        displayInventory = []
        Task {
            let all = await gameManager.getSortedInventoryAsync(by: sortOption, limit: Int.max, filterAssigned: false)
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
    
    /// Rafraîchit le contenu SANS repasser par l'état de chargement et en conservant les pages
    /// déjà chargées (calqué sur `InventoryView.silentUpdateDisplayInventory`).
    /// Coût évité : l'Auto-Ouvrier fait varier `inventory.count` en continu ; la version lourde
    /// vidait la liste, remettait `isLoading = true` et re-triait tout à chaque canard généré.
    /// Le contenu affiché reste identique (mêmes canards, même tri) : seule l'apparition du
    /// spinner disparaît, et elle n'a pas lieu d'être pour un simple ajout de canard.
    private func silentUpdateDisplayInventory() {
        Task {
            let all = await gameManager.getSortedInventoryAsync(by: sortOption, limit: Int.max, filterAssigned: false)
            let currentLoadedCount = max(self.currentPage * self.pageSize, self.pageSize)
            let slice = Array(all.prefix(currentLoadedCount))
            await MainActor.run {
                self.sortedAll = all
                self.displayInventory = slice
                self.hasMore = all.count > currentLoadedCount
            }
        }
    }

    /// Charge la page suivante (appelé quand le joueur approche du bas).
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
    
    var futurePrice: BigNumber {
        guard selectedDuckIds.count == 3 else { return .zero }
        let ducks = gameManager.inventory.filter { selectedDuckIds.contains($0.id) }
        return ducks.reduce(.zero) { $0 + gameManager.displaySellValue(for: $1) }
    }
    
    var fusionCost: BigNumber {
        return futurePrice * 0.05
    }
    
    var body: some View {
        // Le canard de référence de la sélection (rareté + niveau verrouillés) était re-résolu par
        // un scan linéaire de l'inventaire (jusqu'à 10 000 canards) DANS chaque cellule de la grille,
        // et même deux fois par cellule (currentRarity PUIS currentLevel). Comme le corps lit
        // gameManager.money, tout cela était refait chaque seconde. On résout ici une seule fois :
        // les valeurs comparées sont exactement les mêmes, donc l'affichage est identique.
        let referenceDuck = selectedDuckIds.first.flatMap { firstId in
            gameManager.inventory.first(where: { $0.id == firstId })
        }
        let lockedRarity = referenceDuck?.rarity
        let lockedLevel = referenceDuck?.fusionLevel

        // Un Set des canards assignés remplace le `factories.contains(where:)` refait par cellule :
        // même résultat booléen, mais un seul balayage des usines au lieu d'un par carte affichée.
        let assignedDuckIds = Set(gameManager.factories.flatMap { $0.assignedDuckIds })

        // `futurePrice` balaye tout l'inventaire : il était évalué jusqu'à 4 fois par reconstruction
        // du corps (prix affiché, coût affiché, couleur du coût, bouton FUSIONNER). Une seule
        // évaluation donne exactement les mêmes nombres.
        let futurePriceValue = futurePrice
        let fusionCostValue = futurePriceValue * 0.05

        VStack(spacing: 0) {
            // Custom Top Bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.down")
                        Text(tr("Fermer"))
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Spacer()
                
                Button(action: {
                    if gameManager.isAutoFusionUnlocked {
                        showingBulkFusion = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: gameManager.isAutoFusionUnlocked ? "bolt.fill" : "lock.fill")
                        Text(tr("Auto"))
                    }
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(gameManager.isAutoFusionUnlocked ? Color.orange.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundColor(gameManager.isAutoFusionUnlocked ? .orange : .gray)
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Neon.green.opacity(0.25)).frame(height: 1)
            }

            // Menu de tri + info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("\(gameManager.inventory.count) \(tr("Canards"))")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Text(tr("Tous affichés"))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Menu {
                    Picker(tr("Trier par"), selection: $sortOption) {
                        ForEach(InventorySortOption.allCases, id: \.self) { option in
                            Text(tr(option.rawValue)).tag(option)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(tr(sortOption.rawValue))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 6)
            
            // Inventaire au dessus
            ScrollView {
                if isLoading {
                    ProgressView("Chargement...")
                        .padding(.top, 50)
                } else if displayInventory.isEmpty {
                    Text(tr("Aucun canard disponible."))
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(displayInventory) { duck in
                        let isAssigned = assignedDuckIds.contains(duck.id)
                        let isSelected = selectedDuckIds.contains(duck.id)
                        let isMismatched = lockedRarity != nil && (duck.rarity != lockedRarity || duck.fusionLevel != lockedLevel)
                        let isFull = selectedDuckIds.count >= 3 && !isSelected
                        let isDisabled = isMismatched || isFull
                        
                        ZStack {
                            DuckGridCard(
                                duck: duck,
                                displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                isAssigned: isAssigned,
                                dynamicLevel: gameManager.getDynamicStats(for: duck).level
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 3)
                                    .opacity(isSelected ? 1 : 0)
                            )
                            .opacity(isDisabled ? 0.3 : 1.0)
                            
                            if isSelected {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                            .offset(x: -4, y: 4)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .onTapGesture {
                            if isSelected {
                                selectedDuckIds.removeAll(where: { $0 == duck.id })
                            } else if !isDisabled {
                                selectedDuckIds.append(duck.id)
                            }
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
                                    .gridCellColumns(columns.count)
                            }
                        }
                    }
                    .padding()
            }
            }
            
            Divider()
            
            // Zone de fusion en bas
            VStack(spacing: 15) {
                if selectedDuckIds.count == 3 {
                    Text("\(tr("Prix futur : "))\(futurePriceValue.formattedString()) 💰 / sec")
                        .font(.headline)
                        .foregroundColor(.green)
                        .bold()
                } else {
                    Text(tr("Sélectionnez 3 canards de même rareté et niveau"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        if index < selectedDuckIds.count {
                            if let duck = gameManager.inventory.first(where: { $0.id == selectedDuckIds[index] }) {
                                DuckGridCard(
                                    duck: duck,
                                    displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                    isAssigned: assignedDuckIds.contains(duck.id),
                                    dynamicLevel: gameManager.getDynamicStats(for: duck).level
                                )
                                .onTapGesture {
                                    selectedDuckIds.remove(at: index)
                                }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .frame(width: 55, height: 55)
                                
                                Text(tr("?"))
                                    .foregroundColor(.gray)
                                    .font(.title)
                            }
                        }
                    }
                }
                
                if selectedDuckIds.count == 3 {
                    VStack(spacing: 4) {
                        Text("\(tr("Coût de fusion: "))\(fusionCostValue.formattedString()) 💰")
                            .font(.headline)
                            .foregroundColor(gameManager.money >= fusionCostValue ? .primary : .red)
                        Text(tr("(Taxe 5%)"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .bold()
                }
                
                let canFuse = selectedDuckIds.count == 3 && gameManager.money >= fusionCostValue
                Button(action: {
                    if canFuse {
                        // Résolution au moment du tap (une seule fois, pas par cellule) : on garde
                        // volontairement les propriétés calculées ici pour lire l'état le plus frais.
                        let rarity = currentRarity ?? .commun
                        let level = currentLevel ?? 0
                        animationData = Array(repeating: (rarity, level), count: 3)

                        var newRarity = rarity
                        var newLevel = level + 1
                        if level == 4 {
                            newLevel = 0
                            newRarity = rarity.nextRarity ?? rarity
                        }
                        animationResultDuck = (newRarity, newLevel)

                        pendingFusionAction = {
                            gameManager.fuseDucks(ids: Set(selectedDuckIds))
                            selectedDuckIds.removeAll()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text(tr("FUSIONNER"))
                    }
                }
                .neonButton(Neon.purple)
                .opacity(canFuse ? 1.0 : 0.45)
                .disabled(!canFuse)
            }
            .padding()
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle().fill(Neon.green.opacity(0.25)).frame(height: 1)
            }
        }
        .background(NeonBackground(accent: Neon.green))
        .overlay {
            if let data = animationData {
                FusionAnimationView(ducksToAnimate: data, resultingDuck: animationResultDuck) {
                    animationData = nil
                    animationResultDuck = nil
                    pendingFusionAction?()
                    pendingFusionAction = nil
                }
            }
        }
        .onAppear {
            updateDisplayInventory()
        }
        .onChange(of: sortOption) { _, _ in
            updateDisplayInventory()
        }
        // L'Auto-Ouvrier fait varier inventory.count en permanence : la version lourde
        // (vidage de la liste + spinner + re-tri complet) était relancée à chaque canard généré.
        // La variante silencieuse affiche exactement le même contenu sans passer par l'écran
        // de chargement ni perdre les pages déjà chargées.
        .onChange(of: gameManager.inventory.count) { _, _ in
            if displayInventory.isEmpty {
                updateDisplayInventory()
            } else {
                silentUpdateDisplayInventory()
            }
        }
        .sheet(isPresented: $showingBulkFusion) {
            BulkFusionSheet()
                .environment(gameManager)
        }
        .sheet(isPresented: $showingSummary) {
            InventorySummaryView()
                .environment(gameManager)
        }
        .preferredColorScheme(.dark)
    }

}
