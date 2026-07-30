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
    case exotique = "Exotique"
    case celeste = "Céleste"
    case primordiale = "Primordiale"

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
        case .exotique: return 8000.0
        case .celeste: return 75000.0
        case .primordiale: return 750000.0
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
        case .exotique: return 80000.0
        case .celeste: return 750000.0
        case .primordiale: return 7500000.0
        }
    }

    var baseProbability: Double {
        // Perf : lecture dans la table pré-extraite (une prise de verrou, zéro allocation) au lieu
        // de construire une clé String par interpolation puis de la hacher. Valeur identique :
        // la table est remplie depuis le même instantané Remote Config.
        return RemoteConfigManager.shared.rarityProbabilities().value(for: self)
    }

    var color: Color {
        switch self {
        case .commun: return .gray
        case .peuCommun: return .green
        case .rare: return .blue
        case .epique: return .purple
        case .legendaire: return .orange
        case .mythique: return .red
        case .exotique: return .indigo
        case .celeste: return .pink
        case .primordiale: return .white
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
        case .exotique: return "duck_exotique"
        case .celeste: return "duck_celeste"
        case .primordiale: return "duck_primordiale"
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
        case .exotique: return "EXO"
        case .celeste: return "CEL"
        case .primordiale: return "PRI"
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
        case .exotique: return "EXOTIQUE !!!!"
        case .celeste: return "CÉLESTE !!!!!"
        case .primordiale: return "PRIMORDIALE !!!!!!"
        }
    }

    var nextRarity: DuckRarity? {
        switch self {
        case .commun: return .peuCommun
        case .peuCommun: return .rare
        case .rare: return .epique
        case .epique: return .legendaire
        case .legendaire: return .mythique
        case .mythique: return .exotique
        case .exotique: return .celeste
        case .celeste: return .primordiale
        case .primordiale: return nil
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
        case .exotique: return 800.0
        case .celeste: return 3000.0
        case .primordiale: return 12000.0
        }
    }
    
    /// Ordre de tirage figé (même contenu et même ordre que `allCases`, qui suit l'ordre de
    /// déclaration). Perf : `allCases` est une propriété calculée synthétisée qui reconstruit un
    /// tableau de 9 éléments (allocation sur le tas) à CHAQUE accès ; il était lu deux fois par
    /// tirage, donc pour chaque canard généré. Rendu et tirage identiques : mêmes éléments, même
    /// ordre de parcours, même dernier élément pour le repli.
    private nonisolated static let rollOrder: [DuckRarity] = [
        .commun, .peuCommun, .rare, .epique, .legendaire,
        .mythique, .exotique, .celeste, .primordiale
    ]

    static func rollRandom(globalBonus: Double = 0.0) -> DuckRarity {
        let roll = Double.random(in: 0..<100)

        // Perf : les 9 probabilités sont récupérées en UNE prise de verrou au lieu d'une par rareté
        // (chacune précédée d'une allocation de clé String). Tirage inchangé : même appel unique au
        // générateur aléatoire, dans le même ordre, et mêmes valeurs de probabilités.
        let probabilities = RemoteConfigManager.shared.rarityProbabilities()

        let baseCommun = probabilities.value(for: .commun)
        let communThreshold = max(0.0, baseCommun - (globalBonus * 100.0))

        if roll < communThreshold { return .commun }

        // Distribution of the remaining chance proportionally
        let remaining = 100.0 - communThreshold
        let originalRemaining = 100.0 - baseCommun

        var cumulative = communThreshold
        for rarity in DuckRarity.rollOrder where rarity != .commun {
            let share = remaining * (probabilities.value(for: rarity) / originalRemaining)
            cumulative += share
            if roll < cumulative {
                return rarity
            }
        }
        
        // Fallback to the rarest case
        return DuckRarity.rollOrder.last ?? .commun
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
        case .exotique: return 4.0
        case .celeste: return 6.0
        case .primordiale: return 10.0
        }
    }
}

enum DuckSize: String, Codable, CaseIterable, Comparable {
    case petit = "Petit"
    case moyen = "Moyen"
    case grand = "Grand"
    case geant = "Géant"
    case colossal = "Colossal"

    nonisolated var index: Int {
        switch self {
        case .petit: return 0
        case .moyen: return 1
        case .grand: return 2
        case .geant: return 3
        case .colossal: return 4
        }
    }

    nonisolated static func fromIndex(_ i: Int) -> DuckSize {
        if i <= 0 { return .petit }
        if i == 1 { return .moyen }
        if i == 2 { return .grand }
        if i == 3 { return .geant }
        return .colossal
    }

    nonisolated var multiplier: Double {
        switch self {
        case .petit: return 1.0
        case .moyen: return 1.5
        case .grand: return 2.5
        case .geant: return 5.0
        case .colossal: return 9.0
        }
    }

    // Multiplicateur pour les points de recyclage
    nonisolated var recycleMultiplier: Double {
        switch self {
        case .petit: return 1.0
        case .moyen: return 1.5
        case .grand: return 2.0
        case .geant: return 3.0
        case .colossal: return 4.5
        }
    }

    // Coût d'amélioration de base
    nonisolated var upgradeCostBase: BigNumber {
        switch self {
        case .petit: return BigNumber(20.0) // Pour passer à moyen
        case .moyen: return BigNumber(60.0) // Pour passer à grand
        case .grand: return BigNumber(200.0) // Pour passer à géant
        case .geant: return BigNumber(200.0) // Pour passer à colossal
        case .colossal: return .zero // Max
        }
    }

    nonisolated var next: DuckSize? {
        switch self {
        case .petit: return .moyen
        case .moyen: return .grand
        case .grand: return .geant
        case .geant: return .colossal
        case .colossal: return nil
        }
    }

    var baseProbability: Double {
        // Perf : voir DuckRarity.baseProbability — table pré-extraite, valeur identique.
        return RemoteConfigManager.shared.sizeProbabilities().value(for: self)
    }

    nonisolated static func < (lhs: DuckSize, rhs: DuckSize) -> Bool {
        return lhs.multiplier < rhs.multiplier
    }

    /// Ordre de tirage figé : `allCases` reconstruit un tableau (allocation sur le tas) à CHAQUE
    /// accès, or il est parcouru à chaque canard généré. Même contenu, même ordre que `allCases`.
    private nonisolated static let rollOrder: [DuckSize] = [.petit, .moyen, .grand, .geant, .colossal]

    // Poids pour la probabilité de drop dans les capsules
    static func rollRandom(genesCroissants: Bool = false) -> DuckSize {
        let roll = Double.random(in: 0..<100)
        let modifier = genesCroissants ? 1.618 : 0.0

        // Perf : les 5 probabilités en UNE prise de verrou, sans allocation de clé String.
        // Tirage inchangé : mêmes valeurs, même ordre de parcours, même usage de l'aléatoire.
        let probabilities = RemoteConfigManager.shared.sizeProbabilities()

        var cumulative: Double = 0.0
        for size in DuckSize.rollOrder {
            var chance = probabilities.value(for: size)

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

        return .colossal
    }
}

enum DuckMutation: String, Codable, CaseIterable, Comparable {
    case aucune = "Aucune"
    case dore = "Doré"
    case radioactif = "Radioactif"
    case cristallise = "Cristallisé"
    case quantique = "Quantique"

    nonisolated var index: Int {
        switch self {
        case .aucune: return 0
        case .dore: return 1
        case .radioactif: return 2
        case .cristallise: return 3
        case .quantique: return 4
        }
    }

    nonisolated static func fromIndex(_ i: Int) -> DuckMutation {
        if i <= 0 { return .aucune }
        if i == 1 { return .dore }
        if i == 2 { return .radioactif }
        if i == 3 { return .cristallise }
        return .quantique
    }

    nonisolated var multiplier: Double {
        switch self {
        case .aucune: return 1.0
        case .dore: return 5.0
        case .radioactif: return 15.0
        case .cristallise: return 50.0
        case .quantique: return 180.0
        }
    }

    nonisolated var recycleMultiplier: Double {
        switch self {
        case .aucune: return 1.0
        case .dore: return 2.0
        case .radioactif: return 3.0
        case .cristallise: return 5.0
        case .quantique: return 8.0
        }
    }

    nonisolated var upgradeCostBase: BigNumber {
        switch self {
        case .aucune: return BigNumber(50.0) // Pour passer à doré
        case .dore: return BigNumber(200.0) // Pour passer à radioactif
        case .radioactif: return BigNumber(800.0) // Pour passer à cristallisé
        case .cristallise: return BigNumber(800.0) // Pour passer à quantique
        case .quantique: return .zero // Max
        }
    }

    nonisolated var next: DuckMutation? {
        switch self {
        case .aucune: return .dore
        case .dore: return .radioactif
        case .radioactif: return .cristallise
        case .cristallise: return .quantique
        case .quantique: return nil
        }
    }

    var baseProbability: Double {
        // Perf : voir DuckRarity.baseProbability — table pré-extraite, valeur identique.
        return RemoteConfigManager.shared.mutationProbabilities().value(for: self)
    }

    var color: Color {
        switch self {
        case .aucune: return .primary
        case .dore: return .yellow
        case .radioactif: return .green
        case .cristallise: return .cyan
        case .quantique: return .purple
        }
    }

    nonisolated static func < (lhs: DuckMutation, rhs: DuckMutation) -> Bool {
        return lhs.multiplier < rhs.multiplier
    }
    
    /// Ordre de tirage figé (voir `DuckSize.rollOrder`) : évite l'allocation d'`allCases`.
    private nonisolated static let rollOrder: [DuckMutation] = [.aucune, .dore, .radioactif, .cristallise, .quantique]

    // Les mutations sont rares au tirage
    static func rollRandom(bonusChance: Double = 0.0) -> DuckMutation {
        let roll = Double.random(in: 0..<100)

        // Perf : les 5 probabilités en UNE prise de verrou, sans allocation de clé String.
        // Tirage inchangé : mêmes valeurs, même ordre de parcours, même usage de l'aléatoire.
        let probabilities = RemoteConfigManager.shared.mutationProbabilities()

        let baseAucune = probabilities.value(for: .aucune)
        let aucuneThreshold = max(0.0, baseAucune - (bonusChance * 100.0))

        if roll < aucuneThreshold { return .aucune }

        // Distribution of the remaining chance proportionally
        let remaining = 100.0 - aucuneThreshold
        let originalRemaining = 100.0 - baseAucune

        var cumulative = aucuneThreshold
        for mutation in DuckMutation.rollOrder where mutation != .aucune {
            let share = remaining * (probabilities.value(for: mutation) / originalRemaining)
            cumulative += share
            if roll < cumulative {
                return mutation
            }
        }

        // Fallback to the last case
        return DuckMutation.rollOrder.last ?? .aucune
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
    /// Nombre de rituels réussis sur ce canard (soft cap : la chance décroît à chaque succès).
    var ritualCount: Int = 0

    var equippedPerkIds: [UUID] = []

    // Migration fields
    private var equippedPerkId: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, rarity, size, mutation, ritualSuccesses, goldenRitualSuccesses, ritualCount, equippedPerkId, equippedPerkIds, fusionLevel, customBasePrice, customRecycleValue, level
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
        // Migration : à défaut de valeur, on reprend le total de rituels déjà réussis.
        self.ritualCount = try container.decodeIfPresent(Int.self, forKey: .ritualCount) ?? (self.ritualSuccesses + self.goldenRitualSuccesses)

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
        try container.encode(ritualCount, forKey: .ritualCount)
        try container.encode(equippedPerkIds, forKey: .equippedPerkIds)
        try container.encode(fusionLevel, forKey: .fusionLevel)
        try container.encodeIfPresent(customBasePrice, forKey: .customBasePrice)
        try container.encodeIfPresent(customRecycleValue, forKey: .customRecycleValue)
        try container.encode(level, forKey: .level)
    }
    
    var totalRituals: Int {
        return ritualSuccesses + goldenRitualSuccesses
    }
    
    /// Probabilité de réussite du prochain rituel (de 0.0 à 1.0).
    /// Soft cap : la zone verte décroît exponentiellement à chaque rituel réussi sur ce canard
    /// (`base * 0.75^ritualCount`). L'Occulte ralentit la décroissance.
    func ritualSuccessChance(occulteLevel: Int = 0) -> Double {
        let base = 0.95
        let decay = min(0.95, 0.75 + Double(occulteLevel) * 0.02)
        let chance = base * Foundation.pow(decay, Double(ritualCount))
        return max(0.02, min(0.95, chance))
    }
    
    // Fusion
    var fusionLevel: Int = 0
    var customBasePrice: BigNumber? = nil
    var customRecycleValue: BigNumber? = nil
    
    // Niveau du canard (1 à 100)
    var level: Int = 1
    
    // Le prix de base abstrait d'un canard
    nonisolated static let basePrice: Double = 5.0

    /// Constantes BigNumber pré-calculées.
    /// Perf : `BigNumber(Double)` exécute un `log10` + un `Foundation.pow` à CHAQUE construction, et
    /// ces valeurs constantes étaient reconstruites à chaque calcul de valeur de vente / recyclage
    /// (donc pour chaque canard de l'inventaire, à chaque rafraîchissement). Le résultat est
    /// identique au bit près — même littéral, même conversion —, seul le travail répété disparaît.
    nonisolated static let basePriceBig = BigNumber(Duck.basePrice)
    nonisolated static let ritualMultiplierBase = BigNumber(2.0)
    nonisolated static let goldenRitualMultiplierBase = BigNumber(10.0)
    nonisolated static let fusionMultiplierBase = BigNumber(3.1)

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
            
            if perk.family == .mythicDuck {
                // Mythic: maximize all
                tempLevel = 100
                tempSizeIdx = 4
                tempMutIdx = 4
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
                if tempSizeIdx > 4 {
                    extraMultiplier += perk.duckOverflowBonus
                }
                if tempMutIdx > 4 {
                    extraMultiplier += perk.duckOverflowBonus
                }
            }

            recycleMult *= perk.duckRecycleMutationMultiplier
        }

        let finalLevel = min(100, tempLevel)
        let finalSize = DuckSize.fromIndex(min(4, tempSizeIdx))
        let finalMutation = DuckMutation.fromIndex(min(4, tempMutIdx))
        
        return (finalLevel, finalSize, finalMutation, extraMultiplier, recycleMult)
    }
    
    /// Calcule la valeur de vente de ce canard
    nonisolated func calculateSellValue(with perks: [Perk], perkPowerFactor: Double = 1.0) -> BigNumber {
        let stats = getDynamicStats(with: perks)

        let ritualMultiplier = BigNumber.pow(Duck.ritualMultiplierBase, Double(ritualSuccesses)) * BigNumber.pow(Duck.goldenRitualMultiplierBase, Double(goldenRitualSuccesses))
        let levelMultiplier = 1.0 + (Double(stats.level - 1) * 0.01)
        let base = customBasePrice ?? Duck.basePriceBig
        var value = base * rarity.multiplier * stats.mutation.multiplier * stats.size.multiplier * levelMultiplier

        if customBasePrice == nil && fusionLevel > 0 {
            value *= BigNumber.pow(Duck.fusionMultiplierBase, Double(fusionLevel))
        }

        let perkAdjustedExtra = 1.0 + (stats.extraValueMultiplier - 1.0) * perkPowerFactor
        return value * ritualMultiplier * perkAdjustedExtra
    }
    
    // Valeur de vente sans perks (pour affichage de base)
    nonisolated var sellValue: BigNumber {
        return calculateSellValue(with: [])
    }
    
    /// Calcule les points de mutation obtenus en recyclant ce canard
    nonisolated func calculateRecycleValue(with perks: [Perk], perkPowerFactor: Double = 1.0) -> BigNumber {
        let stats = getDynamicStats(with: perks)

        var baseValue: BigNumber
        if let custom = customRecycleValue {
            baseValue = custom * stats.size.recycleMultiplier * stats.mutation.recycleMultiplier
        } else {
            // Rester en BigNumber : à haut niveau de fusion, Foundation.pow(3.1, n) déborde le Double
            // (→ .infinity → BigNumber(0)), ce qui annulait la valeur de recyclage.
            var value = BigNumber(rarity.baseRecyclePoints * stats.size.recycleMultiplier * stats.mutation.recycleMultiplier)
            if fusionLevel > 0 {
                value *= BigNumber.pow(Duck.fusionMultiplierBase, Double(fusionLevel))
            }
            baseValue = value
        }

        let perkAdjustedRecycleMult = 1.0 + (stats.recycleMultiplier - 1.0) * perkPowerFactor
        return baseValue * perkAdjustedRecycleMult
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
