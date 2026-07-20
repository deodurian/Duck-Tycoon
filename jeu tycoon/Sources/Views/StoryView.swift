import SwiftUI

struct StoryView: View {
    @Environment(GameManager.self) private var gameManager

    @State private var showingMissions = false

    private let totalChapters = 8

    var body: some View {
        ZStack {
            // Fond transparent : le dégradé global de ContentView reste visible,
            // pour une cohérence de couleur avec la barre du haut et la barre du bas.
            StarFieldView()
                .opacity(0.25)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                header

                if let storyInfo = gameManager.currentStoryInfo {
                    DialogueBubble(dialogue: tr(storyInfo.dialogue))
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity, alignment: .top)

                    QuestCard(storyInfo: storyInfo)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                } else {
                    StoryCompletedView()
                }
            }
        }
        .sheet(isPresented: $showingMissions) {
            MissionSheetView()
                .environment(gameManager)
        }
    }

    // MARK: - En-tête + progression des chapitres

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.blue)
                Text(tr("Histoire & Objectifs"))
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Spacer()

                // Missions (déplacé depuis le menu Usines)
                Button(action: { showingMissions = true }) {
                    HStack(spacing: 4) {
                        Text(tr("🎯"))
                        Text(tr("Missions"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)

            let step = gameManager.currentStoryStep

            HStack(spacing: 6) {
                ForEach(0..<totalChapters, id: \.self) { i in
                    Capsule()
                        .fill(segmentStyle(for: i, currentStep: step))
                        .frame(height: 6)
                        .shadow(color: i == step ? .yellow.opacity(0.6) : .clear, radius: 4)
                }

                Text("\(min(step + 1, totalChapters))/\(totalChapters)")
                    .font(.caption2.bold())
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 2)
            }
            .padding(.horizontal)
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
    @Environment(GameManager.self) private var gameManager
    let dialogue: String

    @State private var visibleCharacters: Int = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar d'Anthony avec anneau lumineux
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [.blue.opacity(0.45), .clear], center: .center, startRadius: 4, endRadius: 32))
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
                    .frame(width: 46, height: 46)
                Text("👨‍🔬")
                    .font(.system(size: 26))
            }
            .frame(width: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(tr("Anthony le scientifique"))
                    .font(.subheadline.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                    )

                // Le texte complet invisible réserve la hauteur : la carte ne "saute" pas
                Text(dialogue)
                    .font(.subheadline)
                    .opacity(0)
                    .overlay(alignment: .topLeading) {
                        Text(String(dialogue.prefix(visibleCharacters)))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.92))
                    }
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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
            // L'effet machine à écrire ne joue qu'à la première découverte du dialogue.
            // Le flag est remis à zéro automatiquement à chaque nouveau chapitre (claimStoryReward).
            if gameManager.storyFlags["dialogueSeen"] == true {
                visibleCharacters = dialogue.count
                return
            }
            gameManager.storyFlags["dialogueSeen"] = true
            gameManager.saveGame()

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

        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: isReady ? "checkmark.seal.fill" : "scope")
                    .font(.title2)
                    .foregroundColor(isReady ? .green : .blue.opacity(0.7))
                    .shadow(color: isReady ? .green.opacity(0.7) : .clear, radius: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tr(storyInfo.quest.title))
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(tr(storyInfo.quest.description))
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isReady ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )

            // Récompense
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                Text(tr("Récompense :") + " " + tr(storyInfo.quest.rewardDescription))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.caption.bold())
            .foregroundColor(.purple)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
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
                    .padding(.vertical, 13)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
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
