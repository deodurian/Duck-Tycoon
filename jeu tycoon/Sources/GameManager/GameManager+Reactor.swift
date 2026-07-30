import SwiftUI

extension GameManager {

    // MARK: - Réacteur Stellaire

    enum ReactorSlot {
        case energy, mutagen, optimization
    }

    /// Total d'étoiles actuellement allouées dans le Réacteur.
    var reactorAllocatedStars: BigNumber {
        starsInEnergy + starsInMutagen + starsInOptimization
    }

    /// Le Réacteur est verrouillé pendant le cooldown de respec (12 h).
    var isReactorLocked: Bool {
        if let end = reactorCooldownEndTime { return Date() < end }
        return false
    }

    /// Secondes restantes avant la fin du cooldown (0 si aucun).
    var reactorCooldownRemaining: TimeInterval {
        guard let end = reactorCooldownEndTime else { return 0 }
        return max(0, end.timeIntervalSince(Date()))
    }

    /// Alloue `amount` étoiles non dépensées dans un emplacement du Réacteur.
    func allocateToReactor(_ slot: ReactorSlot, amount: BigNumber) {
        guard !isReactorLocked else { return }
        guard amount > .zero, unspentStars >= amount else { return }
        unspentStars -= amount
        switch slot {
        case .energy: starsInEnergy += amount
        case .mutagen: starsInMutagen += amount
        case .optimization: starsInOptimization += amount
        }
        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }

    /// Retire toutes les étoiles du Réacteur (respec) → déclenche le cooldown de 12 h.
    func respecReactor() {
        guard !isReactorLocked else { return }
        let refunded = reactorAllocatedStars
        guard refunded > .zero else { return }
        unspentStars += refunded
        starsInEnergy = .zero
        starsInMutagen = .zero
        starsInOptimization = .zero
        reactorCooldownEndTime = Date().addingTimeInterval(12 * 3600)
        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }

    static let reactorSkipGemCost = BigNumber(50.0)

    /// Passe le cooldown du Réacteur en payant des gemmes.
    func skipReactorCooldownWithGems() {
        guard isReactorLocked, gems >= GameManager.reactorSkipGemCost else { return }
        gems -= GameManager.reactorSkipGemCost
        reactorCooldownEndTime = nil
        saveGame()
    }

    /// Passe le cooldown du Réacteur en regardant une publicité récompensée.
    func skipReactorCooldownWithAd() {
        AdManager.shared.showRewardedAd(for: .offlineBoost) { [weak self] earned in
            guard let self, earned else { return }
            DispatchQueue.main.async {
                self.reactorCooldownEndTime = nil
                self.saveGame()
            }
        }
    }

    // MARK: - Respec de l'Arbre de Prestige (Gem Sink)

    static let prestigeRespecGemCost = BigNumber(200.0)

    var canAffordPrestigeRespec: Bool { gems >= GameManager.prestigeRespecGemCost }

    /// Réinitialise toutes les améliorations de prestige achetées et rend les étoiles dépensées.
    func respecPrestigeTree() {
        guard gems >= GameManager.prestigeRespecGemCost else { return }
        gems -= GameManager.prestigeRespecGemCost
        // Rembourse les étoiles verrouillées dans les améliorations, puis vide l'arbre.
        unspentStars += spentStars
        spentStars = .zero
        purchasedPrestigeUpgrades.removeAll()
        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        saveGame()
    }

    // MARK: - Sauvetage de Rituel par Gemmes (Gem Sink)

    static let ritualSaveGemCost = BigNumber(100.0)

    var canAffordRitualGemSave: Bool { gems >= GameManager.ritualSaveGemCost }

    /// Sauve le canard d'un rituel raté en payant des gemmes. Retourne true si le paiement a réussi.
    func saveRitualWithGems() -> Bool {
        guard gems >= GameManager.ritualSaveGemCost else { return false }
        gems -= GameManager.ritualSaveGemCost
        saveGame()
        return true
    }
}
