import SwiftUI
import StoreKit

struct IAPShopView: View {
    @Environment(GameManager.self) private var gameManager
    
    // Pour recharger les produits si nécessaire
    @State private var storeManager = StoreManager.shared
    
    // Le mode développeur est utilisé pour bypasser les prix réels
    @AppStorage("isDeveloperMode") private var isDeveloperMode: Bool = false
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                // En-tête
                Text(tr("Banque"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                Text(tr("Achats Premium"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Section 1 : Argent
                        ShopSectionView(
                            title: "Packs d'Argent",
                            icon: "banknote.fill",
                            color: .green,
                            definitions: storeManager.definitions.filter { def in
                                if case .money = def.type { return true }
                                if case .moneyOverTime = def.type { return true }
                                return false
                            }
                        )
                        
                        // Section 2 : ADN
                        ShopSectionView(
                            title: "Packs d'ADN",
                            icon: "dna",
                            color: .purple,
                            definitions: storeManager.definitions.filter { def in
                                if case .dna = def.type { return true }
                                return false
                            }
                        )
                        
                        // Section 3 : Gemmes
                        ShopSectionView(
                            title: tr("Gemmes"),
                            icon: "diamond.fill",
                            color: .cyan,
                            definitions: storeManager.definitions.filter { def in
                                if case .gems = def.type { return true }
                                return false
                            }
                        )
                    }
                    .padding(.vertical)
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            // Charge les produits depuis Apple au chargement de la vue
            if !isDeveloperMode && storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
        }
    }
}

struct ShopSectionView: View {
    let title: String
    let icon: String
    let color: Color
    let definitions: [StoreProductDefinition]
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(tr(title))
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(definitions, id: \.id) { def in
                    ShopItemCard(definition: def, color: color)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ShopItemCard: View {
    @Environment(GameManager.self) private var gameManager
    @State private var storeManager = StoreManager.shared
    @AppStorage("isDeveloperMode") private var isDeveloperMode: Bool = false
    
    let definition: StoreProductDefinition
    let color: Color
    
    var product: Product? {
        storeManager.products.first(where: { $0.id == definition.id })
    }
    

    
    var body: some View {
        Button(action: {
            Task {
                if isDeveloperMode {
                    await storeManager.purchase(definition: definition, gameManager: gameManager)
                } else if let p = product {
                    await storeManager.purchase(product: p, gameManager: gameManager)
                } else {
                    // Silently ignore if product is not available yet
                }
            }
        }) {
            VStack(spacing: 8) {
                Text(definition.type.iconName)
                    .font(.system(size: 30))
                
                Text(tr(definition.type.title))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
                
                Text(isDeveloperMode ? "Gratuit (Dev)" : (product?.displayPrice ?? definition.type.simulatedPrice))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(10)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(storeManager.isPurchasing && !isDeveloperMode)
        .opacity(storeManager.isPurchasing && !isDeveloperMode ? 0.5 : 1.0)
    }
}
