#if DEBUG
import Foundation

// MARK: - Outils Développeur
// Ce fichier n'existe que dans les builds Debug (Xcode). Il est entièrement
// exclu des builds Release (App Store) par la directive #if DEBUG.

extension GameManager {

    // MARK: Ressources

    func devAddMoney(_ amount: Double) {
        money += BigNumber(amount)
        evaluateAffordableCrates(reset: false)
        saveGame()
    }

    func devAddDNA(_ amount: Double) {
        addMutationPoints(BigNumber(amount))
        saveGame()
    }

    func devAddGems(_ amount: Double) {
        gems += BigNumber(amount)
        saveGame()
    }

    // MARK: Générateur de canards

    func devSpawnDuck(rarity: DuckRarity, size: DuckSize, mutation: DuckMutation) {
        guard inventory.count < maxInventoryCapacity else { return }
        let duck = Duck(rarity: rarity, size: size, mutation: mutation)
        inventory.append(duck)
        registerDuckDiscovery(duck)
        invalidateEarningsCache()
        saveGame()
    }

    // MARK: Collection

    /// Débloque toutes les entrées du Compendium de Perks (pour les visualiser dans la Collection).
    /// Renvoie le nombre total d'entrées de perks.
    @discardableResult
    func devUnlockAllPerks() -> Int {
        for entry in PerkCollectionEntry.allEntries where (discoveredPerks[entry.id] ?? 0) < 1 {
            discoveredPerks[entry.id] = 1
        }
        saveGame()
        return PerkCollectionEntry.allEntries.count
    }

    // MARK: Time Travel

    /// Crédite instantanément le joueur comme s'il s'était absenté pendant `seconds`.
    func devSimulateTimeJump(seconds: TimeInterval) {
        let (earningsPerSecond, mutationsPerSecond) = computePassiveRates()

        money += earningsPerSecond * seconds
        addMutationPoints(mutationsPerSecond * seconds)
        playerXP += PlayerLevelSystem.calculatePassiveXP(earningsPerSecond: earningsPerSecond) * Int(seconds)
        checkLevelUp()

        // Rejouer aussi l'automatisation (auto-ouvrier, auto-usine) sur la période
        processOfflineAutomation(secondsPassed: seconds, earningsPerSecond: earningsPerSecond.doubleValue)

        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }

    // MARK: Capsules & Publicités

    /// Réinitialise tous les cooldowns liés aux pubs et à la Capsule Mystère
    func devResetAdCooldowns() {
        nextMysteryCrateDate = nil
        dailyAdGemsCount = 0
        lastAdGemsDate = nil
        adBoostEndTime = nil
        adBoostMultiplier = 1.0
        invalidateEarningsCache()
        saveGame()
    }

    /// Fait apparaître immédiatement la Capsule Mystère en boutique
    func devForceMysteryCrateSpawn() {
        nextMysteryCrateDate = nil
        saveGame()
    }

    /// Applique directement la récompense d'une pub, sans passer par AdMob
    func devGrantAdReward(for placement: AdPlacement) {
        switch placement {
        case .factoryBoost:
            if let end = adBoostEndTime, Date() < end {
                adBoostMultiplier += 1.0
            } else {
                adBoostMultiplier = 2.0
            }
            adBoostEndTime = Date().addingTimeInterval(3600)
            invalidateEarningsCache()
        case .dailyGems:
            gems += BigNumber(10)
            dailyAdGemsCount += 1
            lastAdGemsDate = Date()
        case .mysteryCrate:
            let duck = Duck(rarity: .mythique, size: DuckSize.allCases.randomElement()!, mutation: .aucune)
            inventory.append(duck)
            registerDuckDiscovery(duck)
            nextMysteryCrateDate = Date().addingTimeInterval(Double.random(in: 1800...3600))
        case .ritualSave, .offlineBoost:
            break // Récompenses contextuelles (rituel en cours / popup hors-ligne) : utiliser la simulation de pub
        }
        saveGame()
    }

    // MARK: Quêtes secondaires

    /// La quête actuellement « active » : première quête disponible non réclamée
    var devActiveSideQuest: SideQuest? {
        SideQuest.all.first { !isSideQuestClaimed($0) && isSideQuestAvailable($0) }
    }

    /// Valide de force la quête active en contournant les prérequis de progression
    func devSkipActiveSideQuest() {
        guard let quest = devActiveSideQuest else { return }
        claimedSideQuestIds.insert(quest.id)
        purchasedUpgrades.insert(quest.rewardId)
        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }

    /// Injecte les valeurs demandées par la quête active dans les statistiques,
    /// pour tester le bouton « Réclamer » du menu normal.
    /// Retourne les objectifs impossibles à injecter (ex: revenus/s).
    @discardableResult
    func devFillActiveSideQuestRequirements() -> [SideQuestMetric] {
        guard let quest = devActiveSideQuest else { return [] }
        var notInjectable: [SideQuestMetric] = []

        for req in quest.requirements {
            let target = req.target
            switch req.metric {
            case .ducksFromCrates:
                totalDucksFromCrates = max(totalDucksFromCrates, Int(target))
            case .ducksRecycled:
                totalRecycledDucks = max(totalRecycledDucks, Int(target))
            case .fusionsDone:
                totalFusionsDone = max(totalFusionsDone, Int(target))
            case .playerLevel:
                playerLevel = max(playerLevel, Int(target))
            case .mutationPointsEarned:
                if totalMutationPointsEarned < BigNumber(target) {
                    totalMutationPointsEarned = BigNumber(target)
                }
            case .inventoryCount:
                let missing = Int(target) - inventory.count
                if missing > 0 {
                    let toAdd = min(missing, maxInventoryCapacity - inventory.count)
                    for _ in 0..<max(0, toAdd) {
                        inventory.append(Duck(rarity: .commun, size: .petit, mutation: .aucune))
                    }
                    registerDuckDiscovery(rarity: .commun, size: .petit)
                }
            case .earningsPerSecond:
                notInjectable.append(req.metric) // dépend des usines réelles, non injectable
            }
        }

        invalidateEarningsCache()
        saveGame()
        return notInjectable
    }

    /// Remet les quêtes secondaires à zéro (retire aussi les récompenses débloquées)
    func devResetSideQuests() {
        for quest in SideQuest.all {
            purchasedUpgrades.remove(quest.rewardId)
        }
        claimedSideQuestIds.removeAll()
        totalDucksFromCrates = 0
        totalRecycledDucks = 0
        totalFusionsDone = 0

        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }
}
#endif
