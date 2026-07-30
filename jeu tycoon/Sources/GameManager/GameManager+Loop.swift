import SwiftUI

extension GameManager {
    // MARK: - Core Loop
    

    
    func setGamePaused(_ paused: Bool) {
        if isGamePaused == paused { return }
        isGamePaused = paused
        if paused {
            pauseStartDate = Date()
        } else {
            if let start = pauseStartDate {
                let seconds = Date().timeIntervalSince(start)
                let earnings = (cachedEarningsPerSecond ?? .zero) * seconds
                let mutations = (cachedMutationsPerSecond ?? .zero) * seconds
                money += earnings
                mutationPoints += mutations
                if earnings > .zero {
                    evaluateAffordableCrates(reset: false)
                }
                processOfflineAutomation(secondsPassed: seconds, earningsPerSecond: (cachedEarningsPerSecond ?? .zero).doubleValue)
            }
            pauseStartDate = nil
        }
    }
    
    func startGameLoop() {
        lastTickTime = Date()
        timer?.invalidate()
        // Un tick toutes les 1.0 seconde
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Sans tolérance, le noyau doit programmer un réveil EXACT chaque seconde et ne peut pas
        // le regrouper avec les autres réveils du système : c'est le pire cas pour la batterie.
        // 0,2 s de marge est invisible pour le joueur (le tick utilise le temps réel écoulé).
        timer?.tolerance = 0.2
    }

    

    
    func getAssignedDuck(id: UUID?) -> Duck? {
        guard let id = id else { return nil }
        if !isAssignedDucksCacheValid {
            rebuildAssignedDucksCache()
        }
        return assignedDucksCache[id]
    }
    
    private func rebuildAssignedDucksCache() {
        let assignedDuckIds = Set(factories.flatMap { $0.assignedDuckIds })
        assignedDucksCache.removeAll(keepingCapacity: true)
        for duck in inventory where assignedDuckIds.contains(duck.id) {
            assignedDucksCache[duck.id] = duck
        }
        isAssignedDucksCacheValid = true
    }
    
    func invalidateEarningsCache() {
        cachedEarningsPerSecond = nil
        cachedMutationsPerSecond = nil
        isAssignedDucksCacheValid = false
    }

    /// Résout des perks par id via un index O(1) (reconstruit paresseusement). Préserve l'ordre
    /// et la sémantique « ignore les ids introuvables » du scan linéaire d'origine.
    func perks(for ids: [UUID]) -> [Perk] {
        guard !ids.isEmpty else { return [] }
        if !isPerkCacheValid { rebuildPerkCache() }
        return ids.compactMap { perkById[$0] }
    }

    func invalidatePerkCache() {
        isPerkCacheValid = false
    }

    private func rebuildPerkCache() {
        perkById.removeAll(keepingCapacity: true)
        for perk in perksInventory { perkById[perk.id] = perk }
        isPerkCacheValid = true
    }
    
    private func tick() {
        if isGamePaused {
            lastTickTime = Date()
            return
        }
        
        let now = Date()
        let deltaTime: Double
        if let last = lastTickTime {
            deltaTime = now.timeIntervalSince(last)
        } else {
            deltaTime = 1.0
        }
        
        let tickCount = Int(now.timeIntervalSince1970)
        
        // Auto-save toutes les 60 secondes environ
        if tickCount % 60 == 0 && lastTickTime?.timeIntervalSince1970 != now.timeIntervalSince1970 {
            saveGame()
            checkDailyMissionsReset()
        }
        
        lastTickTime = now
        
        if cachedEarningsPerSecond == nil || cachedMutationsPerSecond == nil {
            var earningsThisSecond: BigNumber = .zero
            var mutationsThisSecond: BigNumber = .zero

            if !isAssignedDucksCacheValid {
                rebuildAssignedDucksCache()
            }

            // Perks résolus UNE seule fois par usine (index O(1)) et réutilisés pour le bonus global
            // et les calculs de revenus (au lieu de deux scans linéaires par usine).
            let perksByFactory = factories.map { perks(for: $0.equippedPerkIds) }
            var globalFactoryBonusOthers = 0.0
            for fp in perksByFactory {
                for perk in fp { globalFactoryBonusOthers += perk.factoryBonusOthers }
            }

            // Multiplicateurs joueur invariants sur la passe : calculés une fois.
            // `earningsMult` et `collectionBonus` s'ajoutent ici pour la même raison que `ppm` :
            // `displaySellValue(for:)` les relisait pour CHAQUE canard assigné, et chacun prend le
            // verrou NSLock de RemoteConfig plus plusieurs hachages de String. Valeur identique,
            // simplement calculée une fois par passe au lieu d'une fois par canard.
            let ppm = perkPowerMultiplier
            let mutMult = mutationMultiplier
            let earningsMult = earningsMultiplier
            let collectionBonus = collectionDuckBonusMultiplier

            for (i, factory) in factories.enumerated() {
                if !factory.assignedDuckIds.isEmpty {
                    let ducks = factory.assignedDuckIds.compactMap { assignedDucksCache[$0] }
                    let displayValues = ducks.map {
                        displaySellValue(for: $0, earningsMult: earningsMult, perkPower: ppm, collectionBonus: collectionBonus)
                    }
                    let factoryPerks = perksByFactory[i]
                    earningsThisSecond += factory.calculateEarningsPerSecond(assignedDucks: ducks, duckDisplayValues: displayValues, factoryPerks: factoryPerks, globalPerkBonus: globalFactoryBonusOthers, perkPowerFactor: ppm)
                    mutationsThisSecond += factory.calculateMutationsPerSecond(assignedDucks: ducks, globalBonus: mutMult, factoryPerks: factoryPerks)
                }
            }

            cachedEarningsPerSecond = earningsThisSecond
            cachedMutationsPerSecond = mutationsThisSecond
        }
        
        if let eps = cachedEarningsPerSecond {
            money += eps * deltaTime
        }
        
        if let mps = cachedMutationsPerSecond {
            mutationPoints += mps * deltaTime
        }
        
        // Mettre à jour l'état des boutons de boutique s'il y a eu des gains
        if (cachedEarningsPerSecond ?? .zero) > .zero {
            evaluateAffordableCrates(reset: false)
        }
        
        // Gain d'XP Passif
        if let eps = cachedEarningsPerSecond, eps > .zero {
            let xpToGain = PlayerLevelSystem.calculatePassiveXP(earningsPerSecond: eps)
            let rawXp = Double(xpToGain) * deltaTime
            let intXp = Int(rawXp)
            playerXP += intXp
            xpAccumulator += rawXp - Double(intXp)
            if xpAccumulator >= 1.0 {
                playerXP += Int(xpAccumulator)
                xpAccumulator -= Double(Int(xpAccumulator))
            }
            checkLevelUp()
        }
        
        processOnlineAutomation(deltaTime: deltaTime)

        // Ces scans passifs (revenus/ADN atteignant un palier) n'ont pas besoin d'être vérifiés
        // chaque seconde — les progrès liés aux actions passent déjà par emitMissionEvent.
        // Toutes les ~5 s : imperceptible pour le joueur, O(missions)+O(quêtes) divisé par 5.
        if tickCount % 5 == 0 {
            verifyStateMissions()
            checkSideQuestToasts()
        }
    }
    
    // MARK: - Automatisation
    private func processOnlineAutomation(deltaTime: Double) {
        // Auto-Ouvrier : ajoute des canards NON assignés (sans impact sur les revenus/s).
        // On calcule le bonus de chance UNE fois, on saute la sauvegarde par canard (deferSave)
        // et on s'arrête dès qu'un achat échoue (l'argent ne remonte pas dans ce tick).
        if let interval = autoCrateInterval, let targetId = autoCrateTargetId, let crate = Crate.allCrates.first(where: { $0.type.rawValue == targetId }) {
            autoCrateAccumulator += deltaTime
            if autoCrateAccumulator >= interval {
                while autoCrateAccumulator >= interval {
                    autoCrateAccumulator -= interval
                    if !silentBuyCrateAutomation(crate: crate, deferSave: true) {
                        autoCrateAccumulator = 0
                        break
                    }
                }
            }
        }
        
        // Auto-Usine
        for (i, factory) in factories.enumerated() {
            if let interval = autoFactoryInterval(for: factory.id) {
                let currentAcc = autoFactoryAccumulators[factory.id] ?? 0.0
                let newAcc = currentAcc + deltaTime
                
                if newAcc >= interval {
                    let cycles = Int(newAcc / interval)
                    autoFactoryAccumulators[factory.id] = newAcc - (Double(cycles) * interval)
                    
                    let _ = executeAutoFactoryUpgrade(factoryIndex: i, maxCycles: cycles)
                } else {
                    autoFactoryAccumulators[factory.id] = newAcc
                }
            }
        }
    }
    
    func processOfflineAutomation(secondsPassed: Double, earningsPerSecond: Double) {
        // Pour le hors ligne, on suppose un gain d'argent lisse sur la période.
        // C'est une simulation simplifiée pour éviter de freezer le téléphone avec une boucle par seconde.
        
        // 1. Auto-Ouvrier
        if let interval = autoCrateInterval, let targetId = autoCrateTargetId, let crate = Crate.allCrates.first(where: { $0.type.rawValue == targetId }) {
            let totalCycles = Int(secondsPassed / interval)
            if totalCycles > 0 {
                // On essaie d'en acheter le maximum possible avec l'argent qu'on avait + l'argent gagné.
                // En vrai, on va simplifier : on simule l'achat un par un.
                var moneyPool = money // On utilise l'argent (qui inclut déjà les gains hors-ligne calculés juste avant)
                var mutationPool = mutationPoints
                var ducksToGenerate = 0
                
                if let moneyCost = crate.costMoney {
                    // Calcul mathématique rapide au lieu d'une boucle
                    let affordable = (moneyPool / moneyCost).intValue
                    ducksToGenerate = min(totalCycles, affordable)
                    moneyPool -= moneyCost * BigNumber(Double(ducksToGenerate))
                } else if let mutCost = crate.costMutationPoints {
                    let affordable = (mutationPool / mutCost).intValue
                    ducksToGenerate = min(totalCycles, affordable)
                    mutationPool -= mutCost * BigNumber(Double(ducksToGenerate))
                }
                
                money = moneyPool
                mutationPoints = mutationPool
                
                // Générer les canards (seulement ceux qui rentreront dans l'inventaire)
                if ducksToGenerate > 0 {
                    let hasGenes = isUnlocked(.genesCroissants)
                    var remainingToGenerate = ducksToGenerate
                    while remainingToGenerate > 0 {
                        let spaceLeft = maxInventoryCapacity - inventory.count
                        if spaceLeft <= 0 { break }

                        let batchSize = min(remainingToGenerate, spaceLeft)
                        var generatedDucks = [Duck]()
                        generatedDucks.reserveCapacity(batchSize)

                        for _ in 0..<batchSize {
                            let rarity = crate.probabilities.rollRarity()
                            let size = DuckSize.rollRandom(genesCroissants: hasGenes)
                            let mutation = DuckMutation.rollRandom()
                            generatedDucks.append(Duck(rarity: rarity, size: size, mutation: mutation))
                        }
                        
                        processNewDucks(generatedDucks)
                        remainingToGenerate -= batchSize
                    }
                }
            }
        }
        
        // 2. Auto-Usine
        for (i, factory) in factories.enumerated() {
            if let interval = autoFactoryInterval(for: factory.id) {
                let totalCycles = Int(secondsPassed / interval)
                let _ = executeAutoFactoryUpgrade(factoryIndex: i, maxCycles: totalCycles)
            }
        }
    }
    
    private func executeAutoFactoryUpgrade(factoryIndex: Int, maxCycles: Int) -> BigNumber {
        var spent = BigNumber.zero
        // Les perks de l'usine sont invariants sur les cycles : résolus une seule fois.
        let factoryPerks = perks(for: factories[factoryIndex].equippedPerkIds)
        for _ in 0..<maxCycles {
            if factories[factoryIndex].level >= 100 { break }
            let upgradeCost = factories[factoryIndex].upgradeCost(levels: 1, factoryPerks: factoryPerks, baseDiscount: factoryCostDiscount)
            if money >= upgradeCost {
                money -= upgradeCost
                spent += upgradeCost
                factories[factoryIndex].level += 1
            } else {
                break
            }
        }
        if spent > .zero { invalidateEarningsCache() }
        return spent
    }
    
    private func silentBuyCrateAutomation(crate: Crate, deferSave: Bool = false) -> Bool {
        if inventory.count >= maxInventoryCapacity { return false } // Excédent jeté ignoré pour l'automatisation en ligne pour ne pas gaspiller d'argent sans avertissement

        if let moneyCost = crate.costMoney, money >= moneyCost {
            money -= moneyCost
        } else if let mutCost = crate.costMutationPoints, mutationPoints >= mutCost {
            mutationPoints -= mutCost
        } else {
            return false
        }

        let hasGenes = isUnlocked(.genesCroissants)
        let rarity = crate.probabilities.rollRarity()
        let size = DuckSize.rollRandom(genesCroissants: hasGenes)
        let mutation = DuckMutation.rollRandom()
        let duck = Duck(rarity: rarity, size: size, mutation: mutation)

        processNewDucks([duck], deferSave: deferSave)
        return true
    }
    
}
