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
                    Text(gameManager.currentStars.formattedString())
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
                        FactoryView()
                    case 1:
                        InventoryView(selectedTab: $selectedTab, navPath: $navPath)
                    case 2:
                        UpgradeView()
                    case 3:
                        CrateShopView()
                    case 4:
                        RitualView()
                    case 5:
                        PrestigeView()
                    case 6:
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
    
    let tabs = [
        (title: "Usines", icon: "building.2.crop.circle"),
        (title: "Canards", icon: "bird"),
        (title: "Amélio.", icon: "bolt.circle.fill"),
        (title: "Boutique", icon: "shippingbox"),
        (title: "Rituel", icon: "flame"),
        (title: "Prestige", icon: "star.fill"),
        (title: "Banque", icon: "creditcard.fill")
    ]
    
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    feedbackGenerator.prepare()
                    feedbackGenerator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20, weight: selectedTab == index ? .bold : .regular))
                            .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                        
                        if selectedTab == index {
                            Text(tr(tabs[index].title))
                                .font(.system(size: 9, weight: .bold)) // Slightly smaller to fit 7 tabs
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .foregroundColor(selectedTab == index ? (colorScheme == .dark ? .white : .blue) : .gray)
                    .frame(maxWidth: .infinity)
                }
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
