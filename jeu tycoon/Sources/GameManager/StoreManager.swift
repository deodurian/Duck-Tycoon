import StoreKit
import SwiftUI

enum IAPProductType {
    case money(amount: Double)
    case moneyOverTime(hours: Int)
    case dna(amount: Int)
    case gems(amount: Int)
    
    var title: String {
        switch self {
        case .money(let amount): return "+\(BigNumber(amount).formattedString())"
        case .moneyOverTime(let hours): return "\(hours)H de revenus"
        case .dna(let amount): return "+\(amount.formattedString())"
        case .gems(let amount): return "+\(amount)"
        }
    }
    
    var iconName: String {
        switch self {
        case .money, .moneyOverTime: return "💰"
        case .dna: return "🧬"
        case .gems: return "💎"
        }
    }
    
    var simulatedPrice: String {
        switch self {
        case .moneyOverTime(let hours):
            return "€\(Double(hours) * 0.99)"
        case .money(let amount):
            let tier = log10(amount) - 3 // pseudo pricing
            return "€\(max(0.99, (tier * 1.5).roundedToSixSignificantDigits()))"
        case .dna(let amount):
            let tier = log10(Double(amount)) - 1
            return "€\(max(0.99, (tier * 2.0).roundedToSixSignificantDigits()))"
        case .gems(let amount):
            let tier = Double(amount) / 100.0
            return "€\(max(0.99, tier.roundedToSixSignificantDigits()))"
        }
    }
}

struct StoreProductDefinition {
    let id: String
    let type: IAPProductType
}

@Observable
class StoreManager {
    static let shared = StoreManager()
    
    // Les produits récupérés depuis StoreKit
    var products: [Product] = []
    var isPurchasing = false
    
    // Définition de tous les produits de la boutique
    let definitions: [StoreProductDefinition] = [
        // Argent fixe
        StoreProductDefinition(id: "com.jeutycoon.money.1", type: .money(amount: 10_000)),
        StoreProductDefinition(id: "com.jeutycoon.money.2", type: .money(amount: 100_000)),
        StoreProductDefinition(id: "com.jeutycoon.money.3", type: .money(amount: 1_000_000)),
        StoreProductDefinition(id: "com.jeutycoon.money.4", type: .money(amount: 10_000_000)),
        StoreProductDefinition(id: "com.jeutycoon.money.5", type: .money(amount: 100_000_000)),
        StoreProductDefinition(id: "com.jeutycoon.money.6", type: .money(amount: 1_000_000_000)),
        
        // Argent sur la durée
        StoreProductDefinition(id: "com.jeutycoon.money.time.1", type: .moneyOverTime(hours: 1)),
        StoreProductDefinition(id: "com.jeutycoon.money.time.2", type: .moneyOverTime(hours: 4)),
        StoreProductDefinition(id: "com.jeutycoon.money.time.3", type: .moneyOverTime(hours: 12)),
        
        // ADN
        StoreProductDefinition(id: "com.jeutycoon.dna.1", type: .dna(amount: 100)),
        StoreProductDefinition(id: "com.jeutycoon.dna.2", type: .dna(amount: 500)),
        StoreProductDefinition(id: "com.jeutycoon.dna.3", type: .dna(amount: 2500)),
        StoreProductDefinition(id: "com.jeutycoon.dna.4", type: .dna(amount: 10_000)),
        StoreProductDefinition(id: "com.jeutycoon.dna.5", type: .dna(amount: 50_000)),
        StoreProductDefinition(id: "com.jeutycoon.dna.6", type: .dna(amount: 250_000)),
        
        // Gemmes
        StoreProductDefinition(id: "com.jeutycoon.gems.1", type: .gems(amount: 50)),
        StoreProductDefinition(id: "com.jeutycoon.gems.2", type: .gems(amount: 250)),
        StoreProductDefinition(id: "com.jeutycoon.gems.3", type: .gems(amount: 1200)),
        StoreProductDefinition(id: "com.jeutycoon.gems.4", type: .gems(amount: 2500)),
        StoreProductDefinition(id: "com.jeutycoon.gems.5", type: .gems(amount: 6500)),
        StoreProductDefinition(id: "com.jeutycoon.gems.6", type: .gems(amount: 15000))
    ]
    
    private var updatesTask: Task<Void, Never>? = nil
    
    init() {
        updatesTask = listenForTransactions()
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    func loadProducts() async {
        let productIds = definitions.map { $0.id }
        do {
            products = try await Product.products(for: productIds)
        } catch {
            // Silently ignore store loading errors
        }
    }
    
    func purchase(product: Product, gameManager: GameManager) async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        let isDeveloperMode = UserDefaults.standard.bool(forKey: "isDeveloperMode")
        
        if isDeveloperMode {
            // Mode développeur : achat simulé immédiat
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            deliverReward(for: product.id, gameManager: gameManager)
            return
        }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Livraison de la récompense
                    deliverReward(for: transaction.productID, gameManager: gameManager)
                    await transaction.finish()
                case .unverified(_, _):
                    break
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // Silently handle purchase error
        }
    }
    
    // Purchase via Definition directly (for developer mode if product is not loaded)
    func purchase(definition: StoreProductDefinition, gameManager: GameManager) async {
        let isDeveloperMode = UserDefaults.standard.bool(forKey: "isDeveloperMode")
        guard isDeveloperMode else { return }
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        deliverReward(for: definition.id, gameManager: gameManager)
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    // On s'assure juste que la transaction est terminée.
                    await transaction.finish()
                case .unverified(_, _):
                    break
                }
            }
        }
    }
    
    private func deliverReward(for productId: String, gameManager: GameManager) {
        guard let def = definitions.first(where: { $0.id == productId }) else { return }
        
        switch def.type {
        case .money(let amount):
            gameManager.money += BigNumber(amount)
        case .moneyOverTime(let hours):
            // Calculer les revenus actuels de toutes les usines
            var eps: BigNumber = .zero
            for factory in gameManager.factories {
                if !factory.assignedDuckIds.isEmpty {
                    let ducks = factory.assignedDuckIds.compactMap { id in gameManager.inventory.first { $0.id == id } }
                    let displayValues = ducks.map { gameManager.displaySellValue(for: $0) }
                    let factoryPerks = factory.equippedPerkIds.compactMap { id in gameManager.perksInventory.first { $0.id == id } }
                    eps += factory.calculateEarningsPerSecond(assignedDucks: ducks, duckDisplayValues: displayValues, factoryPerks: factoryPerks)
                }
            }
            let seconds = Double(hours * 3600)
            let total = eps * seconds
            if total > .zero {
                gameManager.money += total
            } else {
                gameManager.money += BigNumber(Double(hours * 100))
            }
        case .dna(let amount):
            gameManager.addMutationPoints(BigNumber(Double(amount)))
        case .gems(let amount):
            gameManager.gems += BigNumber(Double(amount))
        }
        
        gameManager.saveGame()
    }
}
