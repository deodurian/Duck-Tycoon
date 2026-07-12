import Foundation

enum MissionType: String, Codable {
    case intro // Tutoriel
    case daily // Quotidienne
}

enum MissionStatus: String, Codable {
    case notStarted
    case inProgress
    case completed
    case claimed
}

enum MissionActionType: String, Codable {
    case openWoodenCrate
    case assignDuckToFactory
    case upgradeFactory
    case openCrates
    case recycleDuck
    case unlockFusionLab
    case fuseCommonDuck
    case reachIncome
    case totalRecycleCount // Avoir recyclé au moins X canards jusqu'à présent
    case upgradeDuckSize
    case upgradeDuckMutation
    case reachDuckLevel
    case bulkRecycle
    case unlockUpgrades
    case autoFusion // Auto fusion simple
    case megaFusion // Pas implémenté encore, on l'assimilera à l'auto-fusion ou une fusion de masse
    case bulkOpenCrates // Ouverture multiple d'au moins X
    case ritual
    case assignHighLevelDucks // 5 canards lvl 30+ à 5 usines lvl 30+
    case assignPerk
    case totalFusionCount
    case haveGoldenRitual
    case maxRepeatableUpgrades
    case haveMaxMythicDuck
    case prestige
    case none
}

struct Mission: Identifiable, Codable {
    var id: String
    let title: String
    let description: String
    let type: MissionType
    var status: MissionStatus
    let actionType: MissionActionType
    
    // For progress tracking
    var currentProgress: BigNumber // Utile pour les gros nombres comme l'argent
    let targetProgress: BigNumber
    
    // Pour certaines missions qui requièrent des paramètres spécifiques
    var targetLevel: Int? = nil
    var targetCount: Int? = nil
    var targetRarity: DuckRarity? = nil
    
    // Reward details
    let rewardXP: Int
    // We will just drop Perks when a tutorial mission gives one, or maybe give gems.
    // The prompt didn't specify rewards for the tutorial, only that level 10 gives 1 perk factory & 1 perk duck.
    
    init(id: String, title: String, description: String, type: MissionType, status: MissionStatus = .inProgress, actionType: MissionActionType, currentProgress: BigNumber = .zero, targetProgress: BigNumber, targetLevel: Int? = nil, targetCount: Int? = nil, targetRarity: DuckRarity? = nil, rewardXP: Int = 100) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.status = status
        self.actionType = actionType
        self.currentProgress = currentProgress
        self.targetProgress = targetProgress
        self.targetLevel = targetLevel
        self.targetCount = targetCount
        self.targetRarity = targetRarity
        self.rewardXP = rewardXP
    }
}
