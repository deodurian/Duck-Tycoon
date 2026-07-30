import SwiftUI

/// Réacteur Stellaire : allocation des étoiles non dépensées dans 3 emplacements.
/// (UI fonctionnelle — le style néon final arrive en Phase 2.)
struct ReactorView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss

    @State private var showRespecConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                NeonBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        if gameManager.isReactorLocked {
                            cooldownBanner
                        }

                        slotCard(
                            slot: .energy,
                            title: tr("Énergie"),
                            subtitle: tr("+3% revenus (Argent) / étoile"),
                            icon: "bolt.fill",
                            color: .yellow,
                            allocated: gameManager.starsInEnergy,
                            bonusText: "+\((gameManager.starsInEnergy * 3.0).formattedString())%"
                        )

                        slotCard(
                            slot: .mutagen,
                            title: tr("Mutagène"),
                            subtitle: tr("+1% revenus (ADN) / étoile"),
                            icon: "flask.fill",
                            color: .green,
                            allocated: gameManager.starsInMutagen,
                            bonusText: "+\((gameManager.starsInMutagen * 1.0).formattedString())%"
                        )

                        slotCard(
                            slot: .optimization,
                            title: tr("Optimisation"),
                            subtitle: tr("Réduit le coût des usines"),
                            icon: "building.2.fill",
                            color: .cyan,
                            allocated: gameManager.starsInOptimization,
                            bonusText: "-\(String(format: "%.1f", (1.0 - gameManager.factoryCostDiscount) * 100))%"
                        )

                        respecButton
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(tr("Réacteur Stellaire"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }
            .alert(tr("Vider le Réacteur ?"), isPresented: $showRespecConfirm) {
                Button(tr("Annuler"), role: .cancel) {}
                Button(tr("Confirmer"), role: .destructive) { gameManager.respecReactor() }
            } message: {
                Text(tr("Toutes les étoiles seront rendues, mais le Réacteur sera verrouillé 12 h (annulable par gemmes ou pub)."))
            }
        }
    }

    // MARK: - En-tête

    private var header: some View {
        HStack {
            Image(systemName: "star.circle.fill").foregroundColor(.yellow)
            Text("\(gameManager.unspentStars.formattedString())")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundColor(.yellow)
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(tr("étoiles libres")).font(.subheadline).foregroundColor(.yellow.opacity(0.7))
            Spacer()
        }
        .padding()
        .neonPanel(color: Neon.yellow, cornerRadius: 14)
    }

    // MARK: - Bannière de cooldown

    private var cooldownBanner: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
            let remaining = gameManager.reactorCooldownRemaining
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").foregroundColor(.orange)
                    Text(tr("Réacteur verrouillé") + " — " + formatDuration(remaining))
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundColor(.orange)
                }
                HStack(spacing: 10) {
                    Button(action: { gameManager.skipReactorCooldownWithGems() }) {
                        Label("50 💎", systemImage: "diamond.fill")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(gameManager.gems >= GameManager.reactorSkipGemCost ? Color.cyan.opacity(0.25) : Color.gray.opacity(0.2))
                            .foregroundColor(gameManager.gems >= GameManager.reactorSkipGemCost ? .cyan : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(gameManager.gems < GameManager.reactorSkipGemCost)

                    Button(action: { gameManager.skipReactorCooldownWithAd() }) {
                        Label(tr("Pub"), systemImage: "play.rectangle.fill")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.25))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
            .neonPanel(color: Neon.red, cornerRadius: 14)
        }
    }

    // MARK: - Carte d'un emplacement

    private func slotCard(slot: GameManager.ReactorSlot, title: String, subtitle: String, icon: String, color: Color, allocated: BigNumber, bonusText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ReactorCoreIcon(icon: icon, color: color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundColor(.white)
                    Text(subtitle).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(allocated.formattedString()) ⭐️")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundColor(.white)
                    Text(bonusText)
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundColor(color)
                }
            }

            HStack(spacing: 8) {
                allocButton(slot: slot, amount: BigNumber(1.0), label: "+1", color: color)
                allocButton(slot: slot, amount: BigNumber(10.0), label: "+10", color: color)
                allocButton(slot: slot, amount: BigNumber(100.0), label: "+100", color: color)
                allocButton(slot: slot, amount: gameManager.unspentStars, label: tr("Max"), color: color)
            }
        }
        .padding()
        .neonPanel(color: color, cornerRadius: 16)
    }

    private func allocButton(slot: GameManager.ReactorSlot, amount: BigNumber, label: String, color: Color) -> some View {
        let enabled = !gameManager.isReactorLocked && gameManager.unspentStars >= amount && amount > .zero
        return Button(action: { gameManager.allocateToReactor(slot, amount: amount) }) {
            Text(label)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(enabled ? color.opacity(0.2) : Color.gray.opacity(0.15))
                .foregroundColor(enabled ? color : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!enabled)
    }

    // MARK: - Bouton respec

    private var respecButton: some View {
        let disabled = gameManager.isReactorLocked || gameManager.reactorAllocatedStars <= .zero
        return Button(action: { showRespecConfirm = true }) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text(tr("Réinitialiser le Réacteur"))
            }
        }
        .buttonStyle(NeonButtonStyle(color: Neon.red, cornerRadius: 12))
        .opacity(disabled ? 0.5 : 1.0)
        .disabled(disabled)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

/// Noyau du Réacteur : halo pulsant + anneau + icône (aspect cosmique).
private struct ReactorCoreIcon: View {
    let icon: String
    let color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.55), .clear], center: .center, startRadius: 1, endRadius: 24))
                .frame(width: 46, height: 46)
            Circle()
                .stroke(color.opacity(0.6), lineWidth: 1)
                .frame(width: 30, height: 30)
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
        }
        .shadow(color: color.opacity(pulse ? 0.8 : 0.3), radius: pulse ? 9 : 3)
        .scaleEffect(pulse ? 1.06 : 0.98)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
