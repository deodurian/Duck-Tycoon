import SwiftUI

extension GameManager {

    // MARK: - Toasts

    /// Affiche une bannière transitoire en haut de l'écran, auto-masquée après 3 s.
    func showToast(title: String, subtitle: String? = nil, icon: String, color: Color) {
        let toast = ToastMessage(title: title, subtitle: subtitle, icon: icon, color: color)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            activeToast = toast
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, self.activeToast?.id == toast.id else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.activeToast = nil
            }
        }
    }

    // MARK: - Confettis

    /// Déclenche une salve de confettis (compteur monotone observé par ConfettiView).
    func triggerConfetti() {
        confettiBurst &+= 1
    }

    /// Secousse de l'écran (oscillation horizontale amortie), appliquée via `globalShakeOffset` dans ContentView.
    func triggerScreenShake() {
        let steps: [CGFloat] = [14, -11, 8, -6, 4, -2, 0]
        for (i, dx) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) { [weak self] in
                withAnimation(.linear(duration: 0.05)) {
                    self?.globalShakeOffset = CGSize(width: dx, height: 0)
                }
            }
        }
    }

    // MARK: - Déclencheurs de quête

    /// Appelé quand une quête (principale, quotidienne ou secondaire) vient d'être complétée.
    func announceQuestCompleted() {
        showToast(title: "Quête Complétée !", icon: "checkmark.seal.fill", color: .green)
        triggerConfetti()
    }

    /// Confettis si une capsule / fusion produit un canard Mythique ou Primordial.
    func celebrateRareDucks(_ ducks: [Duck]) {
        if ducks.contains(where: { $0.rarity == .mythique || $0.rarity == .primordiale }) {
            triggerConfetti()
        }
    }

    // MARK: - Badges (points rouges) par onglet

    /// Indique si l'onglet `index` (index de `CustomTabBar`) doit afficher un point rouge.
    /// Règle stricte : jamais de badge pour les Améliorations achetables en ADN (onglet 4).
    func hasNotification(forTab index: Int) -> Bool {
        switch index {
        case 0:  // Histoire : une quête principale, quotidienne ou secondaire réclamable
            return isStoryQuestReadyToClaim
                || missions.contains { $0.status == .completed }
                || hasClaimableSideQuest
        case 1:  // Usines : un nouveau perk obtenu
            return hasUnseenPerk
        case 2:  // Canards : nouveau canard débloqué ou récompense de collection réclamable
            return hasUnseenCollectionDuck || hasClaimableCollectionReward
        case 3:  // Boutique : une capsule gratuite / pub est disponible
            return isMysteryCrateAvailable
        case 6:  // Prestige : étoiles non dépensées
            return unspentStars > .zero
        default:
            return false
        }
    }

    /// Vrai si au moins une quête secondaire est réclamable maintenant.
    ///
    /// Coût évité : `canClaimSideQuest` passe par `effectiveTarget`, qui relit `questDifficultyMult`
    /// — donc prend le NSLock de RemoteConfig — pour CHAQUE objectif de CHAQUE quête, soit une
    /// quinzaine de verrous par évaluation, une fois par seconde (le `body` de la barre d'onglets est
    /// réévalué à chaque tick). Ici le multiplicateur est lu une seule fois puis réutilisé.
    ///
    /// Rendu identique : mêmes quêtes, dans le même ordre, mêmes prédicats (`req.target * mult`, soit
    /// exactement `effectiveTarget(req)`), même arrêt au premier résultat positif. On ne met pas le
    /// multiplicateur en cache durablement : `RemoteConfigManager` peut rafraîchir sa valeur en cours
    /// de session (`fetchAndActivate` au démarrage, en arrière-plan) et le figer changerait les cibles
    /// de quêtes — donc le comportement du jeu.
    private var hasClaimableSideQuest: Bool {
        let mult = questDifficultyMult
        for quest in SideQuest.all {
            guard !isSideQuestClaimed(quest), isSideQuestAvailable(quest) else { continue }
            if quest.requirements.allSatisfy({ sideQuestValue(for: $0.metric) >= $0.target * mult }) {
                return true
            }
        }
        return false
    }
}
