import StoreKit
import SwiftUI

enum IAPProductType {
    case gems(amount: Int)
    
    var title: String {
        switch self {
        case .gems(let amount): return "+\(amount)"
        }
    }
    
    var iconName: String {
        switch self {
        case .gems: return "💎"
        }
    }
    
    var simulatedPrice: String {
        switch self {
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

enum VirtualShopProduct {
    case money(amount: Double, gemCost: Int)
    case moneyOverTime(hours: Int, gemCost: Int)
    case dna(amount: Int, gemCost: Int)
    
    var title: String {
        switch self {
        case .money(let amount, _): return "+\(BigNumber(amount).formattedString())"
        case .moneyOverTime(let hours, _): return "\(hours)H de revenus"
        case .dna(let amount, _): return "+\(amount.formattedString())"
        }
    }
    
    var iconName: String {
        switch self {
        case .money, .moneyOverTime: return "💰"
        case .dna: return "🧬"
        }
    }
    
    var gemCost: Int {
        switch self {
        case .money(_, let cost): return cost
        case .moneyOverTime(_, let cost): return cost
        case .dna(_, let cost): return cost
        }
    }
}

@Observable
class StoreManager {
    static let shared = StoreManager()
    
    // Les produits récupérés depuis StoreKit
    var products: [Product] = []
    var isPurchasing = false
    
    // Définition de tous les produits IAP de la boutique
    let definitions: [StoreProductDefinition] = [
        // Gemmes
        StoreProductDefinition(id: "com.jeutycoon.gems.1", type: .gems(amount: 50)),
        StoreProductDefinition(id: "com.jeutycoon.gems.2", type: .gems(amount: 250)),
        StoreProductDefinition(id: "com.jeutycoon.gems.3", type: .gems(amount: 1200)),
        StoreProductDefinition(id: "com.jeutycoon.gems.4", type: .gems(amount: 2500)),
        StoreProductDefinition(id: "com.jeutycoon.gems.5", type: .gems(amount: 6500)),
        StoreProductDefinition(id: "com.jeutycoon.gems.6", type: .gems(amount: 15000))
    ]
    
    // Définition de tous les produits Virtuels (achetables en Gemmes)
    let virtualProducts: [VirtualShopProduct] = [
        // Argent fixe
        .money(amount: 10_000, gemCost: 10),
        .money(amount: 100_000, gemCost: 50),
        .money(amount: 1_000_000, gemCost: 200),
        .money(amount: 10_000_000, gemCost: 500),
        .money(amount: 100_000_000, gemCost: 1200),
        .money(amount: 1_000_000_000, gemCost: 2500),
        
        // Argent sur la durée
        .moneyOverTime(hours: 1, gemCost: 10),
        .moneyOverTime(hours: 4, gemCost: 50),
        .moneyOverTime(hours: 12, gemCost: 200),
        
        // ADN
        .dna(amount: 100, gemCost: 10),
        .dna(amount: 500, gemCost: 50),
        .dna(amount: 2500, gemCost: 200),
        .dna(amount: 10_000, gemCost: 500),
        .dna(amount: 50_000, gemCost: 1200),
        .dna(amount: 250_000, gemCost: 2500)
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
        case .gems(let amount):
            gameManager.gems += BigNumber(Double(amount))
        }
        
        gameManager.saveGame()
    }
    
    func purchaseVirtualProduct(_ product: VirtualShopProduct, gameManager: GameManager) -> Bool {
        let cost = BigNumber(Double(product.gemCost))
        if gameManager.gems >= cost {
            gameManager.gems -= cost
            
            switch product {
            case .money(let amount, _):
                gameManager.money += BigNumber(amount)
            case .moneyOverTime(let hours, _):
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
            case .dna(let amount, _):
                gameManager.addMutationPoints(BigNumber(Double(amount)))
            }
            gameManager.saveGame()
            return true
        }
        return false
    }
}
