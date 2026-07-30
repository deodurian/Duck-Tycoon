import SwiftUI

extension GameManager {
    // MARK: - Traitement de l'Ajout de Canards
    /// `deferSave`: n'écrit pas la sauvegarde (utilisé par l'automatisation qui ajoute des canards
    /// NON assignés — sans impact sur les revenus/s — pour éviter un snapshot+invalidation par tick).
    func processNewDucks(_ ducks: [Duck], deferSave: Bool = false) {
        var ducksToKeep = [Duck]()
        var recycleYield: BigNumber = .zero
        
        let filterRarityRaw = UserDefaults.standard.string(forKey: "autoRecycleRarity") ?? "None"
        let isFilterActive = isUnlocked(.autoRecycleFilter) && filterRarityRaw != "None"
        
        let mutationLvl = spontaneousMutationLevel

        // CE QUI COÛTAIT : `mutationMultiplier` est une propriété calculée (arithmétique BigNumber +
        // plusieurs `hasPrestigeUpgrade`, donc autant de hachages de String) qui était réévaluée pour
        // CHAQUE canard auto-recyclé — jusqu'à des centaines par ouverture multiple.
        // POURQUOI LE RENDU RESTE IDENTIQUE : elle ne dépend que d'états (upgrades, niveau joueur) que
        // cette boucle ne modifie pas ; sa valeur est donc strictement constante ici. Elle n'est calculée
        // que si le filtre est actif, exactement comme avant où elle n'était lue que dans cette branche.
        let mutationMult: BigNumber = isFilterActive ? mutationMultiplier : .zero

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
                let yield = duck.recycleValue * mutationMult
                recycleYield += yield
            } else {
                ducksToKeep.append(duck)
            }
        }
        
        if recycleYield > .zero {
            addMutationPoints(recycleYield)
        }
        
        registerDuckDiscoveries(ducks)
        celebrateRareDucks(ducks)
        inventory.append(contentsOf: ducksToKeep)
        totalDucksFromCrates += ducks.count
        emitMissionEvent(.openCrates, amount: BigNumber(ducks.count))
        emitMissionEvent(.openWoodenCrate, amount: BigNumber(ducks.count))
        if ducks.count > 1 {
            emitMissionEvent(.bulkOpenCrates, amount: BigNumber(ducks.count))
        }
        
        checkStoryAction("open_wooden_crate")
        if !deferSave { saveGame() }
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
        // Calcul en BigNumber : pow(5.0, n) en Double débordait (→ ∞ → BigNumber(0) → usines gratuites) vers ~442 usines.
        return BigNumber(1000.0) * BigNumber.pow(BigNumber(5.0), factories.count - 1) * factoryCostDiscount
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

    /// Perks équipés sur un canard (via l'index O(1))
    func equippedPerks(of duck: Duck) -> [Perk] {
        return perks(for: duck.equippedPerkIds)
    }

    /// Détruit les perks « Recyclage+ » consommés lors du recyclage de ce canard (Perk détruit)
    private func consumeRecyclePerks(of duck: Duck) {
        let consumedIds = equippedPerks(of: duck).filter { $0.duckRecycleMutationMultiplier > 1.0 }.map { $0.id }
        if !consumedIds.isEmpty {
            perksInventory.removeAll { consumedIds.contains($0.id) }
            invalidatePerkCache()
        }
    }

    /// Variante « en masse » du recyclage des perks consommés.
    ///
    /// CE QUI COÛTAIT : appeler `consumeRecyclePerks(of:)` canard par canard faisait, pour chaque canard
    /// porteur d'un perk « Recyclage+ », un `removeAll` complet sur `perksInventory` PUIS une
    /// invalidation de l'index des perks — que le canard suivant devait aussitôt reconstruire
    /// (O(canards × perks) au lieu de O(canards + perks)).
    ///
    /// POURQUOI LE RENDU RESTE IDENTIQUE : l'ensemble final des perks retirés est exactement le même.
    /// Dans la version séquentielle, un perk déjà retiré n'était simplement plus proposé au canard
    /// suivant ; ici il est simplement inséré une seconde fois dans un Set, ce qui ne change rien.
    /// `perksInventory` conserve le même contenu et le même ordre, et l'index reconstruit est identique.
    private func consumeRecyclePerks(of ducks: [Duck]) {
        var consumedIds = Set<UUID>()
        for duck in ducks {
            for perk in equippedPerks(of: duck) where perk.duckRecycleMutationMultiplier > 1.0 {
                consumedIds.insert(perk.id)
            }
        }
        if !consumedIds.isEmpty {
            perksInventory.removeAll { consumedIds.contains($0.id) }
            invalidatePerkCache()
        }
    }

    func recycleDuck(id: UUID) {
        guard !isDuckAssigned(duckId: id),
              let index = inventory.firstIndex(where: { $0.id == id }) else { return }

        let duck = inventory[index]
        let perks = equippedPerks(of: duck)

        addMutationPoints(duck.calculateRecycleValue(with: perks, perkPowerFactor: perkPowerMultiplier) * mutationMultiplier)
        consumeRecyclePerks(of: duck)
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
        // CE QUI COÛTAIT : `perkPowerMultiplier` prend le verrou NSLock de RemoteConfig et refait un
        // hachage de String (`hasPrestigeUpgrade`) ; il était réévalué pour CHAQUE canard de la somme.
        // POURQUOI LE RENDU RESTE IDENTIQUE : rien dans cette boucle ne modifie les upgrades ou la
        // RemoteConfig, la valeur est donc strictement constante → mêmes facteurs, mêmes arrondis.
        let perkPower = perkPowerMultiplier
        return unassigned.reduce(into: .zero) { $0 += $1.calculateRecycleValue(with: equippedPerks(of: $1), perkPowerFactor: perkPower) }
    }

    func recycleAllUnassigned(rarity: DuckRarity) {
        let assignedIds = Set(factories.flatMap { $0.assignedDuckIds })
        let unassigned = inventory.filter { $0.rarity == rarity && !assignedIds.contains($0.id) }
        guard !unassigned.isEmpty else { return }

        // Idem : multiplicateur invariant sorti de la boucle (voir `potentialRecycleYield`).
        let perkPower = perkPowerMultiplier
        let sum = unassigned.reduce(into: BigNumber.zero) { $0 += $1.calculateRecycleValue(with: equippedPerks(of: $1), perkPowerFactor: perkPower) }
        let totalYield = sum * mutationMultiplier
        addMutationPoints(totalYield)

        // Une seule passe de suppression des perks consommés au lieu d'une par canard (voir la doc
        // de `consumeRecyclePerks(of ducks:)`) : mêmes perks retirés, même inventaire final.
        consumeRecyclePerks(of: unassigned)

        let unassignedIds = Set(unassigned.map { $0.id })
        inventory.removeAll(where: { unassignedIds.contains($0.id) })

        totalRecycledDucks += unassigned.count
        emitMissionEvent(.recycleDuck, amount: BigNumber(unassigned.count))
        emitMissionEvent(.totalRecycleCount, amount: BigNumber(unassigned.count))

        saveGame()
    }

    func recycleDucks(ids: Set<UUID>) {
        // CE QUI COÛTAIT : `perkPowerMultiplier` (verrou RemoteConfig + hachage de String) et
        // `mutationMultiplier` (BigNumber + plusieurs hachages de String) étaient recalculés pour
        // CHAQUE canard de la sélection.
        // POURQUOI LE RENDU RESTE IDENTIQUE : ni `addMutationPoints` ni la suppression de canards ne
        // modifient les upgrades / le niveau joueur dont ces valeurs dépendent → elles sont constantes
        // sur toute la boucle, donc mêmes montants et mêmes arrondis qu'avant.
        let perkPower = perkPowerMultiplier
        let mutationMult = mutationMultiplier

        // CE QUI COÛTAIT : pour CHAQUE id sélectionné, un `firstIndex` linéaire sur les usines PUIS
        // un autre sur l'inventaire — soit O(sélection × inventaire), ce qui explose sur un « tout
        // sélectionner » (5 000 × 10 000 comparaisons). En prime, `consumeRecyclePerks(of:)` était
        // appelé canard par canard : chaque appel refaisait un `removeAll` complet sur
        // `perksInventory` puis invalidait l'index des perks, que le canard suivant reconstruisait.
        //
        // POURQUOI LE RENDU RESTE IDENTIQUE : les deux index sont construits en « premier trouvé »,
        // exactement comme `firstIndex` ; les ids sont parcourus dans le même ordre, donc
        // `addMutationPoints` reçoit les mêmes montants dans le même ordre (mêmes arrondis cumulés).
        // Les index de l'inventaire restent valides puisque la suppression est désormais faite en une
        // seule passe à la fin, et l'ensemble final de canards retirés est le même. Pour les perks
        // consommés, c'est le raisonnement déjà documenté sur `consumeRecyclePerks(of ducks:)` : un
        // perk n'est équipé que sur une seule cible, donc en retirer un ne change jamais les perks
        // résolus pour un autre canard de la sélection.
        var factoryIndexByDuckId = [UUID: Int]()
        for (factoryIndex, factory) in factories.enumerated() {
            for duckId in factory.assignedDuckIds where factoryIndexByDuckId[duckId] == nil {
                factoryIndexByDuckId[duckId] = factoryIndex
            }
        }
        var inventoryIndexById = [UUID: Int]()
        inventoryIndexById.reserveCapacity(inventory.count)
        for (i, duck) in inventory.enumerated() where inventoryIndexById[duck.id] == nil {
            inventoryIndexById[duck.id] = i
        }

        var recycledDucks = [Duck]()

        for id in ids {
            // Si le canard est dans une usine, on le retire d'abord.
            if let factoryIndex = factoryIndexByDuckId[id] {
                factories[factoryIndex].assignedDuckIds.removeAll { $0 == id }
            }

            // Puis on le recycle
            if let index = inventoryIndexById[id] {
                let duck = inventory[index]
                addMutationPoints(duck.calculateRecycleValue(with: equippedPerks(of: duck), perkPowerFactor: perkPower) * mutationMult)
                recycledDucks.append(duck)
            }
        }

        if !recycledDucks.isEmpty {
            consumeRecyclePerks(of: recycledDucks)
            inventory.removeAll { ids.contains($0.id) }
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

        // Multiplicateur invariant sorti de la boucle (voir `potentialRecycleYield`) : même valeur pour
        // chaque canard, donc mêmes montants.
        let perkPower = perkPowerMultiplier
        let sum = toRecycle.reduce(into: BigNumber.zero) { $0 += $1.calculateRecycleValue(with: equippedPerks(of: $1), perkPowerFactor: perkPower) }
        let idsToRemove = Set(toRecycle.map { $0.id })

        // Une seule passe de suppression des perks consommés au lieu d'une par canard : mêmes perks
        // retirés, même inventaire final (voir la doc de `consumeRecyclePerks(of ducks:)`).
        consumeRecyclePerks(of: toRecycle)

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
        case .exotique: mutYield = 400000
        case .celeste: mutYield = 1600000
        case .primordiale: mutYield = 6400000
        }
        
        addMutationPoints(BigNumber(mutYield) * mutationMultiplier)
        perksInventory.remove(at: index)
        invalidatePerkCache()
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
        // CE QUI COÛTAIT : `sellValue` est une propriété CALCULÉE (BigNumber.pow, stats dynamiques…) et
        // elle était réévaluée à chaque comparaison, soit 2·n·log n fois par appel — et cette fonction
        // est appelée dans les boucles imbriquées de la méga-fusion.
        // POURQUOI LE RENDU RESTE IDENTIQUE : on pré-calcule la clé une fois par canard puis on trie les
        // index. Le comparateur renvoie exactement les mêmes booléens pour les mêmes paires et le tri
        // de la stdlib est stable, donc la permutation obtenue — et donc les chunks — sont les mêmes.
        let sellValues = ducks.map { $0.sellValue }
        let sortedDucks = ducks.indices.sorted { sellValues[$0] < sellValues[$1] }.map { ducks[$0] }
        var chunks = [[Duck]]()
        chunks.reserveCapacity(numberOfFusions)
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
        let rawCustomBasePrice = (totalSellValue / newRarity.multiplier)
        let newCustomBasePrice = rawCustomBasePrice
        var newDuck = createFusedDuck(from: ducksToFuse, newRarity: newRarity, newLevel: newLevel, newCustomBasePrice: newCustomBasePrice)
        
        // Spontaneous Mutation check
        if Double.random(in: 0...1) < 0.01 {
            newDuck.mutation = DuckMutation.allCases.filter { $0 != .aucune }.randomElement() ?? .aucune
        }
        
        inventory.append(newDuck)
        registerDuckDiscovery(newDuck)
        celebrateRareDucks([newDuck])
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
            // CE QUI COÛTAIT : un scan linéaire complet de `perksInventory` par perk équipé, répété
            // pour chaque canard de chaque chunk des (méga-)fusions.
            // POURQUOI LE RENDU RESTE IDENTIQUE : `equippedPerks(of:)` passe par l'index O(1)
            // `perks(for:)`, qui préserve l'ordre des ids et ignore les ids introuvables — il rend
            // donc exactement le même tableau que le `first(where:)` d'origine.
            let duckPerks = equippedPerks(of: duck)
            let weight = duck.fusionWeight(with: duckPerks)
            total += duck.sellValue * Double(weight)
        }
        return total
    }

    private func getWeightedDisplaySellValue(from chunk: [Duck]) -> BigNumber {
        // CE QUI COÛTAIT : `displaySellValue(for:)` relit `earningsMultiplier`,
        // `perkPowerMultiplier` et `collectionDuckBonusMultiplier` pour CHAQUE canard — chacun
        // prenant le verrou NSLock de RemoteConfig et refaisant des hachages de String — alors que
        // ces trois valeurs sont invariantes sur toute la boucle.
        // POURQUOI LE RENDU RESTE IDENTIQUE : on appelle la variante « boucle » déjà prévue pour ça,
        // dont le corps de calcul est le même (mêmes facteurs, même ordre de multiplication, donc
        // mêmes arrondis) ; seuls les multiplicateurs globaux sont lus une fois au lieu de n fois.
        let earningsMult = earningsMultiplier
        let perkPower = perkPowerMultiplier
        let collectionBonus = collectionDuckBonusMultiplier
        var total = BigNumber.zero
        for duck in chunk {
            // Index O(1) au lieu du scan linéaire de `perksInventory` (même tableau de perks).
            let duckPerks = equippedPerks(of: duck)
            let weight = duck.fusionWeight(with: duckPerks)
            total += displaySellValue(for: duck, earningsMult: earningsMult, perkPower: perkPower, collectionBonus: collectionBonus) * Double(weight)
        }
        return total
    }
    
    // MARK: - Tri Asynchrone (Pagination)
    func getSortedInventoryAsync(by sortOption: InventorySortOption, limit: Int = 100, filterAssigned: Bool = false) async -> [Duck] {
        let snapshot = self.inventory
        let assigned = filterAssigned ? Set(self.factories.flatMap { $0.assignedDuckIds }) : Set()
        
        return await Task.detached {
            let ducks: [Duck] = filterAssigned ? snapshot.filter { !assigned.contains($0.id) } : snapshot

            // CE QUI COÛTAIT : `sellValue` / `recycleValue` sont des propriétés CALCULÉES
            // (getDynamicStats + plusieurs BigNumber.pow) et elles étaient réévaluées à CHAQUE
            // comparaison du tri, soit ~2·n·log n fois par appel (≈70 000 recalculs pour 3 000
            // canards) — et ce tri est relancé à chaque canard généré, depuis l'inventaire, la
            // fusion, les usines et le rituel. Le `switch sortOption` était lui aussi réévalué
            // à chaque comparaison.
            //
            // POURQUOI LE RENDU RESTE IDENTIQUE : « decorate-sort-undecorate ». Ces propriétés
            // sont pures (elles ne dépendent que des champs du canard, que rien ne modifie ici),
            // donc la clé pré-calculée vaut exactement ce que le comparateur lisait. On trie des
            // index avec un comparateur qui renvoie les MÊMES booléens pour les mêmes paires, y
            // compris les départages du cas `.defaultSort` (rareté, puis niveau de fusion, puis
            // sellValue) ; le tri de la stdlib étant déterministe, la permutation obtenue est la
            // même, donc la liste renvoyée est identique élément pour élément.
            let order: [Int]
            switch sortOption {
            case .defaultSort:
                let keys: [(rarity: Double, fusion: Int, sell: BigNumber)] = ducks.map {
                    (rarity: $0.rarity.multiplier, fusion: $0.fusionLevel, sell: $0.sellValue)
                }
                order = ducks.indices.sorted { i, j in
                    if keys[i].rarity != keys[j].rarity { return keys[i].rarity > keys[j].rarity }
                    if keys[i].fusion != keys[j].fusion { return keys[i].fusion > keys[j].fusion }
                    return keys[i].sell > keys[j].sell
                }
            case .recycleValueDesc:
                let keys = ducks.map { $0.recycleValue }
                order = ducks.indices.sorted { keys[$0] > keys[$1] }
            case .recycleValueAsc:
                let keys = ducks.map { $0.recycleValue }
                order = ducks.indices.sorted { keys[$0] < keys[$1] }
            case .sellValueDesc:
                let keys = ducks.map { $0.sellValue }
                order = ducks.indices.sorted { keys[$0] > keys[$1] }
            case .rarity:
                let keys = ducks.map { $0.rarity.multiplier }
                order = ducks.indices.sorted { keys[$0] > keys[$1] }
            }

            // On ne matérialise que la page demandée : `order` est la permutation triée, donc
            // ses `limit` premiers index désignent exactement les `limit` premiers canards du
            // tableau trié (même contenu que `Array(ducks.prefix(limit))` d'avant).
            return order.prefix(limit).map { ducks[$0] }
        }.value
    }
    
    // Auto-Fusion : Calcule les fusions possibles et le coût total
    func calculateBulkFusionCost(for rarity: DuckRarity) -> (fusionsCount: Int, totalCost: BigNumber) {
        let matchingDucks = inventory.filter { $0.rarity == rarity }
        let grouped = Dictionary(grouping: matchingDucks, by: { $0.fusionLevel })
        
        var fusionsCount = 0
        var totalCost = BigNumber.zero

        // CE QUI COÛTAIT : `hasPrestigeUpgrade` (hachage de String dans un Set) et `taxMultiplier`
        // (lecture de dictionnaire + `hasPrestigeUpgrade`) étaient réévalués pour CHAQUE chunk,
        // et les trois multiplicateurs globaux de `displaySellValue(for:)` pour CHAQUE canard
        // (verrou NSLock de RemoteConfig + hachages de String à chaque fois).
        // POURQUOI LE RENDU RESTE IDENTIQUE : cette fonction ne fait que lire — elle ne modifie ni
        // les upgrades, ni le prestige, ni le niveau joueur — donc ces valeurs sont strictement
        // constantes sur toute la boucle : mêmes facteurs, même ordre de multiplication, mêmes
        // arrondis, donc exactement le même coût affiché.
        let hasFusionIngenierie = hasPrestigeUpgrade("p4_fusion_ing")
        let tax = taxMultiplier
        let earningsMult = earningsMultiplier
        let perkPower = perkPowerMultiplier
        let collectionBonus = collectionDuckBonusMultiplier

        for (level, ducks) in grouped {
            for chunk in getFusionChunks(from: ducks) {
                var sumSellValue = getWeightedDisplaySellValue(from: chunk)
                if hasFusionIngenierie,
                   let maxVal = chunk.map({ displaySellValue(for: $0, earningsMult: earningsMult, perkPower: perkPower, collectionBonus: collectionBonus) }).max() {
                    sumSellValue += maxVal
                }
                var futureDisplayPrice = sumSellValue
                if level == 4 {
                    futureDisplayPrice *= 2.0
                }
                totalCost += futureDisplayPrice * tax
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

        // CE QUI COÛTAIT : `hasPrestigeUpgrade` (hachage de String) était réévalué pour chaque chunk.
        // POURQUOI LE RENDU RESTE IDENTIQUE : rien dans cette boucle ne modifie
        // `purchasedPrestigeUpgrades`, la valeur est donc constante — même branche prise à chaque tour.
        let hasFusionIngenierie = hasPrestigeUpgrade("p4_fusion_ing")

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
                if hasFusionIngenierie, let maxRaw = chunk.map({ $0.sellValue }).max() {
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
                
                let rawCustomBasePrice = (futureRawPrice / newRarity.multiplier)
                
                ducksToAdd.append(createFusedDuck(from: chunk, newRarity: newRarity, newLevel: newLevel, newCustomBasePrice: rawCustomBasePrice))
            }
        }
        
        inventory.removeAll(where: { ducksToRemove.contains($0.id) })
        inventory.append(contentsOf: ducksToAdd)
        registerDuckDiscoveries(ducksToAdd)
        celebrateRareDucks(ducksToAdd)

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

        // CE QUI COÛTAIT : `hasPrestigeUpgrade` (hachage de String), `taxMultiplier` (dictionnaire +
        // `hasPrestigeUpgrade`) et les trois multiplicateurs globaux de `displaySellValue(for:)`
        // (verrou NSLock de RemoteConfig + hachages de String) étaient réévalués à CHAQUE chunk /
        // CHAQUE canard, sur une boucle en cascade qui peut traiter tout l'inventaire plusieurs fois.
        // POURQUOI LE RENDU RESTE IDENTIQUE : la méga-fusion ne touche ni aux upgrades, ni au
        // prestige, ni au niveau joueur — ces valeurs sont donc constantes du début à la fin. On
        // passe par la variante « boucle » de `displaySellValue`, dont le corps de calcul est le
        // même (mêmes facteurs, même ordre, mêmes arrondis).
        let hasFusionIngenierie = hasPrestigeUpgrade("p4_fusion_ing")
        let tax = taxMultiplier
        let earningsMult = earningsMultiplier
        let perkPower = perkPowerMultiplier
        let collectionBonus = collectionDuckBonusMultiplier

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
                        
                        if hasFusionIngenierie {
                            let maxRaw = chunk.map({ $0.sellValue }).max() ?? .zero
                            let maxDisplay = chunk.map({ displaySellValue(for: $0, earningsMult: earningsMult, perkPower: perkPower, collectionBonus: collectionBonus) }).max() ?? .zero
                            futureRawPrice += maxRaw
                            futureDisplayPrice += maxDisplay
                        }

                        if level == 4 {
                            futureRawPrice *= 2.0
                            futureDisplayPrice *= 2.0
                        }

                        totalCost += futureDisplayPrice * tax // 100% tax for mega fusion
                        totalFusionsCount += 1
                        
                        var newRarity = rarity
                        var newLevel = level + 1
                        if level == 4 {
                            newLevel = 0
                            newRarity = rarity.nextRarity ?? rarity
                        }
                        
                        let rawCustomBasePrice = (futureRawPrice / newRarity.multiplier)
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
            registerDuckDiscoveries(finalDucksToAdd)
            celebrateRareDucks(finalDucksToAdd)
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
        // CE QUI COÛTAIT : un scan linéaire de tout `perksInventory` par perk équipé.
        // POURQUOI LE RENDU RESTE IDENTIQUE : `equippedPerks(of:)` s'appuie sur l'index O(1)
        // `perks(for:)`, qui conserve l'ordre des ids et ignore les ids introuvables → même tableau.
        let duckPerks = equippedPerks(of: duck)

        if let cost = duck.sizeUpgradeCost(with: duckPerks), mutationPoints >= cost, let nextSize = duck.size.next {
            mutationPoints -= cost
            duck.size = nextSize
            inventory[index] = duck
            registerDuckDiscovery(duck)
            emitMissionEvent(.upgradeDuckSize)
            checkStoryAction("upgrade_duck")
            saveGame()
        }
    }
    
    func upgradeDuckMutation(id: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return }
        var duck = inventory[index]
        // Index O(1) au lieu du scan linéaire de `perksInventory` (même tableau de perks).
        let duckPerks = equippedPerks(of: duck)

        if let cost = duck.mutationUpgradeCost(with: duckPerks), mutationPoints >= cost, let nextMutation = duck.mutation.next {
            mutationPoints -= cost
            duck.mutation = nextMutation
            inventory[index] = duck
            emitMissionEvent(.upgradeDuckMutation)
            saveGame()
        }
    }
    
    func getDynamicStats(for duck: Duck) -> (level: Int, size: DuckSize, mutation: DuckMutation) {
        let stats = duck.getDynamicStats(with: equippedPerks(of: duck))
        return (stats.level, stats.size, stats.mutation)
    }
    
    func upgradeDuckLevel(id: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return }
        var duck = inventory[index]
        // Index O(1) au lieu du scan linéaire de `perksInventory` (même tableau de perks).
        let duckPerks = equippedPerks(of: duck)

        if let cost = duck.levelUpgradeCost(with: duckPerks), money >= cost, duck.level < 100 {
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
        
        // CE QUI COÛTAIT : un scan linéaire de tout `perksInventory` par perk équipé.
        // POURQUOI LE RENDU RESTE IDENTIQUE : `perks(for:)` est l'index O(1) déjà en place ; il
        // préserve l'ordre des ids et ignore les ids introuvables → tableau strictement identique.
        let factoryPerks = perks(for: factories[index].equippedPerkIds)
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
        
        // Index O(1) au lieu du scan linéaire de `perksInventory` (même tableau de perks).
        let factoryPerks = perks(for: factories[index].equippedPerkIds)
        let cost = factories[index].evolveCost(factoryPerks: factoryPerks, baseDiscount: factoryEvolutionCostDiscount)
        if money >= cost {
            money -= cost
            factories[index].evolution += 1
            // "Double Évolution": la 1ère évolution offre directement la 2ème gratuitement
            if factories[index].evolution == 1 && hasPrestigeUpgrade("p6_usine_evo2") {
                factories[index].evolution = 2
            }
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
            
            let maxSlots = maxPerkSlots(for: factories[index])

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
            
            let maxSlots = maxDuckPerkSlots(for: inventory[index])

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
            // Index O(1) au lieu du scan linéaire de `perksInventory` (même tableau de perks :
            // `perks(for:)` préserve l'ordre et ignore les ids introuvables).
            let currentPerks = perks(for: factories[index].equippedPerkIds)
            let hasExtraDuckSlot = currentPerks.contains(where: { $0.factoryExtraDuckSlot })
            if !hasExtraDuckSlot && factories[index].assignedDuckIds.count > 1 {
                factories[index].assignedDuckIds = [factories[index].assignedDuckIds[0]]
            }
            
            // Si on retire un perk qui donnait un slot perk extra, retirer les perks en surplus
            let hasExtraPerkSlot = currentPerks.contains(where: { $0.factoryExtraPerkSlot })
            let allowedSlots = hasExtraPerkSlot ? basePerkSlots + 1 : basePerkSlots
            if factories[index].equippedPerkIds.count > allowedSlots {
                factories[index].equippedPerkIds = Array(factories[index].equippedPerkIds.prefix(allowedSlots))
            }

            invalidateEarningsCache()
            saveGame()
            return
        }
        
        // Retirer d'un canard
        if let index = inventory.firstIndex(where: { $0.id == targetId }) {
            inventory[index].equippedPerkIds.removeAll { $0 == perkId }
            
            // Si on retire un perk qui donnait un slot perk extra, retirer les perks en surplus
            // Index O(1) au lieu du scan linéaire de `perksInventory` (même tableau de perks).
            let currentPerks = perks(for: inventory[index].equippedPerkIds)
            let hasExtraPerkSlot = currentPerks.contains(where: { $0.duckExtraPerkSlot })
            let allowedSlots = hasExtraPerkSlot ? basePerkSlots + 1 : basePerkSlots
            if inventory[index].equippedPerkIds.count > allowedSlots {
                inventory[index].equippedPerkIds = Array(inventory[index].equippedPerkIds.prefix(allowedSlots))
            }

            saveGame()
            return
        }
    }
    
    // CE QUI COÛTAIT : ces quatre helpers sont appelés par les vues (une fois par usine / par canard
    // affiché, donc à chaque réévaluation de la liste) et chacun faisait un scan linéaire complet de
    // `perksInventory` pour CHAQUE perk équipé.
    // POURQUOI LE RENDU RESTE IDENTIQUE : `perks(for:)` / `equippedPerks(of:)` s'appuient sur l'index
    // O(1) déjà en place, qui préserve l'ordre des ids et ignore les ids introuvables : le tableau de
    // perks est le même, donc le `contains(where:)` et la valeur renvoyée sont les mêmes.

    /// Calcule le nombre max de canards autorisés dans une usine
    func maxDuckSlots(for factory: DuckFactory) -> Int {
        return perks(for: factory.equippedPerkIds).contains(where: { $0.factoryExtraDuckSlot }) ? 2 : 1
    }

    /// Calcule le nombre max de perks autorisés sur une usine
    func maxPerkSlots(for factory: DuckFactory) -> Int {
        return perks(for: factory.equippedPerkIds).contains(where: { $0.factoryExtraPerkSlot }) ? basePerkSlots + 1 : basePerkSlots
    }

    /// Calcule le nombre max de canards autorisés sur une usine
    func maxDucks(for factory: DuckFactory) -> Int {
        return perks(for: factory.equippedPerkIds).contains(where: { $0.factoryExtraDuckSlot }) ? 2 : 1
    }

    /// Calcule le nombre max de perks autorisés sur un canard
    func maxDuckPerkSlots(for duck: Duck) -> Int {
        return equippedPerks(of: duck).contains(where: { $0.duckExtraPerkSlot }) ? basePerkSlots + 1 : basePerkSlots
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
    
    func destroyDuck(id: UUID) {
        if let factoryIndex = factories.firstIndex(where: { $0.assignedDuckIds.contains(id) }) {
            factories[factoryIndex].assignedDuckIds.removeAll { $0 == id }
        }
        inventory.removeAll { $0.id == id }
        saveGame()
    }
    
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
            inventory[index].ritualCount += 1  // soft cap : durcit le prochain rituel de ce canard
            emitMissionEvent(.upgradeDuckMutation)
            checkStoryAction("ritual_success")
            saveGame()
        } else {
            // L'échec est géré par la vue pour permettre le sauvetage publicitaire
        }
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
