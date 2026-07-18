import Foundation
import SwiftUI

// MARK: - Enums

enum DuckRarity: String, Codable, CaseIterable, Comparable {
    case commun = "Commun"
    case peuCommun = "Peu Commun"
    case rare = "Rare"
    case epique = "Épique"
    case legendaire = "Légendaire"
    case mythique = "Mythique"
    
    @MainActor var localizedName: String {
        return tr(self.rawValue)
    }
    
    nonisolated var multiplier: Double {
        switch self {
        case .commun: return 1.0
        case .peuCommun: return 2.5
        case .rare: return 8.0
        case .epique: return 30.0
        case .legendaire: return 150.0
        case .mythique: return 1000.0
        }
    }
    
    nonisolated var baseRecyclePoints: Double {
        switch self {
        case .commun: return 5.0
        case .peuCommun: return 15.0
        case .rare: return 50.0
        case .epique: return 200.0
        case .legendaire: return 1000.0
        case .mythique: return 10000.0
        }
    }
    
    var baseProbability: Double {
        switch self {
        case .commun: return 60.0
        case .peuCommun: return 25.0
        case .rare: return 10.0
        case .epique: return 4.0
        case .legendaire: return 0.9
        case .mythique: return 0.1
        }
    }
    
    var color: Color {
        switch self {
        case .commun: return .gray
        case .peuCommun: return .green
        case .rare: return .blue
        case .epique: return .purple
        case .legendaire: return .orange
        case .mythique: return .red
        }
    }
    
    var imageName: String {
        switch self {
        case .commun: return "duck_commun"
        case .peuCommun: return "duck_peu_commun"
        case .rare: return "duck_rare"
        case .epique: return "duck_epique"
        case .legendaire: return "duck_legendaire"
        case .mythique: return "duck_mythique"
        }
    }
    
    var shortName: String {
        switch self {
        case .commun: return "COM"
        case .peuCommun: return "PEU"
        case .rare: return "RAR"
        case .epique: return "EPI"
        case .legendaire: return "LEG"
        case .mythique: return "MYT"
        }
    }
    
    var revealTitle: String {
        switch self {
        case .commun: return "COMMUN !"
        case .peuCommun: return "PEU COMMUN !"
        case .rare: return "RARE !"
        case .epique: return "ÉPIQUE !"
        case .legendaire: return "LÉGENDAIRE !!!"
        case .mythique: return "MYTHIQUE !!!"
        }
    }
    
    var nextRarity: DuckRarity? {
        switch self {
        case .commun: return .peuCommun
        case .peuCommun: return .rare
        case .rare: return .epique
        case .epique: return .legendaire
        case .legendaire: return .mythique
        case .mythique: return nil
        }
    }
    
    nonisolated static func < (lhs: DuckRarity, rhs: DuckRarity) -> Bool {
        return lhs.multiplier < rhs.multiplier
    }
    
    // Multiplicateur pour les points de recyclage de base
    nonisolated var recycleMultiplier: Double {
        switch self {
        case .commun: return 1.0
        case .peuCommun: return 2.0
        case .rare: return 5.0
        case .epique: return 15.0
        case .legendaire: return 50.0
        case .mythique: return 200.0
        }
    }
    
    static func rollRandom(globalBonus: Double = 0.0) -> DuckRarity {
        let roll = Double.random(in: 0..<100)
        
        let baseCommun = DuckRarity.commun.baseProbability
        let communThreshold = max(0.0, baseCommun - (globalBonus * 100.0))
        
        if roll < communThreshold { return .commun }
        
        // Distribution of the remaining chance proportionally
        let remaining = 100.0 - communThreshold
        let originalRemaining = 100.0 - baseCommun
        
        var cumulative = communThreshold
        for rarity in DuckRarity.allCases where rarity != .commun {
            let share = remaining * (rarity.baseProbability / originalRemaining)
            cumulative += share
            if roll < cumulative {
                return rarity
            }
        }
        
        // Fallback to the rarest case
        return DuckRarity.allCases.last ?? .commun
    }
    
    // Le bonus qu'une rareté donne lors du recyclage d'un canard en masse
    nonisolated var bonusDeMasse: Double {
        switch self {
        case .commun: return 1.0
        case .peuCommun: return 1.1
        case .rare: return 1.3
        case .epique: return 1.6
        case .legendaire: return 2.0
        case .mythique: return 3.0
        }
    }
}

enum DuckSize: String, Codable, CaseIterable, Comparable {
    case petit = "Petit"
    case moyen = "Moyen"
    case grand = "Grand"
    case geant = "Géant"
    
    nonisolated var index: Int {
        switch self {
        case .petit: return 0
        case .moyen: return 1
        case .grand: return 2
        case .geant: return 3
        }
    }
    
    nonisolated static func fromIndex(_ i: Int) -> DuckSize {
        if i <= 0 { return .petit }
        if i == 1 { return .moyen }
        if i == 2 { return .grand }
        return .geant
    }
    
    nonisolated var multiplier: Double {
        switch self {
        case .petit: return 1.0
        case .moyen: return 1.5
        case .grand: return 2.5
        case .geant: return 5.0
        }
    }
    
    // Multiplicateur pour les points de recyclage
    nonisolated var recycleMultiplier: Double {
        switch self {
        case .petit: return 1.0
        case .moyen: return 1.5
        case .grand: return 2.0
        case .geant: return 3.0
        }
    }
    
    // Coût d'amélioration de base
    var upgradeCostBase: BigNumber {
        switch self {
        case .petit: return BigNumber(20.0) // Pour passer à moyen
        case .moyen: return BigNumber(60.0) // Pour passer à grand
        case .grand: return BigNumber(200.0) // Pour passer à géant
        case .geant: return .zero // Max
        }
    }
    
    var next: DuckSize? {
        switch self {
        case .petit: return .moyen
        case .moyen: return .grand
        case .grand: return .geant
        case .geant: return nil
        }
    }
    
    var baseProbability: Double {
        switch self {
        case .petit: return 70.0
        case .moyen: return 20.0
        case .grand: return 8.0
        case .geant: return 2.0
        }
    }
    
    nonisolated static func < (lhs: DuckSize, rhs: DuckSize) -> Bool {
        return lhs.multiplier < rhs.multiplier
    }
    
    // Poids pour la probabilité de drop dans les caisses
    static func rollRandom(genesCroissants: Bool = false) -> DuckSize {
        let roll = Double.random(in: 0..<100)
        let modifier = genesCroissants ? 1.618 : 0.0
        
        var cumulative: Double = 0.0
        for size in DuckSize.allCases {
            var chance = size.baseProbability
            
            // Les gènes croissants réduisent la chance d'avoir un petit et l'ajoutent au moyen
            if size == .petit {
                chance -= modifier
            } else if size == .moyen {
                chance += modifier
            }
            
            cumulative += chance
            if roll < cumulative {
                return size
            }
        }
        
        return .geant
    }
}

enum DuckMutation: String, Codable, CaseIterable, Comparable {
    case aucune = "Aucune"
    case dore = "Doré"
    case radioactif = "Radioactif"
    case cristallise = "Cristallisé"
    
    nonisolated var index: Int {
        switch self {
        case .aucune: return 0
        case .dore: return 1
        case .radioactif: return 2
        case .cristallise: return 3
        }
    }
    
    nonisolated static func fromIndex(_ i: Int) -> DuckMutation {
        if i <= 0 { return .aucune }
        if i == 1 { return .dore }
        if i == 2 { return .radioactif }
        return .cristallise
    }
    
    nonisolated var multiplier: Double {
        switch self {
        case .aucune: return 1.0
        case .dore: return 5.0
        case .radioactif: return 15.0
        case .cristallise: return 50.0
        }
    }
    
    nonisolated var recycleMultiplier: Double {
        switch self {
        case .aucune: return 1.0
        case .dore: return 2.0
        case .radioactif: return 3.0
        case .cristallise: return 5.0
        }
    }
    
    var upgradeCostBase: BigNumber {
        switch self {
        case .aucune: return BigNumber(50.0) // Pour passer à doré
        case .dore: return BigNumber(200.0) // Pour passer à radioactif
        case .radioactif: return BigNumber(800.0) // Pour passer à cristallisé
        case .cristallise: return .zero // Max
        }
    }
    
    var next: DuckMutation? {
        switch self {
        case .aucune: return .dore
        case .dore: return .radioactif
        case .radioactif: return .cristallise
        case .cristallise: return nil
        }
    }
    
    var baseProbability: Double {
        switch self {
        case .aucune: return 85.0
        case .dore: return 10.0
        case .radioactif: return 4.0
        case .cristallise: return 1.0
        }
    }
    
    var color: Color {
        switch self {
        case .aucune: return .primary
        case .dore: return .yellow
        case .radioactif: return .green
        case .cristallise: return .cyan
        }
    }
    
    nonisolated static func < (lhs: DuckMutation, rhs: DuckMutation) -> Bool {
        return lhs.multiplier < rhs.multiplier
    }
    
    // Les mutations sont rares au tirage
    static func rollRandom(bonusChance: Double = 0.0) -> DuckMutation {
        let roll = Double.random(in: 0..<100)
        
        let baseAucune = DuckMutation.aucune.baseProbability
        let aucuneThreshold = max(0.0, baseAucune - (bonusChance * 100.0))
        
        if roll < aucuneThreshold { return .aucune }
        
        // Distribution of the remaining chance proportionally
        let remaining = 100.0 - aucuneThreshold
        let originalRemaining = 100.0 - baseAucune
        
        var cumulative = aucuneThreshold
        for mutation in DuckMutation.allCases where mutation != .aucune {
            let share = remaining * (mutation.baseProbability / originalRemaining)
            cumulative += share
            if roll < cumulative {
                return mutation
            }
        }
        
        // Fallback to the last case
        return DuckMutation.allCases.last ?? .aucune
    }
}

// MARK: - Duck Model

struct Duck: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var rarity: DuckRarity
    var size: DuckSize
    var mutation: DuckMutation
    var ritualSuccesses: Int = 0
    var goldenRitualSuccesses: Int = 0
    
    var equippedPerkIds: [UUID] = []
    
    // Migration fields
    private var equippedPerkId: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, rarity, size, mutation, ritualSuccesses, goldenRitualSuccesses, equippedPerkId, equippedPerkIds, fusionLevel, customBasePrice, customRecycleValue, level
    }
    
    init(id: UUID = UUID(), rarity: DuckRarity, size: DuckSize, mutation: DuckMutation, ritualSuccesses: Int = 0, goldenRitualSuccesses: Int = 0, equippedPerkIds: [UUID] = [], fusionLevel: Int = 0, customBasePrice: BigNumber? = nil, customRecycleValue: BigNumber? = nil, level: Int = 1) {
        self.id = id
        self.rarity = rarity
        self.size = size
        self.mutation = mutation
        self.ritualSuccesses = ritualSuccesses
        self.goldenRitualSuccesses = goldenRitualSuccesses
        self.equippedPerkIds = equippedPerkIds
        self.fusionLevel = fusionLevel
        self.customBasePrice = customBasePrice
        self.customRecycleValue = customRecycleValue
        self.level = level
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.rarity = try container.decode(DuckRarity.self, forKey: .rarity)
        self.size = try container.decode(DuckSize.self, forKey: .size)
        self.mutation = try container.decode(DuckMutation.self, forKey: .mutation)
        self.ritualSuccesses = try container.decodeIfPresent(Int.self, forKey: .ritualSuccesses) ?? 0
        self.goldenRitualSuccesses = try container.decodeIfPresent(Int.self, forKey: .goldenRitualSuccesses) ?? 0
        
        if let singlePerkStr = try container.decodeIfPresent(String.self, forKey: .equippedPerkId), let singlePerkUUID = UUID(uuidString: singlePerkStr) {
            self.equippedPerkIds = [singlePerkUUID]
        } else {
            self.equippedPerkIds = try container.decodeIfPresent([UUID].self, forKey: .equippedPerkIds) ?? []
        }
        
        self.fusionLevel = try container.decodeIfPresent(Int.self, forKey: .fusionLevel) ?? 0
        self.customBasePrice = try container.decodeIfPresent(BigNumber.self, forKey: .customBasePrice)
        self.customRecycleValue = try container.decodeIfPresent(BigNumber.self, forKey: .customRecycleValue)
        self.level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(size, forKey: .size)
        try container.encode(mutation, forKey: .mutation)
        try container.encode(ritualSuccesses, forKey: .ritualSuccesses)
        try container.encode(goldenRitualSuccesses, forKey: .goldenRitualSuccesses)
        try container.encode(equippedPerkIds, forKey: .equippedPerkIds)
        try container.encode(fusionLevel, forKey: .fusionLevel)
        try container.encodeIfPresent(customBasePrice, forKey: .customBasePrice)
        try container.encodeIfPresent(customRecycleValue, forKey: .customRecycleValue)
        try container.encode(level, forKey: .level)
    }
    
    var totalRituals: Int {
        return ritualSuccesses + goldenRitualSuccesses
    }
    
    /// Probabilité de réussite du prochain rituel (de 0.0 à 1.0)
    func ritualSuccessChance(occulteLevel: Int = 0) -> Double {
        let baseFailure = Double(totalRituals + 1) * 0.05
        let reduction = Double(occulteLevel) * 0.05
        let actualFailure = max(0.005, baseFailure - reduction)
        return max(0.0, 1.0 - actualFailure)
    }
    
    // Fusion
    var fusionLevel: Int = 0
    var customBasePrice: BigNumber? = nil
    var customRecycleValue: BigNumber? = nil
    
    // Niveau du canard (1 à 100)
    var level: Int = 1
    
    // Le prix de base abstrait d'un canard
    nonisolated static let basePrice: Double = 5.0
    
    // MARK: - Dynamic Stats (including perks)
    
    nonisolated func getDynamicStats(with perks: [Perk]) -> (level: Int, size: DuckSize, mutation: DuckMutation, extraValueMultiplier: Double, recycleMultiplier: Double) {
        var tempLevel = level
        var tempSizeIdx = size.index
        var tempMutIdx = mutation.index
        
        var extraMultiplier = 1.0
        var recycleMult = 1.0
        
        for perk in perks {
            extraMultiplier += perk.duckValueBonus
            extraMultiplier += perk.duckExtraPerkBonus
            
            if perk.duckConditionalLevels(duckRarity: .commun) == 999 {
                // Mythic: maximize all
                tempLevel = 100
                tempSizeIdx = 3
                tempMutIdx = 3
            } else {
                let addedLevels = perk.duckConditionalLevels(duckRarity: rarity)
                let addedSize = perk.duckSizeIncrease
                let addedMut = perk.duckMutationIncrease
                
                tempLevel += addedLevels
                tempSizeIdx += addedSize
                tempMutIdx += addedMut
                
                if tempLevel > 100 {
                    extraMultiplier += perk.duckOverflowValueBonus
                }
                if tempSizeIdx > 3 {
                    extraMultiplier += perk.duckOverflowBonus
                }
                if tempMutIdx > 3 {
                    extraMultiplier += perk.duckOverflowBonus
                }
            }
            
            recycleMult *= perk.duckRecycleMutationMultiplier
        }
        
        let finalLevel = min(100, tempLevel)
        let finalSize = DuckSize.fromIndex(min(3, tempSizeIdx))
        let finalMutation = DuckMutation.fromIndex(min(3, tempMutIdx))
        
        return (finalLevel, finalSize, finalMutation, extraMultiplier, recycleMult)
    }
    
    /// Calcule la valeur de vente de ce canard
    nonisolated func calculateSellValue(with perks: [Perk]) -> BigNumber {
        let stats = getDynamicStats(with: perks)
        
        let ritualMultiplier = BigNumber.pow(BigNumber(2.0), Double(ritualSuccesses)) * BigNumber.pow(BigNumber(10.0), Double(goldenRitualSuccesses))
        let levelMultiplier = 1.0 + (Double(stats.level - 1) * 0.01)
        let base = customBasePrice ?? BigNumber(Duck.basePrice)
        var value = base * rarity.multiplier * stats.mutation.multiplier * stats.size.multiplier * levelMultiplier
        
        if customBasePrice == nil && fusionLevel > 0 {
            value *= BigNumber.pow(BigNumber(3.1), Double(fusionLevel))
        }
        
        return value * ritualMultiplier * stats.extraValueMultiplier
    }
    
    // Valeur de vente sans perks (pour affichage de base)
    nonisolated var sellValue: BigNumber {
        return calculateSellValue(with: [])
    }
    
    /// Calcule les points de mutation obtenus en recyclant ce canard
    nonisolated func calculateRecycleValue(with perks: [Perk]) -> BigNumber {
        let stats = getDynamicStats(with: perks)
        
        var baseValue: BigNumber
        if let custom = customRecycleValue {
            baseValue = custom * stats.size.recycleMultiplier * stats.mutation.recycleMultiplier
        } else {
            var value = rarity.baseRecyclePoints * stats.size.recycleMultiplier * stats.mutation.recycleMultiplier
            if fusionLevel > 0 {
                value *= Foundation.pow(3.1, Double(fusionLevel))
            }
            baseValue = BigNumber(value)
        }
        
        return baseValue * stats.recycleMultiplier
    }
    
    nonisolated var recycleValue: BigNumber {
        return calculateRecycleValue(with: [])
    }
    
    nonisolated func fusionWeight(with perks: [Perk]) -> Int {
        var weight = 1
        for perk in perks {
            weight *= perk.duckFusionWeight
        }
        return weight
    }
    
    /// Coût en points de mutation pour améliorer la taille de ce canard
    nonisolated func sizeUpgradeCost(with perks: [Perk]) -> BigNumber? {
        let stats = getDynamicStats(with: perks)
        guard stats.size.next != nil else { return nil }
        return stats.size.upgradeCostBase * rarity.multiplier
    }
    
    /// Coût en points de mutation pour améliorer la mutation de ce canard
    nonisolated func mutationUpgradeCost(with perks: [Perk]) -> BigNumber? {
        let stats = getDynamicStats(with: perks)
        guard stats.mutation.next != nil else { return nil }
        return stats.mutation.upgradeCostBase * rarity.multiplier
    }
    
    /// Coût en argent pour augmenter le niveau de ce canard
    nonisolated func levelUpgradeCost(with perks: [Perk]) -> BigNumber? {
        let stats = getDynamicStats(with: perks)
        guard stats.level < 100 else { return nil }
        return BigNumber(1000.0 * rarity.multiplier * pow(1.15, Double(stats.level - 1)))
    }
}
