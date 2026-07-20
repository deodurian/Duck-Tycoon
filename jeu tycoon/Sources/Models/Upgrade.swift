import Foundation
import SwiftUI

enum UpgradeTabType: String, CaseIterable {
    case repetable = "Répétables"
    case deblocage = "Déblocages"
    case automatisation = "Automatisation"
    
    var icon: String {
        switch self {
        case .repetable: return "arrow.up.circle.fill"
        case .deblocage: return "lock.open.fill"
        case .automatisation: return "gearshape.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .repetable: return .cyan
        case .deblocage: return .orange
        case .automatisation: return .purple
        }
    }
}

// MARK: - Identifiants uniques des améliorations
enum UpgradeID: String, Codable, CaseIterable, Hashable {
    // Déblocages
    case manualFusion
    case autoFusion
    case megaFusion
    case multipleOpenX5
    case multipleOpenX10
    case multipleOpenMax
    case holdToOpen
    case bulkRecycle
    case annihilation
    case autoRecycleFilter
    case inventory1000
    case inventory5000
    case inventory10000
    case genesCroissants
    case occultePenalty
    case occultePenalty2
    case occultePenalty3
    case occultePenalty4
    case occultePenalty5
    case goldenRitual
    case goldenRitual2
    case goldenRitual3
    case goldenRitual4
    case goldenRitual5
    
    case mutationSpontanee
    case mutationSpontanee2
    case mutationSpontanee3
    case mutationSpontanee4
    
    case expertiseRecyclage
    
    case autoOuvrier
    case autoOuvrier2
    case autoOuvrier3
    case autoOuvrier4
    case autoOuvrier5
    case autoOuvrier6

    // Bonus permanents (niveaux multiples)
    case bonusGlobal
    case bonusCommun
    case bonusPeuCommun
    case bonusRare
    case bonusEpique
    case bonusLegendaire
    case bonusMythique
    case bonusMutation
    case paradisFiscal
    case bonusExotique
    case bonusCeleste
    case bonusPrimordiale
    case bonusEvolutionCost
    case bonusAutomationSpeed
    case bonusPerkPower
    case bonusPrestigeStars
}

// MARK: - Catégorie
enum UpgradeCategory: String {
    case unlock = "Déblocages"
    case bonus  = "Bonus Permanents"
    case automation = "Automatisation"
}

enum CurrencyType {
    case money
    case mutationPoints
}

// MARK: - Modèle
struct UpgradeDefinition {
    let id: UpgradeID
    let category: UpgradeCategory
    let currency: CurrencyType
    let icon: String
    let name: String
    let description: String
    let effectDescription: String   // affiché sur la carte
    let baseCost: Double            // coût (niveau 1)
    let costMultiplier: Double      // multiplicateur de coût par niveau (déblocages = 1.0 car achat unique)
    let maxLevel: Int               // 1 = achat unique, >1 = niveaux
}

// MARK: - Catalogue complet
extension UpgradeDefinition {
    static let all: [UpgradeDefinition] = [

        // ── DÉBLOCAGES ──────────────────────────────────────────────────────

        UpgradeDefinition(
            id: .manualFusion,
            category: .unlock,
            currency: .mutationPoints,
            icon: "flask.fill",
            name: "Labo de Fusion",
            description: "Débloque l'accès au Laboratoire de Fusion.",
            effectDescription: "Permet de fusionner 5 canards identiques pour en créer un meilleur.",
            baseCost: 100,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .autoFusion,
            category: .unlock,
            currency: .mutationPoints,
            icon: "bolt.fill",
            name: "Auto-Fusion",
            description: "Débloque la fusion automatique dans le Laboratoire.",
            effectDescription: "Fusionne automatiquement 5 canards de même rareté d'un seul tap.",
            baseCost: 500,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .megaFusion,
            category: .unlock,
            currency: .mutationPoints,
            icon: "sparkles",
            name: "Méga-Fusion",
            description: "Débloque la Méga-Fusion dans l'Auto-Fusion.",
            effectDescription: "Fusionne en cascade jusqu'à la rareté maximale possible.",
            baseCost: 2000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .multipleOpenX5,
            category: .unlock,
            currency: .mutationPoints,
            icon: "square.stack.fill",
            name: "Ouverture ×5",
            description: "Débloque l'ouverture de 5 caisses simultanément.",
            effectDescription: "Ouvre 5 caisses en une seule fois.",
            baseCost: 300,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .multipleOpenX10,
            category: .unlock,
            currency: .mutationPoints,
            icon: "square.stack.3d.up.fill",
            name: "Ouverture ×10",
            description: "Remplace le bouton d'ouverture ×5 par ×10.",
            effectDescription: "Ouvre 10 caisses en une seule fois.",
            baseCost: 800,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .multipleOpenMax,
            category: .unlock,
            currency: .mutationPoints,
            icon: "infinity",
            name: "Ouverture MAX",
            description: "Débloque l'ouverture du maximum de caisses possible.",
            effectDescription: "Ouvre autant de caisses que ton solde le permet.",
            baseCost: 25000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .holdToOpen,
            category: .unlock,
            currency: .mutationPoints,
            icon: "hand.tap.fill",
            name: "Hold to Open",
            description: "Débloque l'ouverture continue.",
            effectDescription: "Maintenez appuyé sur une caisse pour l'ouvrir en boucle à toute vitesse.",
            baseCost: 1000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .bulkRecycle,
            category: .unlock,
            currency: .mutationPoints,
            icon: "arrow.3.trianglepath",
            name: "Recyclage de Masse",
            description: "Débloque le recyclage en lot dans l'inventaire.",
            effectDescription: "Recycle tous les canards d'une rareté et d'un niveau d'un seul coup.",
            baseCost: 500,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .autoRecycleFilter,
            category: .unlock,
            currency: .mutationPoints,
            icon: "line.3.horizontal.decrease.circle.fill",
            name: "Filtre de Recyclage",
            description: "Automatise le recyclage à l'ouverture des caisses.",
            effectDescription: "Recycle automatiquement les canards d'une rareté spécifiée.",
            baseCost: 2000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .annihilation,
            category: .unlock,
            currency: .mutationPoints,
            icon: "flame.fill",
            name: "Annihilation",
            description: "Débloque la suppression de masse dans l'inventaire.",
            effectDescription: "Supprime d'un coup tous les canards d'une rareté et d'un niveau.",
            baseCost: 1500,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .inventory1000,
            category: .unlock,
            currency: .mutationPoints,
            icon: "shippingbox.circle.fill",
            name: "Inventaire Étendu I",
            description: "Augmente la taille maximale de l'inventaire.",
            effectDescription: "Capacité maximale augmentée à 1 000 canards.",
            baseCost: 1000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .inventory5000,
            category: .unlock,
            currency: .mutationPoints,
            icon: "shippingbox.circle.fill",
            name: "Inventaire Étendu II",
            description: "Augmente encore la taille de l'inventaire.",
            effectDescription: "Capacité maximale augmentée à 5 000 canards.",
            baseCost: 2000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .inventory10000,
            category: .unlock,
            currency: .mutationPoints,
            icon: "shippingbox.circle.fill",
            name: "Inventaire Étendu III",
            description: "Maximise la taille de l'inventaire.",
            effectDescription: "Capacité maximale augmentée à 10 000 canards.",
            baseCost: 5000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .genesCroissants,
            category: .unlock,
            currency: .mutationPoints,
            icon: "leaf.fill",
            name: "Gènes Croissants",
            description: "Augmente les chances d'obtenir de gros canards.",
            effectDescription: "+1.618% chances (Moyen, Grand, Géant).",
            baseCost: 100000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .occultePenalty,
            category: .unlock,
            currency: .mutationPoints,
            icon: "moon.fill",
            name: "Coup de Pouce Occulte",
            description: "Réduit la pénalité des rituels.",
            effectDescription: "Retire 5% de zone rouge au Rituel.",
            baseCost: 500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .occultePenalty2,
            category: .unlock,
            currency: .mutationPoints,
            icon: "moon.fill",
            name: "Coup de Pouce Occulte II",
            description: "Réduit davantage la pénalité des rituels.",
            effectDescription: "Retire 10% de zone rouge au Rituel.",
            baseCost: 1000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .occultePenalty3,
            category: .unlock,
            currency: .mutationPoints,
            icon: "moon.fill",
            name: "Coup de Pouce Occulte III",
            description: "Réduit drastiquement la pénalité des rituels.",
            effectDescription: "Retire 15% de zone rouge au Rituel.",
            baseCost: 2500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .occultePenalty4,
            category: .unlock,
            currency: .mutationPoints,
            icon: "moon.fill",
            name: "Coup de Pouce Occulte IV",
            description: "Réduit massivement la pénalité des rituels.",
            effectDescription: "Retire 20% de zone rouge au Rituel.",
            baseCost: 5000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .occultePenalty5,
            category: .unlock,
            currency: .mutationPoints,
            icon: "moon.fill",
            name: "Coup de Pouce Occulte MAX",
            description: "Minimise au maximum la pénalité des rituels.",
            effectDescription: "Retire 25% de zone rouge au Rituel.",
            baseCost: 10000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .goldenRitual,
            category: .unlock,
            currency: .mutationPoints,
            icon: "star.fill",
            name: "Rituel Doré",
            description: "Ajoute une case dorée à la roue.",
            effectDescription: "Ajoute 4% de zone dorée (x10).",
            baseCost: 100000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .goldenRitual2,
            category: .unlock,
            currency: .mutationPoints,
            icon: "star.fill",
            name: "Rituel Doré II",
            description: "Agrandit la case dorée.",
            effectDescription: "Ajoute 8% de zone dorée (x10).",
            baseCost: 250000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .goldenRitual3,
            category: .unlock,
            currency: .mutationPoints,
            icon: "star.fill",
            name: "Rituel Doré III",
            description: "Agrandit encore la case dorée.",
            effectDescription: "Ajoute 12% de zone dorée (x10).",
            baseCost: 500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .goldenRitual4,
            category: .unlock,
            currency: .mutationPoints,
            icon: "star.fill",
            name: "Rituel Doré IV",
            description: "Agrandit considérablement la case dorée.",
            effectDescription: "Ajoute 16% de zone dorée (x10).",
            baseCost: 1000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .goldenRitual5,
            category: .unlock,
            currency: .mutationPoints,
            icon: "star.fill",
            name: "Rituel Doré MAX",
            description: "Maximise la taille de la case dorée.",
            effectDescription: "Ajoute 20% de zone dorée (x10).",
            baseCost: 2500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        
        UpgradeDefinition(
            id: .mutationSpontanee,
            category: .unlock,
            currency: .mutationPoints,
            icon: "sparkles.rectangle.stack.fill",
            name: "Mutation Spontanée I",
            description: "Les canards ont 5% de chance d'apparaître déjà fusionnés.",
            effectDescription: "Niveau de fusion +1 (5% de chance).",
            baseCost: 500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .mutationSpontanee2,
            category: .unlock,
            currency: .mutationPoints,
            icon: "sparkles.rectangle.stack.fill",
            name: "Mutation Spontanée II",
            description: "Augmente la puissance de la mutation spontanée.",
            effectDescription: "Niveau de fusion +2 (5% de chance).",
            baseCost: 1500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .mutationSpontanee3,
            category: .unlock,
            currency: .mutationPoints,
            icon: "sparkles.rectangle.stack.fill",
            name: "Mutation Spontanée III",
            description: "Augmente drastiquement la puissance de la mutation spontanée.",
            effectDescription: "Niveau de fusion +3 (5% de chance).",
            baseCost: 5000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .mutationSpontanee4,
            category: .unlock,
            currency: .mutationPoints,
            icon: "sparkles.rectangle.stack.fill",
            name: "Mutation Spontanée MAX",
            description: "Les canards mutants naissent avec une fusion maximale.",
            effectDescription: "Niveau de fusion +4 (5% de chance).",
            baseCost: 15000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        
        UpgradeDefinition(
            id: .expertiseRecyclage,
            category: .unlock,
            currency: .mutationPoints,
            icon: "arrow.3.trianglepath",
            name: "Expertise en Recyclage",
            description: "Réduit la perte d'ADN lors des fusions massives.",
            effectDescription: "Les fusions massives conservent 100% de la valeur de recyclage au lieu de 95%.",
            baseCost: 1000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        
        // ── AUTOMATISATION ─────────────────────────────────────────────────
        UpgradeDefinition(
            id: .autoOuvrier,
            category: .automation,
            currency: .mutationPoints,
            icon: "clock.fill",
            name: "Auto-Ouvrier I",
            description: "Ouvre automatiquement une caisse choisie.",
            effectDescription: "1 caisse toutes les 10 secondes.",
            baseCost: 50000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .autoOuvrier2,
            category: .automation,
            currency: .mutationPoints,
            icon: "clock.fill",
            name: "Auto-Ouvrier II",
            description: "Accélère l'Auto-Ouvrier.",
            effectDescription: "1 caisse toutes les 5 secondes.",
            baseCost: 150000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .autoOuvrier3,
            category: .automation,
            currency: .mutationPoints,
            icon: "clock.fill",
            name: "Auto-Ouvrier III",
            description: "Accélère considérablement l'Auto-Ouvrier.",
            effectDescription: "1 caisse toutes les 2 secondes.",
            baseCost: 500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .autoOuvrier4,
            category: .automation,
            currency: .mutationPoints,
            icon: "clock.fill",
            name: "Auto-Ouvrier IV",
            description: "Accélère encore l'Auto-Ouvrier.",
            effectDescription: "1 caisse toutes les 0.5 secondes.",
            baseCost: 2500000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .autoOuvrier5,
            category: .automation,
            currency: .mutationPoints,
            icon: "clock.fill",
            name: "Auto-Ouvrier V",
            description: "Accélère massivement l'Auto-Ouvrier.",
            effectDescription: "1 caisse toutes les 0.25 secondes.",
            baseCost: 10000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),
        UpgradeDefinition(
            id: .autoOuvrier6,
            category: .automation,
            currency: .mutationPoints,
            icon: "clock.fill",
            name: "Auto-Ouvrier MAX",
            description: "L'Auto-Ouvrier atteint sa vitesse maximale.",
            effectDescription: "1 caisse toutes les 0.1 seconde.",
            baseCost: 50000000,
            costMultiplier: 1.0,
            maxLevel: 1
        ),

        // ── BONUS PERMANENTS ─────────────────────────────────────────────────

        UpgradeDefinition(
            id: .bonusGlobal,
            category: .bonus,
            currency: .money,
            icon: "chart.line.uptrend.xyaxis",
            name: "Efficacité Globale",
            description: "Augmente les revenus de toutes les usines.",
            effectDescription: "+1% revenus globaux/niv.",
            baseCost: 1000,
            costMultiplier: 1.45,
            maxLevel: 999999
        ),
        UpgradeDefinition(
            id: .bonusCommun,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Commun",
            description: "Augmente les revenus des canards Communs.",
            effectDescription: "+2% revenus Communs/niv.",
            baseCost: 1000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusPeuCommun,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Peu Commun",
            description: "Augmente les revenus des canards Peu Communs.",
            effectDescription: "+2% revenus P.C./niv.",
            baseCost: 10000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusRare,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Rare",
            description: "Augmente les revenus des canards Rares.",
            effectDescription: "+2% revenus Rares/niv.",
            baseCost: 100_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusEpique,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Épique",
            description: "Augmente les revenus des canards Épiques.",
            effectDescription: "+2% revenus Épiques/niv.",
            baseCost: 1_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusLegendaire,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Légendaire",
            description: "Augmente les revenus des canards Légendaires.",
            effectDescription: "+2% revenus Lég./niv.",
            baseCost: 10_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusMythique,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Mythique",
            description: "Augmente les revenus des canards Mythiques.",
            effectDescription: "+2% revenus Mythiques/niv.",
            baseCost: 100_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusMutation,
            category: .bonus,
            currency: .money,
            icon: "flask.fill",
            name: "Bonus Mutation",
            description: "Augmente les mutations obtenues lors du recyclage.",
            effectDescription: "+2% de mutations/niv.",
            baseCost: 1_000_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .paradisFiscal,
            category: .bonus,
            currency: .money,
            icon: "banknote.fill",
            name: "Paradis Fiscal",
            description: "Réduit les taxes de fusion.",
            effectDescription: "-5% taxes fusion/niv.",
            baseCost: 2_000_000,
            costMultiplier: 1.618,
            maxLevel: 20
        ),
        UpgradeDefinition(
            id: .bonusExotique,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Exotique",
            description: "Augmente les revenus des canards Exotiques.",
            effectDescription: "+2% revenus Exotiques/niv.",
            baseCost: 1_000_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusCeleste,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Céleste",
            description: "Augmente les revenus des canards Célestes.",
            effectDescription: "+2% revenus Célestes/niv.",
            baseCost: 10_000_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusPrimordiale,
            category: .bonus,
            currency: .money,
            icon: "circle.fill",
            name: "Bonus Primordial",
            description: "Augmente les revenus des canards Primordiaux.",
            effectDescription: "+2% revenus Primordiaux/niv.",
            baseCost: 100_000_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusEvolutionCost,
            category: .bonus,
            currency: .mutationPoints,
            icon: "arrow.down.circle.fill",
            name: "Maîtrise d'Évolution",
            description: "Réduit le coût des évolutions d'usine.",
            effectDescription: "-1% coût d'évolution/niv.",
            baseCost: 1_000_000,
            costMultiplier: 1.55,
            maxLevel: 50
        ),
        UpgradeDefinition(
            id: .bonusAutomationSpeed,
            category: .bonus,
            currency: .mutationPoints,
            icon: "speedometer",
            name: "Cadence Automatisée",
            description: "Réduit les intervalles de l'Auto-Ouvrier et de l'Auto-Usine.",
            effectDescription: "-1% intervalle automatisation/niv.",
            baseCost: 2_000_000,
            costMultiplier: 1.5,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusPerkPower,
            category: .bonus,
            currency: .mutationPoints,
            icon: "sparkle",
            name: "Résonance de Perk",
            description: "Amplifie tous les effets numériques des perks équipés.",
            effectDescription: "+2% effets de perks/niv.",
            baseCost: 3_000_000,
            costMultiplier: 1.618,
            maxLevel: 100
        ),
        UpgradeDefinition(
            id: .bonusPrestigeStars,
            category: .bonus,
            currency: .mutationPoints,
            icon: "star.circle.fill",
            name: "Calcul Stellaire",
            description: "Augmente le nombre d'étoiles gagnées au prestige.",
            effectDescription: "+0.5% étoiles gagnées/niv.",
            baseCost: 5_000_000,
            costMultiplier: 1.6,
            maxLevel: 50
        ),
    ]

    /// Calcule le coût pour acheter le prochain niveau
    func cost(forNextLevel level: Int) -> BigNumber {
        if maxLevel == 1 { return BigNumber(baseCost) }
        return BigNumber(baseCost) * BigNumber.pow(BigNumber(costMultiplier), level)
    }
}
