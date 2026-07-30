import Foundation

struct DuckFactory: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    
    /// L'ID des canards assignés à cette usine. (Peut être jusqu'à 2 avec le Perk Légendaire/Mythique)
    var assignedDuckIds: [UUID]
    
    // Niveaux d'améliorations
    var level: Int
    var evolution: Int
    
    /// IDs des Perks équipés sur cette usine (jusqu'à 2 avec le Perk Épique/Légendaire/Mythique)
    var equippedPerkIds: [UUID]
    
    /// Prix d'achat de l'usine, utilisé pour calculer le coût des niveaux
    var basePurchasePrice: Double?
    
    // Pour la migration depuis d'anciennes sauvegardes
    private var assignedDuckId: UUID?
    private var equippedPerkId: String?
    private var productionLevel: Int?
    private var multiplierLevel: Int?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.assignedDuckIds = []
        self.level = 1
        self.evolution = 0
        self.equippedPerkIds = []
        self.basePurchasePrice = nil
    }
    
    // Migration logic
    enum CodingKeys: String, CodingKey {
        case id, name, assignedDuckId, assignedDuckIds, level, evolution, equippedPerkId, equippedPerkIds, productionLevel, multiplierLevel, basePurchasePrice
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        // Migration from single ID to multiple IDs
        if let singleId = try container.decodeIfPresent(UUID.self, forKey: .assignedDuckId) {
            self.assignedDuckIds = [singleId]
        } else {
            self.assignedDuckIds = try container.decodeIfPresent([UUID].self, forKey: .assignedDuckIds) ?? []
        }
        
        // Migration from single string ID to multiple UUIDs
        if let singlePerkStr = try container.decodeIfPresent(String.self, forKey: .equippedPerkId), let singlePerkUUID = UUID(uuidString: singlePerkStr) {
            self.equippedPerkIds = [singlePerkUUID]
        } else {
            self.equippedPerkIds = try container.decodeIfPresent([UUID].self, forKey: .equippedPerkIds) ?? []
        }
        
        // Migration
        if let prodLevel = try container.decodeIfPresent(Int.self, forKey: .productionLevel) {
            self.level = min(100, prodLevel)
            self.evolution = prodLevel > 100 ? (prodLevel / 100) : 0
        } else {
            self.level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
            self.evolution = try container.decodeIfPresent(Int.self, forKey: .evolution) ?? 0
        }
        
        self.basePurchasePrice = try container.decodeIfPresent(Double.self, forKey: .basePurchasePrice)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(assignedDuckIds, forKey: .assignedDuckIds)
        try container.encode(level, forKey: .level)
        try container.encode(evolution, forKey: .evolution)
        try container.encode(equippedPerkIds, forKey: .equippedPerkIds)
        try container.encodeIfPresent(basePurchasePrice, forKey: .basePurchasePrice)
    }
    
    // Paramètres d'équilibrage de base
    private let baseProductionRate: Double = 1.0
    var baseUpgradeCost: Double {
        return (basePurchasePrice ?? 500.0) / 10.0
    }
    
    private var effectiveLevel: Int {
        return level + (evolution * 200)
    }

    /// Nombre TOTAL de niveaux achetés par l'usine depuis sa création : le niveau repart à 1 à
    /// chaque évolution, donc chaque évolution représente 100 niveaux déjà payés.
    /// Utilisé par le perk « Cumul d'Usine ».
    var cumulativeLevel: Int {
        return level + (evolution * 100)
    }
    
    /// Le nombre de canards générés par seconde de base
    var baseProductionPerSecond: BigNumber {
        return BigNumber(baseProductionRate) * BigNumber.pow(BigNumber(1.05), Double(effectiveLevel - 1))
    }
    
    /// Calcule la réduction applicable (perks)
    func calculateDiscount(with factoryPerks: [Perk]) -> Double {
        var totalDiscount = 0.0
        for perk in factoryPerks {
            totalDiscount += perk.factoryUpgradeDiscount
        }
        return totalDiscount
    }
    
    /// Multiplicateur de réduction appliqué à CHAQUE niveau (réduction de prestige × perks).
    ///
    /// La réduction s'applique mathématiquement: budget = budget * (1 - (baseDiscount+perkDiscount))?
    /// Wait, the original code had: budget >= cost * discount. Wait, discount 1.0 means full price!
    /// Oh! "discount" in original code was actually a multiplier. If cost is cheaper, discount < 1.0.
    /// e.g. factoryCostDiscount = 100 / (100 + totalStars). So it's a multiplier.
    /// If a perk gives 5% off, it means multiplier decreases by 0.05.
    ///
    /// Extrait tel quel des trois fonctions ci-dessous pour qu'il n'existe qu'UNE définition du
    /// prix : la vue s'en sert aussi comme clé de cache, sans risque de diverger du modèle.
    func upgradeDiscountMultiplier(factoryPerks: [Perk] = [], baseDiscount: Double = 1.0) -> Double {
        let perkDiscount = calculateDiscount(with: factoryPerks)
        return max(0.001, baseDiscount - perkDiscount)
    }

    /// Coût d'UN niveau donné (`offset` = décalage par rapport au niveau courant).
    ///
    /// CE QUI COÛTAIT : les boucles ci-dessous reconstruisaient `BigNumber(baseUpgradeCost)`,
    /// `BigNumber(1.44)` et `BigNumber(finalDiscountMultiplier)` à CHAQUE itération. Or chaque
    /// `BigNumber(Double)` fait un `log10` + un `Foundation.pow` (et son `normalize` peut en refaire
    /// autant) : c'était une demi-douzaine d'appels transcendants gaspillés par niveau, sur des
    /// boucles allant jusqu'à 99 tours, pour chaque carte d'usine affichée et à chaque seconde.
    ///
    /// POURQUOI LE RÉSULTAT EST IDENTIQUE : ces trois valeurs sont des constantes de la boucle
    /// (elles ne dépendent pas de `offset`) ; on les calcule une fois et on conserve exactement la
    /// même expression et le même ordre de multiplication, donc les mêmes BigNumber au bit près.
    private func levelUpgradeCost(offset: Int, base: BigNumber, ratio: BigNumber, discount: BigNumber) -> BigNumber {
        let currentEffective = (level + offset) + (evolution * 200)
        let multiplier = BigNumber.pow(ratio, Double(currentEffective))
        return base * multiplier * discount
    }

    /// Coût pour améliorer le niveau
    func upgradeCost(levels: Int = 1, factoryPerks: [Perk] = [], baseDiscount: Double = 1.0) -> BigNumber {
        let finalDiscountMultiplier = upgradeDiscountMultiplier(factoryPerks: factoryPerks, baseDiscount: baseDiscount)
        let base = BigNumber(baseUpgradeCost)
        let ratio = BigNumber(1.44)
        let discount = BigNumber(finalDiscountMultiplier)

        var totalCost = BigNumber.zero
        for i in 0..<levels {
            if level + i > 100 { break }
            totalCost += levelUpgradeCost(offset: i, base: base, ratio: ratio, discount: discount)
        }
        return totalCost
    }

    /// Coût pour évoluer
    func evolveCost(factoryPerks: [Perk] = [], baseDiscount: Double = 1.0) -> BigNumber {
        let finalDiscountMultiplier = upgradeDiscountMultiplier(factoryPerks: factoryPerks, baseDiscount: baseDiscount)

        let multiplier = BigNumber.pow(BigNumber(1.44), Double(100 + (evolution * 200)))
        let level100Cost = BigNumber(baseUpgradeCost) * multiplier * BigNumber(finalDiscountMultiplier)
        return level100Cost * 4.0
    }

    /// Nombre de niveaux qu'on peut acheter avec un budget (Max)
    func maxUpgrades(with budget: BigNumber, factoryPerks: [Perk] = [], baseDiscount: Double = 1.0) -> Int {
        let finalDiscountMultiplier = upgradeDiscountMultiplier(factoryPerks: factoryPerks, baseDiscount: baseDiscount)
        let base = BigNumber(baseUpgradeCost)
        let ratio = BigNumber(1.44)
        let discount = BigNumber(finalDiscountMultiplier)

        var remainingBudget = budget
        var count = 0
        for i in 0..<(100 - level) {
            let cost = levelUpgradeCost(offset: i, base: base, ratio: ratio, discount: discount)
            if remainingBudget >= cost {
                remainingBudget -= cost
                count += 1
            } else {
                break
            }
        }
        return count
    }

    // MARK: - Coûts pré-calculés (pour l'interface)

    /// Coûts unitaires de TOUS les niveaux encore achetables (index 0 = niveau courant).
    ///
    /// Ces coûts ne dépendent PAS de l'argent du joueur : la barre d'action d'une usine peut donc
    /// les garder en mémoire tant que le niveau, l'évolution, le prix d'achat de l'usine et le
    /// multiplicateur de réduction n'ont pas bougé, au lieu de tout recalculer chaque seconde.
    /// Le dernier index utile est `100 - level`, car `upgradeCost` s'arrête dès `level + i > 100`.
    func levelUpgradeCosts(factoryPerks: [Perk] = [], baseDiscount: Double = 1.0) -> [BigNumber] {
        let finalDiscountMultiplier = upgradeDiscountMultiplier(factoryPerks: factoryPerks, baseDiscount: baseDiscount)
        let base = BigNumber(baseUpgradeCost)
        let ratio = BigNumber(1.44)
        let discount = BigNumber(finalDiscountMultiplier)

        let count = max(0, 101 - level)
        var costs: [BigNumber] = []
        costs.reserveCapacity(count)
        for i in 0..<count {
            costs.append(levelUpgradeCost(offset: i, base: base, ratio: ratio, discount: discount))
        }
        return costs
    }

    /// Variante de `upgradeCost` qui consomme les coûts déjà calculés par `levelUpgradeCosts`.
    /// Mêmes valeurs, même condition d'arrêt, même ordre d'accumulation → montant identique.
    func upgradeCost(levels: Int, precomputedCosts costs: [BigNumber]) -> BigNumber {
        var totalCost = BigNumber.zero
        for i in 0..<levels {
            if level + i > 100 { break }
            guard i < costs.count else { break }
            totalCost += costs[i]
        }
        return totalCost
    }

    /// Variante de `maxUpgrades` qui consomme les coûts déjà calculés par `levelUpgradeCosts`.
    /// Même boucle, mêmes soustractions de budget → même nombre de niveaux, au niveau près.
    func maxUpgrades(with budget: BigNumber, precomputedCosts costs: [BigNumber]) -> Int {
        var remainingBudget = budget
        var count = 0
        for i in 0..<(100 - level) {
            guard i < costs.count else { break }
            let cost = costs[i]
            if remainingBudget >= cost {
                remainingBudget -= cost
                count += 1
            } else {
                break
            }
        }
        return count
    }

    /// Calcule l'argent généré par cette usine en une seconde, incluant tous les canards et les perks
    func calculateEarningsPerSecond(assignedDucks: [Duck], duckDisplayValues: [BigNumber], factoryPerks: [Perk], globalPerkBonus: Double = 0.0, perkPowerFactor: Double = 1.0) -> BigNumber {
        guard !assignedDucks.isEmpty else { return .zero }

        var totalIncomeBonus = 0.0
        var totalConditionalBonus = 0.0
        var totalDrawbackSelf = 0.0
        var totalExtraDuckBonus = 0.0
        var totalExtraPerkBonus = 0.0
        var perEquippedDuckBonus = 0.0
        var totalStackBonus = 0.0
        var totalEvolutionBonus = 0.0

        for perk in factoryPerks {
            totalIncomeBonus += perk.factoryIncomeBonus
            totalDrawbackSelf += perk.factoryDrawbackSelf
            totalExtraDuckBonus += perk.factoryExtraDuckBonus
            totalExtraPerkBonus += perk.factoryExtraPerkBonus
            perEquippedDuckBonus += perk.factoryPerEquippedDuckBonus
            totalStackBonus += perk.factoryStackBonus(cumulativeLevel: cumulativeLevel)
            totalEvolutionBonus += perk.factoryEvolutionProductionBonus(evolution: evolution)

            // Les bonus conditionnels s'appliquent si au moins un des canards remplit la condition
            var bestConditionalBonus = 0.0
            for duck in assignedDucks {
                let duckBonus = perk.factoryIncomeConditionalBonus(duckRarity: duck.rarity, duckFusionLevel: duck.fusionLevel)
                bestConditionalBonus = max(bestConditionalBonus, duckBonus)
            }
            totalConditionalBonus += bestConditionalBonus
        }

        let rawPerkBonus = totalIncomeBonus + totalConditionalBonus + totalExtraDuckBonus + totalExtraPerkBonus + totalStackBonus + totalEvolutionBonus - totalDrawbackSelf + (perEquippedDuckBonus * Double(assignedDucks.count))
        let perkMultiplier = max(0.0, 1.0 + (rawPerkBonus * perkPowerFactor) + globalPerkBonus)

        var totalEarnings = BigNumber.zero
        for displayValue in duckDisplayValues {
            totalEarnings += displayValue * baseProductionPerSecond * perkMultiplier
        }

        return totalEarnings
    }

    /// Calcule les mutations générées par seconde
    func calculateMutationsPerSecond(assignedDucks: [Duck], globalBonus: BigNumber = BigNumber(1.0), factoryPerks: [Perk] = []) -> BigNumber {
        guard evolution > 0, !assignedDucks.isEmpty else { return .zero }

        var mutationYieldBonus = 0.0
        for perk in factoryPerks {
            mutationYieldBonus += perk.factoryMutationYieldBonus
        }
        let yieldMultiplier = 1.0 + mutationYieldBonus

        var totalMutations = BigNumber.zero
        for duck in assignedDucks {
            let baseMutation = duck.recycleValue * 0.01
            totalMutations += baseMutation * globalBonus * yieldMultiplier
        }
        return totalMutations
    }
}
