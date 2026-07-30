import SwiftUI
import Foundation

struct BulkFusionSheet: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRarity: DuckRarity = .commun
    @State private var costInfo: (fusionsCount: Int, totalCost: BigNumber) = (0, .zero)
    @State private var megaCostInfo: (fusionsCount: Int, totalCost: BigNumber) = (0, .zero)
    @State private var isCalculatingBulk = true
    @State private var isCalculatingMega = true
    @State private var showInfo = false
    
    // Animation state
    @State private var animationData: [(rarity: DuckRarity, level: Int)]? = nil
    @State private var animationResultDuck: (rarity: DuckRarity, level: Int)? = nil
    @State private var pendingFusionAction: (() -> Void)? = nil
    
    private func updateBulkCost() {
        isCalculatingBulk = true
        let rarity = selectedRarity
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.gameManager.calculateBulkFusionCost(for: rarity)
            DispatchQueue.main.async {
                self.costInfo = result
                self.isCalculatingBulk = false
            }
        }
    }
    
    private func updateMegaCost() {
        isCalculatingMega = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.gameManager.calculateMegaFusionCost()
            DispatchQueue.main.async {
                self.megaCostInfo = result
                self.isCalculatingMega = false
            }
        }
    }
    

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    Text(tr("Auto-Fusion"))
                        .font(.largeTitle.bold())
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top)
                
                VStack(spacing: 24) {
                    // Selection section
                    VStack(alignment: .leading, spacing: 15) {
                        Text(tr("Rareté cible"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(DuckRarity.allCases, id: \.self) { rarity in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedRarity = rarity
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(rarity.color.opacity(selectedRarity == rarity ? 1.0 : 0.2))
                                                .frame(width: 24, height: 24)
                                            
                                            Image(rarity.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 16, height: 16)
                                                .opacity(selectedRarity == rarity ? 1.0 : 0.7)
                                        }
                                        
                                        Text(tr(rarity.rawValue))
                                            .font(.subheadline)
                                            .fontWeight(selectedRarity == rarity ? .bold : .medium)
                                            .foregroundColor(selectedRarity == rarity ? rarity.color : .primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedRarity == rarity ? rarity.color.opacity(0.15) : Color.white.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedRarity == rarity ? rarity.color : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .neonPanel(color: selectedRarity.color, cornerRadius: 16)
                        .padding(.horizontal)
                        .onChange(of: selectedRarity) { _, _ in
                            updateBulkCost()
                        }
                    }
                    
                    // Result section
                    if isCalculatingBulk {
                        ProgressView()
                            .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 15) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(tr("Fusions possibles"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("\(costInfo.fusionsCount)")
                                        .font(.title2.bold())
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text(tr("Coût de l'opération"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .trailing) {
                                        Text("\(costInfo.totalCost.formattedString()) 💰")
                                            .font(.title2.bold())
                                            .foregroundColor(gameManager.money >= costInfo.totalCost ? .primary : .red)
                                        Text(tr("(Taxe 100%)"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            if costInfo.fusionsCount > 0 {
                                let canBulk = gameManager.money >= costInfo.totalCost
                                Button(action: {
                                    if canBulk {
                                        animationData = Array(repeating: (selectedRarity, 0), count: 12)
                                        animationResultDuck = nil
                                        pendingFusionAction = {
                                            gameManager.executeBulkFusion(for: selectedRarity)
                                            dismiss()
                                        }
                                    }
                                }) {
                                    Text(tr("TOUT FUSIONNER"))
                                }
                                .buttonStyle(NeonButtonStyle(color: selectedRarity.color))
                                .opacity(canBulk ? 1.0 : 0.45)
                                .disabled(!canBulk)
                            }
                        }
                        .padding()
                        .neonPanel(color: selectedRarity.color, cornerRadius: 16)
                        .padding(.horizontal)
                    }

                    // Mega-Fusion section
                    if gameManager.isUnlocked(.megaFusion) {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(tr("Méga-Fusion"))
                                .font(.headline)
                                .foregroundColor(.purple)
                            
                            if isCalculatingMega {
                                ProgressView()
                                    .padding()
                            } else {
                                HStack {
                                    Text("\(megaCostInfo.fusionsCount)\(tr(" fusions estimées"))")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("\(megaCostInfo.totalCost.formattedString()) 💰")
                                            .font(.title2.bold())
                                            .foregroundColor(gameManager.money >= megaCostInfo.totalCost ? .primary : .red)
                                        Text(tr("(Taxe 100%)"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if megaCostInfo.fusionsCount > 0 {
                                    let canMega = gameManager.money >= megaCostInfo.totalCost
                                    Button(action: {
                                        let allRarities = DuckRarity.allCases
                                        animationData = allRarities.flatMap { [$0, $0] }.map { ($0, 0) }
                                        animationResultDuck = nil
                                        pendingFusionAction = {
                                            gameManager.executeMegaFusion()
                                            dismiss()
                                        }
                                    }) {
                                        Text(tr("LANCER MÉGA-FUSION"))
                                    }
                                    .buttonStyle(NeonButtonStyle(color: .purple, cornerRadius: 12))
                                    .opacity(canMega ? 1.0 : 0.45)
                                    .disabled(!canMega)
                                }
                            }
                        }
                        .padding()
                        .neonPanel(color: .purple, cornerRadius: 16)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(NeonBackground(accent: Neon.green))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
            .infoPopup(
                isPresented: $showInfo,
                title: tr("Comment ça marche ?"),
                message: tr("Auto-Fusion : S'applique uniquement à la rareté sélectionnée. Assemble tous les groupes de 3 canards identiques.\n\nMéga-Fusion : Fusionne TOUS les canards de l'inventaire en cascade jusqu'à épuisement des canards ou de l'argent."),
                accent: Neon.green
            )
            .overlay {
                if let data = animationData {
                    FusionAnimationView(ducksToAnimate: data, resultingDuck: animationResultDuck) {
                        animationData = nil
                        animationResultDuck = nil
                        pendingFusionAction?()
                        pendingFusionAction = nil
                    }
                }
            }
            .onAppear {
                updateBulkCost()
                if gameManager.isUnlocked(.megaFusion) {
                    updateMegaCost()
                }
            }
        }
    }
}
