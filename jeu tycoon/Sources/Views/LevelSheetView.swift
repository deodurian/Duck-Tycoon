import SwiftUI

struct LevelSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showInfo = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.0, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    let currentLevel = gameManager.playerLevel
                    let requiredXP = PlayerLevelSystem.requiredXP(for: currentLevel)
                    let currentXP = gameManager.playerXP
                    let progress = min(1.0, Double(currentXP) / Double(requiredXP))
                    
                    VStack(spacing: 10) {
                        Text("⭐ \(tr("Niveau")) \(currentLevel)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        
                        // Barre de progression
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 30)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(0, geometry.size.width * progress), height: 30)
                            }
                        }
                        .frame(height: 30)
                        .padding(.horizontal)
                        
                        Text("\(currentXP) / \(requiredXP) \(tr("XP"))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Bonus actuels
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tr("Bonus Actuels"))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        let moneyBonusText: String = {
                            let part1 = Double(currentLevel) * 1.0
                            let part2 = Double(currentLevel / 5) * 5.0
                            let part3 = Double(currentLevel / 10) * 25.0
                            let mb = Int(part1 + part2 + part3)
                            
                            let db = currentLevel / 100
                            if db > 0 {
                                let mult = Int(pow(2.0, Double(db)))
                                return "Revenus : +\(mb)% et x\(mult)"
                            } else {
                                return "Revenus : +\(mb)%"
                            }
                        }()
                        
                        let mutationBonusText: String = {
                            let part1 = Double(currentLevel / 5) * 1.0
                            let part2 = Double(currentLevel / 10) * 5.0
                            let mb = Int(part1 + part2)
                            return "Mutation : +\(mb)%"
                        }()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.yellow)
                                Text(moneyBonusText)
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Image(systemName: "flask.fill")
                                    .foregroundColor(.green)
                                Text(mutationBonusText)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        let nextMilestone = ((currentLevel / 10) + 1) * 10
                        
                        Text("\(tr("Prochain Palier (Niveau")) \(nextMilestone))")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.top, 10)
                        
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(tr("+25% Revenus & +5% Mutation"))
                                Text(tr("10 Gemmes"))
                                Text(tr("1 Perk Usine & 1 Perk Canard"))
                                if nextMilestone % 100 == 0 {
                                    Text(tr("Revenus doublés !")).bold().foregroundColor(.yellow)
                                }
                            }
                            .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle(tr("Niveau Joueur"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.cyan)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
            .alert("Comment gagner de l'XP ?", isPresented: $showInfo) {
                Button(tr("Compris"), role: .cancel) { }
            } message: {
                Text(tr("Vous gagnez de l'XP passivement en fonction de l'argent généré par vos usines chaque seconde. L'XP continue d'augmenter même lorsque vous êtes hors ligne. Vous pouvez également gagner de l'XP en accomplissant des missions."))
            }
        }
    }
}
