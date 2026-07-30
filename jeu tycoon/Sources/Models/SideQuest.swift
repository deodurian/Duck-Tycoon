import Foundation

/// La statistique du jeu sur laquelle une quête secondaire mesure sa progression
enum SideQuestMetric {
    case ducksFromCrates   // canards obtenus en ouvrant des capsules (cumulé)
    case ducksRecycled     // canards recyclés (cumulé)
    case fusionsDone       // fusions effectuées (cumulé)
    case inventoryCount    // canards actuellement dans l'inventaire
    case playerLevel       // niveau du joueur
    case earningsPerSecond // argent généré par seconde
    case mutationPointsEarned // points de mutation (ADN) totaux gagnés
}

struct SideQuestRequirement {
    let metric: SideQuestMetric
    let target: Double
}

/// Une quête secondaire : un objectif basé sur les statistiques du joueur,
/// récompensé par un déblocage permanent (UpgradeID inséré dans purchasedUpgrades).
struct SideQuest: Identifiable {
    let id: String
    let title: String
    let description: String
    let requirements: [SideQuestRequirement]
    let rewardId: UpgradeID
    /// La quête n'apparaît « disponible » que si la quête prérequise est réclamée
    let prerequisiteQuestId: String?

    // Convenience initializer for a single requirement
    init(title: String, description: String, metric: SideQuestMetric, target: Double, rewardId: UpgradeID, prerequisiteQuestId: String? = nil) {
        self.id = rewardId.rawValue
        self.title = title
        self.description = description
        self.requirements = [SideQuestRequirement(metric: metric, target: target)]
        self.rewardId = rewardId
        self.prerequisiteQuestId = prerequisiteQuestId
    }
    
    // Initializer for multiple requirements
    init(title: String, description: String, requirements: [SideQuestRequirement], rewardId: UpgradeID, prerequisiteQuestId: String? = nil) {
        self.id = rewardId.rawValue
        self.title = title
        self.description = description
        self.requirements = requirements
        self.rewardId = rewardId
        self.prerequisiteQuestId = prerequisiteQuestId
    }

    // MARK: - Catalogue

    static let all: [SideQuest] = [
        // ── Ouverture de capsules ────────────────────────────────────────────
        SideQuest(
            title: "Fournisseur",
            description: "Obtenir 32 canards via des capsules",
            metric: .ducksFromCrates, target: 32,
            rewardId: .multipleOpenX5
        ),
        SideQuest(
            title: "Grossiste",
            description: "Obtenir 160 canards via des capsules",
            metric: .ducksFromCrates, target: 160,
            rewardId: .multipleOpenX10,
            prerequisiteQuestId: UpgradeID.multipleOpenX5.rawValue
        ),
        SideQuest(
            title: "Magnat des Capsules",
            description: "Obtenir 800 canards via des capsules",
            metric: .ducksFromCrates, target: 800,
            rewardId: .multipleOpenMax,
            prerequisiteQuestId: UpgradeID.multipleOpenX10.rawValue
        ),
        SideQuest(
            title: "La Cadence Infernale",
            description: "Obtenir 200 canards et faire 20 fusions",
            requirements: [
                SideQuestRequirement(metric: .ducksFromCrates, target: 200),
                SideQuestRequirement(metric: .fusionsDone, target: 20)
            ],
            rewardId: .holdToOpen
        ),

        // ── Fusion ──────────────────────────────────────────────────────────
        SideQuest(
            title: "Le Grand Compresseur",
            description: "Effectuer 44 fusions au total",
            metric: .fusionsDone, target: 44,
            rewardId: .megaFusion
        ),

        // ── Recyclage ───────────────────────────────────────────────────────
        SideQuest(
            title: "Le Recycleur Fou",
            description: "Obtenir 15 000 points d'ADN au total",
            metric: .mutationPointsEarned, target: 15000,
            rewardId: .bulkRecycle
        ),
        SideQuest(
            title: "Tri Sélectif Industriel",
            description: "Recycler 1500 canards au total",
            metric: .ducksRecycled, target: 1500,
            rewardId: .autoRecycleFilter,
            prerequisiteQuestId: UpgradeID.bulkRecycle.rawValue
        ),
        SideQuest(
            title: "L'Annihilateur",
            description: "Recycler 8000 canards au total",
            metric: .ducksRecycled, target: 8000,
            rewardId: .annihilation,
            prerequisiteQuestId: UpgradeID.autoRecycleFilter.rawValue
        ),

        // ── Collection ──────────────────────────────────────────────────────
        SideQuest(
            title: "Collectionneur I",
            description: "Avoir 100 canards et générer 100k 💰/s",
            requirements: [
                SideQuestRequirement(metric: .inventoryCount, target: 100),
                SideQuestRequirement(metric: .earningsPerSecond, target: 100000)
            ],
            rewardId: .inventory1000
        ),
        SideQuest(
            title: "Collectionneur II",
            description: "Avoir 900 canards dans l'inventaire",
            metric: .inventoryCount, target: 900,
            rewardId: .inventory5000,
            prerequisiteQuestId: UpgradeID.inventory1000.rawValue
        ),
        SideQuest(
            title: "Collectionneur III",
            description: "Avoir 4500 canards dans l'inventaire",
            metric: .inventoryCount, target: 4500,
            rewardId: .inventory10000,
            prerequisiteQuestId: UpgradeID.inventory5000.rawValue
        )
    ]
}
