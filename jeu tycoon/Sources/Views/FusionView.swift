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
                    if gameManager.isUnlocked(.autoFusion) {
                        showingBulkFusion = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: gameManager.isUnlocked(.autoFusion) ? "bolt.fill" : "lock.fill")
                        Text(tr("Auto"))
                    }
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(gameManager.isUnlocked(.autoFusion) ? Color.orange.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundColor(gameManager.isUnlocked(.autoFusion) ? .orange : .gray)
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.systemBackground).shadow(radius: 2))
            
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
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
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
                        let isAssigned = gameManager.isDuckAssigned(duckId: duck.id)
                        let isSelected = selectedDuckIds.contains(duck.id)
                        let isMismatched = currentRarity != nil && (duck.rarity != currentRarity || duck.fusionLevel != currentLevel)
                        let isFull = selectedDuckIds.count >= 3 && !isSelected
                        let isDisabled = isMismatched || isFull
                        
                        ZStack {
                            DuckGridCard(
                                duck: duck,
                                displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                isAssigned: isAssigned
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
                    Text("\(tr("Prix futur : "))\(futurePrice.formattedString()) 💰 / sec")
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
                                    isAssigned: gameManager.isDuckAssigned(duckId: duck.id)
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
                        Text("\(tr("Coût de fusion: "))\(fusionCost.formattedString()) 💰")
                            .font(.headline)
                            .foregroundColor(gameManager.money >= fusionCost ? .primary : .red)
                        Text(tr("(Taxe 5%)"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .bold()
                }
                
                Button(action: {
                    if selectedDuckIds.count == 3 && gameManager.money >= fusionCost {
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
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        selectedDuckIds.count == 3 && gameManager.money >= fusionCost
                        ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(radius: selectedDuckIds.count == 3 && gameManager.money >= fusionCost ? 5 : 0)
                }
                .disabled(selectedDuckIds.count < 3 || gameManager.money < fusionCost)
            }
            .padding()
            .background(Color(.systemBackground).shadow(radius: 2))
        }
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
        .onChange(of: gameManager.inventory.count) { _, _ in
            updateDisplayInventory()
        }
        .sheet(isPresented: $showingBulkFusion) {
            BulkFusionSheet()
                .environment(gameManager)
        }
        .sheet(isPresented: $showingSummary) {
            InventorySummaryView()
                .environment(gameManager)
        }
    }
    
}
