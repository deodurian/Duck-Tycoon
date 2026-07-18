import SwiftUI

struct StoryView: View {
    @Environment(GameManager.self) private var gameManager

    private let totalChapters = 7

    var body: some View {
        ZStack {
            // Fond : dégradé profond + étoiles subtiles
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.05, blue: 0.18),
                    Color(red: 0.02, green: 0.02, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            StarFieldView()
                .opacity(0.3)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 16) {
                header

                if let storyInfo = gameManager.currentStoryInfo {
                    // Dialogue (scrollable car certains textes sont longs)
                    ScrollView(showsIndicators: false) {
                        DialogueBubble(dialogue: tr(storyInfo.dialogue))
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }

                    QuestCard(storyInfo: storyInfo)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                } else {
                    StoryCompletedView()
                }
            }
        }
    }

    // MARK: - En-tête + progression des chapitres

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.blue)
                Text(tr("Histoire & Objectifs"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            let step = gameManager.currentStoryStep

            HStack(spacing: 6) {
                ForEach(0..<totalChapters, id: \.self) { i in
                    Capsule()
                        .fill(segmentStyle(for: i, currentStep: step))
                        .frame(height: 6)
                        .shadow(color: i == step ? .yellow.opacity(0.6) : .clear, radius: 4)
                }
            }
            .padding(.horizontal, 30)

            Text(tr("Chapitre") + " \(min(step + 1, totalChapters))/\(totalChapters)")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private func segmentStyle(for index: Int, currentStep: Int) -> AnyShapeStyle {
        if index < currentStep {
            // Chapitre terminé
            return AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
        } else if index == currentStep {
            // Chapitre en cours
            return AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
        } else {
            // Chapitre à venir
            return AnyShapeStyle(Color.white.opacity(0.12))
        }
    }
}

// MARK: - Bulle de dialogue avec effet machine à écrire

private struct DialogueBubble: View {
    let dialogue: String

    @State private var visibleCharacters: Int = 0

    private var isFullyRevealed: Bool {
        visibleCharacters >= dialogue.count
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Avatar d'Anthony avec anneau lumineux
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [.blue.opacity(0.45), .clear], center: .center, startRadius: 5, endRadius: 40))
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
                    .frame(width: 58, height: 58)
                Text("👨‍🔬")
                    .font(.system(size: 34))
            }
            .frame(width: 66)

            VStack(alignment: .leading, spacing: 6) {
                Text(tr("Anthony le scientifique"))
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                    )

                // Le texte complet invisible réserve la hauteur : la carte ne "saute" pas
                Text(dialogue)
                    .font(.body)
                    .opacity(0)
                    .overlay(alignment: .topLeading) {
                        Text(String(dialogue.prefix(visibleCharacters)))
                            .font(.body)
                            .foregroundColor(.white.opacity(0.92))
                    }
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.blue.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(colors: [.blue.opacity(0.5), .purple.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap : révéler tout le texte immédiatement
            visibleCharacters = dialogue.count
        }
        .task(id: dialogue) {
            // Effet machine à écrire, relancé à chaque nouveau dialogue
            visibleCharacters = 0
            while visibleCharacters < dialogue.count {
                try? await Task.sleep(nanoseconds: 14_000_000)
                if Task.isCancelled { return }
                visibleCharacters = min(visibleCharacters + 2, dialogue.count)
            }
        }
    }
}

// MARK: - Carte de l'objectif actuel

private struct QuestCard: View {
    @Environment(GameManager.self) private var gameManager
    let storyInfo: StoryStepInfo

    @State private var pulse = false

    var body: some View {
        let isReady = gameManager.isStoryQuestReadyToClaim

        VStack(spacing: 14) {
            Text(tr("Objectif Actuel"))
                .font(.caption.bold())
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.45))

            HStack(spacing: 12) {
                Image(systemName: isReady ? "checkmark.seal.fill" : "scope")
                    .font(.title)
                    .foregroundColor(isReady ? .green : .blue.opacity(0.7))
                    .shadow(color: isReady ? .green.opacity(0.7) : .clear, radius: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tr(storyInfo.quest.title))
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text(tr(storyInfo.quest.description))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isReady ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )

            // Récompense
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                Text(tr("Récompense :") + " " + tr(storyInfo.quest.rewardDescription))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline.bold())
            .foregroundColor(.purple)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(Capsule().fill(Color.purple.opacity(0.15)))
            .overlay(Capsule().stroke(Color.purple.opacity(0.35), lineWidth: 1))

            // Bouton Réclamer
            Button(action: {
                withAnimation(.spring) {
                    gameManager.claimStoryReward()
                }
            }) {
                Text(isReady ? tr("Récupérer la récompense") : tr("Quête en cours..."))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Group {
                            if isReady {
                                LinearGradient(colors: [.green, Color(hue: 0.38, saturation: 0.9, brightness: 0.6)], startPoint: .top, endPoint: .bottom)
                            } else {
                                Color.gray.opacity(0.35)
                            }
                        }
                    )
                    .cornerRadius(12)
                    .shadow(color: isReady ? Color.green.opacity(pulse ? 0.7 : 0.25) : .clear, radius: pulse ? 14 : 8, y: 4)
                    .scaleEffect(isReady && pulse ? 1.02 : 1.0)
            }
            .disabled(!isReady)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Histoire terminée

private struct StoryCompletedView: View {
    @State private var glow = false

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [.yellow.opacity(glow ? 0.5 : 0.2), .clear], center: .center, startRadius: 5, endRadius: 90))
                        .frame(width: 180, height: 180)
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .yellow.opacity(glow ? 0.8 : 0.3), radius: glow ? 20 : 8)
                }

                Text(tr("Histoire Terminée !"))
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                    )

                Text(tr("Tu as terminé toutes les quêtes d'histoire. Le mode libre est activé !"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}
