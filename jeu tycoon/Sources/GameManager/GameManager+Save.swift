import SwiftUI

extension GameManager {
    // MARK: - Sauvegarde Professionnelle (JSON Local)
    
    func loadGame() {
        let url = saveFileURL()
        let backupUrl = url.appendingPathExtension("bak")
        
        var dataToLoad: Data? = nil
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                dataToLoad = try Data(contentsOf: url)
                // Test decode to ensure it's not corrupted
                _ = try JSONDecoder().decode(GameState.self, from: dataToLoad!)
            } catch {
                dataToLoad = nil
            }
        }
        
        if dataToLoad == nil && FileManager.default.fileExists(atPath: backupUrl.path) {
            do {
                dataToLoad = try Data(contentsOf: backupUrl)
            } catch {
                // Silently ignore corrupted backup
            }
        }
        
        guard let data = dataToLoad else { return }
        
        do {
            let loadedState = try JSONDecoder().decode(GameState.self, from: data)
            
            money = loadedState.money
            mutationPoints = loadedState.mutationPoints
            inventory = loadedState.inventory
            factories = loadedState.factories
            lastSaveDate = loadedState.lastSaveDate
            purchasedUpgrades = loadedState.purchasedUpgrades
            upgradeLevels = loadedState.upgradeLevels
            autoCrateTargetId = loadedState.autoCrateTargetId
            autoFactoryLevels = loadedState.autoFactoryLevels
            
            // Migration pour les étoiles
            currentStars = loadedState.currentStars
            totalStars = loadedState.totalStars
            spentStars = loadedState.spentStars
            unspentStars = loadedState.unspentStars
            purchasedPrestigeUpgrades = loadedState.purchasedPrestigeUpgrades
            
            gems = loadedState.gems
            
            playerLevel = loadedState.playerLevel
            playerXP = loadedState.playerXP
            missions = loadedState.missions
            perksInventory = loadedState.perksInventory
            
            // Filet de sécurité si la sauvegarde a été créée vide juste avant
            if money < BigNumber(100) && inventory.isEmpty {
                money = BigNumber(200.0)
            }
            
            invalidateEarningsCache()
            calculateOfflineEarnings()
            evaluateAffordableCrates(reset: true)
        } catch {
            // Silently ignore corrupted file or missing state
        }
    }
    
    private func calculateOfflineEarnings() {
        let secondsOffline = Date().timeIntervalSince(lastSaveDate)
        guard secondsOffline > 60 else { return } // On ignore si c'est moins d'une minute
        
        var earningsPerSecond: BigNumber = .zero
        var mutationsPerSecond: BigNumber = .zero
        
        for factory in factories {
            if !factory.assignedDuckIds.isEmpty {
                let ducks = factory.assignedDuckIds.compactMap { id in inventory.first { $0.id == id } }
                let displayValues = ducks.map { displaySellValue(for: $0) }
                let factoryPerks = factory.equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
                
                earningsPerSecond += factory.calculateEarningsPerSecond(assignedDucks: ducks, duckDisplayValues: displayValues, factoryPerks: factoryPerks)
                mutationsPerSecond += factory.calculateMutationsPerSecond(assignedDucks: ducks, globalBonus: mutationMultiplier)
            }
        }
        
        let totalOfflineEarnings = earningsPerSecond * secondsOffline
        let totalOfflineMutations = mutationsPerSecond * secondsOffline
        
        let offlineXpRate = PlayerLevelSystem.calculatePassiveXP(earningsPerSecond: earningsPerSecond)
        let totalOfflineXP = offlineXpRate * Int(secondsOffline)
        
        // On ne l'ajoute pas directement, on le stocke dans le popup
        pendingOfflineEarnings = OfflineEarnings(money: totalOfflineEarnings, dna: totalOfflineMutations, xp: totalOfflineXP, seconds: secondsOffline)
    }
    
    func claimOfflineEarnings(multiplier: Double) {
        guard let earnings = pendingOfflineEarnings else { return }
        
        // 1. Ajouter l'argent, l'ADN multiplié, et l'XP
        money += earnings.money * multiplier
        addMutationPoints(earnings.dna * multiplier)
        playerXP += Int(Double(earnings.xp) * multiplier)
        checkLevelUp()
        
        let secondsOffline = earnings.seconds
        
        // 2. Lancer l'automatisation avec le *nouveau* solde !
        // Pour estimer le earningsPerSecond original pour l'automatisation, on le recalcule (ou on le déduit)
        let earningsPerSecond = earnings.money / secondsOffline
        processOfflineAutomation(secondsPassed: secondsOffline, earningsPerSecond: earningsPerSecond.doubleValue)
        
        // 3. Fermer le popup
        pendingOfflineEarnings = nil
        saveGame()
    }
    
    private func saveFileURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("CanardFactorySave.json")
    }
    

    
    func saveGame(sync: Bool = false) {
        invalidateEarningsCache()
        
        // Annuler la sauvegarde précédente si elle n'a pas encore été exécutée
        saveWorkItem?.cancel()
        
        // Capturer les valeurs légères sur le main thread
        let money = self.money
        let mutationPoints = self.mutationPoints
        let factories = self.factories
        let purchasedUpgrades = self.purchasedUpgrades
        let upgradeLevels = self.upgradeLevels
        let inventory = self.inventory
        let autoCrateTargetId = self.autoCrateTargetId
        let autoFactoryLevels = self.autoFactoryLevels
        let currentStars = self.currentStars
        let totalStars = self.totalStars
        let spentStars = self.spentStars
        let unspentStars = self.unspentStars
        let purchasedPrestigeUpgrades = self.purchasedPrestigeUpgrades
        let gems = self.gems
        let playerLevel = self.playerLevel
        let playerXP = self.playerXP
        let missions = self.missions
        let perksInventory = self.perksInventory
        let url = saveFileURL()
        
        let workItem = DispatchWorkItem {
            var state = GameState()
            state.money = money
            state.mutationPoints = mutationPoints
            state.inventory = inventory
            state.factories = factories
            state.lastSaveDate = Date()
            state.purchasedUpgrades = purchasedUpgrades
            state.upgradeLevels = upgradeLevels
            state.autoCrateTargetId = autoCrateTargetId
            state.autoFactoryLevels = autoFactoryLevels
            state.currentStars = currentStars
            state.totalStars = totalStars
            state.spentStars = spentStars
            state.unspentStars = unspentStars
            state.purchasedPrestigeUpgrades = purchasedPrestigeUpgrades
            state.gems = gems
            state.playerLevel = playerLevel
            state.playerXP = playerXP
            state.missions = missions
            state.perksInventory = perksInventory
            do {
                let data = try JSONEncoder().encode(state)
                let backupUrl = url.appendingPathExtension("bak")
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: backupUrl)
                    try? FileManager.default.copyItem(at: url, to: backupUrl)
                }
                try data.write(to: url, options: [.atomic])
            } catch {
                // Silently handle save error
            }
        }
        saveWorkItem = workItem
        if sync {
            workItem.perform()
        } else {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
    
    func resetProgression() {
        money = BigNumber(200.0)
        mutationPoints = .zero
        inventory = []
        factories = [DuckFactory(name: "Usine 1")]
        purchasedUpgrades = []
        upgradeLevels = [:]
        autoCrateTargetId = nil
        autoFactoryLevels = [:]
        // We do NOT reset currentStars, totalStars, spentStars, and purchasedPrestigeUpgrades here, only in full hard reset if needed, but for prestige we keep them.
        lastSaveDate = Date()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }
    
}
