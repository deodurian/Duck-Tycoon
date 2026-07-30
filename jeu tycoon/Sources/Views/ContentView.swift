import SwiftUI


struct TopBarView: View {
    @Environment(GameManager.self) private var gameManager
    @Binding var showingSettings: Bool

    @State private var moneyScale: CGFloat = 1.0
    @State private var dnaScale: CGFloat = 1.0

    /// Palpitation ponctuelle quand une ressource fait un gros bond (quête, capsule…),
    /// sans réagir au flux régulier du revenu passif.
    private func pulse(_ scale: Binding<CGFloat>) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { scale.wrappedValue = 1.25 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { scale.wrappedValue = 1.0 }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            CurrencyBadge(icon: "💰", amount: gameManager.money.formattedString(), color: Neon.yellow)
                .scaleEffect(moneyScale)
                .onChange(of: gameManager.money) { old, new in
                    if new > old * 1.5 { pulse($moneyScale) }
                }

            CurrencyBadge(icon: "🧬", amount: gameManager.mutationPoints.formattedString(), color: Neon.green)
                .scaleEffect(dnaScale)
                .onChange(of: gameManager.mutationPoints) { old, new in
                    if new > old * 1.5 { pulse($dnaScale) }
                }

            if gameManager.hasPrestiged {
                CurrencyBadge(icon: "⭐️", amount: gameManager.unspentStars.formattedString(), color: Neon.purple)
            }

            CurrencyBadge(icon: "💎", amount: gameManager.gems.formattedString(), color: Neon.cyan)

            Spacer(minLength: 0)

            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.clear)
    }
}

struct ContentView: View {
    // Injection du GameManager : instance partagée, car ContentView() est reconstruit
    // à chaque réévaluation du body parent (voir GameManager.shared).
    @State private var gameManager = GameManager.shared
    
    // Pour gérer la sauvegarde à la fermeture de l'app
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack(alignment: .top) {
            NeonBackground(accent: Neon.accent(forTab: selectedTab))
                .animation(.easeInOut(duration: 0.5), value: selectedTab)
            
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
                        InventoryView(selectedTab: $selectedTab, navPath: $navPath)
                    case 3:
                        CrateShopView()
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
        .overlay {
            ConfettiView(trigger: gameManager.confettiBurst)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            if let toast = gameManager.activeToast {
                ToastView(toast: toast)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
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
            // iOS passe toujours par .inactive avant .background : sauvegarder sur les deux
            // encodait tout l'état deux fois (sur le thread principal) à chaque aller-retour,
            // y compris pour un simple centre de contrôle tiré vers le bas.
            if newPhase == .background {
                gameManager.saveGame(sync: true)
            }
        }
        #if DEBUG
        // Filigrane discret : rappelle que le build est en mode développeur
        // (stats potentiellement truquées — ne pas utiliser pour des captures App Store)
        .overlay(alignment: .top) {
            Text("DEV")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.orange.opacity(0.8))
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
                .allowsHitTesting(false)
        }
        #endif
        .preferredColorScheme(.dark)
    }
}

/// Petit point rouge de notification avec une pulsation subtile.
struct NotificationDot: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .overlay(
                Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .scaleEffect(pulse ? 1.25 : 0.9)
            .shadow(color: .red.opacity(0.8), radius: pulse ? 4 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @Environment(GameManager.self) private var gameManager
    
    let tabs: [(title: String, icon: String, color: Color)] = [
        ("Histoire", "book.fill", .green),
        ("Usines", "building.2.crop.circle", .blue),
        ("Canards", "bird", Color(red: 0.0, green: 0.35, blue: 0.12)),
        ("Boutique", "hexagon.fill", .orange),
        ("Amélio.", "bolt.circle.fill", .yellow),
        ("Rituel", "flame", Color(red: 0.35, green: 0.05, blue: 0.55)),
        ("Prestige", "star.fill", .yellow),
        ("Banque", "creditcard.fill", Color(red: 0.55, green: 0.85, blue: 0.45))
    ]

    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private func isUnlocked(_ index: Int) -> Bool {
        switch index {
        case 0: return gameManager.isHistoireUnlocked
        case 1: return gameManager.isUsinesUnlocked
        case 2: return gameManager.isInventoryUnlocked
        case 3: return gameManager.isBoutiqueUnlocked
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
                    let accent = Neon.accent(forTab: index)
                    // Icône + libellé toujours affichés : la barre garde une taille constante
                    VStack(spacing: 3) {
                        Image(systemName: unlocked ? tabs[index].icon : "lock.fill")
                            .font(.system(size: 22, weight: selectedTab == index ? .bold : .regular))
                            .scaleEffect(selectedTab == index ? 1.28 : 1.0)
                            .shadow(color: selectedTab == index ? accent.opacity(0.9) : .clear, radius: 6)
                            .overlay(alignment: .topTrailing) {
                                if unlocked && gameManager.hasNotification(forTab: index) {
                                    NotificationDot()
                                        .offset(x: 7, y: -3)
                                }
                            }

                        Text(tr(tabs[index].title))
                            .font(.system(size: 9, weight: selectedTab == index ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        // Point lumineux sous l'onglet actif
                        Circle()
                            .fill(accent)
                            .frame(width: 5, height: 5)
                            .shadow(color: accent, radius: 4)
                            .opacity(selectedTab == index ? 1 : 0)
                    }
                    .foregroundColor(unlocked ? (selectedTab == index ? accent : .white.opacity(0.55)) : .gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                }
                .disabled(!isUnlocked(index))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.black.opacity(0.35)))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Neon.cyan.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}
