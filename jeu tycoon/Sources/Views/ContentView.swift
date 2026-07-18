import SwiftUI


struct TopBarView: View {
    @Environment(GameManager.self) private var gameManager
    @Binding var showingSettings: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                Text(gameManager.money.formattedString())
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(tr("💰"))
            }
            
            HStack(spacing: 2) {
                Text(gameManager.mutationPoints.formattedString())
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(tr("🧬"))
            }
            
            if gameManager.hasPrestiged {
                HStack(spacing: 2) {
                    Text(gameManager.unspentStars.formattedString())
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(tr("⭐️"))
                }
            }
            
            HStack(spacing: 2) {
                Text(gameManager.gems.formattedString())
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(tr("💎"))
            }
            
            Spacer(minLength: 0)
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.clear)
    }
}

struct ContentView: View {
    // Injection du GameManager. (Assure-toi que ton projet cible iOS 17+)
    @State private var gameManager = GameManager()
    
    // Pour gérer la sauvegarde à la fermeture de l'app
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barre globale des ressources et paramètres isolée pour éviter le rafraîchissement global
            TopBarView(showingSettings: $showingSettings)
                .zIndex(1)
            
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case 0:
                        StoryView()
                    case 1:
                        FactoryView()
                    case 2:
                        CrateShopView()
                    case 3:
                        InventoryView(selectedTab: $selectedTab, navPath: $navPath)
                    case 4:
                        UpgradeView()
                    case 5:
                        RitualView()
                    case 6:
                        PrestigeView()
                    case 7:
                        IAPShopView()
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 90)
                
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { gameManager.pendingOfflineEarnings != nil },
            set: { _ in }
        )) {
            OfflineEarningsPopupView()
                .presentationBackground(.clear)
                .environment(gameManager)
        }
        .environment(gameManager)
        .offset(gameManager.globalShakeOffset)
        .overlay(
            Color.white
                .opacity(gameManager.globalFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
        .navigationBarHidden(true)
        .navigationDestination(for: Duck.self) { duck in
            DuckDetailView(duck: duck)
                .environment(gameManager)
        }
        } // closes ZStack
        } // closes NavigationStack
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(gameManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                gameManager.saveGame(sync: true)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @Environment(GameManager.self) private var gameManager
    
    let tabs: [(title: String, icon: String, color: Color)] = [
        ("Histoire", "book.fill", .blue),
        ("Usines", "building.2.crop.circle", .green),
        ("Boutique", "shippingbox", .orange),
        ("Canards", "bird", .yellow),
        ("Amélio.", "bolt.circle.fill", .purple),
        ("Rituel", "flame", .red),
        ("Prestige", "star.fill", .yellow),
        ("Banque", "creditcard.fill", .cyan)
    ]
    
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private func isUnlocked(_ index: Int) -> Bool {
        switch index {
        case 0: return gameManager.isHistoireUnlocked
        case 1: return gameManager.isUsinesUnlocked
        case 2: return gameManager.isBoutiqueUnlocked
        case 3: return gameManager.isInventoryUnlocked
        case 4: return gameManager.isAmelioUnlocked
        case 5: return gameManager.isRituelUnlocked
        case 6: return gameManager.isPrestigeUnlocked
        case 7: return gameManager.isBanqueUnlocked
        default: return true
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    let unlocked = isUnlocked(index)
                    if unlocked {
                        feedbackGenerator.prepare()
                        feedbackGenerator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    } else {
                        let errorFeedback = UINotificationFeedbackGenerator()
                        errorFeedback.notificationOccurred(.error)
                    }
                }) {
                    let unlocked = isUnlocked(index)
                    VStack(spacing: 4) {
                        if unlocked {
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: 20, weight: selectedTab == index ? .bold : .regular))
                                .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20, weight: .regular))
                        }
                        
                        if selectedTab == index {
                            Text(tr(tabs[index].title))
                                .font(.system(size: 9, weight: .bold)) // Slightly smaller to fit 7 tabs
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else if !unlocked {
                            Text(tr(tabs[index].title))
                                .font(.system(size: 7, weight: .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                    .foregroundColor(unlocked ? tabs[index].color.opacity(selectedTab == index ? 1.0 : 0.5) : .gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                }
                .disabled(!isUnlocked(index))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}
