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
        return 5
    }
    
    var tierIconName: String {
        switch tier {
        case 1: return "1.circle.fill"
        case 2: return "2.circle.fill"
        case 3: return "3.circle.fill"
        case 4: return "4.circle.fill"
        default: return "star.circle.fill"
        }
    }
    
    var tierColor: Color {
        switch tier {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
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
        PrestigeUpgrade(id: "p4_fusion_ing", name: "Fusion Ingénieuse", description: "Lors d'une fusion, le canard avec la plus haute valeur est compté 2 fois !", cost: 6, requiredSpentStars: 10)
    ]
}
