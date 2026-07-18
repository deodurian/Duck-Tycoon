import SwiftUI

extension GameManager {
    // MARK: - Traitement de l'Ajout de Canards
    func processNewDucks(_ ducks: [Duck]) {
        var ducksToKeep = [Duck]()
        var recycleYield: BigNumber = .zero
        
        let filterRarityRaw = UserDefaults.standard.string(forKey: "autoRecycleRarity") ?? "None"
        let isFilterActive = isUnlocked(.autoRecycleFilter) && filterRarityRaw != "None"
        
        let mutationLvl = spontaneousMutationLevel
        
        for var duck in ducks {
            // Appliquer la mutation spontanée
            if mutationLvl > 0 {
                let chance = Double.random(in: 0..<100)
                if chance < 5.0 {
                    duck.fusionLevel = mutationLvl
                }
            }
            
            if isFilterActive && duck.rarity.rawValue == filterRarityRaw {
                // Recycle automatically
                let yield = duck.recycleValue * mutationMultiplier
                recycleYield += yield
            } else {
                ducksToKeep.append(duck)
            }
        }
        
        if recycleYield > .zero {
            addMutationPoints(recycleYield)
        }
        
        inventory.append(contentsOf: ducksToKeep)
        emitMissionEvent(.openCrates, amount: BigNumber(ducks.count))
        emitMissionEvent(.openWoodenCrate, amount: BigNumber(ducks.count))
        if ducks.count > 1 {
            emitMissionEvent(.bulkOpenCrates, amount: BigNumber(ducks.count))
        }
        
        checkStoryAction("open_wooden_crate")
        saveGame()
    }
    
    // MARK: - Inventory Limits
    
    var maxInventoryCapacity: Int {
        if isUnlocked(.inventory10000) { return 10000 }
        if isUnlocked(.inventory5000) { return 5000 }
        if isUnlocked(.inventory1000) { return 1000 }
        return 100 // Limite de base
    }
    
    // MARK: - Actions Utilisateur
    
    var newFactoryCost: BigNumber {
        return BigNumber(1000.0 * pow(5.0, Double(factories.count - 1)) * factoryCostDiscount)
    }
    
    func buyNewFactory() {
        if money >= newFactoryCost {
            let costVal = newFactoryCost.doubleValue // Get underlying Double value
            money -= newFactoryCost
            var newFactory = DuckFactory(name: "Usine \(factories.count + 1)")
            newFactory.basePurchasePrice = costVal
            factories.append(newFactory)
            saveGame()
        }
    }
    
    func assignDuck(_ duck: Duck, to factoryId: UUID) {
        if let index = factories.firstIndex(where: { $0.id == factoryId }) {
            let maxCapacity = maxDucks(for: factories[index])
            if !factories[index].assignedDuckIds.contains(duck.id) && factories[index].assignedDuckIds.count < maxCapacity {
                factories[index].assignedDuckIds.append(duck.id)
            } else if factories[index].assignedDuckIds.count >= maxCapacity {
                // Si plein, on remplace le premier
                if !factories[index].assignedDuckIds.isEmpty {
                    factories[index].assignedDuckIds[0] = duck.id
                }
            }
            emitMissionEvent(.assignDuckToFactory)
            checkStoryAction("assign_duck")
            invalidateEarningsCache()
            saveGame()
        }
    }
    
    func unassignDuck(duckId: UUID? = nil, from factoryId: UUID) {
        guard let index = factories.firstIndex(where: { $0.id == factoryId }) else { return }
        if let duckId = duckId {
            factories[index].assignedDuckIds.removeAll { $0 == duckId }
        } else {
            factories[index].assignedDuckIds.removeAll()
        }
        invalidateEarningsCache()
        saveGame()
    }
    
    func isDuckAssigned(duckId: UUID) -> Bool {
        return factories.contains(where: { $0.assignedDuckIds.contains(duckId) })
    }
    
    // MARK: - Mutation & Recyclage
    
    func recycleDuck(id: UUID) {
        guard !isDuckAssigned(duckId: id),
              let index = inventory.firstIndex(where: { $0.id == id }) else { return }
        
        let duck = inventory[index]
        addMutationPoints(duck.recycleValue * mutationMultiplier)
        inventory.remove(at: index)
        checkStoryAction("recycle_duck")
        saveGame()
    }
    
    // MARK: - Mass Recycle
    
    func countUnassigned(rarity: DuckRarity) -> Int {
        let assignedIds = Set(factories.flatMap { $0.assignedDuckIds })
        return inventory.filter { $0.rarity == rarity && !assignedIds.contains($0.id) }.count
    }
    
    func potentialRecycleYield(rarity: DuckRarity) -> BigNumber {
        let assignedIds = Set(factories.flatMap { $0.assignedDuckIds })
        let unassigned = inventory.filter { $0.rarity == rarity && !assignedIds.contains($0.id) }
        return unassigned.reduce(into: .zero) { $0 += $1.recycleValue }
    }
    
    func recycleAllUnassigned(rarity: DuckRarity) {
        let assignedIds = Set(factories.flatMap { $0.assignedDuckIds })
        let unassigned = inventory.filter { $0.rarity == rarity && !assignedIds.contains($0.id) }
        guard !unassigned.isEmpty else { return }
        
        let sum = unassigned.reduce(into: BigNumber.zero) { $0 += $1.recycleValue }
        let totalYield = sum * mutationMultiplier
        addMutationPoints(totalYield)
        
        let unassignedIds = Set(unassigned.map { $0.id })
        inventory.removeAll(where: { unassignedIds.contains($0.id) })
        
        totalRecycledDucks += unassigned.count
        emitMissionEvent(.recycleDuck, amount: BigNumber(unassigned.count))
        emitMissionEvent(.totalRecycleCount, amount: BigNumber(unassigned.count))
        
        saveGame()
    }
    
    func recycleDucks(ids: Set<UUID>) {
        for id in ids {
            // Si le canard est dans une usine, on le retire d'abord
            if isDuckAssigned(duckId: id) {
                if let factoryIndex = factories.firstIndex(where: { $0.assignedDuckIds.contains(id) }) {
                    factories[factoryIndex].assignedDuckIds.removeAll { $0 == id }
                }
            }
            
            // Puis on le recycle
            if let index = inventory.firstIndex(where: { $0.id == id }) {
                addMutationPoints(inventory[index].recycleValue * mutationMultiplier)
                inventory.remove(at: index)
            }
        }
        totalRecycledDucks += ids.count
        emitMissionEvent(.recycleDuck, amount: BigNumber(ids.count))
        emitMissionEvent(.totalRecycleCount, amount: BigNumber(ids.count))
        checkStoryAction("recycle_duck")
        saveGame()
    }
    func countBulkRecycle(rarity: DuckRarity, level: Int) -> Int {
        return getDucksToRecycle(rarity: rarity, level: level).count
    }
    
    func potentialBulkRecycleYield(rarity: DuckRarity, level: Int) -> BigNumber {
        let toRecycle = getDucksToRecycle(rarity: rarity, level: level)
        return toRecycle.reduce(into: .zero) { $0 += displayRecycleValue(for: $1) }
    }
    
    func recycleBulkDucks(rarity: DuckRarity, level: Int) {
        let toRecycle = getDucksToRecycle(rarity: rarity, level: level)
        
        let sum = toRecycle.reduce(into: BigNumber.zero) { $0 += $1.recycleValue }
        let idsToRemove = Set(toRecycle.map { $0.id })
        
        addMutationPoints(sum * mutationMultiplier)
        inventory.removeAll(where: { idsToRemove.contains($0.id) })
        
        totalRecycledDucks += toRecycle.count
        emitMissionEvent(.recycleDuck, amount: BigNumber(toRecycle.count))
        emitMissionEvent(.bulkRecycle)
        emitMissionEvent(.totalRecycleCount, amount: BigNumber(toRecycle.count))
        
        saveGame()
    }
    
    // MARK: - Perks
    
    func recyclePerk(id: UUID) {
        guard let index = perksInventory.firstIndex(where: { $0.id == id }) else { return }
        
        // Vérifier si le perk est équipé
        if let factory = factories.first(where: { $0.equippedPerkIds.contains(id) }) {
            unequipPerk(id, from: factory.id)
        }
        if let duck = inventory.first(where: { $0.equippedPerkIds.contains(id) }) {
            unequipPerk(id, from: duck.id)
        }
        
        let perk = perksInventory[index]
        
        // Calcul des points de mutation (modifiable selon l'équilibrage souhaité)
        let mutYield: Int
        switch perk.rarity {
        case .commun: mutYield = 50
        case .peuCommun: mutYield = 200
        case .rare: mutYield = 1000
        case .epique: mutYield = 5000
        case .legendaire: mutYield = 25000
        case .mythique: mutYield = 100000
        }
        
        addMutationPoints(BigNumber(mutYield) * mutationMultiplier)
        perksInventory.remove(at: index)
        saveGame()
    }
    
    private func getDucksToRecycle(rarity: DuckRarity, level: Int) -> [Duck] {
        let assignedIds = Set(factories.flatMap { $0.assignedDuckIds })
        return inventory.filter { duck in
            guard !assignedIds.contains(duck.id) else { return false }
            if duck.rarity < rarity { return true }
            if duck.rarity == rarity && duck.fusionLevel <= level { return true }
            return false
        }
    }
    
    private func getFusionChunks(from ducks: [Duck]) -> [[Duck]] {
        let numberOfFusions = ducks.count / 3
        if numberOfFusions == 0 { return [] }
        let sortedDucks = ducks.sorted(by: { $0.sellValue < $1.sellValue })
        var chunks = [[Duck]]()
        for i in 0..<numberOfFusions {
            chunks.append(Array(sortedDucks[(i * 3)..<(i * 3 + 3)]))
        }
        return chunks
    }
    

    
    // MARK: - Fusion
    
    func fuseDucks(ids: Set<UUID>) {
        guard ids.count == 3 else { return }
        
        // Récupérer les canards
        let ducksToFuse = inventory.filter { ids.contains($0.id) }
        guard ducksToFuse.count == 3 else { return }
        
        // Vérifier qu'ils ont tous la même rareté et le même niveau de fusion
        let rarity = ducksToFuse[0].rarity
        let level = ducksToFuse[0].fusionLevel
        guard ducksToFuse.allSatisfy({ $0.rarity == rarity && $0.fusionLevel == level }) else { return }
        
        // Déterminer la nouvelle rareté et le nouveau niveau
        var newRarity = rarity
        var newLevel = level + 1
        
        if level == 4 {
            newLevel = 0
            newRarity = rarity.nextRarity ?? rarity
        }
        
        // Calculer la valeur du nouveau canard et le coût
        var totalSellValue = getWeightedSellValue(from: ducksToFuse)
        if hasPrestigeUpgrade("p4_fusion_ing"), let maxVal = ducksToFuse.map({ $0.sellValue }).max() {
            totalSellValue += maxVal
        }
        
        if level == 4 {
            totalSellValue *= 2.0
        }
        
        // La taxe de fusion est de 5% du prix généré par le nouveau canard
        // Le nouveau canard aura le même sellValue que la somme (car customBasePrice annule le newRarity.multiplier)
        let futurePrice = totalSellValue
        let cost = futurePrice * 0.05 * taxMultiplier
        
        guard money >= cost else { return }
        money -= cost
        
        // Désassigner si nécessaire et supprimer
        for id in ids {
            if isDuckAssigned(duckId: id) {
                if let factoryIndex = factories.firstIndex(where: { $0.assignedDuckIds.contains(id) }) {
                    factories[factoryIndex].assignedDuckIds.removeAll { $0 == id }
                }
            }
            inventory.removeAll(where: { $0.id == id })
        }
        
        // Créer le nouveau canard
        // On divise par le multiplicateur de la nouvelle rareté pour que le sellValue final soit exactement totalSellValue
        let rawCustomBasePrice = (totalSellValue / newRarity.multiplier) * fusionValueMultiplier
        let newCustomBasePrice = rawCustomBasePrice
        var newDuck = createFusedDuck(from: ducksToFuse, newRarity: newRarity, newLevel: newLevel, newCustomBasePrice: newCustomBasePrice)
        
        // Spontaneous Mutation check
        if Double.random(in: 0...1) < (0.01 + prestigeSpontaneousMutationChance) {
            newDuck.mutation = DuckMutation.allCases.filter { $0 != .aucune }.randomElement() ?? .aucune
        }
        
        inventory.append(newDuck)
        totalFusionsDone += 1
        emitMissionEvent(.fuseCommonDuck)
        emitMissionEvent(.totalFusionCount)
        checkStoryAction("fusion_duck")
        saveGame()
    }
    
    // MARK: - Helpers Poids de Fusion
    private func getWeightedSellValue(from chunk: [Duck]) -> BigNumber {
        var total = BigNumber.zero
        for duck in chunk {
            let perks = duck.equippedPerkIds.compactMap { id in perksInventory.first(where: { $0.id == id }) }
            let weight = duck.fusionWeight(with: perks)
            total += duck.sellValue * Double(weight)
        }
        return total
    }
    
    private func getWeightedDisplaySellValue(from chunk: [Duck]) -> BigNumber {
        var total = BigNumber.zero
        for duck in chunk {
            let perks = duck.equippedPerkIds.compactMap { id in perksInventory.first(where: { $0.id == id }) }
            let weight = duck.fusionWeight(with: perks)
            total += displaySellValue(for: duck) * Double(weight)
        }
        return total
    }
    
    // MARK: - Tri Asynchrone (Pagination)
    func getSortedInventoryAsync(by sortOption: InventorySortOption, limit: Int = 100, filterAssigned: Bool = false) async -> [Duck] {
        let snapshot = self.inventory
        let assigned = filterAssigned ? Set(self.factories.flatMap { $0.assignedDuckIds }) : Set()
        
        return await Task.detached {
            var ducks = snapshot
            if filterAssigned {
                ducks = ducks.filter { !assigned.contains($0.id) }
            }
            
            ducks.sort { d1, d2 in
                switch sortOption {
                case .defaultSort:
                    if d1.rarity.multiplier != d2.rarity.multiplier { return d1.rarity.multiplier > d2.rarity.multiplier }
                    if d1.fusionLevel != d2.fusionLevel { return d1.fusionLevel > d2.fusionLevel }
                    return d1.sellValue > d2.sellValue
                case .recycleValueDesc:
                    return d1.recycleValue > d2.recycleValue
                case .recycleValueAsc:
                    return d1.recycleValue < d2.recycleValue
                case .sellValueAsc:
                    return d1.sellValue < d2.sellValue
                case .sellValueDesc:
                    return d1.sellValue > d2.sellValue
                case .rarity:
                    return d1.rarity.multiplier > d2.rarity.multiplier
                }
            }
            
            return Array(ducks.prefix(limit))
        }.value
    }
    
    // Auto-Fusion : Calcule les fusions possibles et le coût total
    func calculateBulkFusionCost(for rarity: DuckRarity) -> (fusionsCount: Int, totalCost: BigNumber) {
        let matchingDucks = inventory.filter { $0.rarity == rarity }
        let grouped = Dictionary(grouping: matchingDucks, by: { $0.fusionLevel })
        
        var fusionsCount = 0
        var totalCost = BigNumber.zero
        
        for (level, ducks) in grouped {
            for chunk in getFusionChunks(from: ducks) {
                var sumSellValue = getWeightedDisplaySellValue(from: chunk)
                if hasPrestigeUpgrade("p4_fusion_ing"), let maxVal = chunk.map({ displaySellValue(for: $0) }).max() {
                    sumSellValue += maxVal
                }
                var futureDisplayPrice = sumSellValue
                if level == 4 {
                    futureDisplayPrice *= 2.0
                }
                totalCost += futureDisplayPrice * taxMultiplier
                fusionsCount += 1
            }
        }
        
        return (fusionsCount, totalCost)
    }
    
    // Exécute l'auto-fusion classique (sans cascade)
    func executeBulkFusion(for rarity: DuckRarity) {
        let matchingDucks = inventory.filter { $0.rarity == rarity }
        let grouped = Dictionary(grouping: matchingDucks, by: { $0.fusionLevel })
        
        let costInfo = calculateBulkFusionCost(for: rarity)
        guard costInfo.fusionsCount > 0 else { return }
        guard money >= costInfo.totalCost else { return }
        
        money -= costInfo.totalCost
        
        var ducksToRemove = Set<UUID>()
        var ducksToAdd = [Duck]()
        let assignedIds = Set(factories.flatMap { $0.assignedDuckIds })
        
        for (level, ducks) in grouped {
            for chunk in getFusionChunks(from: ducks) {
                for duck in chunk {
                    ducksToRemove.insert(duck.id)
                    if assignedIds.contains(duck.id) {
                        if let factoryIndex = factories.firstIndex(where: { $0.assignedDuckIds.contains(duck.id) }) {
                            factories[factoryIndex].assignedDuckIds.removeAll { $0 == duck.id }
                        }
                    }
                }
                
                var futureRawPrice = getWeightedSellValue(from: chunk)
                if hasPrestigeUpgrade("p4_fusion_ing"), let maxRaw = chunk.map({ $0.sellValue }).max() {
                    futureRawPrice += maxRaw
                }
                
                if level == 4 {
                    futureRawPrice *= 2.0
                }
                
                var newRarity = rarity
                var newLevel = level + 1
                if level == 4 {
                    newLevel = 0
                    newRarity = rarity.nextRarity ?? rarity
                }
                
                let rawCustomBasePrice = (futureRawPrice / newRarity.multiplier) * fusionValueMultiplier
                
                ducksToAdd.append(createFusedDuck(from: chunk, newRarity: newRarity, newLevel: newLevel, newCustomBasePrice: rawCustomBasePrice))
            }
        }
        
        inventory.removeAll(where: { ducksToRemove.contains($0.id) })
        inventory.append(contentsOf: ducksToAdd)
        
        totalFusionsDone += ducksToAdd.count
        emitMissionEvent(.fuseCommonDuck, amount: BigNumber(ducksToAdd.count))
        emitMissionEvent(.totalFusionCount, amount: BigNumber(ducksToAdd.count))
        emitMissionEvent(.autoFusion)
        
        saveGame()
    }
    
    // MARK: - Mega Auto-Fusion
    
    private func runMegaFusion(simulateOnly: Bool) -> (fusionsCount: Int, totalCost: BigNumber) {
        var totalFusionsCount = 0
        var totalCost = BigNumber.zero
        
        var buckets: [DuckRarity: [Int: [Duck]]] = [:]
        for r in DuckRarity.allCases {
            buckets[r] = [0: [], 1: [], 2: [], 3: [], 4: []]
        }
        for duck in inventory {
            buckets[duck.rarity]?[duck.fusionLevel]?.append(duck)
        }
        
        var ducksToRemove = Set<UUID>()
        var ducksToAdd = [Duck]()
        let assignedIds = simulateOnly ? Set<UUID>() : Set(factories.flatMap { $0.assignedDuckIds })
        
        var didFuseInPass = true
        while didFuseInPass {
            didFuseInPass = false
            
            for rarity in DuckRarity.allCases {
                for level in 0...4 {
                    guard let ducks = buckets[rarity]?[level] else { continue }
                    if ducks.count < 3 { continue }
                    
                    let chunks = getFusionChunks(from: ducks)
                    if !chunks.isEmpty {
                        didFuseInPass = true
                    }
                    
                    for chunk in chunks {
                        var futureRawPrice = getWeightedSellValue(from: chunk)
                        var futureDisplayPrice = getWeightedDisplaySellValue(from: chunk)
                        
                        if hasPrestigeUpgrade("p4_fusion_ing") {
                            let maxRaw = chunk.map({ $0.sellValue }).max() ?? .zero
                            let maxDisplay = chunk.map({ displaySellValue(for: $0) }).max() ?? .zero
                            futureRawPrice += maxRaw
                            futureDisplayPrice += maxDisplay
                        }
                        
                        if level == 4 {
                            futureRawPrice *= 2.0
                            futureDisplayPrice *= 2.0
                        }
                        
                        totalCost += futureDisplayPrice * taxMultiplier // 100% tax for mega fusion
                        totalFusionsCount += 1
                        
                        var newRarity = rarity
                        var newLevel = level + 1
                        if level == 4 {
                            newLevel = 0
                            newRarity = rarity.nextRarity ?? rarity
                        }
                        
                        let rawCustomBasePrice = (futureRawPrice / newRarity.multiplier) * fusionValueMultiplier
                        let newCustomBasePrice = rawCustomBasePrice
                        
                        if !simulateOnly {
                            for duck in chunk {
                                ducksToRemove.insert(duck.id)
                                if assignedIds.contains(duck.id) {
                                    if let factoryIndex = factories.firstIndex(where: { $0.assignedDuckIds.contains(duck.id) }) {
                                        factories[factoryIndex].assignedDuckIds.removeAll { $0 == duck.id }
                                    }
                                }
                            }
                        }
                        
                        let newDuck = createFusedDuck(from: chunk, newRarity: newRarity, newLevel: newLevel, newCustomBasePrice: newCustomBasePrice)
                        
                        if !simulateOnly { ducksToAdd.append(newDuck) }
                        buckets[newRarity]?[newLevel]?.append(newDuck)
                    }
                    
                    // Retirer les canards fusionnés des buckets pour ne pas les refusionner à la prochaine passe
                    let numberOfFusions = chunks.count
                    let remainingDucks = Array(ducks[(numberOfFusions * 3)...])
                    buckets[rarity]?[level] = remainingDucks
                }
            }
        }
        
        if !simulateOnly {
            inventory.removeAll(where: { ducksToRemove.contains($0.id) })
            let finalDucksToAdd = ducksToAdd.filter { !ducksToRemove.contains($0.id) }
            inventory.append(contentsOf: finalDucksToAdd)
            totalFusionsDone += finalDucksToAdd.count
            saveGame()
        }
        
        return (totalFusionsCount, totalCost)
    }
    
    // Calcule le coût et le nombre de fusions possibles pour une Mega Auto-Fusion sur tout l'inventaire
    func calculateMegaFusionCost() -> (fusionsCount: Int, totalCost: BigNumber) {
        return runMegaFusion(simulateOnly: true)
    }
    
    // Exécute la Mega Auto-Fusion sur tout l'inventaire
    func executeMegaFusion() {
        let costInfo = runMegaFusion(simulateOnly: true)
        guard costInfo.fusionsCount > 0 else { return }
        guard money >= costInfo.totalCost else { return }
        
        money -= costInfo.totalCost
        _ = runMegaFusion(simulateOnly: false)
        emitMissionEvent(.megaFusion)
    }
    
    func upgradeDuckSize(id: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return }
        var duck = inventory[index]
        
        if let cost = duck.sizeUpgradeCost, mutationPoints >= cost, let nextSize = duck.size.next {
            mutationPoints -= cost
            duck.size = nextSize
            inventory[index] = duck
            emitMissionEvent(.upgradeDuckSize)
            checkStoryAction("upgrade_duck")
            saveGame()
        }
    }
    
    func upgradeDuckMutation(id: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return }
        var duck = inventory[index]
        
        if let cost = duck.mutationUpgradeCost, mutationPoints >= cost, let nextMutation = duck.mutation.next {
            mutationPoints -= cost
            duck.mutation = nextMutation
            inventory[index] = duck
            emitMissionEvent(.upgradeDuckMutation)
            saveGame()
        }
    }
    
    func upgradeDuckLevel(id: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return }
        var duck = inventory[index]
        
        if let cost = duck.levelUpgradeCost, money >= cost, duck.level < 100 {
            money -= cost
            duck.level += 1
            inventory[index] = duck
            emitMissionEvent(.reachDuckLevel, amount: BigNumber(1))
            saveGame()
        }
    }
    
    // MARK: - Factory Upgrades
    
    func upgradeFactoryLevel(factoryId: UUID, levels: Int) {
        guard let index = factories.firstIndex(where: { $0.id == factoryId }) else { return }
        
        // Sécurité
        if factories[index].level >= 100 { return }
        let amountToUpgrade = min(levels, 100 - factories[index].level)
        
        let factoryPerks = factories[index].equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
        let cost = factories[index].upgradeCost(levels: amountToUpgrade, factoryPerks: factoryPerks, baseDiscount: factoryCostDiscount)
        
        if money >= cost {
            money -= cost
            factories[index].level += amountToUpgrade
            emitMissionEvent(.upgradeFactory, amount: BigNumber(amountToUpgrade))
            emitMissionEvent(.reachDuckLevel, amount: BigNumber(amountToUpgrade))
            saveGame()
        }
    }
    
    func evolveFactory(factoryId: UUID) {
        guard let index = factories.firstIndex(where: { $0.id == factoryId }) else { return }
        
        // Doit être niveau 100 et évolution < 7
        if factories[index].level < 100 || factories[index].evolution >= 7 { return }
        
        // Bloqué par Prestige Upgrade si on n'a pas l'upgrade (uniquement pour la première évolution)
        if factories[index].evolution == 0 && !hasPrestigeUpgrade("p3_usine_evo") { return }
        
        let factoryPerks = factories[index].equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
        let cost = factories[index].evolveCost(factoryPerks: factoryPerks, baseDiscount: factoryCostDiscount)
        if money >= cost {
            money -= cost
            factories[index].evolution += 1
            factories[index].level = 1
            saveGame()
        }
    }
    
    // MARK: - Perks
    
    func equipPerk(_ perk: Perk, to targetId: UUID) {
        // Vérifier que le perk n'est pas déjà équipé quelque part
        let alreadyEquippedOnFactory = factories.contains { $0.equippedPerkIds.contains(perk.id) }
        let alreadyEquippedOnDuck = inventory.contains { $0.equippedPerkIds.contains(perk.id) }
        guard !alreadyEquippedOnFactory && !alreadyEquippedOnDuck else { return }
        
        // Checking if it's a factory
        if let index = factories.firstIndex(where: { $0.id == targetId }) {
            guard perk.type == .factory else { return } // Seuls les perks d'usine sur une usine
            
            let currentPerks = factories[index].equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
            let hasExtraSlot = currentPerks.contains(where: { $0.factoryExtraPerkSlot })
            let maxSlots = hasExtraSlot ? 2 : 1
            
            guard factories[index].equippedPerkIds.count < maxSlots else { return }
            
            factories[index].equippedPerkIds.append(perk.id)
            invalidateEarningsCache()
            emitMissionEvent(.assignPerk)
            checkStoryAction("equip_perk")
            saveGame()
            return
        }
        
        // Checking if it's a duck
        if let index = inventory.firstIndex(where: { $0.id == targetId }) {
            guard perk.type == .duck else { return } // Seuls les perks de canard sur un canard
            
            let currentPerks = inventory[index].equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
            let hasExtraSlot = currentPerks.contains(where: { $0.duckExtraPerkSlot })
            let maxSlots = hasExtraSlot ? 2 : 1
            
            guard inventory[index].equippedPerkIds.count < maxSlots else { return }
            
            inventory[index].equippedPerkIds.append(perk.id)
            emitMissionEvent(.assignPerk)
            checkStoryAction("equip_perk")
            saveGame()
            return
        }
    }
    
    func unequipPerk(_ perkId: UUID, from targetId: UUID) {
        // Retirer d'une usine
        if let index = factories.firstIndex(where: { $0.id == targetId }) {
            factories[index].equippedPerkIds.removeAll { $0 == perkId }
            
            // Si on retire un perk qui donnait un slot canard extra, retirer le 2ème canard
            let currentPerks = factories[index].equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
            let hasExtraDuckSlot = currentPerks.contains(where: { $0.factoryExtraDuckSlot })
            if !hasExtraDuckSlot && factories[index].assignedDuckIds.count > 1 {
                factories[index].assignedDuckIds = [factories[index].assignedDuckIds[0]]
            }
            
            // Si on retire un perk qui donnait un slot perk extra, retirer le 2ème perk
            let hasExtraPerkSlot = currentPerks.contains(where: { $0.factoryExtraPerkSlot })
            if !hasExtraPerkSlot && factories[index].equippedPerkIds.count > 1 {
                factories[index].equippedPerkIds = [factories[index].equippedPerkIds[0]]
            }
            
            invalidateEarningsCache()
            saveGame()
            return
        }
        
        // Retirer d'un canard
        if let index = inventory.firstIndex(where: { $0.id == targetId }) {
            inventory[index].equippedPerkIds.removeAll { $0 == perkId }
            
            // Si on retire un perk qui donnait un slot perk extra, retirer le 2ème perk
            let currentPerks = inventory[index].equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
            let hasExtraPerkSlot = currentPerks.contains(where: { $0.duckExtraPerkSlot })
            if !hasExtraPerkSlot && inventory[index].equippedPerkIds.count > 1 {
                inventory[index].equippedPerkIds = [inventory[index].equippedPerkIds[0]]
            }
            
            saveGame()
            return
        }
    }
    
    /// Calcule le nombre max de canards autorisés dans une usine
    func maxDuckSlots(for factory: DuckFactory) -> Int {
        let perks = factory.equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
        return perks.contains(where: { $0.factoryExtraDuckSlot }) ? 2 : 1
    }
    
    /// Calcule le nombre max de perks autorisés sur une usine
    func maxPerkSlots(for factory: DuckFactory) -> Int {
        let perks = factory.equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
        return perks.contains(where: { $0.factoryExtraPerkSlot }) ? 2 : 1
    }
    
    /// Calcule le nombre max de canards autorisés sur une usine
    func maxDucks(for factory: DuckFactory) -> Int {
        let perks = factory.equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
        return perks.contains(where: { $0.factoryExtraDuckSlot }) ? 2 : 1
    }
    
    /// Calcule le nombre max de perks autorisés sur un canard
    func maxDuckPerkSlots(for duck: Duck) -> Int {
        let perks = duck.equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
        return perks.contains(where: { $0.duckExtraPerkSlot }) ? 2 : 1
    }
    
    /// Retourne TOUS les perks pour un type donné (pour l'affichage)
    func perks(for type: PerkType) -> [Perk] {
        return perksInventory.filter { $0.type == type }
    }
    
    func isPerkEquippedAnywhere(_ id: UUID) -> Bool {
        if factories.contains(where: { $0.equippedPerkIds.contains(id) }) { return true }
        if inventory.contains(where: { $0.equippedPerkIds.contains(id) }) { return true }
        return false
    }
    
    // MARK: - Ritual
    
    func performRitual(on duckId: UUID, success: Bool, isGolden: Bool = false) {
        guard let index = inventory.firstIndex(where: { $0.id == duckId }) else { return }
        
        emitMissionEvent(.ritual)
        
        if success {
            if isGolden {
                inventory[index].goldenRitualSuccesses += 1
                inventory[index].ritualSuccesses += 1
            } else {
                // Succès
                inventory[index].ritualSuccesses += 1
            }
            emitMissionEvent(.upgradeDuckMutation)
            checkStoryAction("ritual_success")
        } else {
            // Unassign from factory if assigned
            if let factoryIndex = factories.firstIndex(where: { $0.assignedDuckIds.contains(duckId) }) {
                factories[factoryIndex].assignedDuckIds.removeAll { $0 == duckId }
            }
            inventory.remove(at: index)
        }
        saveGame()
    }
    
    
    private func createFusedDuck(from chunk: [Duck], newRarity: DuckRarity, newLevel: Int, newCustomBasePrice: BigNumber) -> Duck {
        let totalRecycleValue = chunk.reduce(into: BigNumber.zero) { $0 += $1.recycleValue }
        let retention = hasRecyclingExpertise ? 1.0 : 0.95
        let newCustomRecycleValue = totalRecycleValue * retention
        let maxRitualSuccesses = chunk.map { $0.ritualSuccesses }.max() ?? 0
        let maxGoldenRituals = chunk.map { $0.goldenRitualSuccesses }.max() ?? 0
        
        var newDuck = Duck(rarity: newRarity, size: .petit, mutation: .aucune)
        newDuck.fusionLevel = newLevel
        newDuck.customBasePrice = newCustomBasePrice
        newDuck.customRecycleValue = newCustomRecycleValue
        newDuck.ritualSuccesses = maxRitualSuccesses
        newDuck.goldenRitualSuccesses = maxGoldenRituals
        
        return newDuck
    }
}
