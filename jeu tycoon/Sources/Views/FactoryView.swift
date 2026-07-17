import SwiftUI

struct FactoryView: View {
    @Environment(GameManager.self) private var gameManager
    
    @State private var showingLevelSheet = false
    @State private var showingQuestSheet = false
    @State private var showingPerkSheet = false
    
    let columns = [
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ScrollView {
            // Header
            VStack(spacing: 6) {
                // Barre d'actions (Niveau, Missions, Perks)
                HStack(spacing: 12) {
                    Button(action: { showingLevelSheet = true }) {
                        HStack {
                            Text(tr("⭐"))
                            Text("\(tr("Niv.")) \(gameManager.playerLevel)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.yellow)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showingQuestSheet = true }) {
                        HStack {
                            Text(tr("🎯"))
                            Text(tr("Missions"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showingPerkSheet = true }) {
                        HStack {
                            Text(tr("🎒"))
                            Text(tr("Perks"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("Usines"))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.white, .white.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            )
                        
                        let activeCount = gameManager.factories.filter { !$0.assignedDuckIds.isEmpty }.count
                        Text("\(activeCount) \(tr(activeCount > 1 ? "usines actives" : "usine active"))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Total production badge
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("\((gameManager.cachedEarningsPerSecond ?? .zero).formattedString())/s")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.yellow.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.25), lineWidth: 1))
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(gameManager.factories) { factory in
                    FactoryRow(factory: factory)
                }
                
                // Bouton Ajouter Usine
                let canAfford = gameManager.money >= gameManager.newFactoryCost
                Button(action: {
                    gameManager.buyNewFactory()
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            canAfford ? Color.cyan.opacity(0.2) : Color.gray.opacity(0.1),
                                            .clear
                                        ],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 40
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(
                                    canAfford
                                    ? LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                )
                                .shadow(color: canAfford ? .cyan.opacity(0.4) : .clear, radius: 8)
                        }
                        
                        VStack(spacing: 3) {
                            Text(tr("Nouvelle Usine"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(canAfford ? .white : .gray)
                            
                            Text("\(gameManager.newFactoryCost.formattedString()) 💰")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(canAfford ? .cyan : .gray.opacity(0.6))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [10, 6]))
                            .foregroundColor(canAfford ? .cyan.opacity(0.4) : .gray.opacity(0.2))
                    )
                }
                .disabled(!canAfford)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .background(Color.clear)
        .sheet(isPresented: $showingLevelSheet) {
            LevelSheetView()
                .environment(gameManager)
        }
        .sheet(isPresented: $showingQuestSheet) {
            MissionSheetView()
                .environment(gameManager)
        }
        .sheet(isPresented: $showingPerkSheet) {
            PerkSheetView()
                .environment(gameManager)
        }
    }
}

