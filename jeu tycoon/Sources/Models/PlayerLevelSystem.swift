import Foundation

struct PlayerLevelSystem {
    /// Retourne l'XP nécessaire pour passer du niveau `level` au niveau `level + 1`
    static func requiredXP(for level: Int) -> Int {
        let base = 100.0
        return Int(base * pow(Double(level), 1.5))
    }
    
    /// Calcule l'XP passive gagnée en fonction des revenus par seconde
    static func calculatePassiveXP(earningsPerSecond: BigNumber) -> Int {
        if earningsPerSecond.mantissa == 0 && earningsPerSecond.exponent == 0 { return 0 }
        
        // On utilise log10 pour que l'XP monte doucement même avec des milliards générés
        // log10(A * 10^B) = log10(A) + B
        let xp = log10(earningsPerSecond.mantissa) + Double(earningsPerSecond.exponent)
        
        guard !xp.isNaN && !xp.isInfinite else { return 1 }
        return max(1, Int(xp))
    }
    
    /// Calcule le multiplicateur de production d'argent en fonction du niveau
    static func moneyMultiplier(for level: Int) -> Double {
        let percentBonus = Double(level) * 1.0 + Double(level / 5) * 5.0 + Double(level / 10) * 25.0
        let doubleMultiplier = pow(2.0, Double(level / 100))
        return (1.0 + (percentBonus / 100.0)) * doubleMultiplier
    }
    
    /// Calcule le multiplicateur de mutation en fonction du niveau
    static func mutationMultiplier(for level: Int) -> Double {
        let percentBonus = Double(level / 5) * 1.0 + Double(level / 10) * 5.0
        return 1.0 + (percentBonus / 100.0)
    }
}
