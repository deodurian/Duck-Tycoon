import Foundation
import SwiftUI

enum CrateType: String, Codable, CaseIterable {
    case bois = "Caisse en Bois"
    case fer = "Caisse en Fer"
    case or = "Caisse en Or"
    case platine = "Caisse en Platine"
    case saphir = "Caisse en Saphir"
    case rubis = "Caisse en Rubis"
    case diamant = "Caisse en Diamant"
    
    var shortName: String {
        switch self {
        case .bois: return "Bois"
        case .fer: return "Fer"
        case .or: return "Or"
        case .platine: return "Platine"
        case .saphir: return "Saphir"
        case .rubis: return "Rubis"
        case .diamant: return "Diamant"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .bois:
            return [Color(red: 0.55, green: 0.35, blue: 0.15), Color(red: 0.35, green: 0.2, blue: 0.08)]
        case .fer:
            return [Color(white: 0.55), Color(white: 0.3)]
        case .or:
            return [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.85, green: 0.6, blue: 0.1)]
        case .platine:
            return [Color(white: 0.9), Color(white: 0.7)]
        case .saphir:
            return [Color(red: 0.2, green: 0.4, blue: 0.95), Color(red: 0.1, green: 0.2, blue: 0.7)]
        case .rubis:
            return [Color(red: 0.9, green: 0.15, blue: 0.2), Color(red: 0.6, green: 0.05, blue: 0.1)]
        case .diamant:
            return [Color(red: 0.4, green: 0.9, blue: 1.0), Color(red: 0.2, green: 0.6, blue: 0.8)]
        }
    }
    
    var accentColor: Color {
        switch self {
        case .bois: return .brown
        case .fer: return .gray
        case .or: return .yellow
        case .platine: return Color(white: 0.85)
        case .saphir: return .blue
        case .rubis: return .red
        case .diamant: return .cyan
        }
    }
    
    var textColor: Color {
        switch self {
        case .or, .platine, .diamant: return .black
        default: return .white
        }
    }
}

struct CrateProbabilities {
    let chances: [DuckRarity: Double]
    
    /// Tire une rareté au sort en fonction des probabilités (somme = 100)
    func rollRarity() -> DuckRarity {
        let roll = Double.random(in: 0..<100)
        var cumulative = 0.0
        
        for rarity in DuckRarity.allCases {
            if let chance = chances[rarity], chance > 0 {
                cumulative += chance
                if roll < cumulative {
                    return rarity
                }
            }
        }
        
        return DuckRarity.allCases.last ?? .commun
    }
}

struct Crate {
    let type: CrateType
    
    var costMoney: BigNumber?
    var costMutationPoints: BigNumber?
    
    let numberOfDucks: Int = 10
    let probabilities: CrateProbabilities
    
    // Définition statique des caisses du jeu
    static let allCrates: [Crate] = [
        // Caisses achetables avec de l'Argent (Money)
        Crate(
            type: .bois,
            costMoney: BigNumber(100),
            probabilities: CrateProbabilities(chances: [.commun: 85.0, .peuCommun: 14.9, .rare: 0.1])
        ),
        Crate(
            type: .fer,
            costMoney: BigNumber(20000),
            probabilities: CrateProbabilities(chances: [.commun: 60.0, .peuCommun: 30.0, .rare: 9.5, .epique: 0.4, .legendaire: 0.1])
        ),
        Crate(
            type: .or,
            costMoney: BigNumber(1_000_000),
            probabilities: CrateProbabilities(chances: [.commun: 20.0, .peuCommun: 50.0, .rare: 25.0, .epique: 4.5, .legendaire: 0.4, .mythique: 0.1])
        ),
        Crate(
            type: .platine,
            costMoney: BigNumber(1_000_000_000),
            probabilities: CrateProbabilities(chances: [.peuCommun: 35.0, .rare: 45.0, .epique: 17.5, .legendaire: 2.0, .mythique: 0.5])
        ),
        
        // Caisses achetables avec des Mutations
        Crate(
            type: .saphir,
            costMoney: nil,
            costMutationPoints: BigNumber(500.0),
            probabilities: CrateProbabilities(chances: [.rare: 50.0, .epique: 40.0, .legendaire: 9.0, .mythique: 1.0])
        ),
        Crate(
            type: .rubis,
            costMoney: nil,
            costMutationPoints: BigNumber(5000.0),
            probabilities: CrateProbabilities(chances: [.epique: 40.0, .legendaire: 50.0, .mythique: 10.0])
        ),
        Crate(
            type: .diamant,
            costMoney: nil,
            costMutationPoints: BigNumber(50000.0),
            probabilities: CrateProbabilities(chances: [.legendaire: 40.0, .mythique: 60.0])
        )
    ]
}
