import Foundation

enum PerkType: String, Codable {
    case factory = "Usine"
    case duck = "Canard"
}

struct Perk: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let type: PerkType
    let rarity: DuckRarity
    
    var name: String {
        return "Perk \(type.rawValue) \(rarity.rawValue)"
    }
    
    // MARK: - Factory Effects
    var factoryIncomeBonus: Double {
        guard type == .factory else { return 0.0 }
        switch rarity {
        case .commun: return 0.15
        case .peuCommun: return 0.30
        case .rare: return 0.50
        case .epique: return 0.80
        case .legendaire: return 1.50
        case .mythique: return 5.00
        }
    }
    
    func factoryIncomeConditionalBonus(duckRarity: DuckRarity?, duckFusionLevel: Int?) -> Double {
        guard type == .factory, let duckRarity = duckRarity else { return 0.0 }
        var bonus = 0.0
        
        switch rarity {
        case .commun:
            if duckRarity == .commun { bonus += 0.50 }
        case .peuCommun:
            if duckRarity == .commun { bonus += 0.80 }
            if duckRarity == .peuCommun { bonus += 0.60 }
        case .rare:
            if duckRarity == .commun { bonus += 1.00 }
            if duckRarity == .peuCommun { bonus += 1.00 }
            if duckRarity == .rare { bonus += 0.80 }
            if duckFusionLevel == 2 { bonus += 1.00 }
        case .epique:
            if [.commun, .peuCommun, .rare].contains(duckRarity) { bonus += 2.10 }
            if [.epique, .legendaire].contains(duckRarity) { bonus += 1.00 }
            if duckFusionLevel == 2 || duckFusionLevel == 3 { bonus += 1.50 }
        case .legendaire:
            if [.commun, .peuCommun, .rare].contains(duckRarity) { bonus += 3.00 }
            if [.epique, .legendaire, .mythique].contains(duckRarity) { bonus += 1.30 }
            if let level = duckFusionLevel, level >= 1 && level <= 4 { bonus += 1.50 }
        case .mythique:
            break
        }
        
        return bonus
    }
    
    var factoryUpgradeDiscount: Double {
        guard type == .factory else { return 0.0 }
        switch rarity {
        case .commun: return 0.05
        case .peuCommun: return 0.15
        case .rare: return 0.30
        case .epique: return 0.40
        case .legendaire: return 0.55
        case .mythique: return 0.55
        }
    }
    
    var factoryDrawbackSelf: Double {
        guard type == .factory else { return 0.0 }
        switch rarity {
        case .commun: return 0.33
        case .peuCommun: return 0.30
        case .rare: return 0.25
        case .epique: return 0.15
        case .legendaire: return 0.05
        case .mythique: return 0.0
        }
    }
    
    var factoryBonusOthers: Double {
        guard type == .factory else { return 0.0 }
        switch rarity {
        case .commun: return 0.10
        case .peuCommun: return 0.20
        case .rare: return 0.50
        case .epique: return 0.80
        case .legendaire: return 1.20
        case .mythique: return 0.0
        }
    }
    
    var factoryExtraPerkSlot: Bool {
        guard type == .factory else { return false }
        return rarity == .epique || rarity == .legendaire || rarity == .mythique
    }
    
    var factoryExtraPerkBonus: Double {
        guard type == .factory else { return 0.0 }
        switch rarity {
        case .epique: return 0.50
        case .legendaire: return 0.90
        default: return 0.0
        }
    }
    
    var factoryExtraDuckSlot: Bool {
        guard type == .factory else { return false }
        return rarity == .legendaire || rarity == .mythique
    }
    
    var factoryExtraDuckBonus: Double {
        guard type == .factory else { return 0.0 }
        return rarity == .legendaire ? 0.45 : 0.0
    }
    
    var factoryPerEquippedDuckBonus: Double {
        guard type == .factory, rarity == .mythique else { return 0.0 }
        return 0.10
    }
    
    // MARK: - Duck Effects
    
    nonisolated var duckValueBonus: Double {
        guard type == .duck else { return 0.0 }
        switch rarity {
        case .commun: return 0.15
        case .peuCommun: return 0.40
        case .rare: return 0.80
        case .epique: return 1.00
        case .legendaire: return 2.00
        case .mythique: return 5.00
        }
    }
    
    nonisolated func duckConditionalLevels(duckRarity: DuckRarity) -> Int {
        guard type == .duck else { return 0 }
        switch rarity {
        case .commun:
            if duckRarity == .commun { return 20 }
            if duckRarity == .peuCommun { return 10 }
            if duckRarity == .rare { return 5 }
        case .peuCommun:
            if duckRarity == .commun { return 30 }
            if duckRarity == .peuCommun { return 20 }
            if duckRarity == .rare { return 10 }
        case .rare:
            if [.commun, .peuCommun, .rare].contains(duckRarity) { return 35 }
            if duckRarity == .epique { return 20 }
        case .epique:
            if [.commun, .peuCommun, .rare].contains(duckRarity) { return 70 }
            if [.epique, .legendaire, .mythique].contains(duckRarity) { return 40 }
        case .legendaire:
            if [.commun, .peuCommun, .rare].contains(duckRarity) { return 100 }
            if [.epique, .legendaire, .mythique].contains(duckRarity) { return 80 }
        case .mythique:
            return 999 // Max level indicator
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
        case .mythique: return 0.0
        }
    }
    
    nonisolated var duckSizeIncrease: Int {
        guard type == .duck else { return 0 }
        switch rarity {
        case .commun: return 1
        case .peuCommun: return 2
        case .rare: return 3
        case .epique: return 3
        case .legendaire: return 3
        case .mythique: return 999
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
        case .mythique: return 0.0
        }
    }
    
    nonisolated var duckMutationIncrease: Int {
        guard type == .duck else { return 0 }
        switch rarity {
        case .commun: return 0
        case .peuCommun: return 1
        case .rare: return 2
        case .epique: return 3
        case .legendaire: return 3
        case .mythique: return 999
        }
    }
    

    
    nonisolated var duckFusionWeight: Int {
        guard type == .duck else { return 1 }
        switch rarity {
        case .commun: return 1
        case .peuCommun: return 2
        case .rare: return 4
        case .epique: return 8
        case .legendaire: return 16
        case .mythique: return 32
        }
    }
    
    nonisolated var duckKeptOnFusion: Bool {
        guard type == .duck else { return false }
        return rarity == .peuCommun || rarity == .rare || rarity == .epique || rarity == .legendaire || rarity == .mythique
    }
    
    nonisolated var duckRecycleMutationMultiplier: Double {
        guard type == .duck else { return 1.0 }
        switch rarity {
        case .rare: return 100.0
        case .epique: return 1000.0
        case .legendaire: return 10000.0
        default: return 1.0
        }
    }
    
    nonisolated var duckExtraPerkSlot: Bool {
        guard type == .duck else { return false }
        return rarity == .epique || rarity == .legendaire || rarity == .mythique
    }
    
    nonisolated var duckExtraPerkBonus: Double {
        guard type == .duck else { return 0.0 }
        switch rarity {
        case .epique: return 1.00
        case .legendaire: return 3.00
        default: return 0.0
        }
    }
    
    // MARK: - Generation
    
    static func rollRandom(type: PerkType? = nil) -> Perk {
        let rolledType = type ?? (Bool.random() ? .factory : .duck)
        let roll = Double.random(in: 0...100)
        
        var rarity: DuckRarity = .commun
        if roll <= 0.1 {
            rarity = .mythique
        } else if roll <= 3.0 { // 2.9% + 0.1% = 3.0%
            rarity = .legendaire
        } else if roll <= 10.0 { // 7%
            rarity = .epique
        } else if roll <= 25.0 { // 15%
            rarity = .rare
        } else if roll <= 50.0 { // 25%
            rarity = .peuCommun
        } else {
            rarity = .commun // 50%
        }
        
        return Perk(type: rolledType, rarity: rarity)
    }
}
