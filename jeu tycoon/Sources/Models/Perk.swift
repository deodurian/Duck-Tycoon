import Foundation

enum PerkType: String, Codable {
    case factory = "Usine"
    case duck = "Canard"
}

enum PerkFamily: String, Codable, Hashable {
    case income, synergy, discount, sacrifice, fusion, extraSlot, extraDuck, mythicFactory
    case value, levelBoost, size, mutation, fusionWeight, recycleMut, mythicDuck
}

enum PerkTarget: String, Codable, Hashable {
    case commun, peuCommun, rare, epique, legendaire, mythique
    case cpr, el, elm
    case fusion2, fusion23, fusion1234
    
    var displayName: String {
        switch self {
        case .commun: return "Commun"
        case .peuCommun: return "Peu Commun"
        case .rare: return "Rare"
        case .epique: return "Épique"
        case .legendaire: return "Lég."
        case .mythique: return "Myth."
        case .cpr: return "C/PC/Rare"
        case .el: return "Épique/Lég."
        case .elm: return "Épique/Lég/Myth"
        case .fusion2: return "Fusion 2"
        case .fusion23: return "Fusion 2/3"
        case .fusion1234: return "Fusion 1-4"
        }
    }
}

struct Perk: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let type: PerkType
    let rarity: DuckRarity
    var family: PerkFamily
    var target: PerkTarget?
    
    enum CodingKeys: String, CodingKey {
        case id, type, rarity, family, target
    }
    
    init(id: UUID = UUID(), type: PerkType, rarity: DuckRarity, family: PerkFamily, target: PerkTarget? = nil) {
        self.id = id
        self.type = type
        self.rarity = rarity
        self.family = family
        self.target = target
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.type = try container.decode(PerkType.self, forKey: .type)
        self.rarity = try container.decode(DuckRarity.self, forKey: .rarity)
        
        if let family = try container.decodeIfPresent(PerkFamily.self, forKey: .family) {
            self.family = family
            self.target = try container.decodeIfPresent(PerkTarget.self, forKey: .target)
        } else {
            let rolled = Perk.rollRandom(type: self.type, forcedRarity: self.rarity)
            self.family = rolled.family
            self.target = rolled.target
        }
    }
    
    // MARK: - Affichage
    
    var name: String {
        if type == .factory {
            switch family {
            case .income: return "Boost Revenu"
            case .synergy: return "Synergie \(target?.displayName ?? "")"
            case .discount: return "Réduction Coût"
            case .sacrifice: return "Sacrifice"
            case .fusion: return "Boost Fusion"
            case .extraSlot: return "Emplacement+"
            case .extraDuck: return "Canard+"
            case .mythicFactory: return "Omnipotence Usine"
            default: return "Perk Usine"
            }
        } else {
            switch family {
            case .value: return "Boost Valeur"
            case .levelBoost: return "Gènes \(target?.displayName ?? "")"
            case .size: return "Croissance"
            case .mutation: return "Mutagène"
            case .fusionWeight: return "Poids Fusion"
            case .recycleMut: return "Recyclage+"
            case .extraSlot: return "Emplacement+"
            case .mythicDuck: return "Dieu Canard"
            default: return "Perk Canard"
            }
        }
    }
    
    var description: String {
        if type == .factory {
            switch family {
            case .income: return "Donne \(Int(factoryIncomeBonus * 100))% d'argent en plus à l'usine"
            case .synergy: return "Donne \(Int(factoryIncomeConditionalBonus(duckRarity: expectedRarityForTarget, duckFusionLevel: nil) * 100))% d'argent en plus si un canard \(target?.displayName ?? "") est équipé"
            case .discount: return "Baisse le prix des améliorations de l'usine de \(Int(factoryUpgradeDiscount * 100))%"
            case .sacrifice: return "Réduit la prod de l'usine de \(Int(factoryDrawbackSelf * 100))% mais augmente de \(Int(factoryBonusOthers * 100))% toutes les autres usines sans ce perk"
            case .fusion: return "Augmente de \(Int(factoryIncomeConditionalBonus(duckRarity: nil, duckFusionLevel: expectedFusionForTarget) * 100))% la production si un canard \(target?.displayName ?? "") est équipé"
            case .extraSlot: return "Rajoute un emplacement de perk et donne \(Int(factoryExtraPerkBonus * 100))% d'argent en plus"
            case .extraDuck: return "Permet un 2ème canard et donne \(Int(factoryExtraDuckBonus * 100))% d'argent en plus"
            case .mythicFactory: return "+500% argent, -55% prix amélioration, +10% argent par usine active"
            default: return ""
            }
        } else {
            switch family {
            case .value: return "Augmente de \(Int(duckValueBonus * 100))% la valeur du canard"
            case .levelBoost: return "Donne \(duckConditionalLevels(duckRarity: expectedRarityForTarget)) niveaux si équipé sur un canard \(target?.displayName ?? "")"
            case .size: return "Augmente de \(duckSizeIncrease) la taille du canard"
            case .mutation: return "Augmente de \(duckMutationIncrease) la mutation du canard"
            case .fusionWeight: return "Compte le canard \(duckFusionWeight) fois lors d'une fusion (Perk conservé)"
            case .recycleMut: return "Multiplie par \(Int(duckRecycleMutationMultiplier)) la valeur en 🧬 du canard (Perk détruit)"
            case .extraSlot: return "Permet un 2ème perk et donne \(Int(duckExtraPerkBonus * 100))% de valeur au canard"
            case .mythicDuck: return "+500% valeur, max stats, 2ème perk, compte 32 fois en fusion"
            default: return ""
            }
        }
    }
    
    // Helpers pour la description
    private var expectedRarityForTarget: DuckRarity {
        switch target {
        case .commun, .cpr: return .commun
        case .peuCommun: return .peuCommun
        case .rare: return .rare
        case .epique, .el, .elm: return .epique
        case .legendaire: return .legendaire
        case .mythique: return .mythique
        default: return .commun
        }
    }
    
    private var expectedFusionForTarget: Int {
        switch target {
        case .fusion2, .fusion23: return 2
        case .fusion1234: return 1
        default: return 0
        }
    }
    
    // MARK: - Factory Effects
    
    var factoryIncomeBonus: Double {
        guard type == .factory else { return 0.0 }
        if family == .mythicFactory { return 5.0 }
        guard family == .income else { return 0.0 }
        switch rarity {
        case .commun: return 0.15
        case .peuCommun: return 0.30
        case .rare: return 0.50
        case .epique: return 0.80
        case .legendaire: return 1.50
        default: return 0.0
        }
    }
    
    func factoryIncomeConditionalBonus(duckRarity: DuckRarity?, duckFusionLevel: Int?) -> Double {
        guard type == .factory else { return 0.0 }
        var bonus = 0.0
        
        if family == .synergy, let dRarity = duckRarity, let t = target {
            switch rarity {
            case .commun:
                if t == .commun && dRarity == .commun { bonus += 0.50 }
            case .peuCommun:
                if t == .commun && dRarity == .commun { bonus += 0.80 }
                if t == .peuCommun && dRarity == .peuCommun { bonus += 0.60 }
            case .rare:
                if t == .commun && dRarity == .commun { bonus += 1.00 }
                if t == .peuCommun && dRarity == .peuCommun { bonus += 1.00 }
                if t == .rare && dRarity == .rare { bonus += 0.80 }
            case .epique:
                if t == .cpr && [.commun, .peuCommun, .rare].contains(dRarity) { bonus += 2.10 }
                if t == .el && [.epique, .legendaire].contains(dRarity) { bonus += 1.00 }
            case .legendaire:
                if t == .cpr && [.commun, .peuCommun, .rare].contains(dRarity) { bonus += 3.00 }
                if t == .elm && [.epique, .legendaire, .mythique].contains(dRarity) { bonus += 1.30 }
            default: break
            }
        }
        
        if family == .fusion, let level = duckFusionLevel, let t = target {
            switch rarity {
            case .rare:
                if t == .fusion2 && level == 2 { bonus += 1.00 }
            case .epique:
                if t == .fusion23 && (level == 2 || level == 3) { bonus += 1.50 }
            case .legendaire:
                if t == .fusion1234 && level >= 1 && level <= 4 { bonus += 1.50 }
            default: break
            }
        }
        
        return bonus
    }
    
    var factoryUpgradeDiscount: Double {
        guard type == .factory else { return 0.0 }
        if family == .mythicFactory { return 0.55 }
        guard family == .discount else { return 0.0 }
        switch rarity {
        case .commun: return 0.05
        case .peuCommun: return 0.15
        case .rare: return 0.30
        case .epique: return 0.40
        case .legendaire: return 0.55
        default: return 0.0
        }
    }
    
    var factoryDrawbackSelf: Double {
        guard type == .factory, family == .sacrifice else { return 0.0 }
        switch rarity {
        case .commun: return 0.33
        case .peuCommun: return 0.30
        case .rare: return 0.25
        case .epique: return 0.15
        case .legendaire: return 0.05
        default: return 0.0
        }
    }
    
    var factoryBonusOthers: Double {
        guard type == .factory, family == .sacrifice else { return 0.0 }
        switch rarity {
        case .commun: return 0.10
        case .peuCommun: return 0.20
        case .rare: return 0.50
        case .epique: return 0.80
        case .legendaire: return 1.20
        default: return 0.0
        }
    }
    
    var factoryExtraPerkSlot: Bool {
        guard type == .factory else { return false }
        return family == .extraSlot
    }
    
    var factoryExtraPerkBonus: Double {
        guard type == .factory, family == .extraSlot else { return 0.0 }
        switch rarity {
        case .epique: return 0.50
        case .legendaire: return 0.90
        default: return 0.0
        }
    }
    
    var factoryExtraDuckSlot: Bool {
        guard type == .factory else { return false }
        return family == .extraDuck
    }
    
    var factoryExtraDuckBonus: Double {
        guard type == .factory, family == .extraDuck else { return 0.0 }
        return rarity == .legendaire ? 0.45 : 0.0
    }
    
    var factoryPerEquippedDuckBonus: Double {
        guard type == .factory, family == .mythicFactory else { return 0.0 }
        return 0.10
    }
    
    // MARK: - Duck Effects
    
    nonisolated var duckValueBonus: Double {
        guard type == .duck else { return 0.0 }
        if family == .mythicDuck { return 5.0 }
        guard family == .value else { return 0.0 }
        switch rarity {
        case .commun: return 0.15
        case .peuCommun: return 0.40
        case .rare: return 0.80
        case .epique: return 1.00
        case .legendaire: return 2.00
        default: return 0.0
        }
    }
    
    nonisolated func duckConditionalLevels(duckRarity: DuckRarity) -> Int {
        guard type == .duck, family == .levelBoost, let t = target else { return 0 }
        switch rarity {
        case .commun:
            if t == .commun && duckRarity == .commun { return 20 }
            if t == .peuCommun && duckRarity == .peuCommun { return 10 }
            if t == .rare && duckRarity == .rare { return 5 }
        case .peuCommun:
            if t == .commun && duckRarity == .commun { return 30 }
            if t == .peuCommun && duckRarity == .peuCommun { return 20 }
            if t == .rare && duckRarity == .rare { return 10 }
        case .rare:
            if t == .cpr && [.commun, .peuCommun, .rare].contains(duckRarity) { return 35 }
            if t == .epique && duckRarity == .epique { return 20 }
        case .epique:
            if t == .cpr && [.commun, .peuCommun, .rare].contains(duckRarity) { return 70 }
            if t == .elm && [.epique, .legendaire, .mythique].contains(duckRarity) { return 40 }
        case .legendaire:
            if t == .cpr && [.commun, .peuCommun, .rare].contains(duckRarity) { return 100 }
            if t == .elm && [.epique, .legendaire, .mythique].contains(duckRarity) { return 80 }
        default: break
        }
        return 0
    }
    
    nonisolated var duckOverflowValueBonus: Double {
        guard type == .duck else { return 0.0 }
        switch rarity {
        case .commun: return 1.00
        case .peuCommun: return 2.00
        case .rare: return 3.00
        case .epique: return 4.00
        case .legendaire: return 4.00
        default: return 0.0
        }
    }
    
    nonisolated var duckOverflowBonus: Double {
        guard type == .duck else { return 0.0 }
        switch rarity {
        case .commun: return 0.0
        case .peuCommun: return 2.00
        case .rare: return 3.00
        case .epique: return 4.00
        case .legendaire: return 5.00
        default: return 0.0
        }
    }
    
    nonisolated var duckSizeIncrease: Int {
        guard type == .duck else { return 0 }
        if family == .mythicDuck { return 999 }
        guard family == .size else { return 0 }
        switch rarity {
        case .commun: return 1
        case .peuCommun: return 2
        case .rare: return 3
        case .epique: return 3
        case .legendaire: return 3
        default: return 0
        }
    }
    
    nonisolated var duckMutationIncrease: Int {
        guard type == .duck else { return 0 }
        if family == .mythicDuck { return 999 }
        guard family == .mutation else { return 0 }
        switch rarity {
        case .peuCommun: return 1
        case .rare: return 2
        case .epique: return 3
        case .legendaire: return 3
        default: return 0
        }
    }
    
    nonisolated var duckFusionWeight: Int {
        guard type == .duck else { return 1 }
        if family == .mythicDuck { return 32 }
        guard family == .fusionWeight else { return 1 }
        switch rarity {
        case .peuCommun: return 2
        case .rare: return 4
        case .epique: return 8
        case .legendaire: return 16
        default: return 1
        }
    }
    
    nonisolated var duckKeptOnFusion: Bool {
        guard type == .duck else { return false }
        return family == .fusionWeight || family == .mythicDuck
    }
    
    nonisolated var duckRecycleMutationMultiplier: Double {
        guard type == .duck, family == .recycleMut else { return 1.0 }
        switch rarity {
        case .rare: return 100.0
        case .epique: return 1000.0
        case .legendaire: return 10000.0
        default: return 1.0
        }
    }
    
    nonisolated var duckExtraPerkSlot: Bool {
        guard type == .duck else { return false }
        return family == .extraSlot || family == .mythicDuck
    }
    
    nonisolated var duckExtraPerkBonus: Double {
        guard type == .duck, family == .extraSlot else { return 0.0 }
        switch rarity {
        case .epique: return 1.00
        case .legendaire: return 3.00
        default: return 0.0
        }
    }
    
    // MARK: - Generation
    
    static func rollRandom(type: PerkType? = nil, forcedRarity: DuckRarity? = nil) -> Perk {
        let rolledType = type ?? (Bool.random() ? .factory : .duck)
        
        let rarity: DuckRarity
        if let fRarity = forcedRarity {
            rarity = fRarity
        } else {
            let roll = Double.random(in: 0...100)
            if roll <= 0.1 { rarity = .mythique }
            else if roll <= 3.0 { rarity = .legendaire }
            else if roll <= 10.0 { rarity = .epique }
            else if roll <= 25.0 { rarity = .rare }
            else if roll <= 50.0 { rarity = .peuCommun }
            else { rarity = .commun }
        }
        
        // Definition of specific perks available per rarity based on user rules
        var options: [(PerkFamily, PerkTarget?)] = []
        
        if rolledType == .factory {
            switch rarity {
            case .commun:
                options = [(.income, nil), (.synergy, .commun), (.discount, nil), (.sacrifice, nil)]
            case .peuCommun:
                options = [(.income, nil), (.synergy, .commun), (.synergy, .peuCommun), (.discount, nil), (.sacrifice, nil)]
            case .rare:
                options = [(.income, nil), (.synergy, .commun), (.synergy, .peuCommun), (.synergy, .rare), (.discount, nil), (.sacrifice, nil), (.fusion, .fusion2)]
            case .epique:
                options = [(.income, nil), (.synergy, .cpr), (.synergy, .el), (.discount, nil), (.sacrifice, nil), (.fusion, .fusion23), (.extraSlot, nil)]
            case .legendaire:
                options = [(.income, nil), (.synergy, .cpr), (.synergy, .elm), (.discount, nil), (.sacrifice, nil), (.fusion, .fusion1234), (.extraSlot, nil), (.extraDuck, nil)]
            case .mythique:
                options = [(.mythicFactory, nil)]
            }
        } else {
            switch rarity {
            case .commun:
                options = [(.value, nil), (.levelBoost, .commun), (.levelBoost, .peuCommun), (.levelBoost, .rare), (.size, nil)]
            case .peuCommun:
                options = [(.value, nil), (.levelBoost, .commun), (.levelBoost, .peuCommun), (.levelBoost, .rare), (.size, nil), (.mutation, nil), (.fusionWeight, nil)]
            case .rare:
                options = [(.value, nil), (.levelBoost, .cpr), (.levelBoost, .epique), (.size, nil), (.mutation, nil), (.fusionWeight, nil), (.recycleMut, nil)]
            case .epique:
                options = [(.value, nil), (.levelBoost, .cpr), (.levelBoost, .elm), (.size, nil), (.mutation, nil), (.fusionWeight, nil), (.recycleMut, nil), (.extraSlot, nil)]
            case .legendaire:
                options = [(.value, nil), (.levelBoost, .cpr), (.levelBoost, .elm), (.size, nil), (.mutation, nil), (.fusionWeight, nil), (.recycleMut, nil), (.extraSlot, nil)]
            case .mythique:
                options = [(.mythicDuck, nil)]
            }
        }
        
        let choice = options.randomElement()!
        return Perk(type: rolledType, rarity: rarity, family: choice.0, target: choice.1)
    }
}
