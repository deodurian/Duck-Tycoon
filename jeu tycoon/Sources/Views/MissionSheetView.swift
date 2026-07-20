import SwiftUI

struct MissionSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab = 0

    // Les quêtes principales (tutoriel) sont remplacées par le Mode Histoire :
    // ici, missions quotidiennes + quêtes secondaires.
    private var visibleMissions: [Mission] {
        return gameManager.missions.filter { $0.type == .daily }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.0, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Sélecteur d'onglets
                    HStack(spacing: 8) {
                        MissionTabButton(
                            icon: "calendar",
                            title: tr("Quotidiennes"),
                            color: .blue,
                            isSelected: selectedTab == 0,
                            isLocked: false
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 0 }
                        }

                        MissionTabButton(
                            icon: "list.star",
                            title: tr("Secondaires"),
                            color: .purple,
                            isSelected: selectedTab == 1,
                            isLocked: !gameManager.isSideQuestsUnlocked
                        ) {
                            if gameManager.isSideQuestsUnlocked {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 1 }
                            }
                        }
                    }
                    .padding()

                    ScrollView {
                        if selectedTab == 0 {
                            VStack(spacing: 15) {
                                ForEach(visibleMissions) { mission in
                                    MissionRowView(mission: mission)
                                }
                            }
                            .padding()
                        } else {
                            SideQuestListView()
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle(tr("Missions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("Fermer")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Onglet du sélecteur de missions

private struct MissionTabButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isLocked ? "lock.fill" : icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isLocked ? .gray.opacity(0.5) : (isSelected ? color : .gray))
        }
    }
}

// MARK: - Liste des Quêtes Secondaires

private struct SideQuestListView: View {
    @Environment(GameManager.self) private var gameManager

    var body: some View {
        let available = SideQuest.all.filter { !gameManager.isSideQuestClaimed($0) && gameManager.isSideQuestAvailable($0) }
        let locked = SideQuest.all.filter { !gameManager.isSideQuestClaimed($0) && !gameManager.isSideQuestAvailable($0) }
        let claimed = SideQuest.all.filter { gameManager.isSideQuestClaimed($0) }

        VStack(alignment: .leading, spacing: 15) {
            if !available.isEmpty {
                SideQuestSectionHeader(icon: "scope", title: tr("En cours"), color: .purple)
                ForEach(available) { quest in
                    SideQuestRow(quest: quest, state: .available)
                }
            }

            if !locked.isEmpty {
                SideQuestSectionHeader(icon: "lock.fill", title: tr("Verrouillées"), color: .gray)
                ForEach(locked) { quest in
                    SideQuestRow(quest: quest, state: .locked)
                }
            }

            if !claimed.isEmpty {
                SideQuestSectionHeader(icon: "checkmark.seal.fill", title: tr("Terminées"), color: .green)
                ForEach(claimed) { quest in
                    SideQuestRow(quest: quest, state: .claimed)
                }
            }
        }
    }
}

private struct SideQuestSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
    }
}

private struct SideQuestRow: View {
    enum QuestState { case available, locked, claimed }

    @Environment(GameManager.self) private var gameManager
    let quest: SideQuest
    let state: QuestState

    private var rewardDef: UpgradeDefinition? {
        UpgradeDefinition.all.first(where: { $0.id == quest.rewardId })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tr(quest.title))
                    .font(.headline)
                    .foregroundColor(state == .locked ? .gray : .white)

                Spacer()

                if state == .claimed {
                    Text(tr("Terminé"))
                        .font(.caption)
                        .foregroundColor(.green)
                } else if state == .available {
                    let canClaim = gameManager.canClaimSideQuest(quest)
                    if canClaim {
                        Button(action: {
                            withAnimation(.spring) {
                                gameManager.claimSideQuest(quest)
                            }
                        }) {
                            Text(tr("Réclamer"))
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else if quest.requirements.count == 1 {
                        let req = quest.requirements[0]
                        let value = gameManager.sideQuestValue(for: req.metric)
                        Text("\(Int(value).formattedString()) \(tr("/")) \(Int(req.target).formattedString())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            if state == .locked {
                let prereqTitle = SideQuest.all.first(where: { $0.id == quest.prerequisiteQuestId })?.title ?? ""
                Text("\(tr("Requiert :")) \(tr(prereqTitle))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text(tr(quest.description))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(state == .claimed ? 0.5 : 0.8))
                
                if state == .available && quest.requirements.count > 1 {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(0..<quest.requirements.count, id: \.self) { i in
                            let req = quest.requirements[i]
                            let value = gameManager.sideQuestValue(for: req.metric)
                            HStack {
                                Text(metricLabel(req.metric))
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(value).formattedString()) / \(Int(req.target).formattedString())")
                                    .font(.caption)
                            }
                            .foregroundColor(value >= req.target ? .green : .gray)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            // Récompense
            if let def = rewardDef {
                HStack(spacing: 5) {
                    Image(systemName: state == .claimed ? "checkmark.seal.fill" : "gift.fill")
                        .font(.system(size: 10))
                    Text("\(tr("Récompense :")) \(tr(def.name))")
                        .font(.caption.bold())
                }
                .foregroundColor(state == .claimed ? .green : .purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill((state == .claimed ? Color.green : Color.purple).opacity(0.12)))
            }

            // Barre de progression
            if state == .available {
                GeometryReader { geo in
                    let fraction = gameManager.sideQuestProgress(quest)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(fraction))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color.white.opacity(state == .locked ? 0.03 : 0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(state == .claimed ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(state == .locked ? 0.7 : 1.0)
    }
    
    private func metricLabel(_ metric: SideQuestMetric) -> String {
        switch metric {
        case .ducksFromCrates: return tr("Caisses")
        case .ducksRecycled: return tr("Recyclés")
        case .fusionsDone: return tr("Fusions")
        case .inventoryCount: return tr("Canards")
        case .playerLevel: return tr("Niveau")
        case .earningsPerSecond: return tr("Revenus/s")
        case .mutationPointsEarned: return tr("ADN Obtenu")
        }
    }
}

struct MissionRowView: View {
    @Environment(GameManager.self) private var gameManager
    let mission: Mission
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tr(mission.title))
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if mission.status == .completed {
                    Button(action: {
                        gameManager.claimMission(id: mission.id)
                    }) {
                        Text(tr("Réclamer"))
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else if mission.status == .claimed {
                    Text(tr("Terminé"))
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    HStack(spacing: 2) {
                        Text(mission.currentProgress.formattedString())
                        Text(tr("/"))
                        Text(mission.targetProgress.formattedString())
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            
            Text(tr(mission.description))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            if mission.status != .claimed {
                GeometryReader { geo in
                    let progressDouble = mission.currentProgress.doubleValue
                    let targetDouble = max(1.0, mission.targetProgress.doubleValue)
                    let fraction = min(1.0, progressDouble / targetDouble)
                    let barWidth = geo.size.width * CGFloat(fraction)
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: barWidth)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
