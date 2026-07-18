import SwiftUI

struct MissionSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss

    // Les quêtes principales (tutoriel) sont remplacées par le Mode Histoire :
    // seules les missions quotidiennes restent visibles ici.
    private var visibleMissions: [Mission] {
        return gameManager.missions.filter { $0.type == .daily }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.0, blue: 0.12).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 15) {
                        HStack {
                            Text(tr("Quotidiennes"))
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                        .padding(.top, 10)
                        ForEach(visibleMissions) { mission in
                            MissionRowView(mission: mission)
                        }
                    }
                    .padding()
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
