import Foundation
import Observation
import CoreGraphics
import SwiftUI

extension Double {
    func roundedToSixSignificantDigits() -> Double {
        return Double(String(format: "%.6g", self)) ?? self
    }
    
    // MARK: - Safe Math Helpers
}

/// Représente l'état complet du jeu pour la sauvegarde
struct GameState: Codable, Sendable {
    var money: BigNumber = .zero
    var mutationPoints: BigNumber = .zero
    
    var inventory: [Duck] = [Duck(rarity: .commun, size: .petit, mutation: .aucune)]
    var factories: [DuckFactory] = [DuckFactory(name: "Usine 1")]
    
    var lastSaveDate: Date = Date()
    
    // Système d'améliorations
    var purchasedUpgrades: Set<UpgradeID> = []          // déblocages achetés
    var upgradeLevels: [UpgradeID: Int] = [:]           // niveau de chaque bonus
    
    // Statistiques pour les missions
    var totalRecycledDucks: Int = 0
    var totalFusionsDone: Int = 0
    var totalMaxedRepeatableUpgrades: Int = 0
    var totalMutationPointsEarned: BigNumber = .zero

    // Automatisation
    var autoCrateTargetId: String? = nil; var autoFactoryLevels: [UUID: Int] = [:]

    // Prestige
    var currentStars: BigNumber = .zero; var totalStars: BigNumber = .zero
    var spentStars: BigNumber = .zero; var unspentStars: BigNumber = .zero
    var purchasedPrestigeUpgrades: Set<String> = []; var gems: BigNumber = .zero

    // Réacteur Stellaire : allocation des étoiles non dépensées (remplace les bonus passifs de totalStars)
    var starsInEnergy: BigNumber = .zero        // +10% revenus (Argent) par étoile
    var starsInMutagen: BigNumber = .zero       // +5% revenus (ADN) par étoile
    var starsInOptimization: BigNumber = .zero  // réduit le coût des usines (asymptotique)
    var reactorCooldownEndTime: Date? = nil     // cooldown de respec (12 h)

    // Player Level, Missions, Perks
    var playerLevel: Int = 1; var playerXP: Int = 0
    var missions: [Mission] = []; var perksInventory: [Perk] = []

    // Story Mode
    var currentStoryStep: Int = 0
    var isStoryQuestReadyToClaim: Bool = false
    var storyFlags: [String: Bool] = [:]

    // Quêtes Secondaires
    var totalDucksFromCrates: Int = 0
    var claimedSideQuestIds: Set<String> = []
    var storyVersion: Int = 2
    
    // Ads
    var adBoostMultiplier: Double = 1.0
    var adBoostEndTime: Date? = nil
    var nextMysteryCrateDate: Date? = nil
    var dailyAdGemsCount: Int = 0
    var lastAdGemsDate: Date? = nil

    // Collection (Compendium)
    var unlockedDucks: Set<String> = []
    var discoveredPerks: [String: Int] = [:]
    var claimedRarityCollections: Set<String> = []
    var claimedAllDucksCollection: Bool = false
    var claimedAllPerksCollection: Bool = false

    // Custom Codable implementation for backward compatibility
    enum CodingKeys: String, CodingKey {
        case money, mutationPoints, inventory, factories, lastSaveDate
        case purchasedUpgrades, upgradeLevels
        case totalRecycledDucks, totalFusionsDone, totalMaxedRepeatableUpgrades, totalMutationPointsEarned
        case autoCrateTargetId, autoFactoryLevels
        case currentStars, totalStars, spentStars, unspentStars, purchasedPrestigeUpgrades
        case gems
        case starsInEnergy, starsInMutagen, starsInOptimization, reactorCooldownEndTime
        case playerLevel, playerXP, missions, perksInventory
        case currentStoryStep, isStoryQuestReadyToClaim, storyFlags
        case totalDucksFromCrates, claimedSideQuestIds, storyVersion
        case adBoostMultiplier, adBoostEndTime, nextMysteryCrateDate, dailyAdGemsCount, lastAdGemsDate
        case unlockedDucks, discoveredPerks, claimedRarityCollections, claimedAllDucksCollection, claimedAllPerksCollection
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.money = try container.decodeIfPresent(BigNumber.self, forKey: .money) ?? .zero
        
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
        self.totalMutationPointsEarned = try container.decodeIfPresent(BigNumber.self, forKey: .totalMutationPointsEarned) ?? .zero
        
        self.autoCrateTargetId = try container.decodeIfPresent(String.self, forKey: .autoCrateTargetId)
        self.autoFactoryLevels = try container.decodeIfPresent([UUID: Int].self, forKey: .autoFactoryLevels) ?? [:]
        
        // Migration logic for stars (Int -> BigNumber)
        if let csInt = try? container.decodeIfPresent(Int.self, forKey: .currentStars) { self.currentStars = BigNumber(Double(csInt)) } else { self.currentStars = try container.decodeIfPresent(BigNumber.self, forKey: .currentStars) ?? .zero }
        if let tsInt = try? container.decodeIfPresent(Int.self, forKey: .totalStars) { self.totalStars = BigNumber(Double(tsInt)) } else { self.totalStars = try container.decodeIfPresent(BigNumber.self, forKey: .totalStars) ?? .zero }
        if let ssInt = try? container.decodeIfPresent(Int.self, forKey: .spentStars) { self.spentStars = BigNumber(Double(ssInt)) } else { self.spentStars = try container.decodeIfPresent(BigNumber.self, forKey: .spentStars) ?? .zero }
        if let usInt = try? container.decodeIfPresent(Int.self, forKey: .unspentStars) { self.unspentStars = BigNumber(Double(usInt)) } else { self.unspentStars = try container.decodeIfPresent(BigNumber.self, forKey: .unspentStars) ?? .zero }
        
        self.purchasedPrestigeUpgrades = try container.decodeIfPresent(Set<String>.self, forKey: .purchasedPrestigeUpgrades) ?? []
        
        // Migration logic for free stars
        if self.unspentStars == .zero && self.totalStars > .zero {
            let diff = self.totalStars - self.spentStars
            self.unspentStars = diff > .zero ? diff : .zero
        }
        
        self.gems = try container.decodeIfPresent(BigNumber.self, forKey: .gems) ?? .zero

        self.starsInEnergy = try container.decodeIfPresent(BigNumber.self, forKey: .starsInEnergy) ?? .zero
        self.starsInMutagen = try container.decodeIfPresent(BigNumber.self, forKey: .starsInMutagen) ?? .zero
        self.starsInOptimization = try container.decodeIfPresent(BigNumber.self, forKey: .starsInOptimization) ?? .zero
        self.reactorCooldownEndTime = try container.decodeIfPresent(Date.self, forKey: .reactorCooldownEndTime)

        self.playerLevel = try container.decodeIfPresent(Int.self, forKey: .playerLevel) ?? 1
        self.playerXP = try container.decodeIfPresent(Int.self, forKey: .playerXP) ?? 0
        self.missions = try container.decodeIfPresent([Mission].self, forKey: .missions) ?? []
        // Migration: Old perks were strings, new perks are custom structs. If we fail to decode [Perk], default to []
        self.perksInventory = try container.decodeIfPresent([Perk].self, forKey: .perksInventory) ?? []
        
        self.currentStoryStep = try container.decodeIfPresent(Int.self, forKey: .currentStoryStep) ?? 0
        self.isStoryQuestReadyToClaim = try container.decodeIfPresent(Bool.self, forKey: .isStoryQuestReadyToClaim) ?? false
        self.storyFlags = try container.decodeIfPresent([String: Bool].self, forKey: .storyFlags) ?? [:]
        
        self.totalDucksFromCrates = try container.decodeIfPresent(Int.self, forKey: .totalDucksFromCrates) ?? 0
        self.claimedSideQuestIds = try container.decodeIfPresent(Set<String>.self, forKey: .claimedSideQuestIds) ?? []
        self.storyVersion = try container.decodeIfPresent(Int.self, forKey: .storyVersion) ?? 1
        
        self.adBoostMultiplier = try container.decodeIfPresent(Double.self, forKey: .adBoostMultiplier) ?? 1.0
        self.adBoostEndTime = try container.decodeIfPresent(Date.self, forKey: .adBoostEndTime)
        self.nextMysteryCrateDate = try container.decodeIfPresent(Date.self, forKey: .nextMysteryCrateDate)
        self.dailyAdGemsCount = try container.decodeIfPresent(Int.self, forKey: .dailyAdGemsCount) ?? 0
        self.lastAdGemsDate = try container.decodeIfPresent(Date.self, forKey: .lastAdGemsDate)

        self.unlockedDucks = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedDucks) ?? []
        self.discoveredPerks = try container.decodeIfPresent([String: Int].self, forKey: .discoveredPerks) ?? [:]
        self.claimedRarityCollections = try container.decodeIfPresent(Set<String>.self, forKey: .claimedRarityCollections) ?? []
        self.claimedAllDucksCollection = try container.decodeIfPresent(Bool.self, forKey: .claimedAllDucksCollection) ?? false
        self.claimedAllPerksCollection = try container.decodeIfPresent(Bool.self, forKey: .claimedAllPerksCollection) ?? false
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
        try container.encode(totalMutationPointsEarned, forKey: .totalMutationPointsEarned)
        try container.encodeIfPresent(autoCrateTargetId, forKey: .autoCrateTargetId)
        try container.encode(autoFactoryLevels, forKey: .autoFactoryLevels)
        try container.encode(currentStars, forKey: .currentStars)
        try container.encode(totalStars, forKey: .totalStars)
        try container.encode(spentStars, forKey: .spentStars)
        try container.encode(unspentStars, forKey: .unspentStars)
        try container.encode(purchasedPrestigeUpgrades, forKey: .purchasedPrestigeUpgrades)
        try container.encode(gems, forKey: .gems)
        try container.encode(starsInEnergy, forKey: .starsInEnergy)
        try container.encode(starsInMutagen, forKey: .starsInMutagen)
        try container.encode(starsInOptimization, forKey: .starsInOptimization)
        try container.encodeIfPresent(reactorCooldownEndTime, forKey: .reactorCooldownEndTime)
        try container.encode(playerLevel, forKey: .playerLevel)
        try container.encode(playerXP, forKey: .playerXP)
        try container.encode(missions, forKey: .missions)
        try container.encode(perksInventory, forKey: .perksInventory)
        try container.encode(currentStoryStep, forKey: .currentStoryStep)
        try container.encode(isStoryQuestReadyToClaim, forKey: .isStoryQuestReadyToClaim)
        try container.encode(storyFlags, forKey: .storyFlags)
        try container.encode(totalDucksFromCrates, forKey: .totalDucksFromCrates)
        try container.encode(claimedSideQuestIds, forKey: .claimedSideQuestIds)
        try container.encode(storyVersion, forKey: .storyVersion)
        try container.encode(adBoostMultiplier, forKey: .adBoostMultiplier)
        try container.encodeIfPresent(adBoostEndTime, forKey: .adBoostEndTime)
        try container.encodeIfPresent(nextMysteryCrateDate, forKey: .nextMysteryCrateDate)
        try container.encode(dailyAdGemsCount, forKey: .dailyAdGemsCount)
        try container.encodeIfPresent(lastAdGemsDate, forKey: .lastAdGemsDate)
        try container.encode(unlockedDucks, forKey: .unlockedDucks)
        try container.encode(discoveredPerks, forKey: .discoveredPerks)
        try container.encode(claimedRarityCollections, forKey: .claimedRarityCollections)
        try container.encode(claimedAllDucksCollection, forKey: .claimedAllDucksCollection)
        try container.encode(claimedAllPerksCollection, forKey: .claimedAllPerksCollection)
    }
}

@Observable
class GameManager {
    var money: BigNumber = .zero
    var mutationPoints: BigNumber = .zero
    var inventory: [Duck] = [Duck(rarity: .commun, size: .petit, mutation: .aucune)]
    var factories: [DuckFactory] = [DuckFactory(name: "Usine 1")]
    var lastSaveDate: Date = Date()
    
    // Système d'améliorations
    var purchasedUpgrades: Set<UpgradeID> = []
    var upgradeLevels: [UpgradeID: Int] = [:]
    
    // Statistiques pour les missions
    var totalRecycledDucks: Int = 0
    var totalFusionsDone: Int = 0
    var totalMaxedRepeatableUpgrades: Int = 0
    var totalMutationPointsEarned: BigNumber = .zero
    
    // Automatisation
    var autoCrateTargetId: String? = nil; var autoFactoryLevels: [UUID: Int] = [:]
    
    // Prestige
    var currentStars: BigNumber = .zero; var totalStars: BigNumber = .zero
    var spentStars: BigNumber = .zero; var unspentStars: BigNumber = .zero
    var purchasedPrestigeUpgrades: Set<String> = []; var gems: BigNumber = .zero

    // Réacteur Stellaire
    var starsInEnergy: BigNumber = .zero
    var starsInMutagen: BigNumber = .zero
    var starsInOptimization: BigNumber = .zero
    var reactorCooldownEndTime: Date? = nil

    // Player Level, Missions, Perks
    var playerLevel: Int = 1; var playerXP: Int = 0
    var missions: [Mission] = []; var perksInventory: [Perk] = []

    // Story Mode
    var currentStoryStep: Int = 0
    var isStoryQuestReadyToClaim: Bool = false
    var storyFlags: [String: Bool] = [:]

    // Quêtes Secondaires
    var totalDucksFromCrates: Int = 0
    var claimedSideQuestIds: Set<String> = []
    var storyVersion: Int = 2

    // Ads
    var adBoostMultiplier: Double = 1.0
    var adBoostEndTime: Date? = nil
    var nextMysteryCrateDate: Date? = nil
    var dailyAdGemsCount: Int = 0
    var lastAdGemsDate: Date? = nil

    // Collection (Compendium)
    var unlockedDucks: Set<String> = []
    var discoveredPerks: [String: Int] = [:]
    var claimedRarityCollections: Set<String> = []
    var claimedAllDucksCollection: Bool = false
    var claimedAllPerksCollection: Bool = false

    // Feedback UX (transient, non persisté)
    var activeToast: ToastMessage? = nil
    var confettiBurst: Int = 0
    /// Badge "nouveau perk obtenu" (onglet Usines). Effacé à l'ouverture de la feuille des perks.
    var hasUnseenPerk: Bool = false
    /// Badge "nouveau canard débloqué" (onglet Canards). Effacé à l'ouverture de la Collection.
    var hasUnseenCollectionDuck: Bool = false
    /// Badge "récompense de collection réclamable" (onglet Canards). Valeur DÉRIVÉE, non persistée.
    ///
    /// Coût évité : elle était calculée à la volée dans `hasNotification(forTab:)`, donc à chaque `body`
    /// de `CustomTabBar` — c'est-à-dire chaque seconde, la barre observant des propriétés mutées par le
    /// tick. Chaque évaluation reconstruisait ~140 String (45 clés canard + ~90 clés perk) et autant de
    /// lookups. On la stocke ici et on ne la recalcule qu'aux rares instants où l'état de collection peut
    /// réellement changer (`refreshClaimableCollectionReward()`), et on ne l'écrit que si elle change :
    /// la pastille affichée est strictement la même dans tous les cas.
    var hasClaimableCollectionReward: Bool = false
    /// Quêtes secondaires déjà annoncées comme réclamables (évite de re-toaster à chaque tick).
    @ObservationIgnored var announcedClaimableSideQuestIds: Set<String> = []

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
    // Index perk-par-id : évite les scans linéaires O(perks) répétés (perksInventory grandit tout au long de la partie).
    @ObservationIgnored var perkById: [UUID: Perk] = [:]
    @ObservationIgnored var isPerkCacheValid = false
    @ObservationIgnored var autoCrateAccumulator: Double = 0
    @ObservationIgnored var xpAccumulator: Double = 0
    @ObservationIgnored var autoFactoryAccumulators: [UUID: Double] = [:]
    @ObservationIgnored var saveWorkItem: DispatchWorkItem? = nil
    /// Heure de la dernière écriture disque RÉELLE (voir la fenêtre de coalescence dans `saveGame`).
    @ObservationIgnored var lastDiskWriteDate: Date = .distantPast
    
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
        st.totalMutationPointsEarned = totalMutationPointsEarned
        st.autoCrateTargetId = autoCrateTargetId
        st.autoFactoryLevels = autoFactoryLevels
        st.currentStars = currentStars
        st.totalStars = totalStars
        st.spentStars = spentStars
        st.unspentStars = unspentStars
        st.purchasedPrestigeUpgrades = purchasedPrestigeUpgrades
        st.gems = gems
        st.starsInEnergy = starsInEnergy
        st.starsInMutagen = starsInMutagen
        st.starsInOptimization = starsInOptimization
        st.reactorCooldownEndTime = reactorCooldownEndTime
        st.playerLevel = playerLevel
        st.playerXP = playerXP
        st.missions = missions
        st.perksInventory = perksInventory
        st.currentStoryStep = currentStoryStep
        st.isStoryQuestReadyToClaim = isStoryQuestReadyToClaim
        st.storyFlags = storyFlags
        st.totalDucksFromCrates = totalDucksFromCrates
        st.claimedSideQuestIds = claimedSideQuestIds
        st.storyVersion = storyVersion
        st.adBoostMultiplier = adBoostMultiplier
        st.adBoostEndTime = adBoostEndTime
        st.nextMysteryCrateDate = nextMysteryCrateDate
        st.dailyAdGemsCount = dailyAdGemsCount
        st.lastAdGemsDate = lastAdGemsDate
        st.unlockedDucks = unlockedDucks
        st.discoveredPerks = discoveredPerks
        st.claimedRarityCollections = claimedRarityCollections
        st.claimedAllDucksCollection = claimedAllDucksCollection
        st.claimedAllPerksCollection = claimedAllPerksCollection
        return st
    }
    
    /// Instance unique du jeu.
    ///
    /// `ContentView` est reconstruit par SwiftUI chaque fois que la vue parente réévalue son `body` :
    /// avec `@State private var gameManager = GameManager()`, l'expression d'initialisation était donc
    /// exécutée à chaque reconstruction (SwiftUI jette la valeur si l'état existe déjà, mais l'objet a
    /// bien été construit). Résultat : la sauvegarde entière était redécodée en JSON sur le thread
    /// principal plusieurs fois par seconde sur une grosse partie, plus un `Timer` reprogrammé à chaque
    /// fois. Passer par une instance partagée rend ces reconstructions gratuites.
    static let shared = GameManager()

    private init() {
        loadGame()
        syncCollectionWithCurrentState()
        // Les badges "nouveau" ne doivent pas s'allumer au lancement à cause du rattrapage de collection.
        hasUnseenPerk = false
        hasUnseenCollectionDuck = false
        // Les quêtes déjà réclamables au lancement ne doivent pas déclencher de bannière.
        announcedClaimableSideQuestIds = Set(SideQuest.all.filter { canClaimSideQuest($0) }.map { $0.id })
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
                invalidatePerkCache()
                registerPerkDiscovery(factoryPerk)
                registerPerkDiscovery(duckPerk)
                hasUnseenPerk = true
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
        totalMutationPointsEarned += amount
        evaluateAffordableCrates(reset: false)
    }
}
