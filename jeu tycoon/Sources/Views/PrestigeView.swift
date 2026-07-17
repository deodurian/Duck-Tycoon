import SwiftUI

enum PrestigeTabType: String, CaseIterable {
    case prestige = "Prestige"
    case arbre = "Arbre Stellaire"
}

struct PrestigeView: View {
    @Environment(GameManager.self) private var gameManager
    @State private var showingPrestigeAlert = false
    @State private var selectedTab: PrestigeTabType = .prestige
    
    // Pour la fenêtre modale d'achat
    @State private var selectedUpgrade: PrestigeUpgrade? = nil
    @State private var showingUpgradeDetails = false
    
    // Animations
    @State private var starPulse = false
    @State private var glowAmount: CGFloat = 0.3
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            // Particules d'étoiles ambiantes
            StarFieldView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // En-tête avec glow
                Text(tr("Le Prestige"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hue: 0.13, saturation: 0.9, brightness: 1.0), Color(hue: 0.08, saturation: 0.85, brightness: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .yellow.opacity(0.5), radius: 10)
                    .padding(.top, 10)
                
                // Sous-onglets stylisés
                HStack(spacing: 0) {
                    ForEach(PrestigeTabType.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(selectedTab == tab ? .black : .yellow.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTab == tab
                                    ? AnyShapeStyle(LinearGradient(colors: [.yellow, Color(hue: 0.12, saturation: 0.8, brightness: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : AnyShapeStyle(Color.white.opacity(0.06))
                                )
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                if selectedTab == .prestige {
                    prestigeContent
                } else {
                    arbreContent
                }
            }
        }
        .alert("Confirmation de Prestige", isPresented: $showingPrestigeAlert) {
            Button(tr("Annuler"), role: .cancel) { }
            Button(tr("Confirmer"), role: .destructive) {
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()
                gameManager.executePrestige()
            }
        } message: {
            Text(tr("Êtes-vous sûr ? Vous allez recommencer à zéro, mais vous conserverez vos étoiles pour de puissants bonus passifs permanents et l'Arbre Stellaire."))
        }
        // Feuille de détails de compétence
        .sheet(item: $selectedUpgrade) { upgrade in
            PrestigeUpgradeDetailSheet(upgrade: upgrade)
                .environment(gameManager)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                starPulse = true
                glowAmount = 0.8
            }
        }
    }
    
    // MARK: - Contenu de l'onglet Prestige classique
    private var prestigeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Étoile animée
                ZStack {
                    // Glow derrière l'étoile
                    Circle()
                        .fill(
                            RadialGradient(colors: [.yellow.opacity(glowAmount), .clear], center: .center, startRadius: 5, endRadius: 80)
                        )
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(hue: 0.13, saturation: 0.9, brightness: 1.0), Color(hue: 0.08, saturation: 0.7, brightness: 0.95)], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .yellow.opacity(0.6), radius: 15)
                        .scaleEffect(starPulse ? 1.08 : 0.95)
                }
                .padding(.top, 5)
                
                if gameManager.hasPrestiged {
                    // Stats d'étoiles
                    HStack(spacing: 20) {
                        statBubble(title: tr("Total"), value: "\(gameManager.totalStars)", icon: "star.fill", color: .gray)
                        statBubble(title: tr("Libres"), value: "\(gameManager.unspentStars)", icon: "star.circle.fill", color: .yellow)
                        statBubble(title: tr("Dépensées"), value: "\(gameManager.spentStars)", icon: "star.slash.fill", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // Carte des bonus passifs
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text(tr("Bonus Passifs"))
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                        
                        VStack(spacing: 0) {
                            bonusRow(icon: "dollarsign.circle.fill", label: tr("Gain d'argent"), value: "+\(formatBonus(10))%", color: .green)
                            Divider().background(Color.white.opacity(0.1))
                            bonusRow(icon: "arrow.triangle.merge", label: tr("Bonus fusion"), value: "+\(formatBonus(5))%", color: .blue)
                            Divider().background(Color.white.opacity(0.1))
                            let discount = 1.0 - gameManager.factoryCostDiscount
                            bonusRow(icon: "building.2.fill", label: tr("Réduction usines"), value: "-\(Int(discount * 100))%", color: .purple)
                            Divider().background(Color.white.opacity(0.1))
                            bonusRow(icon: "DNA", label: tr("Gain mutation"), value: "+\(formatBonus(3))%", color: .cyan)
                            Divider().background(Color.white.opacity(0.1))
                            if gameManager.totalStars >= 100 {
                                bonusRow(icon: "wand.and.stars", label: tr("Mutation spontanée"), value: "+\(formatBonus(0.2))%", color: .mint)
                            } else {
                                bonusRow(icon: "lock.fill", label: tr("Mutation spontanée"), value: "100 ⭐️", color: .red, locked: true)
                            }
                            Divider().background(Color.white.opacity(0.1))
                            if gameManager.totalStars >= 1000 {
                                bonusRow(icon: "flame.fill", label: tr("Gain du Rituel"), value: "+\(formatBonus(2))%", color: .orange)
                            } else {
                                bonusRow(icon: "lock.fill", label: tr("Gain du Rituel"), value: "1000 ⭐️", color: .red, locked: true)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal)
                } else {
                    Text(tr("Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs."))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .font(.body)
                        .padding(.horizontal, 30)
                }
                
                Spacer(minLength: 20)
                
                // Section action Prestige
                if gameManager.money < BigNumber(10_000_000_000) {
                    // Verrouillé
                    VStack(spacing: 14) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text(tr("Atteindre 10B d'argent"))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        let progress = (gameManager.money / BigNumber(10_000_000_000.0)).doubleValue
                        ProgressView(value: min(progress, 1.0))
                            .tint(.yellow)
                            .scaleEffect(y: 1.5)
                            .padding(.horizontal, 30)
                        
                        Text("\(String(format: "%.1f", progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal)
                } else {
                    let potentialStars = gameManager.calculatePrestigeStars()
                    VStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkle")
                                .foregroundColor(.yellow)
                            Text(tr("Prestige Disponible !"))
                                .font(.title3.weight(.bold))
                                .foregroundColor(.yellow)
                            Image(systemName: "sparkle")
                                .foregroundColor(.yellow)
                        }
                        
                        Text("+\(potentialStars.formattedString()) ⭐️")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        Button(action: {
                            showingPrestigeAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                Text(tr("Effectuer un Prestige"))
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.yellow, Color(hue: 0.12, saturation: 0.8, brightness: 1.0)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .yellow.opacity(0.4), radius: 8, y: 4)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.yellow.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Helper Views
    private func statBubble(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }
    
    private func bonusRow(icon: String, label: String, value: String, color: Color, locked: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(locked ? .gray : color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(locked ? .gray : .white)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundColor(locked ? .red.opacity(0.7) : color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Contenu de l'Arbre Stellaire
    private var arbreContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Info étoiles libres
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text("\(gameManager.unspentStars.formattedString())")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundColor(.yellow)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(tr("libres"))
                            .font(.subheadline)
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(tr("Dépensées:"))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(gameManager.spentStars.formattedString())")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                
                // Grouper les améliorations par palier
                let grouped = Dictionary(grouping: PrestigeUpgrade.allUpgrades, by: { $0.tier })
                let sortedTiers = grouped.keys.sorted()
                
                ForEach(sortedTiers, id: \.self) { tier in
                    let upgrades = grouped[tier]!
                    let required = upgrades.first?.requiredSpentStars ?? 0
                    let isUnlocked = gameManager.spentStars >= required
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Titre du palier
                        HStack(spacing: 8) {
                            // Icônes par palier
                            let tierIcon = upgrades.first?.tierIconName ?? "star"
                            Image(systemName: tierIcon)
                                .font(.system(size: 14))
                                .foregroundColor(isUnlocked ? (upgrades.first?.tierColor ?? .gray) : .gray)
                            
                            Text("Palier \(tier)")
                                .font(.headline.weight(.bold))
                                .foregroundColor(isUnlocked ? .white : .gray)
                            
                            // Ligne décorative
                            Rectangle()
                                .fill(
                                    LinearGradient(colors: [isUnlocked ? (upgrades.first?.tierColor ?? .gray).opacity(0.5) : Color.gray.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(height: 1)
                            
                            if !isUnlocked {
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 9))
                                    Text("\(required)")
                                        .font(.caption2.weight(.bold))
                                }
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(upgrades) { upgrade in
                                let isPurchased = gameManager.hasPrestigeUpgrade(upgrade.id)
                                
                                Button(action: {
                                    selectedUpgrade = upgrade
                                }) {
                                    PrestigeUpgradeCard(
                                        upgrade: upgrade,
                                        isPurchased: isPurchased,
                                        isUnlocked: isUnlocked,
                                        tierColor: upgrades.first?.tierColor ?? .gray
                                    )
                                }
                                .disabled(!isUnlocked && !isPurchased)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .padding(.bottom, 60)
        }
    }
    

}

// MARK: - Carte d'amélioration prestige
private struct PrestigeUpgradeCard: View {
    let upgrade: PrestigeUpgrade
    let isPurchased: Bool
    let isUnlocked: Bool
    let tierColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            // Nom
            Text(upgrade.name)
                .font(.caption.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(isPurchased ? .black : (isUnlocked ? .white : .gray.opacity(0.6)))
            
            Spacer(minLength: 0)
            
            // Statut
            if isPurchased {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text(tr("ACQUIS"))
                        .font(.system(size: 10, weight: .heavy))
                }
                .foregroundColor(.black.opacity(0.8))
            } else {
                HStack(spacing: 3) {
                    Text("\(upgrade.cost)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                }
                .foregroundColor(isUnlocked ? .yellow : .gray)
            }
        }
        .padding(10)
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(
            Group {
                if isPurchased {
                    LinearGradient(
                        colors: [tierColor, tierColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else if isUnlocked {
                    Color.white.opacity(0.08)
                } else {
                    Color.white.opacity(0.03)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isPurchased ? tierColor.opacity(0.8) : (isUnlocked ? Color.white.opacity(0.12) : Color.clear),
                    lineWidth: isPurchased ? 2 : 1
                )
        )
        .shadow(color: isPurchased ? tierColor.opacity(0.3) : .clear, radius: 6)
        .opacity(isUnlocked || isPurchased ? 1.0 : 0.5)
    }
}

extension PrestigeView {
    private func formatBonus(_ multiplier: Double) -> String {
        let bnVal = BigNumber.pow(gameManager.totalStars, 0.5) * multiplier
        let val = bnVal.doubleValue
        if bnVal >= BigNumber(1_000_000.0) {
            return bnVal.formattedString()
        } else {
            if val == floor(val) {
                return String(format: "%.0f", val)
            } else {
                return String(format: "%.1f", val)
            }
        }
    }
}
