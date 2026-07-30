import Foundation
import SwiftUI

// MARK: - Identité visuelle du menu Missions
//
// Parti pris : un « tableau de bord d'objectifs ». En haut un récapitulatif chiffré
// (anneau de progression + récompenses en attente + décompte avant reset), au centre un
// sélecteur à indicateur glissant, en dessous des lignes qui hurlent leur état :
//   • en cours   → jauge néon animée avec valeur chiffrée et pourcentage,
//   • réclamable → halo doré qui respire + gros bouton or plein largeur,
//   • terminée   → carte éteinte + tampon « TERMINÉ ».
// La réclamation est LE moment du menu : flash, onde de choc, confettis, haptique de
// réussite et récompense qui s'envole avant que la ligne ne bascule en « terminé ».

private enum MissionStyle {
    /// Bleu des missions quotidiennes.
    static let daily = Color(hex: 0x3D9BFF)
    /// Violet des quêtes secondaires.
    static let quest = Neon.purple
    /// Or : réservé à ce qui est réclamable MAINTENANT.
    static let gold = Color(hex: 0xFFB01F)
    /// Gris éteint des objectifs déjà encaissés.
    static let done = Color(hex: 0x7B86A6)
}

/// Haptique d'échec (onglet verrouillé) : `NeonHaptics` n'expose que impact/tick/success.
private enum MissionHaptics {
    private static let notifier: UINotificationFeedbackGenerator = {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        return g
    }()

    static func refused() {
        notifier.notificationOccurred(.error)
        notifier.prepare()
    }
}

/// Secousse horizontale amortie (onglet verrouillé). `travel` s'incrémente de 1 par secousse.
private struct MissionShake: GeometryEffect {
    var travel: CGFloat

    var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        // Amortissement : la secousse s'éteint sur la fin du cycle.
        let local = travel.truncatingRemainder(dividingBy: 1)
        let damping = 1 - local
        let dx = sin(local * .pi * 6) * 8 * damping
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}

private extension View {
    /// Entrée en scène échelonnée d'une ligne de liste.
    func missionEntrance(appeared: Bool, index: Int) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 26)
            .scaleEffect(appeared ? 1 : 0.96, anchor: .top)
            .animation(
                .spring(response: 0.52, dampingFraction: 0.85)
                    .delay(min(Double(index) * 0.055, 0.55)),
                value: appeared
            )
    }
}

// MARK: - Feuille principale

struct MissionSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab = 0
    /// Secousse de l'onglet verrouillé (incrémentée à chaque tap refusé).
    @State private var lockShake: CGFloat = 0
    @Namespace private var tabNamespace

    private var accent: Color {
        selectedTab == 0 ? MissionStyle.daily : MissionStyle.quest
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NeonBackground(accent: accent)

                VStack(spacing: 0) {
                    summary
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                    tabBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    if !gameManager.isSideQuestsUnlocked {
                        lockHint
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }

                    listArea
                }
            }
            .navigationTitle(tr("Missions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                            Text(tr("Fermer"))
                        }
                    }
                    .buttonStyle(NeonButtonStyle(color: Neon.cyan, cornerRadius: 12, fullWidth: false, compact: true))
                }
            }
        }
    }

    // MARK: En-tête récapitulatif

    @ViewBuilder
    private var summary: some View {
        if selectedTab == 0 {
            MissionDailySummary()
        } else {
            MissionQuestSummary()
        }
    }

    // MARK: Sélecteur d'onglets

    private var tabBar: some View {
        HStack(spacing: 10) {
            MissionTabButton(
                icon: "calendar",
                title: tr("Quotidiennes"),
                color: MissionStyle.daily,
                isSelected: selectedTab == 0,
                isLocked: false,
                badge: .daily,
                namespace: tabNamespace
            ) {
                guard selectedTab != 0 else { return }
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { selectedTab = 0 }
            }

            MissionTabButton(
                icon: "list.star",
                title: tr("Secondaires"),
                color: MissionStyle.quest,
                isSelected: selectedTab == 1,
                isLocked: !gameManager.isSideQuestsUnlocked,
                badge: .sideQuests,
                namespace: tabNamespace
            ) {
                if gameManager.isSideQuestsUnlocked {
                    guard selectedTab != 1 else { return }
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { selectedTab = 1 }
                } else {
                    // Avant : le tap ne produisait rien. Maintenant ça refuse franchement.
                    MissionHaptics.refused()
                    withAnimation(.easeOut(duration: 0.45)) { lockShake += 1 }
                }
            }
            .modifier(MissionShake(travel: lockShake))
        }
    }

    private var lockHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
            Text(tr("Les quêtes secondaires se débloquent en avançant dans l'Histoire."))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.45))
        .modifier(MissionShake(travel: lockShake))
    }

    // MARK: Listes

    private var listArea: some View {
        ScrollView {
            Group {
                if selectedTab == 0 {
                    MissionDailyList()
                } else {
                    SideQuestListView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Récapitulatif « Missions du jour »

/// Vue feuille : elle seule lit `gameManager.missions`, la liste n'est donc pas
/// reconstruite quand un simple compteur de mission bouge.
private struct MissionDailySummary: View {
    @Environment(GameManager.self) private var gameManager
    @State private var glow = false

    var body: some View {
        let dailies = gameManager.missions.filter { $0.type == .daily }
        let total = max(dailies.count, 1)
        let claimable = dailies.reduce(0) { $0 + ($1.status == .completed ? 1 : 0) }
        let done = dailies.reduce(0) { $0 + (($1.status == .completed || $1.status == .claimed) ? 1 : 0) }
        let allClaimed = dailies.allSatisfy { $0.status == .claimed } && !dailies.isEmpty
        let color: Color = claimable > 0 ? MissionStyle.gold : (allClaimed ? Neon.green : MissionStyle.daily)

        HStack(spacing: 14) {
            MissionSummaryRing(fraction: Double(done) / Double(total), color: color) {
                VStack(spacing: -2) {
                    Text("\(done)")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("/ \(dailies.count)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text(tr("Missions du jour").uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.45))

                Text(subtitle(claimable: claimable, allClaimed: allClaimed))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(claimable > 0 ? 0.7 : 0), radius: 8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            MissionResetCountdown()
        }
        .padding(14)
        .neonPanel(color: color, cornerRadius: 22)
        .shadow(color: color.opacity(claimable > 0 && glow ? 0.45 : 0.12), radius: claimable > 0 && glow ? 20 : 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    private func subtitle(claimable: Int, allClaimed: Bool) -> String {
        if claimable > 0 {
            let noun = claimable > 1 ? tr("récompenses à réclamer") : tr("récompense à réclamer")
            return "\(claimable) \(noun)"
        }
        if allClaimed { return tr("Tout est réclamé, revenez demain !") }
        return tr("Objectifs du jour en cours")
    }
}

// MARK: - Récapitulatif « Quêtes secondaires »

private struct MissionQuestSummary: View {
    @Environment(GameManager.self) private var gameManager

    var body: some View {
        // Volontairement métrique-free : seul `claimedSideQuestIds` est lu ici.
        let total = max(SideQuest.all.count, 1)
        let claimed = SideQuest.all.reduce(0) { $0 + (gameManager.isSideQuestClaimed($1) ? 1 : 0) }

        HStack(spacing: 14) {
            MissionSummaryRing(fraction: Double(claimed) / Double(total), color: MissionStyle.quest) {
                VStack(spacing: -2) {
                    Text("\(claimed)")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("/ \(SideQuest.all.count)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text(tr("Quêtes secondaires").uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.45))

                // Feuille isolée : c'est elle qui lit les statistiques du joueur.
                MissionQuestReadyLine()
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .neonPanel(color: MissionStyle.quest, cornerRadius: 22)
    }
}

/// Ligne « N prêtes à réclamer » — isolée car elle lit des statistiques qui bougent chaque tick.
private struct MissionQuestReadyLine: View {
    @Environment(GameManager.self) private var gameManager

    var body: some View {
        let ready = SideQuest.all.reduce(0) { $0 + (gameManager.canClaimSideQuest($1) ? 1 : 0) }
        let color: Color = ready > 0 ? MissionStyle.gold : MissionStyle.quest

        Text(label(ready: ready))
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .shadow(color: color.opacity(ready > 0 ? 0.7 : 0), radius: 8)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func label(ready: Int) -> String {
        if ready > 0 {
            let noun = ready > 1 ? tr("prêtes à réclamer") : tr("prête à réclamer")
            return "\(ready) \(noun)"
        }
        return tr("Aucune récompense en attente")
    }
}

// MARK: - Anneau de progression

private struct MissionSummaryRing<Content: View>: View {
    var fraction: Double
    var color: Color
    @ViewBuilder var content: () -> Content

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.09), lineWidth: 7)

            Circle()
                .trim(from: 0, to: max(0.001, clamped))
                .stroke(
                    AngularGradient(colors: [color.opacity(0.35), color, .white], center: .center),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.75), radius: 7)

            content()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: clamped)
    }
}

// MARK: - Décompte avant réinitialisation quotidienne

/// `GameManager.checkDailyMissionsReset()` mémorise la date du dernier reset dans
/// UserDefaults et reprogramme le suivant 24 h plus tard : on la relit ici en LECTURE
/// SEULE pour afficher le décompte. Rien n'est écrit.
private struct MissionResetCountdown: View {
    private static let storageKey = "lastDailyMissionReset"
    private static let day: Double = 86_400

    var body: some View {
        let last = UserDefaults.standard.double(forKey: Self.storageKey)
        if last > 0 {
            let target = Date(timeIntervalSince1970: last + Self.day)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                capsule(remaining: target.timeIntervalSince(context.date))
            }
        }
    }

    private func capsule(remaining: TimeInterval) -> some View {
        VStack(spacing: 1) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 10, weight: .bold))
            Text(text(for: remaining))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private func text(for remaining: TimeInterval) -> String {
        guard remaining > 0 else { return tr("Bientôt") }
        let total = Int(remaining)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 { return String(format: "%dh%02d", hours, minutes) }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Onglet du sélecteur de missions

private enum MissionBadgeKind { case daily, sideQuests }

private struct MissionTabButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let isLocked: Bool
    let badge: MissionBadgeKind
    let namespace: Namespace.ID
    let action: () -> Void

    private var tint: Color {
        if isLocked { return .white.opacity(0.28) }
        return isSelected ? color : .white.opacity(0.45)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: isLocked ? "lock.fill" : icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(tint)
            .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 6)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background {
                if isSelected {
                    // Indicateur qui glisse d'un onglet à l'autre.
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(color.opacity(0.18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(color.opacity(0.8), lineWidth: 1.2)
                        }
                        .shadow(color: color.opacity(0.5), radius: 10)
                        .matchedGeometryEffect(id: "missionTabIndicator", in: namespace)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.045))
            }
            .overlay(alignment: .topTrailing) {
                MissionTabBadge(kind: badge)
                    .offset(x: 5, y: -7)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .bouncy(scale: 0.96)
    }
}

/// Pastille du nombre de récompenses en attente. Vue feuille : elle lit les données du
/// joueur pour son compte, sans invalider le sélecteur ni la liste.
private struct MissionTabBadge: View {
    @Environment(GameManager.self) private var gameManager
    let kind: MissionBadgeKind
    @State private var pulse = false

    private var count: Int {
        switch kind {
        case .daily:
            return gameManager.missions.reduce(0) { $0 + (($1.type == .daily && $1.status == .completed) ? 1 : 0) }
        case .sideQuests:
            return SideQuest.all.reduce(0) { $0 + (gameManager.canClaimSideQuest($1) ? 1 : 0) }
        }
    }

    var body: some View {
        let value = count
        if value > 0 {
            Text("\(value)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(hex: 0x3F1D00))
                .frame(minWidth: 19, minHeight: 19)
                .background(Circle().fill(MissionStyle.gold))
                .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1))
                .shadow(color: MissionStyle.gold.opacity(0.9), radius: pulse ? 9 : 3)
                .scaleEffect(pulse ? 1.1 : 0.94)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
                }
        }
    }
}

// MARK: - Liste des missions quotidiennes

/// Vue feuille propriétaire de `gameManager.missions` : la feuille modale entière n'est
/// pas reconstruite quand une progression de mission avance.
private struct MissionDailyList: View {
    @Environment(GameManager.self) private var gameManager
    @State private var appeared = false

    /// Réclamables d'abord (elles doivent sauter aux yeux), puis en cours, puis terminées.
    /// Le tri de Swift n'est pas stable : on départage sur l'id pour un ordre déterministe.
    private var ordered: [Mission] {
        gameManager.missions
            .filter { $0.type == .daily }
            .sorted { lhs, rhs in
                let l = (rank(lhs.status), lhs.id)
                let r = (rank(rhs.status), rhs.id)
                return l.0 == r.0 ? l.1 < r.1 : l.0 < r.0
            }
    }

    private func rank(_ status: MissionStatus) -> Int {
        switch status {
        case .completed: return 0
        case .claimed: return 2
        default: return 1
        }
    }

    var body: some View {
        let missions = ordered
        VStack(spacing: 13) {
            if missions.isEmpty {
                MissionEmptyState(
                    icon: "calendar.badge.clock",
                    text: tr("Aucune mission aujourd'hui"),
                    color: MissionStyle.daily
                )
                .missionEntrance(appeared: appeared, index: 0)
            } else {
                ForEach(Array(missions.enumerated()), id: \.element.id) { index, mission in
                    MissionRowView(mission: mission)
                        .missionEntrance(appeared: appeared, index: index)
                }
            }
        }
        .onAppear { appeared = true }
    }
}

private struct MissionEmptyState: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(color.opacity(0.65))
                .shadow(color: color.opacity(0.5), radius: 10)
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .neonPanel(color: color, cornerRadius: 20)
    }
}

// MARK: - Liste des Quêtes Secondaires

private struct SideQuestHeaderSpec {
    let icon: String
    let title: String
    let color: Color
    let showsReadyBadge: Bool
}

/// Entrée de la liste à plat (en-têtes ET quêtes dans un seul `ForEach`).
/// C'est indispensable : avec un `ForEach` par section, une quête qui passe de
/// « En cours » à « Terminées » change de branche structurelle et SwiftUI DÉTRUIT son
/// `@State` — la célébration de réclamation serait coupée net. Ici l'identité est stable.
private struct SideQuestListEntry: Identifiable {
    enum Kind {
        case header(SideQuestHeaderSpec)
        case quest(SideQuest, SideQuestRow.QuestState)
    }
    let id: String
    let kind: Kind
}

private struct SideQuestListView: View {
    @Environment(GameManager.self) private var gameManager
    @State private var appeared = false

    /// Partition volontairement « métrique-free » : seuls les identifiants réclamés et
    /// les prérequis sont lus ici. L'état « réclamable » est calculé par chaque ligne.
    private var entries: [SideQuestListEntry] {
        let available = SideQuest.all.filter { !gameManager.isSideQuestClaimed($0) && gameManager.isSideQuestAvailable($0) }
        let locked = SideQuest.all.filter { !gameManager.isSideQuestClaimed($0) && !gameManager.isSideQuestAvailable($0) }
        let claimed = SideQuest.all.filter { gameManager.isSideQuestClaimed($0) }

        var result: [SideQuestListEntry] = []

        if !available.isEmpty {
            result.append(SideQuestListEntry(
                id: "sq_header_available",
                kind: .header(SideQuestHeaderSpec(icon: "scope", title: tr("En cours"), color: MissionStyle.quest, showsReadyBadge: true))
            ))
            result.append(contentsOf: available.map { SideQuestListEntry(id: $0.id, kind: .quest($0, .available)) })
        }

        if !locked.isEmpty {
            result.append(SideQuestListEntry(
                id: "sq_header_locked",
                kind: .header(SideQuestHeaderSpec(icon: "lock.fill", title: tr("Verrouillées"), color: MissionStyle.done, showsReadyBadge: false))
            ))
            result.append(contentsOf: locked.map { SideQuestListEntry(id: $0.id, kind: .quest($0, .locked)) })
        }

        if !claimed.isEmpty {
            result.append(SideQuestListEntry(
                id: "sq_header_claimed",
                kind: .header(SideQuestHeaderSpec(icon: "checkmark.seal.fill", title: tr("Terminées"), color: Neon.green, showsReadyBadge: false))
            ))
            result.append(contentsOf: claimed.map { SideQuestListEntry(id: $0.id, kind: .quest($0, .claimed)) })
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                row(for: entry, index: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { appeared = true }
    }

    @ViewBuilder
    private func row(for entry: SideQuestListEntry, index: Int) -> some View {
        switch entry.kind {
        case .header(let spec):
            SideQuestSectionHeader(
                icon: spec.icon,
                title: spec.title,
                color: spec.color,
                showsReadyBadge: spec.showsReadyBadge
            )
            .missionEntrance(appeared: appeared, index: index)
        case .quest(let quest, let state):
            SideQuestRow(quest: quest, state: state)
                .missionEntrance(appeared: appeared, index: index)
        }
    }
}

private struct SideQuestSectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    var showsReadyBadge: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.7), radius: 5)

            Text(title.uppercased())
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.55))

            if showsReadyBadge {
                MissionTabBadge(kind: .sideQuests)
            }

            Rectangle()
                .fill(LinearGradient(colors: [color.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
        .padding(.top, 4)
    }
}

// MARK: - Ligne de quête secondaire

private struct SideQuestRow: View {
    enum QuestState { case available, locked, claimed }

    @Environment(GameManager.self) private var gameManager
    let quest: SideQuest
    let state: QuestState

    // Célébration locale
    @State private var isClaiming = false
    @State private var justClaimed = false
    @State private var flash: Double = 0
    @State private var shockwave: CGFloat = 0
    @State private var confettiBurst = 0
    @State private var rewardFly = false
    @State private var halo = false

    private var rewardDef: UpgradeDefinition? {
        UpgradeDefinition.all.first(where: { $0.id == quest.rewardId })
    }

    private var isDone: Bool { state == .claimed || justClaimed }
    private var canClaim: Bool {
        state == .available && !justClaimed && gameManager.canClaimSideQuest(quest)
    }

    private var accent: Color {
        if isDone { return Neon.green }
        if canClaim { return MissionStyle.gold }
        if state == .locked { return MissionStyle.done }
        return MissionStyle.quest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            headerLine
            bodyLine
            rewardBlock
            progressBlock
            claimButton
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonPanel(color: accent, cornerRadius: 18)
        .background { claimableHalo }
        .overlay { celebrationLayer }
        .overlay(alignment: .top) { confettiLayer }
        .overlay(alignment: .topTrailing) { flyingReward }
        .opacity(state == .locked ? 0.72 : 1)
        .onAppear { if canClaim { startHalo() } }
        .onChange(of: canClaim) { _, ready in if ready { startHalo() } }
    }

    // MARK: Contenu

    private var headerLine: some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.16))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(accent.opacity(0.5), lineWidth: 1)
                Image(systemName: state == .locked ? "lock.fill" : (isDone ? "checkmark.seal.fill" : "target"))
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(accent)
            }
            .frame(width: 38, height: 38)
            .shadow(color: accent.opacity(0.45), radius: 6)

            Text(tr(quest.title))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(isDone || state == .locked ? Color.white.opacity(0.5) : Color.white)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if isDone {
                MissionDoneStamp(color: Neon.green)
                    .transition(.scale(scale: 2.2).combined(with: .opacity))
            } else if canClaim {
                MissionReadyChip()
            }
        }
    }

    @ViewBuilder
    private var bodyLine: some View {
        if state == .locked {
            let prereqTitle = SideQuest.all.first(where: { $0.id == quest.prerequisiteQuestId })?.title ?? ""
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 10, weight: .bold))
                Text("\(tr("Requiert :")) \(tr(prereqTitle))")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(MissionStyle.gold.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(MissionStyle.gold.opacity(0.10)))
        } else {
            Text(tr(quest.description))
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(isDone ? 0.35 : 0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// La récompense est la motivation du joueur : elle occupe une vraie carte, pas une pastille.
    @ViewBuilder
    private var rewardBlock: some View {
        if let def = rewardDef {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(accent.opacity(0.18))
                    Circle().stroke(accent.opacity(0.55), lineWidth: 1)
                    Image(systemName: def.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accent)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text(tr("Débloque").uppercased())
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(tr(def.name))
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .foregroundStyle(isDone ? Color.white.opacity(0.5) : Color.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(LinearGradient(colors: [accent.opacity(0.16), accent.opacity(0.04)],
                                         startPoint: .leading, endPoint: .trailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(accent.opacity(0.3), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var progressBlock: some View {
        if state == .available && !justClaimed {
            let fraction = gameManager.sideQuestProgress(quest)
            VStack(spacing: 7) {
                if quest.requirements.count == 1, let req = quest.requirements.first {
                    singleRequirementLine(req, fraction: fraction)
                } else {
                    HStack(spacing: 8) {
                        Text(tr("Progression"))
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(.white.opacity(0.45))
                        Spacer(minLength: 0)
                        percentText(fraction)
                    }
                }

                NeonProgressBar(fraction: fraction, color: accent, height: 9, animated: true)

                if quest.requirements.count > 1 {
                    VStack(spacing: 7) {
                        ForEach(0..<quest.requirements.count, id: \.self) { i in
                            requirementRow(quest.requirements[i])
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func singleRequirementLine(_ req: SideQuestRequirement, fraction: Double) -> some View {
        let value = gameManager.sideQuestValue(for: req.metric)
        let target = gameManager.effectiveTarget(req)
        return HStack(spacing: 8) {
            Text("\(BigNumber(value).formattedString()) / \(BigNumber(target).formattedString())")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.8))
                .contentTransition(.numericText())
            Spacer(minLength: 0)
            percentText(fraction)
        }
        .animation(.easeInOut(duration: 0.35), value: fraction)
    }

    private func percentText(_ fraction: Double) -> some View {
        Text("\(Int((min(max(fraction, 0), 1) * 100).rounded())) %")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(accent)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.35), value: fraction)
    }

    private func requirementRow(_ req: SideQuestRequirement) -> some View {
        let value = gameManager.sideQuestValue(for: req.metric)
        let target = max(1.0, gameManager.effectiveTarget(req))
        let reached = value >= target
        let fraction = min(1.0, value / target)
        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10, weight: .black))
                Text(metricLabel(req.metric))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                Spacer(minLength: 0)
                Text("\(BigNumber(value).formattedString()) / \(BigNumber(target).formattedString())")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(reached ? Neon.green : Color.white.opacity(0.5))

            NeonProgressBar(fraction: fraction, color: reached ? Neon.green : MissionStyle.quest, height: 5, animated: false)
        }
    }

    @ViewBuilder
    private var claimButton: some View {
        if canClaim {
            Button(action: claim) {
                HStack(spacing: 9) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 15, weight: .black))
                    Text(tr("Réclamer"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .black))
                        .opacity(0.55)
                }
            }
            .buttonStyle(GoldenAdButtonStyle(cornerRadius: 14))
            .disabled(isClaiming)
            .padding(.top, 2)
        }
    }

    // MARK: Célébration

    @ViewBuilder
    private var claimableHalo: some View {
        if canClaim {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MissionStyle.gold.opacity(0.20))
                .blur(radius: 15)
                .scaleEffect(halo ? 1.05 : 0.96)
        }
    }

    @ViewBuilder
    private var celebrationLayer: some View {
        if isClaiming {
            ZStack {
                Circle()
                    .stroke(Neon.green, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .scaleEffect(1 + shockwave * 3.6)
                    .opacity(max(0, 0.85 - Double(shockwave) * 0.85))
                    .blur(radius: 1)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .opacity(flash)
                    .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var confettiLayer: some View {
        if isClaiming {
            // Monté seulement pendant la célébration : le Canvas/TimelineView de ConfettiView
            // ne doit surtout pas tourner en permanence dans chaque ligne de la liste.
            ConfettiView(trigger: confettiBurst)
                .frame(height: 300)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var flyingReward: some View {
        if isClaiming, let def = rewardDef {
            HStack(spacing: 5) {
                Image(systemName: def.icon)
                    .font(.system(size: 11, weight: .black))
                Text(tr(def.name))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(Neon.green)
            .shadow(color: Neon.green.opacity(0.9), radius: 10)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.55)))
            .overlay(Capsule().stroke(Neon.green.opacity(0.7), lineWidth: 1))
            .scaleEffect(rewardFly ? 1.35 : 0.9)
            .offset(y: rewardFly ? -52 : 6)
            .opacity(rewardFly ? 0 : 1)
            .allowsHitTesting(false)
        }
    }

    // MARK: Actions

    private func startHalo() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { halo = true }
    }

    private func claim() {
        guard !isClaiming, gameManager.canClaimSideQuest(quest) else { return }
        // Les calques de célébration sont montés AU REPOS ici : ils doivent exister avant
        // qu'on lance les animations, sinon rien ne s'anime (une insertion n'anime pas).
        isClaiming = true
        Task { @MainActor in await runCelebration() }
    }

    @MainActor
    private func runCelebration() async {
        try? await Task.sleep(nanoseconds: 60_000_000)

        NeonHaptics.success()
        confettiBurst &+= 1
        withAnimation(.easeOut(duration: 0.12)) { flash = 0.55 }
        withAnimation(.easeOut(duration: 0.55)) { shockwave = 1 }
        withAnimation(.easeOut(duration: 0.28).delay(0.10)) { flash = 0 }
        withAnimation(.easeOut(duration: 0.85)) { rewardFly = true }

        try? await Task.sleep(nanoseconds: 420_000_000)

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            gameManager.claimSideQuest(quest)
            justClaimed = true
        }

        // On laisse retomber les confettis avant de démonter le calque.
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        isClaiming = false
        shockwave = 0
        rewardFly = false
    }

    private func metricLabel(_ metric: SideQuestMetric) -> String {
        switch metric {
        case .ducksFromCrates: return tr("Capsules")
        case .ducksRecycled: return tr("Recyclés")
        case .fusionsDone: return tr("Fusions")
        case .inventoryCount: return tr("Canards")
        case .playerLevel: return tr("Niveau")
        case .earningsPerSecond: return tr("Revenus/s")
        case .mutationPointsEarned: return tr("ADN Obtenu")
        }
    }
}

// MARK: - Tampons / pastilles partagés

private struct MissionDoneStamp: View {
    var color: Color = Neon.green

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10, weight: .black))
            Text(tr("Terminé").uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.2)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.opacity(0.12))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(color.opacity(0.75), lineWidth: 1.5)
        }
        .rotationEffect(.degrees(-8))
        .shadow(color: color.opacity(0.45), radius: 5)
        .fixedSize()
    }
}

/// Pastille « objectif atteint » qui respire, posée sur les lignes réclamables.
private struct MissionReadyChip: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 9, weight: .black))
            Text(tr("Objectif atteint !"))
                .font(.system(size: 10, weight: .black, design: .rounded))
        }
        .foregroundStyle(Color(hex: 0x3F1D00))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(MissionStyle.gold))
        .shadow(color: MissionStyle.gold.opacity(pulse ? 0.95 : 0.4), radius: pulse ? 11 : 4)
        .scaleEffect(pulse ? 1.04 : 0.97)
        .fixedSize()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

// MARK: - Ligne de mission (quotidienne / histoire)

struct MissionRowView: View {
    @Environment(GameManager.self) private var gameManager
    let mission: Mission

    // Célébration locale
    @State private var isClaiming = false
    @State private var justClaimed = false
    @State private var flash: Double = 0
    @State private var shockwave: CGFloat = 0
    @State private var confettiBurst = 0
    @State private var rewardFly = false
    @State private var halo = false

    private var isDone: Bool { mission.status == .claimed || justClaimed }
    private var isClaimable: Bool { mission.status == .completed && !justClaimed }

    private var accent: Color {
        if isDone { return MissionStyle.done }
        if isClaimable { return MissionStyle.gold }
        return MissionStyle.daily
    }

    /// Progression 0 → 1. Une mission complétée est forcément pleine.
    private var fraction: Double {
        if isDone || mission.status == .completed { return 1 }
        let target = max(1.0, mission.targetProgress.doubleValue)
        let current = mission.currentProgress.doubleValue
        guard current > 0 else { return 0 }
        return min(1.0, current / target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerLine
            progressBlock
            claimButton
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonPanel(color: accent, cornerRadius: 18)
        .background { claimableHalo }
        .overlay { celebrationLayer }
        .overlay(alignment: .top) { confettiLayer }
        .overlay(alignment: .topTrailing) { flyingReward }
        .onAppear { if isClaimable { startHalo() } }
        .onChange(of: isClaimable) { _, ready in if ready { startHalo() } }
    }

    // MARK: Contenu

    private var headerLine: some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.16))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(accent.opacity(0.5), lineWidth: 1)
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(accent)
            }
            .frame(width: 38, height: 38)
            .shadow(color: accent.opacity(0.45), radius: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(tr(mission.title))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(isDone ? Color.white.opacity(0.45) : Color.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tr(mission.description))
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(isDone ? 0.32 : 0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if isDone {
                MissionDoneStamp(color: Neon.green)
                    .transition(.scale(scale: 2.2).combined(with: .opacity))
            } else {
                rewardChip
            }
        }
    }

    /// La récompense (XP) est affichée en évidence : c'est ce qui donne envie de finir.
    private var rewardChip: some View {
        let color = isClaimable ? MissionStyle.gold : Neon.cyan
        return HStack(spacing: 3) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 11, weight: .black))
            Text("+\(mission.rewardXP)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .monospacedDigit()
            Text(tr("XP"))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .opacity(0.75)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
        .shadow(color: color.opacity(isClaimable ? 0.65 : 0), radius: 8)
        .fixedSize()
    }

    @ViewBuilder
    private var progressBlock: some View {
        if !isDone {
            VStack(spacing: 7) {
                HStack(spacing: 8) {
                    Text("\(mission.currentProgress.formattedString()) / \(mission.targetProgress.formattedString())")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.8))
                        .contentTransition(.numericText())

                    Spacer(minLength: 0)

                    Text("\(Int((fraction * 100).rounded())) %")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                        .contentTransition(.numericText())
                }
                .animation(.easeInOut(duration: 0.35), value: fraction)

                NeonProgressBar(fraction: fraction, color: accent, height: 9, animated: true)
            }
        }
    }

    @ViewBuilder
    private var claimButton: some View {
        if isClaimable {
            Button(action: claim) {
                HStack(spacing: 9) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 15, weight: .black))
                    Text(tr("Réclamer"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                    Spacer(minLength: 0)
                    Text("+\(mission.rewardXP) \(tr("XP"))")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: 0x4A2400))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.9)))
                }
            }
            .buttonStyle(GoldenAdButtonStyle(cornerRadius: 14))
            .disabled(isClaiming)
            .padding(.top, 2)
        }
    }

    // MARK: Célébration

    @ViewBuilder
    private var claimableHalo: some View {
        if isClaimable {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MissionStyle.gold.opacity(0.20))
                .blur(radius: 15)
                .scaleEffect(halo ? 1.05 : 0.96)
        }
    }

    @ViewBuilder
    private var celebrationLayer: some View {
        if isClaiming {
            ZStack {
                Circle()
                    .stroke(Neon.green, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .scaleEffect(1 + shockwave * 3.6)
                    .opacity(max(0, 0.85 - Double(shockwave) * 0.85))
                    .blur(radius: 1)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .opacity(flash)
                    .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var confettiLayer: some View {
        if isClaiming {
            // Idem quêtes secondaires : monté uniquement le temps de la salve.
            ConfettiView(trigger: confettiBurst)
                .frame(height: 300)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var flyingReward: some View {
        if isClaiming {
            HStack(spacing: 4) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 12, weight: .black))
                Text("+\(mission.rewardXP) \(tr("XP"))")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(MissionStyle.gold)
            .shadow(color: MissionStyle.gold.opacity(0.95), radius: 12)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.55)))
            .overlay(Capsule().stroke(MissionStyle.gold.opacity(0.7), lineWidth: 1))
            .scaleEffect(rewardFly ? 1.45 : 0.9)
            .offset(y: rewardFly ? -54 : 6)
            .opacity(rewardFly ? 0 : 1)
            .allowsHitTesting(false)
        }
    }

    // MARK: Actions

    private func startHalo() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { halo = true }
    }

    private func claim() {
        guard !isClaiming, mission.status == .completed else { return }
        // Les calques doivent exister avant qu'on anime : on les monte au repos ici.
        isClaiming = true
        Task { @MainActor in await runCelebration() }
    }

    @MainActor
    private func runCelebration() async {
        try? await Task.sleep(nanoseconds: 60_000_000)

        NeonHaptics.success()
        confettiBurst &+= 1
        withAnimation(.easeOut(duration: 0.12)) { flash = 0.55 }
        withAnimation(.easeOut(duration: 0.55)) { shockwave = 1 }
        withAnimation(.easeOut(duration: 0.28).delay(0.10)) { flash = 0 }
        withAnimation(.easeOut(duration: 0.85)) { rewardFly = true }

        try? await Task.sleep(nanoseconds: 420_000_000)

        // Même appel qu'avant, simplement joué après la célébration (comme l'écran hors-ligne).
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            gameManager.claimMission(id: mission.id)
            justClaimed = true
        }

        try? await Task.sleep(nanoseconds: 2_500_000_000)
        isClaiming = false
        shockwave = 0
        rewardFly = false
    }

    /// Petit repère visuel par type d'objectif : la liste devient lisible d'un coup d'œil.
    private var symbol: String {
        switch mission.actionType {
        case .openWoodenCrate, .openCrates, .bulkOpenCrates:
            return "shippingbox.fill"
        case .recycleDuck, .totalRecycleCount, .bulkRecycle:
            return "arrow.3.trianglepath"
        case .unlockFusionLab, .fuseCommonDuck, .autoFusion, .megaFusion, .totalFusionCount:
            return "atom"
        case .ritual, .haveGoldenRitual:
            return "flame.fill"
        case .unlockUpgrades, .maxRepeatableUpgrades:
            return "sparkles"
        case .upgradeDuckSize, .upgradeDuckMutation, .reachDuckLevel:
            return "chart.line.uptrend.xyaxis"
        case .upgradeFactory:
            return "building.2.fill"
        case .assignDuckToFactory, .assignHighLevelDucks:
            return "person.badge.plus"
        case .assignPerk:
            return "bolt.circle.fill"
        case .reachIncome:
            return "dollarsign.circle.fill"
        case .prestige:
            return "star.fill"
        case .haveMaxMythicDuck:
            return "crown.fill"
        case MissionActionType.none:
            return "trophy.fill"
        }
    }
}
