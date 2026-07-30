import SwiftUI
import StoreKit

struct IAPShopView: View {
    @Environment(GameManager.self) private var gameManager
    
    // Pour recharger les produits si nécessaire
    @State private var storeManager = StoreManager.shared
    
    // Le mode développeur est utilisé pour bypasser les prix réels
    @AppStorage("isDeveloperMode") private var isDeveloperMode: Bool = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                // En-tête
                Text(tr("Banque"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .neonTitle(Neon.green)
                    .padding(.top, 10)
                
                Text(tr("Achats Premium"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Section 0 : Pub
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "play.rectangle.fill").foregroundColor(.red)
                                Text(tr("Offres Quotidiennes")).font(.title2.bold()).foregroundColor(.white)
                            }.padding(.horizontal)
                            
                            Button(action: { gameManager.watchAdForGems() }) {
                                HStack {
                                    Image(systemName: "video.fill").font(.title2)
                                    VStack(alignment: .leading) {
                                        Text(tr("10 Gemmes Gratuites")).font(.headline)
                                        Text("\(5 - gameManager.dailyAdGemsCount) \(tr("restants aujourd'hui"))").font(.caption).foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    Text("+10 💎").font(.title3.bold())
                                }
                            }
                            .buttonStyle(NeonButtonStyle(color: Neon.cyan))
                            .opacity(gameManager.canWatchAdForGems ? 1.0 : 0.5)
                            .disabled(!gameManager.canWatchAdForGems)
                            .padding(.horizontal)
                        }
                        
                        // Section 1 : Gemmes (Achats IAP réels)
                        ShopSectionView(
                            title: tr("Gemmes"),
                            icon: "diamond.fill",
                            color: .cyan,
                            definitions: storeManager.definitions
                        )
                        
                        // Section 2 : Argent (Achats virtuels en Gemmes)
                        VirtualShopSectionView(
                            title: "Packs d'Argent",
                            icon: "banknote.fill",
                            color: .green,
                            products: storeManager.virtualProducts.filter { prod in
                                if case .money = prod { return true }
                                if case .moneyOverTime = prod { return true }
                                return false
                            },
                            onPurchaseFailed: {
                                alertMessage = tr("Pas assez de gemmes !")
                                showAlert = true
                            }
                        )
                        
                        // Section 3 : ADN (Achats virtuels en Gemmes)
                        VirtualShopSectionView(
                            title: "Packs d'ADN",
                            icon: "flask.fill",
                            color: .purple,
                            products: storeManager.virtualProducts.filter { prod in
                                if case .dna = prod { return true }
                                return false
                            },
                            onPurchaseFailed: {
                                alertMessage = tr("Pas assez de gemmes !")
                                showAlert = true
                            }
                        )
                    }
                    .padding(.vertical)
                    .padding(.bottom, 100)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(tr("Erreur")), message: Text(alertMessage), dismissButton: .default(Text(tr("OK"))))
        }
        .task {
            // Charge les produits depuis Apple au chargement de la vue
            if !isDeveloperMode && storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
        }
    }
}

// MARK: - Shared Section & Card Chrome

/// En-tête de section + grille 3 colonnes, communs aux sections IAP et virtuelles.
struct ShopSectionContainer<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    private static var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 15), count: 3)
    }

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

            LazyVGrid(columns: Self.columns, spacing: 15) {
                content()
            }
            .padding(.horizontal)
        }
    }
}

/// Mise en page commune d'une carte du shop : icône, titre, badge de prix, fond et bordure.
struct ShopCardLayout<Badge: View>: View {
    let iconName: String
    let title: String
    let color: Color
    @ViewBuilder let badge: () -> Badge

    var body: some View {
        VStack(spacing: 8) {
            Text(iconName)
                .font(.system(size: 30))

            Text(tr(title))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            badge()
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
}

// MARK: - IAP Section (Real Money)
struct ShopSectionView: View {
    let title: String
    let icon: String
    let color: Color
    let definitions: [StoreProductDefinition]

    var body: some View {
        ShopSectionContainer(title: title, icon: icon, color: color) {
            ForEach(definitions, id: \.id) { def in
                ShopItemCard(definition: def, color: color)
            }
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
            ShopCardLayout(iconName: definition.type.iconName, title: definition.type.title, color: color) {
                Text(isDeveloperMode ? "Gratuit (Dev)" : (product?.displayPrice ?? definition.type.simulatedPrice))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(storeManager.isPurchasing && !isDeveloperMode)
        .opacity(storeManager.isPurchasing && !isDeveloperMode ? 0.5 : 1.0)
    }
}

// MARK: - Virtual Section (Gems)
struct VirtualShopSectionView: View {
    let title: String
    let icon: String
    let color: Color
    let products: [VirtualShopProduct]
    let onPurchaseFailed: () -> Void

    var body: some View {
        ShopSectionContainer(title: title, icon: icon, color: color) {
            ForEach(0..<products.count, id: \.self) { index in
                VirtualShopItemCard(product: products[index], color: color, onPurchaseFailed: onPurchaseFailed)
            }
        }
    }
}

struct VirtualShopItemCard: View {
    @Environment(GameManager.self) private var gameManager
    @State private var storeManager = StoreManager.shared
    
    let product: VirtualShopProduct
    let color: Color
    let onPurchaseFailed: () -> Void
    
    var body: some View {
        Button(action: {
            let success = storeManager.purchaseVirtualProduct(product, gameManager: gameManager)
            if !success {
                onPurchaseFailed()
            } else {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
        }) {
            ShopCardLayout(iconName: product.iconName, title: product.title, color: color) {
                HStack(spacing: 4) {
                    Text("\(product.gemCost)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)
                    Text("💎")
                        .font(.system(size: 10))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
