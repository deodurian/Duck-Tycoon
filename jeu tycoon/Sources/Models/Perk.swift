import Foundation

enum PerkType: String, Codable {
    case factory = "Usine"
    case duck = "Canard"
}

enum PerkFamily: String, Codable, Hashable {
    case income, synergy, discount, sacrifice, fusion, extraSlot, extraDuck, mythicFactory
    case value, levelBoost, size, mutation, fusionWeight, recycleMut, mythicDuck
    case stackBonus, evolutionBoost, mutationYield
    case rarityUpgrade, crateLuck
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
            case .income: return tr("Boost Revenu")
            case .synergy: return "\(tr("Synergie")) \(tr(target?.displayName ?? ""))"
            case .discount: return tr("Réduction Coût")
            case .sacrifice: return tr("Sacrifice")
            case .fusion: return tr("Boost Fusion")
            case .extraSlot: return tr("Emplacement+")
            case .extraDuck: return tr("Canard+")
            case .mythicFactory: return tr("Omnipotence Usine")
            case .stackBonus: return tr("Cumul d'Usine")
            case .evolutionBoost: return tr("Évolution Boostée")
            case .mutationYield: return tr("Extracteur ADN")
            default: return tr("Perk Usine")
            }
        } else {
            switch family {
            case .value: return tr("Boost Valeur")
            case .levelBoost: return "\(tr("Gènes")) \(target?.displayName ?? "")"
            case .size: return tr("Croissance")
            case .mutation: return tr("Mutagène")
            case .fusionWeight: return tr("Poids Fusion")
            case .recycleMut: return tr("Recyclage+")
            case .extraSlot: return tr("Emplacement+")
            case .mythicDuck: return tr("Dieu Canard")
            default: return tr("Perk Canard")
            }
        }
    }
    
    var description: String {
        if type == .factory {
            switch family {
            case .income: return tr("Donne \(Int(factoryIncomeBonus * 100))% d'argent en plus a l'usine")
            case .synergy: return tr("Donne \(Int(factoryIncomeConditionalBonus(duckRarity: expectedRarityForTarget, duckFusionLevel: nil) * 100))% d'argent en plus si un canard \(synergyTargetLabel) est équipé")
            case .discount: return tr("Baisse le prix des améliorations de l'usine de \(Int(factoryUpgradeDiscount * 100))%")
            case .sacrifice: return tr("Réduit de \(Int(factoryDrawbackSelf * 100))% la production mais augmente de \(Int(factoryBonusOthers * 100))% les autres usines")
            case .fusion: return tr("Augmente de \(Int(factoryIncomeConditionalBonus(duckRarity: nil, duckFusionLevel: 1) * 100))% la production si un canard fusionné est équipé")
            case .extraSlot: return tr("Permet de rajouter un 2ème perk a l'usine et donne \(Int(factoryExtraPerkBonus * 100))% d'argent en plus")
            case .extraDuck: return tr("Permet de mettre un 2ème canard dans l'usine et donne un bonus de \(Int(factoryExtraDuckBonus * 100))%")
            case .mythicFactory: return tr("+500% argent, -55% prix amélioration, +10% argent par usine active")
            case .stackBonus: return tr("Donne \(String(format: "%.1f", factoryStackBonus(cumulativeLevel: 1) * 100))% d'argent en plus par niveau cumulé de l'usine (évolutions comprises)")
            case .evolutionBoost: return tr("Donne \(Int(factoryEvolutionProductionBonus(evolution: 1) * 100))% de production en plus par niveau d'évolution de l'usine")
            case .mutationYield: return tr("Augmente de \(Int(factoryMutationYieldBonus * 100))% la production d'ADN de cette usine")
            default: return ""
            }
        } else {
            switch family {
            case .value: return tr("Augmente de \(Int(duckValueBonus * 100))% la valeur du canard")
            case .levelBoost: return tr("Si équipé à un canard \(target?.displayName ?? "") : reçoit \(duckConditionalLevels(duckRarity: expectedRarityForTarget)) niveaux")
            case .size: return tr("Augmente de \(duckSizeIncrease) la taille du canard")
            case .mutation: return tr("Augmente de \(duckMutationIncrease) la mutation du canard")
            case .fusionWeight: return tr("Compte le canard \(duckFusionWeight) fois lors d'une fusion (Perk conservé)")
            case .recycleMut: return tr("Multiplie par \(Int(duckRecycleMutationMultiplier)) la valeur en 🧬 du canard (Perk détruit)")
            case .extraSlot: return tr("Permet de mettre un 2ème perk et augmente de \(Int(duckExtraPerkBonus * 100))% la valeur")
            case .mythicDuck: return tr("+500% valeur, max stats, 2ème perk, compte 32 fois en fusion")
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

    /// Libellé de la cible de synergie : la variante Légendaire « C/PC/Rare » couvre aussi l'Épique.
    private var synergyTargetLabel: String {
        if rarity == .legendaire && target == .cpr { return tr("de rareté ≤ Épique") }
        return target?.displayName ?? ""
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
                // La variante « commun » légendaire couvre désormais tout ce qui est ≤ Épique.
                if t == .cpr && [.commun, .peuCommun, .rare, .epique].contains(dRarity) { bonus += 3.00 }
                if t == .elm && [.epique, .legendaire, .mythique].contains(dRarity) { bonus += 3.00 }
            default: break
            }
        }

        // Boost Fusion : s'applique dès qu'un canard fusionné (niveau ≠ 0) est équipé,
        // quel que soit son palier de fusion. La puissance dépend de la rareté du perk.
        if family == .fusion, let level = duckFusionLevel, level != 0 {
            switch rarity {
            case .rare: bonus += 1.00
            case .epique: bonus += 2.00
            case .legendaire: bonus += 3.00
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

    /// Bonus de revenu qui scale avec le nombre TOTAL de niveaux achetés par l'usine,
    /// évolutions comprises (voir `DuckFactory.cumulativeLevel`).
    func factoryStackBonus(cumulativeLevel: Int) -> Double {
        guard type == .factory, family == .stackBonus else { return 0.0 }
        let perLevel: Double
        switch rarity {
        case .commun: perLevel = 0.001      // 0,1 % / niveau
        case .peuCommun: perLevel = 0.003   // 0,3 %
        case .rare: perLevel = 0.005        // 0,5 %
        case .epique: perLevel = 0.010      // 1 %
        case .legendaire: perLevel = 0.030  // 3 %
        default: perLevel = 0.0
        }
        return perLevel * Double(cumulativeLevel)
    }

    /// Évolution Boostée : production supplémentaire par niveau d'évolution de l'usine.
    func factoryEvolutionProductionBonus(evolution: Int) -> Double {
        guard type == .factory, family == .evolutionBoost, evolution > 0 else { return 0.0 }
        let perEvolution: Double
        switch rarity {
        case .rare: perEvolution = 0.80
        case .epique: perEvolution = 1.20
        case .legendaire: perEvolution = 1.60
        default: perEvolution = 0.0
        }
        return perEvolution * Double(evolution)
    }

    /// Bonus de production d'ADN de cette usine (pertinent si évolution >= 1)
    var factoryMutationYieldBonus: Double {
        guard type == .factory, family == .mutationYield else { return 0.0 }
        switch rarity {
        case .commun: return 0.10
        case .peuCommun: return 0.20
        case .rare: return 0.35
        case .epique: return 0.55
        case .legendaire: return 0.85
        default: return 0.0
        }
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

    // NOTE : les familles `.rarityUpgrade` (Ascension) et `.crateLuck` (Chance de Capsule) ont été
    // retirées du jeu. Les cas d'enum sont conservés pour que les anciennes sauvegardes se décodent ;
    // `migrateRemovedPerks()` les remplace au chargement par un perk aléatoire de même rareté.

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
                options = [(.income, nil), (.synergy, .commun), (.discount, nil), (.sacrifice, nil), (.stackBonus, nil)]
            case .peuCommun:
                options = [(.income, nil), (.synergy, .commun), (.synergy, .peuCommun), (.discount, nil), (.sacrifice, nil), (.stackBonus, nil)]
            case .rare:
                options = [(.income, nil), (.synergy, .commun), (.synergy, .peuCommun), (.synergy, .rare), (.discount, nil), (.sacrifice, nil), (.fusion, .fusion2), (.stackBonus, nil), (.evolutionBoost, nil), (.mutationYield, nil)]
            case .epique:
                options = [(.income, nil), (.synergy, .cpr), (.synergy, .el), (.discount, nil), (.sacrifice, nil), (.fusion, .fusion23), (.extraSlot, nil), (.stackBonus, nil), (.evolutionBoost, nil), (.mutationYield, nil)]
            case .legendaire:
                options = [(.income, nil), (.synergy, .cpr), (.synergy, .elm), (.discount, nil), (.sacrifice, nil), (.fusion, .fusion1234), (.extraSlot, nil), (.extraDuck, nil), (.stackBonus, nil), (.evolutionBoost, nil), (.mutationYield, nil)]
            case .mythique:
                options = [(.mythicFactory, nil)]
            default:
                options = [(.income, nil)]
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
            default:
                options = [(.value, nil)]
            }
        }
        
        let choice = options.randomElement()!
        return Perk(type: rolledType, rarity: rarity, family: choice.0, target: choice.1)
    }
}
