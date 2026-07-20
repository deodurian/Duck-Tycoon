import SwiftUI

extension GameManager {
    /// Seuil d'argent requis pour le premier prestige (0 étoile). Centralisé pour éviter la duplication.
    static let firstPrestigeThreshold = BigNumber(1_000_000_000_000.0)

    // MARK: - Shop UI Optimization
    func evaluateAffordableCrates(reset: Bool) {
        if reset {
            affordableCrateKeys.removeAll()
        }
        
        let multiplierMulti = isUnlocked(.multipleOpenX10) ? 10 : 5
        let isMultipleUnlocked = isUnlocked(.multipleOpenX5) || isUnlocked(.multipleOpenX10)
        let isMultipleMaxUnlocked = isUnlocked(.multipleOpenMax)
        
        for crate in Crate.allCrates {
            let type = crate.type.rawValue
            
            // 1x Money
            if let cost = crate.costMoney {
                let key1 = "\(type)_money_1"
                if money >= cost {
                    affordableCrateKeys.insert(key1)
                } else {
                    affordableCrateKeys.remove(key1)
                }
                
                // Multi Money
                if isMultipleUnlocked, let multiCost = calculateCrateCostMoney(crate: crate, amount: multiplierMulti) {
                    let keyM = "\(type)_money_multi"
                    if money >= multiCost {
                        affordableCrateKeys.insert(keyM)
                    } else {
                        affordableCrateKeys.remove(keyM)
                    }
                }
            }
            
            // 1x Mutation
            if let cost = crate.costMutationPoints {
                let key1 = "\(type)_mutation_1"
                if mutationPoints >= cost {
                    affordableCrateKeys.insert(key1)
                } else {
                    affordableCrateKeys.remove(key1)
                }
                
                // Multi Mutation
                if isMultipleUnlocked, let multiCost = calculateCrateCostMutation(crate: crate, amount: multiplierMulti) {
                    let keyM = "\(type)_mutation_multi"
                    if mutationPoints >= multiCost {
                        affordableCrateKeys.insert(keyM)
                    } else {
                        affordableCrateKeys.remove(keyM)
                    }
                }
            }
            
            // Multiple Max
            if isMultipleMaxUnlocked {
                let keyMax = "\(type)_max"
                if maxAffordableCrates(crate: crate) >= 1 {
                    affordableCrateKeys.insert(keyMax)
                } else {
                    affordableCrateKeys.remove(keyMax)
                }
            }
        }
    }
    
    // MARK: - Système d'Améliorations
    
    var currentAdMultiplier: Double {
        if let end = adBoostEndTime, Date() < end {
            return adBoostMultiplier
        } else {
            return 1.0
        }
    }
    
    var earningsMultiplier: BigNumber {
        let level = upgradeLevels[.bonusGlobal] ?? 0
        let base = BigNumber(1.0 + Double(level) * 0.01)
        let prestigeBonus = BigNumber(1.0) + (BigNumber.pow(totalStars, 0.5) * 0.10)
        let playerLevelBonus = BigNumber(PlayerLevelSystem.moneyMultiplier(for: playerLevel))
        let adBonus = BigNumber(currentAdMultiplier)
        var total = base * prestigeBonus * playerLevelBonus * adBonus
        if hasPrestigeUpgrade("p2_eco") { total *= 1.30 }
        if hasPrestigeUpgrade("p7_omnipotence") { total *= 11.0 } // +1000%
        return total
    }

    /// Amplifie tous les effets numériques des perks équipés (bonus permanent + prestige tier 6)
    var perkPowerMultiplier: Double {
        let level = upgradeLevels[.bonusPerkPower] ?? 0
        var multiplier = 1.0 + Double(level) * 0.02
        if hasPrestigeUpgrade("p6_perk_power") { multiplier += 0.30 }
        return multiplier
    }

    /// Nombre de base d'emplacements de perk (avant bonus d'extraSlot), usine ET canard
    var basePerkSlots: Int {
        hasPrestigeUpgrade("p5_perk_slot") ? 2 : 1
    }

    /// Bonus cumulé des perks "Chance de Caisse" équipés sur les canards actuellement assignés à une usine
    var crateLuckBonus: Double {
        var bonus = 0.0
        for factory in factories {
            for duckId in factory.assignedDuckIds {
                guard let duck = inventory.first(where: { $0.id == duckId }) else { continue }
                for perkId in duck.equippedPerkIds {
                    if let perk = perksInventory.first(where: { $0.id == perkId }) {
                        bonus += perk.duckCrateLuckBonus
                    }
                }
            }
        }
        return bonus
    }
    
    func watchAdForBoost() {
        AdManager.shared.showRewardedAd(for: .factoryBoost) { [weak self] earned in
            guard let self = self, earned else { return }
            
            DispatchQueue.main.async {
                if let end = self.adBoostEndTime, Date() < end {
                    self.adBoostMultiplier += 1.0
                } else {
                    self.adBoostMultiplier = 2.0
                }
                
                self.adBoostEndTime = Date().addingTimeInterval(3600) // 1 heure
                self.invalidateEarningsCache()
                self.saveGame()
            }
        }
    }
    
    var isMysteryCrateAvailable: Bool {
        if let nextDate = nextMysteryCrateDate {
            return Date() >= nextDate
        }
        return true // Toujours dispo la première fois
    }

    func claimMysteryCrate() {
        guard isMysteryCrateAvailable else { return }
        AdManager.shared.showRewardedAd(for: .mysteryCrate) { [weak self] earned in
            guard let self = self, earned else { return }
            
            DispatchQueue.main.async {
                // Donner un canard mythique
                let duck = Duck(rarity: .mythique, size: DuckSize.allCases.randomElement()!, mutation: .aucune)
                self.inventory.append(duck)
                
                // Relancer le cooldown entre 30 min (1800s) et 1 heure (3600s)
                self.nextMysteryCrateDate = Date().addingTimeInterval(Double.random(in: 1800...3600))
                self.saveGame()
            }
        }
    }
    
    func resetDailyGemsIfNeeded() {
        if let lastDate = lastAdGemsDate {
            if !Calendar.current.isDateInToday(lastDate) {
                dailyAdGemsCount = 0
                lastAdGemsDate = nil
            }
        }
    }
    
    var canWatchAdForGems: Bool {
        resetDailyGemsIfNeeded()
        return dailyAdGemsCount < 5
    }
    
    func watchAdForGems() {
        guard canWatchAdForGems else { return }
        AdManager.shared.showRewardedAd(for: .dailyGems) { [weak self] earned in
            guard let self = self, earned else { return }
            
            DispatchQueue.main.async {
                self.gems += BigNumber(10)
                self.dailyAdGemsCount += 1
                self.lastAdGemsDate = Date()
                self.saveGame()
            }
        }
    }
    
    /// Multiplicateur de points de mutation + Prestige + PlayerLevel
    var mutationMultiplier: BigNumber {
        let level = upgradeLevels[.bonusMutation] ?? 0
        let base = BigNumber(1.0 + Double(level) * 0.02)
        let prestigeBonus = BigNumber(1.0) + (BigNumber.pow(totalStars, 0.5) * 0.03)
        let playerLevelBonus = BigNumber(PlayerLevelSystem.mutationMultiplier(for: playerLevel))
        var total = base * prestigeBonus * playerLevelBonus
        if hasPrestigeUpgrade("p4_adn") { total *= 3.0 } // +200%
        if hasPrestigeUpgrade("p5_adn2") { total *= 2.5 } // +150%
        if hasPrestigeUpgrade("p7_omnipotence") { total *= 6.0 } // +500%
        return total
    }
    
    // Prestige: Bonus d'argent après fusion (+5% par étoile)
    var fusionValueMultiplier: BigNumber {
        return BigNumber(1.0) + (BigNumber.pow(totalStars, 0.5) * 0.05)
    }
    
    // Prestige: Prix des usines moins chères (-1% par étoile, asymptote max 100%)
    var factoryCostDiscount: Double {
        var discount = 100.0 / (100.0 + totalStars.doubleValue)
        if hasPrestigeUpgrade("p7_omnipotence") { discount -= 0.75 }
        return discount
    }

    /// Réduction de coût d'évolution d'usine : factoryCostDiscount + Maîtrise d'Évolution + upgrades de prestige dédiés
    var factoryEvolutionCostDiscount: Double {
        var discount = factoryCostDiscount
        let bonusLevel = upgradeLevels[.bonusEvolutionCost] ?? 0
        if bonusLevel > 0 {
            discount -= (1.0 - pow(0.99, Double(bonusLevel)))
        }
        if hasPrestigeUpgrade("p5_evo_cost") { discount -= 0.20 }
        if hasPrestigeUpgrade("p7_usine_evo_cost") { discount -= 0.50 }
        return discount
    }
    
    // Prestige: Chance de canard muté spontanée (+0.2% par étoile, si totalStars >= 100)
    var prestigeSpontaneousMutationChance: Double {
        guard totalStars >= BigNumber(100.0) else { return 0.0 }
        
        if totalStars >= BigNumber(500.0) { // 500 étoiles = 100% de chance
            return 1.0
        }
        return min(1.0, pow(totalStars.doubleValue, 0.5) * 0.002)
    }
    
    // Prestige: Gain du Rituel (+2% par étoile, si totalStars >= 1000)
    var prestigeRitualBonusMultiplier: BigNumber {
        guard totalStars >= BigNumber(1000.0) else { return BigNumber(1.0) }
        return BigNumber(1.0) + (BigNumber.pow(totalStars, 0.5) * 0.02)
    }
    
    /// Multiplicateur de revenus pour une rareté spécifique
    func rarityMultiplier(for rarity: DuckRarity) -> Double {
        let upgradeId: UpgradeID
        switch rarity {
        case .commun: upgradeId = .bonusCommun
        case .peuCommun: upgradeId = .bonusPeuCommun
        case .rare: upgradeId = .bonusRare
        case .epique: upgradeId = .bonusEpique
        case .legendaire: upgradeId = .bonusLegendaire
        case .mythique: upgradeId = .bonusMythique
        case .exotique: upgradeId = .bonusExotique
        case .celeste: upgradeId = .bonusCeleste
        case .primordiale: upgradeId = .bonusPrimordiale
        }
        let level = upgradeLevels[upgradeId] ?? 0
        var multiplier = 1.0 + Double(level) * 0.02

        if hasPrestigeUpgrade("p2_val_com") && (rarity == .commun || rarity == .peuCommun) {
            multiplier += 1.0
        }
        if hasPrestigeUpgrade("p2_val_rare") && (rarity == .rare || rarity == .epique) {
            multiplier += 0.75
        }
        if hasPrestigeUpgrade("p2_val_leg") && (rarity == .legendaire || rarity == .mythique) {
            multiplier += 0.50
        }
        if hasPrestigeUpgrade("p3_val_base") && (rarity == .commun || rarity == .peuCommun || rarity == .rare) {
            multiplier += 0.50
        }
        if hasPrestigeUpgrade("p5_rarete_exo") && (rarity == .exotique || rarity == .celeste || rarity == .primordiale) {
            multiplier += 1.00
        }
        if hasPrestigeUpgrade("p6_rarete_myth") && (rarity == .mythique || rarity == .exotique || rarity == .celeste || rarity == .primordiale) {
            multiplier += 0.75
        }
        if hasPrestigeUpgrade("p7_rarete_primo") && (rarity == .exotique || rarity == .celeste || rarity == .primordiale) {
            multiplier += 2.00
        }

        return multiplier
    }
    
    /// Multiplicateur de taxe de fusion (Paradis Fiscal + prestige tier 6)
    var taxMultiplier: Double {
        let level = upgradeLevels[.paradisFiscal] ?? 0
        // -5% par niveau, max 20 = -100%
        var multiplier = 1.0 - Double(level) * 0.05
        if hasPrestigeUpgrade("p6_fusion_taxfree") { multiplier -= 0.50 }
        return max(0.0, multiplier)
    }
    
    /// Vérifie si un déblocage est acheté
    func isUnlocked(_ id: UpgradeID) -> Bool {
        purchasedUpgrades.contains(id)
    }
    
    var isFusionUnlocked: Bool {
        return currentStoryStep >= 3 || isUnlocked(.manualFusion) || hasPrestigeUpgrade("p3_fusion")
    }
    
    var isBulkRecycleUnlocked: Bool {
        return isUnlocked(.bulkRecycle) || hasPrestigeUpgrade("p4_recycle")
    }
    
    var occulteLevel: Int {
        if isUnlocked(.occultePenalty5) { return 5 }
        if isUnlocked(.occultePenalty4) { return 4 }
        if isUnlocked(.occultePenalty3) { return 3 }
        if isUnlocked(.occultePenalty2) { return 2 }
        if isUnlocked(.occultePenalty) { return 1 }
        return 0
    }
    
    var goldenRitualLevel: Int {
        if isUnlocked(.goldenRitual5) { return 5 }
        if isUnlocked(.goldenRitual4) { return 4 }
        if isUnlocked(.goldenRitual3) { return 3 }
        if isUnlocked(.goldenRitual2) { return 2 }
        if isUnlocked(.goldenRitual) { return 1 }
        return 0
    }
    
    var spontaneousMutationLevel: Int {
        if isUnlocked(.mutationSpontanee4) { return 4 }
        if isUnlocked(.mutationSpontanee3) { return 3 }
        if isUnlocked(.mutationSpontanee2) { return 2 }
        if isUnlocked(.mutationSpontanee) { return 1 }
        return 0
    }

    var autoCrateInterval: Double? {
        var interval: Double? = nil
        if isUnlocked(.autoOuvrier6) { interval = 0.1 }
        else if isUnlocked(.autoOuvrier5) { interval = 0.25 }
        else if isUnlocked(.autoOuvrier4) { interval = 0.5 }
        else if isUnlocked(.autoOuvrier3) { interval = 2.0 }
        else if isUnlocked(.autoOuvrier2) { interval = 5.0 }
        else if isUnlocked(.autoOuvrier) { interval = 10.0 }

        if hasPrestigeUpgrade("p5_auto2") {
            interval = min(interval ?? .infinity, 0.25)
        }
        if hasPrestigeUpgrade("p7_auto_max") {
            interval = 0.1
        }

        guard let baseInterval = interval else { return nil }
        let speedLevel = upgradeLevels[.bonusAutomationSpeed] ?? 0
        let speedFactor = speedLevel > 0 ? pow(0.99, Double(speedLevel)) : 1.0
        return max(0.02, baseInterval * speedFactor)
    }

    var hasRecyclingExpertise: Bool {
        return isUnlocked(.expertiseRecyclage)
    }

    func autoFactoryInterval(for factoryId: UUID) -> Double? {
        var level = autoFactoryLevels[factoryId] ?? 0
        if hasPrestigeUpgrade("p6_auto3") { level = max(level, 5) }
        if hasPrestigeUpgrade("p7_auto_max") { level = max(level, 5) }

        var interval: Double?
        switch level {
        case 5: interval = 0.2
        case 4: interval = 0.5
        case 3: interval = 1.0
        case 2: interval = 3.0
        case 1: interval = 10.0
        default: interval = nil
        }
        guard let baseInterval = interval else { return nil }
        let speedLevel = upgradeLevels[.bonusAutomationSpeed] ?? 0
        let speedFactor = speedLevel > 0 ? pow(0.99, Double(speedLevel)) : 1.0
        return max(0.05, baseInterval * speedFactor)
    }
    
    /// Niveau d'un bonus permanent (0 si non acheté)
    func upgradeLevel(_ id: UpgradeID) -> Int {
        upgradeLevels[id] ?? 0
    }
    
    /// Acheter ou améliorer une amélioration (1 niveau)
    func buyUpgrade(_ def: UpgradeDefinition) {
        let currentLevel = upgradeLevels[def.id] ?? 0
        guard currentLevel < def.maxLevel else { return }
        let cost = def.cost(forNextLevel: currentLevel)
        
        switch def.currency {
        case .money:
            guard money >= cost else { return }
            money -= cost
        case .mutationPoints:
            guard mutationPoints >= cost else { return }
            mutationPoints -= cost
        }
        if def.maxLevel == 1 {
            purchasedUpgrades.insert(def.id)
            if def.id == .manualFusion {
                emitMissionEvent(.unlockFusionLab)
            }
        } else {
            upgradeLevels[def.id] = currentLevel + 1
        }
        
        emitMissionEvent(.unlockUpgrades, amount: BigNumber(1))
        
        // Vérifier si le repeatable est maxed
        if let currentLevel = upgradeLevels[def.id], currentLevel == def.maxLevel {
            totalMaxedRepeatableUpgrades += 1
            emitMissionEvent(.maxRepeatableUpgrades)
        }
        
        invalidateEarningsCache()
        saveGame()
    }
    
    /// Calcule le coût total et le nombre de niveaux pour acheter jusqu'au maximum possible
    func calculateMaxUpgrades(for def: UpgradeDefinition) -> (levels: Int, cost: BigNumber) {
        let currentLevel = upgradeLevels[def.id] ?? 0
        guard currentLevel < def.maxLevel else { return (0, .zero) }
        
        let availableCurrency = def.currency == .money ? money : mutationPoints
        let cost = def.cost(forNextLevel: currentLevel)
        if availableCurrency < cost { return (0, .zero) }
        
        if def.costMultiplier == 1.0 {
            let maxCanBuy = (availableCurrency / cost).intValue
            let levelsToBuy = min(def.maxLevel - currentLevel, maxCanBuy)
            let totalCost = cost * levelsToBuy
            return (levelsToBuy, totalCost)
        } else {
            let r = def.costMultiplier
            let a = cost
            
            let S = availableCurrency
            let r_minus_1 = BigNumber(r - 1.0)
            let maxK_double = ((S * r_minus_1 / a) + BigNumber.one).ln / log(r)
            
            var k = 0
            if maxK_double.isNaN || maxK_double.isInfinite {
                k = def.maxLevel - currentLevel
            } else {
                k = Int(floor(maxK_double))
            }
            
            let levelsToBuy = min(def.maxLevel - currentLevel, max(1, k))
            let r_pow_k = BigNumber.pow(BigNumber(r), levelsToBuy)
            var totalCost = a * (r_pow_k - BigNumber.one) / r_minus_1
            
            // Sécurité précision
            if totalCost > availableCurrency && levelsToBuy > 1 {
                let safeLevels = levelsToBuy - 1
                let safe_r_pow_k = BigNumber.pow(BigNumber(r), safeLevels)
                totalCost = a * (safe_r_pow_k - BigNumber.one) / r_minus_1
                return (safeLevels, totalCost)
            }
            
            return (levelsToBuy, totalCost)
        }
    }
    
    /// Acheter le maximum de niveaux possibles d'un coup
    func buyMaxUpgrade(_ def: UpgradeDefinition) {
        let maxInfo = calculateMaxUpgrades(for: def)
        guard maxInfo.levels > 0 else { return }
        
        switch def.currency {
        case .money:
            money -= maxInfo.cost
        case .mutationPoints:
            mutationPoints -= maxInfo.cost
        }
        
        let currentLevel = upgradeLevels[def.id] ?? 0
        upgradeLevels[def.id] = currentLevel + maxInfo.levels
        
        emitMissionEvent(.unlockUpgrades, amount: BigNumber(maxInfo.levels))
        
        if (currentLevel + maxInfo.levels) == def.maxLevel {
            totalMaxedRepeatableUpgrades += 1
            emitMissionEvent(.maxRepeatableUpgrades)
        }
        
        invalidateEarningsCache()
        saveGame()
    }
    
    // MARK: - Prestige Upgrades
    
    func hasPrestigeUpgrade(_ id: String) -> Bool {
        return purchasedPrestigeUpgrades.contains(id)
    }
    
    func buyPrestigeUpgrade(_ upgrade: PrestigeUpgrade) {
        guard !hasPrestigeUpgrade(upgrade.id) else { return }
        guard spentStars >= BigNumber(Double(upgrade.requiredSpentStars)) else { return }
        guard unspentStars >= BigNumber(Double(upgrade.cost)) else { return }
        
        unspentStars -= BigNumber(Double(upgrade.cost))
        spentStars += BigNumber(Double(upgrade.cost))
        purchasedPrestigeUpgrades.insert(upgrade.id)
        
        emitMissionEvent(.unlockUpgrades, amount: BigNumber(1))
        
        invalidateEarningsCache()
        saveGame()
    }
    
    // MARK: - Sell Value & UI Helpers
    
    func displaySellValue(for duck: Duck) -> BigNumber {
        let ritualCount = Double(duck.ritualSuccesses + duck.goldenRitualSuccesses)
        var prestigeRitualBonus = BigNumber.pow(prestigeRitualBonusMultiplier, ritualCount)
        
        if hasPrestigeUpgrade("p4_rituel") {
            let fixRitual = BigNumber.pow(BigNumber(1.5), Double(duck.ritualSuccesses)) // 3.0 / 2.0
            let fixGolden = BigNumber.pow(BigNumber(1.5), Double(duck.goldenRitualSuccesses)) // 15.0 / 10.0
            prestigeRitualBonus *= fixRitual * fixGolden
        }
        
        let duckPerks = duck.equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }

        return duck.calculateSellValue(with: duckPerks, perkPowerFactor: perkPowerMultiplier) * earningsMultiplier * rarityMultiplier(for: duck.rarity) * prestigeRitualBonus
    }

    func displayRecycleValue(for duck: Duck) -> BigNumber {
        let duckPerks = duck.equippedPerkIds.compactMap { id in perksInventory.first { $0.id == id } }
        var recycleRarityBonus = 1.0
        if hasPrestigeUpgrade("p7_rarete_primo") && (duck.rarity == .exotique || duck.rarity == .celeste || duck.rarity == .primordiale) {
            recycleRarityBonus += 2.00
        }
        return duck.calculateRecycleValue(with: duckPerks, perkPowerFactor: perkPowerMultiplier) * mutationMultiplier * recycleRarityBonus
    }
    
    func calculateCrateCostMoney(crate: Crate, amount: Int) -> BigNumber? {
        guard let baseCost = crate.costMoney else { return nil }
        guard inventory.count + amount <= maxInventoryCapacity else { return nil }
        
        if crate.type == .bois && amount == 1 && storyFlags["firstWoodenCrateOpened"] != true {
            return .zero
        }
        
        let multiplier = amount <= 10000 ? 2.0 : max(2.0, 1.0 + Double(amount) / 10000.0)
        return amount <= 1 ? baseCost : baseCost * Double(amount) * multiplier
    }
    
    func calculateCrateCostMutation(crate: Crate, amount: Int) -> BigNumber? {
        guard let baseCost = crate.costMutationPoints else { return nil }
        guard inventory.count + amount <= maxInventoryCapacity else { return nil }
        
        let multiplier = amount <= 10000 ? 2.0 : max(2.0, 1.0 + Double(amount) / 10000.0)
        return amount <= 1 ? baseCost : baseCost * Double(amount) * multiplier
    }
    
    func maxAffordableCrates(crate: Crate) -> Int {
        var limit = 0
        
        if let baseCost = crate.costMoney {
            if crate.type == .bois && storyFlags["firstWoodenCrateOpened"] != true {
                return 1
            }
            if money < baseCost { return 0 }
            if money < baseCost * 4.0 { limit = 1 }
            else {
                let a = money / (baseCost * 2.0)
                if a <= 10000.0 {
                    limit = a.intValue
                } else {
                    let M_B = (money / baseCost).doubleValue
                    let ans = (-10000.0 + sqrt(100000000.0 + 40000.0 * M_B)) / 2.0
                    let cappedAns = ans.isNaN ? 0.0 : min(ans, Double(maxInventoryCapacity))
                    limit = Int(cappedAns)
                }
            }
        } else if let baseCost = crate.costMutationPoints {
            if mutationPoints < baseCost { return 0 }
            if mutationPoints < baseCost * 4.0 { limit = 1 }
            else {
                let M_B = (mutationPoints / baseCost).doubleValue
                let a = M_B / 2.0
                if a <= 10000 {
                    limit = Int(a)
                } else {
                    let ans = (-10000.0 + sqrt(100000000.0 + 40000.0 * M_B)) / 2.0
                    let cappedAns = ans.isNaN ? 0.0 : min(ans, Double(maxInventoryCapacity))
                    limit = Int(cappedAns)
                }
            }
        }
        
        let availableSpace = max(0, maxInventoryCapacity - inventory.count)
        return min(limit, min(50000, availableSpace))
    }
    
    // MARK: - Prestige System
    
    func calculatePrestigeStars() -> BigNumber {
        guard money >= GameManager.firstPrestigeThreshold else { return .zero }
        let ratioBN = money / GameManager.firstPrestigeThreshold

        // floor( pow( Argent / seuil, 0.25 ) )
        let rawStars = BigNumber.pow(ratioBN, 0.25)

        var stars = rawStars.exponent >= 15 ? rawStars : BigNumber(Foundation.floor(rawStars.doubleValue))

        let bonusLevel = upgradeLevels[.bonusPrestigeStars] ?? 0
        var starGainMultiplier = 1.0 + Double(bonusLevel) * 0.005
        if hasPrestigeUpgrade("p7_star_gain") { starGainMultiplier += 0.50 }
        if starGainMultiplier != 1.0 {
            stars = BigNumber(Foundation.floor((stars * starGainMultiplier).doubleValue))
        }

        return stars
    }
    
    func executePrestige() {
        let starsEarned = calculatePrestigeStars()
        guard starsEarned > .zero else { return }
        
        currentStars += starsEarned
        totalStars += starsEarned
        unspentStars += starsEarned
        
        // Reset everything
        money = BigNumber(150.0)
        mutationPoints = .zero
        
        emitMissionEvent(.prestige)
        checkStoryAction("prestige")
        
        inventory.removeAll()
        factories = [DuckFactory(name: "Usine 1")]
        purchasedUpgrades.removeAll()
        upgradeLevels.removeAll()
        totalMaxedRepeatableUpgrades = 0
        autoCrateTargetId = nil
        autoFactoryLevels.removeAll()

        // Les déblocages gagnés via les Quêtes Secondaires sont permanents
        regrantSideQuestRewards()
        
        invalidateEarningsCache()
        isAssignedDucksCacheValid = false
        assignedDucksCache.removeAll()
        evaluateAffordableCrates(reset: true)
        
        saveGame()
    }
    

}

enum NumberFormatStyle: String, CaseIterable, Identifiable {
    case suffixes = "Lettres"
    case scientific = "Scientifique"
    
    var id: String { self.rawValue }
}

extension Double {
    func formattedString() -> String {
        let styleString = UserDefaults.standard.string(forKey: "numberFormatStyle") ?? NumberFormatStyle.scientific.rawValue
        let style = NumberFormatStyle(rawValue: styleString) ?? .scientific
        
        let value = self
        
        if value < 1000 {
            return String(format: "%.0f", value)
        }
        
        if value >= 1e100 {
            return NumberFormatter.sharedScientific.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        }
        
        switch style {
        case .suffixes:
            let suffixArray = [
                "k", "M", "Md", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "UDc", "DDc", "TDc", "QaDc", "QiDc", "SxDc", "SpDc", "OcDc", "NoDc", "Vg", "UVg", "DVg", "TVg", "QaVg", "QiVg", "SxVg", "SpVg", "OcVg", "NoVg", "Tg", "UTg", "DTg"
            ]
            let order = Int(log10(value) / 3)
            let index = order - 1
            
            if index >= 0 && index < suffixArray.count {
                let divisor = pow(10.0, Double(order * 3))
                let val = value / divisor
                if floor(val) == val {
                    return String(format: "%.0f%@", val, suffixArray[index])
                } else {
                    return String(format: "%.1f%@", val, suffixArray[index])
                }
            } else {
                // Fallback de sécurité (ne devrait pas arriver grâce à la condition 1e100)
                return String(format: "%.0f", value)
            }
            
        case .scientific:
            return NumberFormatter.sharedScientific.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        }
    }
}

extension NumberFormatter {
    static let sharedScientific: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.positiveFormat = "0.##E0"
        formatter.exponentSymbol = "e"
        return formatter
    }()
}

extension Int {
    func formattedString() -> String {
        return Double(self).formattedString()
    }
}
