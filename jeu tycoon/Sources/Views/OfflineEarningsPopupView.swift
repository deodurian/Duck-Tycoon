import SwiftUI

struct OfflineEarningsPopupView: View {
    @Environment(GameManager.self) private var gameManager
    @ObservedObject private var adManager = AdManager.shared

    @State private var showCard = false
    @State private var showRows = false
    @State private var showButtons = false
    @State private var iconPulse = false

    var body: some View {
        if let earnings = gameManager.pendingOfflineEarnings {
            ZStack {
                // Fond assombri avec une teinte violette proche de l'écran titre
                RadialGradient(
                    colors: [Color(red: 0.10, green: 0.02, blue: 0.22).opacity(0.9), Color.black.opacity(0.92)],
                    center: .center, startRadius: 60, endRadius: 500
                )
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .highPriorityGesture(DragGesture(minimumDistance: 0))

                VStack(spacing: 22) {
                    // Icône lune avec halo
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(colors: [Color.indigo.opacity(0.55), .clear],
                                               center: .center, startRadius: 5, endRadius: 70)
                            )
                            .frame(width: 130, height: 130)
                            .scaleEffect(iconPulse ? 1.1 : 0.95)

                        Circle()
                            .fill(
                                LinearGradient(colors: [Color(red: 0.35, green: 0.25, blue: 0.75), Color(red: 0.15, green: 0.08, blue: 0.35)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 74, height: 74)
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: .orange.opacity(0.8), radius: 8)
                    }
                    .frame(height: 100)

                    VStack(spacing: 10) {
                        Text(tr("De Retour !"))
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                            .shadow(color: .orange.opacity(0.8), radius: 5, x: 0, y: 2)

                        // Durée d'absence en petite capsule
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("\(tr("Absent pendant")) \(formatTime(earnings.seconds))")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }

                    // Récompenses
                    VStack(spacing: 12) {
                        rewardRow(emoji: "💰", label: tr("Argent"), value: earnings.money.formattedString(), color: .green, index: 0)
                        if earnings.dna > .zero {
                            rewardRow(emoji: "🧬", label: tr("ADN"), value: earnings.dna.formattedString(), color: .purple, index: 1)
                        }
                        if earnings.xp > 0 {
                            rewardRow(emoji: "⭐", label: tr("Expérience"), value: "\(earnings.xp)\(tr(" XP"))", color: .yellow, index: 2)
                        }
                    }
                    .padding(.horizontal)

                    // Boutons
                    VStack(spacing: 12) {
                        if adManager.isReady {
                            Button(action: {
                                AdManager.shared.showRewardedAd(for: .offlineBoost) { earned in
                                    if earned {
                                        DispatchQueue.main.async {
                                            withAnimation {
                                                gameManager.claimOfflineEarnings(multiplier: 2.0)
                                            }
                                        }
                                    }
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.tv.fill")
                                        .font(.headline)
                                    Text(tr("Récupérer X2"))
                                        .font(.headline.bold())
                                    Image(systemName: "sparkles")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: .orange.opacity(iconPulse ? 0.7 : 0.35), radius: iconPulse ? 12 : 6)
                            }
                        } else {
                            HStack {
                                Text(tr("Chargement de la pub..."))
                                    .font(.headline.bold())
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button(action: {
                            withAnimation {
                                gameManager.claimOfflineEarnings(multiplier: 1.0)
                            }
                        }) {
                            Text(tr("Récupérer"))
                                .font(.subheadline.bold())
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.06))
                                .foregroundColor(.white.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 15)
                }
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.11, green: 0.05, blue: 0.22), Color(red: 0.05, green: 0.0, blue: 0.12)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                .padding(24)
                .shadow(color: Color.purple.opacity(0.35), radius: 30)
                .scaleEffect(showCard ? 1.0 : 0.85)
                .opacity(showCard ? 1.0 : 0.0)
            }
            .transition(.scale.combined(with: .opacity))
            .zIndex(100)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    showCard = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
                    showRows = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
                    showButtons = true
                }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    iconPulse = true
                }
            }
        }
    }

    @ViewBuilder
    private func rewardRow(emoji: String, label: String, value: String, color: Color, index: Int) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(color.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [color.opacity(0.12), color.opacity(0.04)],
                                   startPoint: .leading, endPoint: .trailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .opacity(showRows ? 1 : 0)
        .offset(x: showRows ? 0 : -25)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.08), value: showRows)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(max(1, minutes)) minutes"
        }
    }
}
