import Foundation
import Observation
import CoreGraphics

extension Double {
    func roundedToSixSignificantDigits() -> Double {
        return Double(String(format: "%.6g", self)) ?? self
    }
    
    // MARK: - Safe Math Helpers
}

/// Représente l'état complet du jeu pour la sauvegarde
struct GameState: Codable, Sendable {
    var money: BigNumber = BigNumber(150.0)
    var mutationPoints: BigNumber = .zero
    
    var inventory: [Duck] = []
    var factories: [DuckFactory] = [DuckFactory(name: "Usine 1")]
    
    var lastSaveDate: Date = Date()
    
    // Système d'améliorations
    var purchasedUpgrades: Set<UpgradeID> = []          // déblocages achetés
    var upgradeLevels: [UpgradeID: Int] = [:]           // niveau de chaque bonus
    
    // Statistiques pour les missions
    var totalRecycledDucks: Int = 0
    var totalFusionsDone: Int = 0
    var totalMaxedRepeatableUpgrades: Int = 0
    
    // Automatisation
    var autoCrateTargetId: String? = nil; var autoFactoryLevels: [UUID: Int] = [:]
    
    // Prestige
    var currentStars: BigNumber = .zero; var totalStars: BigNumber = .zero
    var spentStars: BigNumber = .zero; var unspentStars: BigNumber = .zero
    var purchasedPrestigeUpgrades: Set<String> = []; var gems: BigNumber = .zero
    
    // Player Level, Missions, Perks
    var playerLevel: Int = 1; var playerXP: Int = 0
    var missions: [Mission] = []; var perksInventory: [Perk] = []
    
    // Custom Codable implementation for backward compatibility
    enum CodingKeys: String, CodingKey {
        case money, mutationPoints, inventory, factories, lastSaveDate
        case purchasedUpgrades, upgradeLevels
        case totalRecycledDucks, totalFusionsDone, totalMaxedRepeatableUpgrades
        case autoCrateTargetId, autoFactoryLevels
        case currentStars, totalStars, spentStars, unspentStars, purchasedPrestigeUpgrades
        case gems
        case playerLevel, playerXP, missions, perksInventory
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.money = try container.decodeIfPresent(BigNumber.self, forKey: .money) ?? BigNumber(150.0)
        
        // Migration logic for mutationPoints (Int -> BigNumber)
        if let mpInt = try? container.decodeIfPresent(Int.self, forKey: .mutationPoints) {
            self.mutationPoints = BigNumber(Double(mpInt))
        } else {
            self.mutationPoints = try container.decodeIfPresent(BigNumber.self, forKey: .mutationPoints) ?? .zero
        }
        
        self.inventory = try container.decodeIfPresent([Duck].self, forKey: .inventory) ?? []
        self.factories = try container.decodeIfPresent([DuckFactory].self, forKey: .factories) ?? [DuckFactory(name: "Usine 1")]
        self.lastSaveDate = try container.decodeIfPresent(Date.self, forKey: .lastSaveDate) ?? Date()
        
        self.purchasedUpgrades = try container.decodeIfPresent(Set<UpgradeID>.self, forKey: .purchasedUpgrades) ?? []
        self.upgradeLevels = try container.decodeIfPresent([UpgradeID: Int].self, forKey: .upgradeLevels) ?? [:]
        
        self.totalRecycledDucks = try container.decodeIfPresent(Int.self, forKey: .totalRecycledDucks) ?? 0
        self.totalFusionsDone = try container.decodeIfPresent(Int.self, forKey: .totalFusionsDone) ?? 0
        self.totalMaxedRepeatableUpgrades = try container.decodeIfPresent(Int.self, forKey: .totalMaxedRepeatableUpgrades) ?? 0
        
        self.autoCrateTargetId = try container.decodeIfPresent(String.self, forKey: .autoCrateTargetId)
        self.autoFactoryLevels = try container.decodeIfPresent([UUID: Int].self, forKey: .autoFactoryLevels) ?? [:]
        
        // Migration logic for stars (Int -> BigNumber)
        if let csInt = try? container.decodeIfPresent(Int.self, forKey: .currentStars) { self.currentStars = BigNumber(Double(csInt)) } else { self.currentStars = try container.decodeIfPresent(BigNumber.self, forKey: .currentStars) ?? .zero }
        if let tsInt = try? container.decodeIfPresent(Int.self, forKey: .totalStars) { self.totalStars = BigNumber(Double(tsInt)) } else { self.totalStars = try container.decodeIfPresent(BigNumber.self, forKey: .totalStars) ?? .zero }
        if let ssInt = try? container.decodeIfPresent(Int.self, forKey: .spentStars) { self.spentStars = BigNumber(Double(ssInt)) } else { self.spentStars = try container.decodeIfPresent(BigNumber.self, forKey: .spentStars) ?? .zero }
        if let usInt = try? container.decodeIfPresent(Int.self, forKey: .unspentStars) { self.unspentStars = BigNumber(Double(usInt)) } else { self.unspentStars = try container.decodeIfPresent(BigNumber.self, forKey: .unspentStars) ?? .zero }
        
        self.purchasedPrestigeUpgrades = try container.decodeIfPresent(Set<String>.self, forKey: .purchasedPrestigeUpgrades) ?? []
        
        self.gems = try container.decodeIfPresent(BigNumber.self, forKey: .gems) ?? .zero
        
        self.playerLevel = try container.decodeIfPresent(Int.self, forKey: .playerLevel) ?? 1
        self.playerXP = try container.decodeIfPresent(Int.self, forKey: .playerXP) ?? 0
        self.missions = try container.decodeIfPresent([Mission].self, forKey: .missions) ?? []
        // Migration: Old perks were strings, new perks are custom structs. If we fail to decode [Perk], default to []
        self.perksInventory = try container.decodeIfPresent([Perk].self, forKey: .perksInventory) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(money, forKey: .money)
        try container.encode(mutationPoints, forKey: .mutationPoints)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(factories, forKey: .factories)
        try container.encode(lastSaveDate, forKey: .lastSaveDate)
        try container.encode(purchasedUpgrades, forKey: .purchasedUpgrades)
        try container.encode(upgradeLevels, forKey: .upgradeLevels)
        try container.encode(totalRecycledDucks, forKey: .totalRecycledDucks)
        try container.encode(totalFusionsDone, forKey: .totalFusionsDone)
        try container.encode(totalMaxedRepeatableUpgrades, forKey: .totalMaxedRepeatableUpgrades)
        try container.encodeIfPresent(autoCrateTargetId, forKey: .autoCrateTargetId)
        try container.encode(autoFactoryLevels, forKey: .autoFactoryLevels)
        try container.encode(currentStars, forKey: .currentStars)
        try container.encode(totalStars, forKey: .totalStars)
        try container.encode(spentStars, forKey: .spentStars)
        try container.encode(unspentStars, forKey: .unspentStars)
        try container.encode(purchasedPrestigeUpgrades, forKey: .purchasedPrestigeUpgrades)
        try container.encode(gems, forKey: .gems)
        try container.encode(playerLevel, forKey: .playerLevel)
        try container.encode(playerXP, forKey: .playerXP)
        try container.encode(missions, forKey: .missions)
        try container.encode(perksInventory, forKey: .perksInventory)
    }
}

@Observable
class GameManager {
    var money: BigNumber = BigNumber(150.0)
    var mutationPoints: BigNumber = .zero
    var inventory: [Duck] = []
    var factories: [DuckFactory] = [DuckFactory(name: "Usine 1")]
    var lastSaveDate: Date = Date()
    
    // Système d'améliorations
    var purchasedUpgrades: Set<UpgradeID> = []
    var upgradeLevels: [UpgradeID: Int] = [:]
    
    // Statistiques pour les missions
    var totalRecycledDucks: Int = 0
    var totalFusionsDone: Int = 0
    var totalMaxedRepeatableUpgrades: Int = 0
    
    // Automatisation
    var autoCrateTargetId: String? = nil; var autoFactoryLevels: [UUID: Int] = [:]
    
    // Prestige
    var currentStars: BigNumber = .zero; var totalStars: BigNumber = .zero
    var spentStars: BigNumber = .zero; var unspentStars: BigNumber = .zero
    var purchasedPrestigeUpgrades: Set<String> = []; var gems: BigNumber = .zero
    
    // Player Level, Missions, Perks
    var playerLevel: Int = 1; var playerXP: Int = 0
    var missions: [Mission] = []; var perksInventory: [Perk] = []
    
    // Hors Ligne
    struct OfflineEarnings {
        let money: BigNumber
        let dna: BigNumber
        let xp: Int
        let seconds: TimeInterval
    }
    var pendingOfflineEarnings: OfflineEarnings? = nil
    
    // MARK: - Game Loop
    var hasPrestiged: Bool { (currentStars + spentStars) > .zero }
    
    // Cache de l'interface de boutique
    var affordableCrateKeys: Set<String> = []
    
    // Le Timer de la boucle principale
    var timer: Timer?
    @ObservationIgnored var lastTickTime: Date? = nil
    
    // Propriétés du Loop
    var isGamePaused = false
    var globalFlashOpacity: Double = 0.0
    var globalShakeOffset: CGSize = .zero
    @ObservationIgnored var pauseStartDate: Date? = nil
    
    var cachedEarningsPerSecond: BigNumber? = nil
    var cachedMutationsPerSecond: BigNumber? = nil
    @ObservationIgnored var assignedDucksCache: [UUID: Duck] = [:]
    @ObservationIgnored var isAssignedDucksCacheValid = false
    @ObservationIgnored var autoCrateAccumulator: Double = 0
    @ObservationIgnored var xpAccumulator: Double = 0
    @ObservationIgnored var autoFactoryAccumulators: [UUID: Double] = [:]
    @ObservationIgnored var saveWorkItem: DispatchWorkItem? = nil
    
    // Propriété state générée pour la sauvegarde
    var state: GameState {
        var st = GameState()
        st.money = money
        st.mutationPoints = mutationPoints
        st.inventory = inventory
        st.factories = factories
        st.lastSaveDate = lastSaveDate
        st.purchasedUpgrades = purchasedUpgrades
        st.upgradeLevels = upgradeLevels
        st.totalRecycledDucks = totalRecycledDucks
        st.totalFusionsDone = totalFusionsDone
        st.totalMaxedRepeatableUpgrades = totalMaxedRepeatableUpgrades
        st.autoCrateTargetId = autoCrateTargetId
        st.autoFactoryLevels = autoFactoryLevels
        st.currentStars = currentStars
        st.totalStars = totalStars
        st.spentStars = spentStars
        st.unspentStars = unspentStars
        st.purchasedPrestigeUpgrades = purchasedPrestigeUpgrades
        st.gems = gems
        st.playerLevel = playerLevel
        st.playerXP = playerXP
        st.missions = missions
        st.perksInventory = perksInventory
        return st
    }
    
    init() {
        loadGame()
        initializeTutorialMissions()
        evaluateAffordableCrates(reset: true)
        startGameLoop()
    }
    
    // MARK: - Level System
    func checkLevelUp() {
        var requiredXP = PlayerLevelSystem.requiredXP(for: playerLevel)
        var leveledUp = false
        
        while playerXP >= requiredXP {
            playerXP -= requiredXP
            playerLevel += 1
            
            // Récompenses tous les 10 niveaux
            if playerLevel % 10 == 0 {
                gems += BigNumber(10)
                let factoryPerk = Perk.rollRandom(type: .factory)
                let duckPerk = Perk.rollRandom(type: .duck)
                perksInventory.append(factoryPerk)
                perksInventory.append(duckPerk)
            }
            
            requiredXP = PlayerLevelSystem.requiredXP(for: playerLevel)
            leveledUp = true
        }
        
        if leveledUp {
            invalidateEarningsCache()
            saveGame()
        }
    }
    
    // MARK: - App Lifecycle
    deinit {
        timer?.invalidate()
     }
    
    // MARK: - Safe Math Helpers
    func addMutationPoints(_ amount: BigNumber) {
        mutationPoints += amount
    }
}
