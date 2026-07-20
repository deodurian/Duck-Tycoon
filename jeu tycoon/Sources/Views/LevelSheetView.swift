import SwiftUI

struct LevelSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss

    @State private var showInfo = false
    @State private var animateRing = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        let currentLevel = gameManager.playerLevel
                        let requiredXP = PlayerLevelSystem.requiredXP(for: currentLevel)
                        let currentXP = gameManager.playerXP
                        let progress = min(1.0, Double(currentXP) / Double(requiredXP))

                        // Anneau de progression XP
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [.yellow.opacity(0.12), .clear], center: .center, startRadius: 20, endRadius: 110))

                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 14)

                            Circle()
                                .trim(from: 0, to: animateRing ? progress : 0)
                                .stroke(
                                    AngularGradient(colors: [.yellow, .orange, .yellow], center: .center),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .shadow(color: .yellow.opacity(0.5), radius: 6)

                            VStack(spacing: 2) {
                                Text("⭐")
                                    .font(.system(size: 30))
                                Text("\(tr("Niveau")) \(currentLevel)")
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                                Text("\(currentXP.formattedString()) / \(requiredXP.formattedString()) \(tr("XP"))")
                                    .font(.caption.bold())
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .frame(width: 190, height: 190)
                        .padding(.top, 16)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
                                animateRing = true
                            }
                        }

                        // Bonus actuels
                        let moneyBonusText: String = {
                            let part1 = Double(currentLevel) * 1.0
                            let part2 = Double(currentLevel / 5) * 5.0
                            let part3 = Double(currentLevel / 10) * 25.0
                            let mb = Int(part1 + part2 + part3)

                            let db = currentLevel / 100
                            if db > 0 {
                                let mult = Int(pow(2.0, Double(db)))
                                return "+\(mb)% et x\(mult)"
                            } else {
                                return "+\(mb)%"
                            }
                        }()

                        let mutationBonusText: String = {
                            let part1 = Double(currentLevel / 5) * 1.0
                            let part2 = Double(currentLevel / 10) * 5.0
                            let mb = Int(part1 + part2)
                            return "+\(mb)%"
                        }()

                        HStack(spacing: 12) {
                            StatBonusCard(icon: "dollarsign.circle.fill", color: .yellow, title: tr("Revenus"), value: moneyBonusText)
                            StatBonusCard(icon: "flask.fill", color: .green, title: tr("Mutation"), value: mutationBonusText)
                        }
                        .padding(.horizontal)

                        // Prochain palier
                        let nextMilestone = ((currentLevel / 10) + 1) * 10

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.orange)
                                Text("\(tr("Prochain Palier (Niveau")) \(nextMilestone))")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                MilestoneRewardRow(icon: "chart.line.uptrend.xyaxis", color: .yellow, text: tr("+25% Revenus & +5% Mutation"))
                                MilestoneRewardRow(icon: "diamond.fill", color: .cyan, text: tr("10 Gemmes"))
                                MilestoneRewardRow(icon: "star.fill", color: .purple, text: tr("1 Perk Usine & 1 Perk Canard"))
                                if nextMilestone % 100 == 0 {
                                    MilestoneRewardRow(icon: "flame.fill", color: .red, text: tr("Revenus doublés !"), highlight: true)
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.orange.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(colors: [.orange.opacity(0.5), .orange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
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
            .alert(tr("Comment gagner de l'XP ?"), isPresented: $showInfo) {
                Button(tr("Compris"), role: .cancel) { }
            } message: {
                Text(tr("Vous gagnez de l'XP passivement en fonction de l'argent généré par vos usines chaque seconde. L'XP continue d'augmenter même lorsque vous êtes hors ligne. Vous pouvez également gagner de l'XP en accomplissant des missions."))
            }
        }
    }
}

// MARK: - Composants

private struct StatBonusCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [color.opacity(0.3), color.opacity(0.08)], center: .center, startRadius: 2, endRadius: 22))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.55))

            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct MilestoneRewardRow: View {
    let icon: String
    let color: Color
    let text: String
    var highlight: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 22, height: 22)
                .background(Circle().fill(color.opacity(0.15)))

            Text(text)
                .font(highlight ? .subheadline.bold() : .subheadline)
                .foregroundColor(highlight ? .yellow : .white.opacity(0.9))

            Spacer(minLength: 0)
        }
    }
}
