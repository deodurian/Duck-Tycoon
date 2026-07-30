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
    case secrete = "Caisse Secrète"

    // Noms courts "Cryo-Boutique" (le rawValue reste inchangé pour la compatibilité des sauvegardes).
    var shortName: String {
        switch self {
        case .bois: return "Standard"
        case .fer: return "Renforcée"
        case .or: return "Ionique"
        case .platine: return "Plasma"
        case .saphir: return "Cryo"
        case .rubis: return "Quantique"
        case .diamant: return "Antimatière"
        case .secrete: return "Secrète"
        }
    }

    /// Nom complet affiché (capsule/data-cube). Le rawValue sert uniquement à la persistance.
    var displayName: String {
        switch self {
        case .bois: return "Capsule Standard"
        case .fer: return "Capsule Renforcée"
        case .or: return "Capsule Ionique"
        case .platine: return "Capsule Plasma"
        case .saphir: return "Capsule Cryo"
        case .rubis: return "Capsule Quantique"
        case .diamant: return "Capsule Antimatière"
        case .secrete: return "Capsule Secrète"
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
        case .secrete:
            return [Color(red: 0.35, green: 0.1, blue: 0.5), Color(red: 0.1, green: 0.02, blue: 0.2)]
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
        case .secrete: return .purple
        }
    }
    
    var textColor: Color {
        switch self {
        case .or, .platine, .diamant: return .black
        default: return .white
        }
    }
}

// MARK: - Clés d'accessibilité de la boutique (pré-calculées)

/// Les cinq clés que `GameManager.affordableCrateKeys` peut contenir pour un type de capsule.
///
/// CE QUI COÛTAIT : `evaluateAffordableCrates` tourne à CHAQUE tick (1 Hz, plus à chaque achat)
/// et reconstruisait ces chaînes par interpolation (`"\(type.rawValue)_money_1"`, …) : jusqu'à
/// 5 allocations de String par capsule et par seconde, immédiatement jetées après un simple
/// `insert` dans un Set. Elles sont désormais construites une seule fois pour toute la durée de
/// vie de l'application.
///
/// POURQUOI LE RENDU RESTE IDENTIQUE : la concaténation produit exactement les mêmes chaînes que
/// l'interpolation (le rawValue est déjà une String, aucune conversion intermédiaire), donc les
/// tests `affordableCrateKeys.contains("\(crate.type.rawValue)_money_1")` effectués dans les vues
/// (CrateShopCards) continuent de matcher à l'identique.
struct CrateAffordabilityKeys {
    let money1: String
    let moneyMulti: String
    let mutation1: String
    let mutationMulti: String
    let maxKey: String

    fileprivate init(type: CrateType) {
        let raw = type.rawValue
        self.money1 = raw + "_money_1"
        self.moneyMulti = raw + "_money_multi"
        self.mutation1 = raw + "_mutation_1"
        self.mutationMulti = raw + "_mutation_multi"
        self.maxKey = raw + "_max"
    }
}

extension CrateType {
    /// Table construite une seule fois (un `static let` est initialisé paresseusement et une seule
    /// fois, de façon thread-safe).
    private static let affordabilityKeysByType: [CrateType: CrateAffordabilityKeys] = {
        var map = [CrateType: CrateAffordabilityKeys](minimumCapacity: CrateType.allCases.count)
        for type in CrateType.allCases {
            map[type] = CrateAffordabilityKeys(type: type)
        }
        return map
    }()

    /// Clés pré-calculées de ce type de capsule.
    /// Le repli reconstruit à la volée : il ne peut pas être atteint (la table couvre `allCases`),
    /// il évite juste un `!` sur le dictionnaire.
    var affordabilityKeys: CrateAffordabilityKeys {
        CrateType.affordabilityKeysByType[self] ?? CrateAffordabilityKeys(type: self)
    }
}

/// Ordre canonique des raretés, capturé UNE seule fois.
///
/// CE QUI COÛTAIT : `DuckRarity.allCases` n'est pas une constante mais une propriété *calculée*
/// synthétisée par `CaseIterable` — chaque lecture reconstruit (et donc alloue) un tableau de
/// 9 éléments. `rollRarity` la relisait jusqu'à trois fois par tirage, et un tirage a lieu pour
/// CHAQUE canard généré : 10 par capsule ouverte, jusqu'à plusieurs dizaines de milliers lors d'un
/// achat « Max » ou d'un rattrapage d'automatisation hors-ligne. C'était donc des centaines de
/// milliers d'allocations éphémères pendant les pics où le jeu saccade le plus.
///
/// POURQUOI LE RENDU RESTE IDENTIQUE : c'est exactement le même contenu dans le même ordre (l'ordre
/// de déclaration des `case`), et le tirage aléatoire (`Double.random`) reste appelé une seule fois,
/// au même endroit : la suite de nombres aléatoires consommée et les raretés obtenues sont
/// rigoureusement les mêmes.
private let orderedRarities: [DuckRarity] = DuckRarity.allCases

struct CrateProbabilities {
    let chances: [DuckRarity: Double]

    /// Tire une rareté au sort en fonction des probabilités (somme = 100).
    /// `bonus` (perk Chance de Caisse) réduit la part de la rareté la plus commune de cette caisse
    /// et redistribue proportionnellement le reste vers les raretés plus élevées.
    func rollRarity(bonus: Double = 0.0) -> DuckRarity {
        let roll = Double.random(in: 0..<100)

        guard bonus > 0, let lowestRarity = orderedRarities.first(where: { (chances[$0] ?? 0) > 0 }) else {
            var cumulative = 0.0
            for rarity in orderedRarities {
                if let chance = chances[rarity], chance > 0 {
                    cumulative += chance
                    if roll < cumulative { return rarity }
                }
            }
            return orderedRarities.last ?? .commun
        }

        let baseLowest = chances[lowestRarity] ?? 0
        let lowestThreshold = max(0.0, baseLowest - (bonus * 100.0))
        if roll < lowestThreshold { return lowestRarity }

        let remaining = 100.0 - lowestThreshold
        let originalRemaining = 100.0 - baseLowest

        var cumulative = lowestThreshold
        for rarity in orderedRarities where rarity != lowestRarity {
            if let chance = chances[rarity], chance > 0 {
                let share = originalRemaining > 0 ? remaining * (chance / originalRemaining) : 0
                cumulative += share
                if roll < cumulative { return rarity }
            }
        }

        return orderedRarities.last ?? lowestRarity
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
            probabilities: CrateProbabilities(chances: [.commun: 87.0, .peuCommun: 12.9, .rare: 0.1])
        ),
        Crate(
            type: .fer,
            costMoney: BigNumber(20000),
            probabilities: CrateProbabilities(chances: [.commun: 63.0, .peuCommun: 32.0, .rare: 4.7, .epique: 0.25, .legendaire: 0.05])
        ),
        Crate(
            type: .or,
            costMoney: BigNumber(1_000_000),
            probabilities: CrateProbabilities(chances: [.commun: 27.0, .peuCommun: 58.0, .rare: 13.0, .epique: 1.7, .legendaire: 0.25, .mythique: 0.05])
        ),
        Crate(
            type: .platine,
            costMoney: BigNumber(1_000_000_000),
            probabilities: CrateProbabilities(chances: [.peuCommun: 40.0, .rare: 50.0, .epique: 8.5, .legendaire: 1.2, .mythique: 0.3])
        ),

        // Caisses achetables avec des Mutations
        Crate(
            type: .saphir,
            costMoney: nil,
            costMutationPoints: BigNumber(500.0),
            probabilities: CrateProbabilities(chances: [.rare: 50.0, .epique: 40.0, .legendaire: 8.7, .mythique: 1.1, .exotique: 0.2])
        ),
        Crate(
            type: .rubis,
            costMoney: nil,
            costMutationPoints: BigNumber(5000.0),
            probabilities: CrateProbabilities(chances: [.epique: 40.0, .legendaire: 48.0, .mythique: 8.5, .exotique: 3.3, .celeste: 0.2])
        ),
        Crate(
            type: .diamant,
            costMoney: nil,
            costMutationPoints: BigNumber(50000.0),
            probabilities: CrateProbabilities(chances: [.legendaire: 25.0, .mythique: 55.0, .exotique: 15.0, .celeste: 4.5, .primordiale: 0.5])
        )
    ]

    /// Caisse Secrète : récompense de la collection complète de canards.
    /// Hors de `allCrates` pour ne pas apparaître dans la boutique ni l'automatisation tant qu'elle n'est pas débloquée.
    static let secretCrate = Crate(
        type: .secrete,
        costMoney: nil,
        costMutationPoints: BigNumber(100.0),
        probabilities: CrateProbabilities(chances: [.mythique: 40.0, .exotique: 35.0, .celeste: 20.0, .primordiale: 5.0])
    )

    /// Boutique complète : les capsules standard SUIVIES de la Capsule Secrète, assemblées une fois.
    ///
    /// CE QUI COÛTAIT : `GameManager.availableCrates` repartait de `allCrates` puis faisait un
    /// `append`. Une fois la collection complète réclamée, ce `append` déclenche une copie du
    /// tableau (copy-on-write) à CHAQUE lecture : allocation d'un tableau de 8 `Crate` — chacun
    /// retenant son dictionnaire de probabilités — pour le jeter aussitôt. Or `availableCrates` est
    /// lu à chaque tick par `evaluateAffordableCrates`, et à chaque `body` de la boutique.
    ///
    /// POURQUOI LE RENDU RESTE IDENTIQUE : ce sont les mêmes capsules, avec les mêmes valeurs, dans
    /// le même ordre (standard d'abord, Secrète en dernier) — c'est littéralement le tableau que
    /// produisait l'`append`, simplement construit une fois pour toutes.
    static let allCratesWithSecret: [Crate] = Crate.allCrates + [Crate.secretCrate]
}
