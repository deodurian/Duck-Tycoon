import Foundation

extension GameManager {

    // MARK: - Quêtes Secondaires

    /// Valeur actuelle de la statistique mesurée par une quête
    func sideQuestValue(for metric: SideQuestMetric) -> Double {
        switch metric {
        case .ducksFromCrates: return Double(totalDucksFromCrates)
        case .ducksRecycled: return Double(totalRecycledDucks)
        case .fusionsDone: return Double(totalFusionsDone)
        case .inventoryCount: return Double(inventory.count)
        case .playerLevel: return Double(playerLevel)
        case .earningsPerSecond: return (cachedEarningsPerSecond ?? .zero).doubleValue
        case .mutationPointsEarned: return totalMutationPointsEarned.doubleValue
        }
    }

    /// Multiplicateur global de difficulté des quêtes (Remote Config). Borné pour éviter une cible nulle.
    var questDifficultyMult: Double {
        max(0.01, RemoteConfigManager.shared.getDouble(RCKey.questDifficultyMult))
    }

    /// Cible effective d'un objectif de quête après application du multiplicateur de difficulté.
    func effectiveTarget(_ req: SideQuestRequirement) -> Double {
        return req.target * questDifficultyMult
    }

    func isSideQuestClaimed(_ quest: SideQuest) -> Bool {
        return claimedSideQuestIds.contains(quest.id)
    }

    /// Une quête est disponible si sa quête prérequise (tier précédent) a été réclamée
    func isSideQuestAvailable(_ quest: SideQuest) -> Bool {
        guard let prereq = quest.prerequisiteQuestId else { return true }
        return claimedSideQuestIds.contains(prereq)
    }

    /// Progression moyenne (de 0.0 à 1.0) sur l'ensemble des objectifs
    func sideQuestProgress(_ quest: SideQuest) -> Double {
        if quest.requirements.isEmpty { return 1.0 }
        let totalProgress = quest.requirements.reduce(0.0) { sum, req in
            let target = effectiveTarget(req)
            guard target > 0 else { return sum + 1.0 }
            return sum + min(1.0, sideQuestValue(for: req.metric) / target)
        }
        return totalProgress / Double(quest.requirements.count)
    }

    func canClaimSideQuest(_ quest: SideQuest) -> Bool {
        guard !isSideQuestClaimed(quest), isSideQuestAvailable(quest) else { return false }
        return quest.requirements.allSatisfy { req in
            sideQuestValue(for: req.metric) >= effectiveTarget(req)
        }
    }

    /// Réclame la récompense : le déblocage rejoint purchasedUpgrades,
    /// donc tout le gating existant (boutique, fusion, inventaire...) fonctionne tel quel.
    func claimSideQuest(_ quest: SideQuest) {
        guard canClaimSideQuest(quest) else { return }

        claimedSideQuestIds.insert(quest.id)
        purchasedUpgrades.insert(quest.rewardId)

        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }

    /// Déclenche une bannière quand une quête secondaire vient de devenir réclamable (jauge à 100%).
    /// Appelé à chaque tick ; le set `announcedClaimableSideQuestIds` évite les répétitions.
    func checkSideQuestToasts() {
        for quest in SideQuest.all {
            if canClaimSideQuest(quest) {
                if !announcedClaimableSideQuestIds.contains(quest.id) {
                    announcedClaimableSideQuestIds.insert(quest.id)
                    announceQuestCompleted()
                }
            } else {
                announcedClaimableSideQuestIds.remove(quest.id)
            }
        }
    }

    /// Les récompenses de quêtes sont des déblocages permanents : on les
    /// re-applique après le reset des améliorations du Prestige.
    func regrantSideQuestRewards() {
        for quest in SideQuest.all where claimedSideQuestIds.contains(quest.id) {
            purchasedUpgrades.insert(quest.rewardId)
        }
    }
}
