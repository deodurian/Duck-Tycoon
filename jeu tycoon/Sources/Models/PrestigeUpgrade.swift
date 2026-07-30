import Foundation
import SwiftUI

struct PrestigeUpgrade: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let cost: Int
    let requiredSpentStars: Int
    
    // Paliers for UI organization
    var tier: Int {
        if requiredSpentStars == 0 { return 1 }
        if requiredSpentStars == 1 { return 2 }
        if requiredSpentStars == 3 { return 3 }
        if requiredSpentStars == 10 { return 4 }
        if requiredSpentStars == 25 { return 5 }
        if requiredSpentStars == 60 { return 6 }
        if requiredSpentStars == 120 { return 7 }
        return 7 // fallback explicite pour tout seuil futur non mappé
    }

    var tierIconName: String {
        switch tier {
        case 1: return "1.circle.fill"
        case 2: return "2.circle.fill"
        case 3: return "3.circle.fill"
        case 4: return "4.circle.fill"
        case 5: return "5.circle.fill"
        case 6: return "6.circle.fill"
        default: return "7.circle.fill"
        }
    }

    var tierColor: Color {
        switch tier {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        case 5: return .pink
        case 6: return .indigo
        default: return .yellow
        }
    }
}

extension PrestigeUpgrade {
    static let allUpgrades: [PrestigeUpgrade] = [
        // Palier 1
        PrestigeUpgrade(id: "p1_auto", name: "Automatisation Initiale", description: "Débloque l'accès aux automatisations dans l'onglet des améliorations.", cost: 1, requiredSpentStars: 0),
        
        // Palier 2
        PrestigeUpgrade(id: "p2_val_com", name: "Valeur Commune", description: "+100 % à la valeur des canards Communs et Peu Communs.", cost: 1, requiredSpentStars: 1),
        PrestigeUpgrade(id: "p2_val_rare", name: "Valeur Rare", description: "+75 % à la valeur des canards Rares et Épiques.", cost: 1, requiredSpentStars: 1),
        PrestigeUpgrade(id: "p2_val_leg", name: "Valeur Légendaire", description: "+50 % à la valeur des canards Légendaires et Mythiques.", cost: 2, requiredSpentStars: 1),
        PrestigeUpgrade(id: "p2_eco", name: "Économie Globale", description: "+30 % à tous les revenus d'argent.", cost: 1, requiredSpentStars: 1),
        
        // Palier 3
        PrestigeUpgrade(id: "p3_fusion", name: "Savoir de Fusion", description: "La mécanique de Fusion est débloquée d'office, même après un prestige.", cost: 5, requiredSpentStars: 3),
        PrestigeUpgrade(id: "p3_val_base", name: "Valeur de Base II", description: "+50 % à la valeur des canards Communs, Peu Communs et Rares.", cost: 2, requiredSpentStars: 3),
        PrestigeUpgrade(id: "p3_usine_evo", name: "Évolution d'Usine", description: "Débloque la première Évolution de l'usine (permet de dépasser le niveau 100).", cost: 4, requiredSpentStars: 3),
        
        // Palier 4
        PrestigeUpgrade(id: "p4_recycle", name: "Savoir de Recyclage", description: "La mécanique de Recyclage est débloquée d'office.", cost: 3, requiredSpentStars: 10),
        PrestigeUpgrade(id: "p4_adn", name: "Mutagénèse Globale", description: "+200 % à tous les revenus d'ADN.", cost: 5, requiredSpentStars: 10),
        PrestigeUpgrade(id: "p4_rituel", name: "Magie Rituelle", description: "Le gain de base du rituel passe de x2 à x3 (et le Rituel Doré passe de x10 à x15).", cost: 5, requiredSpentStars: 10),
        PrestigeUpgrade(id: "p4_fusion_ing", name: "Fusion Ingénieuse", description: "Lors d'une fusion, le canard avec la plus haute valeur est compté 2 fois !", cost: 6, requiredSpentStars: 10),

        // Palier 5
        PrestigeUpgrade(id: "p5_rarete_exo", name: "Synchronisation Exotique", description: "+100 % à la valeur des canards Exotique, Céleste et Primordiale.", cost: 8, requiredSpentStars: 25),
        PrestigeUpgrade(id: "p5_evo_cost", name: "Ingénierie d'Évolution", description: "-20 % sur le coût des évolutions d'usine (cumulatif).", cost: 6, requiredSpentStars: 25),
        PrestigeUpgrade(id: "p5_auto2", name: "Automatisation Avancée", description: "Débloque directement Auto-Ouvrier V (1 capsule / 0.25s).", cost: 10, requiredSpentStars: 25),
        PrestigeUpgrade(id: "p5_perk_slot", name: "Emplacements Renforcés", description: "+1 emplacement de perk supplémentaire pour les usines ET les canards.", cost: 12, requiredSpentStars: 25),
        PrestigeUpgrade(id: "p5_adn2", name: "Mutagénèse Avancée", description: "+150 % à tous les revenus d'ADN (cumulatif avec Mutagénèse Globale).", cost: 8, requiredSpentStars: 25),

        // Palier 6
        PrestigeUpgrade(id: "p6_rarete_myth", name: "Résonance Mythique", description: "+75 % à la valeur des canards Mythique, Exotique, Céleste et Primordiale.", cost: 10, requiredSpentStars: 60),
        PrestigeUpgrade(id: "p6_usine_evo2", name: "Double Évolution", description: "La 1ère Évolution d'une usine offre directement la 2ème gratuitement.", cost: 15, requiredSpentStars: 60),
        PrestigeUpgrade(id: "p6_auto3", name: "Auto-Usine Suprême", description: "Débloque directement le niveau 5 (1 niv / 0.2s) de l'Auto-Usine sur toutes les usines.", cost: 12, requiredSpentStars: 60),
        PrestigeUpgrade(id: "p6_perk_power", name: "Perks Amplifiés", description: "+30 % à tous les effets numériques des perks équipés.", cost: 14, requiredSpentStars: 60),
        PrestigeUpgrade(id: "p6_fusion_taxfree", name: "Fusion Libre", description: "-50 % supplémentaires sur la taxe de fusion (cumulatif avec Paradis Fiscal).", cost: 10, requiredSpentStars: 60),

        // Palier 7
        PrestigeUpgrade(id: "p7_rarete_primo", name: "Éveil Primordial", description: "+200 % valeur ET +200 % ADN pour les canards Primordiale, Céleste et Exotique.", cost: 20, requiredSpentStars: 120),
        PrestigeUpgrade(id: "p7_usine_evo_cost", name: "Maîtrise Industrielle Totale", description: "-50 % sur le coût de toutes les évolutions d'usine (cumulatif).", cost: 18, requiredSpentStars: 120),
        PrestigeUpgrade(id: "p7_star_gain", name: "Constellation", description: "+50 % d'étoiles gagnées à chaque prestige.", cost: 25, requiredSpentStars: 120),
        PrestigeUpgrade(id: "p7_auto_max", name: "Singularité Automatisée", description: "Auto-Ouvrier et Auto-Usine démarrent instantanément à vitesse maximale sur toute usine.", cost: 20, requiredSpentStars: 120),
        PrestigeUpgrade(id: "p7_omnipotence", name: "Ascension Finale", description: "+1000 % argent, +500 % ADN, -75 % sur tous les coûts d'usine et d'évolution.", cost: 30, requiredSpentStars: 120)
    ]
}
