import SwiftUI

extension View {
    @ViewBuilder
    func fusionBorder(level: Int, rarityColor: Color) -> some View {
        switch level {
        case 0:
            self.overlay(RoundedRectangle(cornerRadius: 8).stroke(rarityColor, lineWidth: 1))
        case 1:
            self.overlay(RoundedRectangle(cornerRadius: 8).stroke(rarityColor, lineWidth: 3))
        case 2:
            self.overlay(RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 3).shadow(color: .white, radius: 2))
        case 3:
            self.overlay(RoundedRectangle(cornerRadius: 8).stroke(.yellow, lineWidth: 3).shadow(color: .yellow, radius: 4))
        case 4:
            self.overlay(RoundedRectangle(cornerRadius: 8).stroke(LinearGradient(colors: [.red, .blue, .purple, .orange], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4).shadow(color: .purple, radius: 5))
        default:
            self.overlay(RoundedRectangle(cornerRadius: 8).stroke(rarityColor, lineWidth: 1))
        }
    }
    
    @ViewBuilder
    func ritualBadge(count: Int) -> some View {
        if count > 0 {
            self.overlay(
                VStack {
                    HStack {
                        ZStack {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(
                                    LinearGradient(colors: [.purple, .pink], startPoint: .bottom, endPoint: .top)
                                )
                                .shadow(color: .purple.opacity(0.8), radius: 3, x: 0, y: 1)
                            
                            Text("\(count)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .offset(y: 2) // La base de la flamme est plus large
                        }
                        .offset(x: -6, y: -6)
                        
                        Spacer()
                    }
                    Spacer()
                }
            )
        } else {
            self
        }
    }
}

enum InventorySortOption: String, CaseIterable {
    case defaultSort = "Défaut"
    case recycleValueDesc = "Recyclage 🧬 (Max)"
    case recycleValueAsc = "Recyclage 🧬 (Min)"
    case sellValueDesc = "Revenus 💰 (Max)"
    case rarity = "Rareté"
}

/// Carte de canard légère pour la grille — utilise des valeurs pré-calculées
/// pour éviter les appels à gameManager pendant le scroll
struct DuckGridCard: View {
    let duck: Duck
    let displayValue: String
    let isAssigned: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Image(duck.rarity.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
            
            Text("Lv.\(duck.level)")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(displayValue) 💰")
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: 55, height: 55)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(rarityColor.opacity(0.3))
        )
        .fusionBorder(level: duck.fusionLevel, rarityColor: rarityColor)
        .ritualBadge(count: duck.ritualSuccesses)
        .overlay(alignment: .topTrailing) {
            if isAssigned {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .offset(x: 5, y: -5)
            }
        }
    }
    private var rarityColor: Color {
        duck.rarity.color
    }
}

struct InventoryView: View {
    @Binding var selectedTab: Int
    @Environment(GameManager.self) private var gameManager
    
    // Grille adaptative pour afficher 6 canards par ligne
    let columns = [
        GridItem(.adaptive(minimum: 55), spacing: 8)
    ]
    
    @State private var sortOption: InventorySortOption = .defaultSort
    @State private var showingBulkRecycle = false
    
    // Navigation manuelle vers FusionView
    @State private var showingFusionLab = false
    @State private var showingSummary = false
    @State private var showStatsInfo = false
    
    // Chemin de navigation
    @Binding var navPath: NavigationPath
    
    @State private var displayInventory: [(duck: Duck, displayValue: String, isAssigned: Bool)] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    
    private let pageSize = 100
    @State private var currentPage = 0
    @State private var sortedAll: [Duck] = []
    @State private var hasMore = false
    @State private var needsUpdate = false
    
    private func processDucks(_ ducks: [Duck], gm: GameManager) -> [(duck: Duck, displayValue: String, isAssigned: Bool)] {
        let assignedIds = Set(gm.factories.flatMap { $0.assignedDuckIds })
        return ducks.map { duck in
            (duck: duck,
             displayValue: gm.displaySellValue(for: duck).formattedString(),
             isAssigned: assignedIds.contains(duck.id))
        }
    }
    
    private func updateDisplayInventory() {
        isLoading = true
        currentPage = 0
        displayInventory = []
        let gm = gameManager
        Task {
            let all = await gm.getSortedInventoryAsync(by: sortOption, limit: Int.max)
            let firstSlice = Array(all.prefix(pageSize))
            let processed = processDucks(firstSlice, gm: gm)
            
            await MainActor.run {
                self.sortedAll = all
                self.displayInventory = processed
                self.hasMore = all.count > pageSize
                self.currentPage = 1
                self.isLoading = false
            }
        }
    }
    
    private func silentUpdateDisplayInventory() {
        let gm = gameManager
        Task {
            let all = await gm.getSortedInventoryAsync(by: sortOption, limit: Int.max)
            let currentLoadedCount = max(self.currentPage * self.pageSize, self.pageSize)
            let slice = Array(all.prefix(currentLoadedCount))
            let processed = processDucks(slice, gm: gm)
            
            await MainActor.run {
                self.sortedAll = all
                self.displayInventory = processed
                self.hasMore = all.count > currentLoadedCount
            }
        }
    }
    
    private func loadMoreIfNeeded() {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let gm = gameManager
        Task {
            let nextSlice = Array(sortedAll.dropFirst(currentPage * pageSize).prefix(pageSize))
            let processed = processDucks(nextSlice, gm: gm)
            await MainActor.run {
                self.displayInventory.append(contentsOf: processed)
                self.currentPage += 1
                self.hasMore = (self.currentPage * self.pageSize) < self.sortedAll.count
                self.isLoadingMore = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                        Text(tr("Inventaire"))
                            .font(.largeTitle.bold())
                        
                        Button(action: { showStatsInfo = true }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding()
                
            // Custom Top Bar
            HStack(spacing: 15) {
                Button(action: {
                    if gameManager.isFusionUnlocked {
                        showingFusionLab = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: gameManager.isFusionUnlocked ? "flask.fill" : "lock.fill")
                            .font(.title3)
                        Text(tr("Labo"))
                            .font(.title3)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(gameManager.isFusionUnlocked ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                    .foregroundColor(gameManager.isFusionUnlocked ? .white : .gray)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    if gameManager.isBulkRecycleUnlocked {
                        showingBulkRecycle = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: gameManager.isBulkRecycleUnlocked ? "arrow.3.trianglepath" : "lock.fill")
                            .font(.title3)
                        Text(tr("Recyclage"))
                            .font(.title3)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(gameManager.isBulkRecycleUnlocked ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                    .foregroundColor(gameManager.isBulkRecycleUnlocked ? .white : .gray)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.clear)
                .zIndex(2)
            
            // Custom Sort Bar
            HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(gameManager.inventory.count) / \(gameManager.maxInventoryCapacity) \(tr("Canards"))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Button(action: { showingSummary = true }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                        if gameManager.maxInventoryCapacity >= 5000 {
                            Text(tr("Tous affichés"))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 15)
                    Spacer()
                    Menu {
                        Picker(tr("Trier par"), selection: $sortOption) {
                            ForEach(InventorySortOption.allCases, id: \.self) { option in
                                Text(tr(option.rawValue)).tag(option)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(tr(sortOption.rawValue))
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(Color.white.opacity(0.02))
                .zIndex(1)
            
            ScrollView {
                if isLoading {
                    ProgressView("Chargement des canards...")
                        .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(displayInventory, id: \.duck.id) { item in
                            NavigationLink(value: item.duck) {
                                DuckGridCard(
                                    duck: item.duck,
                                    displayValue: item.displayValue,
                                    isAssigned: item.isAssigned
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Sentinelle de chargement progressif
                        if hasMore {
                            Color.clear
                                .frame(height: 1)
                                .onAppear { loadMoreIfNeeded() }
                            if isLoadingMore {
                                ProgressView()
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                updateDisplayInventory()
            }
            .onChange(of: sortOption) { _, _ in
                updateDisplayInventory()
            }
            // Mettre à jour l'inventaire si la taille de l'inventaire change (achats, fusions, etc.)
            .onChange(of: gameManager.inventory.count) { _, _ in
                if selectedTab == 1 {
                    if displayInventory.isEmpty {
                        updateDisplayInventory()
                    } else {
                        silentUpdateDisplayInventory()
                    }
                } else {
                    needsUpdate = true
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == 1 && needsUpdate {
                    silentUpdateDisplayInventory()
                    needsUpdate = false
                }
            }
            .sheet(isPresented: $showingFusionLab) {
                FusionView(sortOption: $sortOption)
                    .environment(gameManager)
            }
            .sheet(isPresented: $showingBulkRecycle) {
                BulkRecycleSheet()
                    .environment(gameManager)
            }
            .sheet(isPresented: $showingSummary) {
                InventorySummaryView()
                    .environment(gameManager)
            }
        }
        .alert("Niveaux, Mutations & Tailles", isPresented: $showStatsInfo) {
            Button(tr("Compris"), role: .cancel) {}
        } message: {
            Text(tr("Niveau :\nChaque niveau augmente les revenus générés par le canard de 1%.\n\nMutations :\n- Doré : Revenus x5 / Recyclage x2\n- Radioactif : Revenus x15 / Recyclage x3\n- Cristallisé : Revenus x50 / Recyclage x5\n\nTailles :\n- Moyen : Revenus x1.5 / Recyclage x1.5\n- Grand : Revenus x2.5 / Recyclage x2\n- Géant : Revenus x5 / Recyclage x3"))
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue != 1 {
                navPath = NavigationPath()
            }
        }
    }
}

// (DuckDetailView et les autres extensions restent identiques)
