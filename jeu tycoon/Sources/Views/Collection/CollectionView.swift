import SwiftUI

// MARK: - Compendium (Collection)

struct CollectionView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var selectedPerkEntry: PerkCollectionEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                NeonBackground()

                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text(tr("Canards")).tag(0)
                        Text(tr("Perks")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if selectedTab == 0 {
                        DuckCollectionTab()
                    } else {
                        PerkCollectionTab(selectedPerkEntry: $selectedPerkEntry)
                    }
                }
            }
            .navigationTitle(tr("Collection"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .overlay {
                if let entry = selectedPerkEntry {
                    PerkDetailPopup(entry: entry, count: gameManager.perkDiscoveryCount(for: entry)) {
                        withAnimation { selectedPerkEntry = nil }
                    }
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - Onglet Canards

private struct DuckCollectionTab: View {
    @Environment(GameManager.self) private var gameManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Jauge ultime
                CollectionProgressHeader(
                    current: gameManager.unlockedDuckCollectionCount,
                    total: gameManager.totalDuckCollectionSlots,
                    color: .yellow
                )

                // Récompense finale
                if gameManager.isDuckCollectionComplete && !gameManager.claimedAllDucksCollection {
                    Button(action: {
                        withAnimation { gameManager.claimAllDucksCollection() }
                    }) {
                        VStack(spacing: 4) {
                            Text(tr("COLLECTION COMPLÈTE !"))
                                .font(.headline.bold())
                            Text(tr("Réclamer : +50% revenus des canards + Capsule Secrète"))
                                .font(.caption)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: .yellow.opacity(0.6), radius: 6)
                    }
                    .padding(.horizontal)
                } else if gameManager.claimedAllDucksCollection {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.yellow)
                        Text(tr("Bonus permanent actif : +50% revenus des canards"))
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 8)
                }

                // Une rangée par rareté
                VStack(spacing: 10) {
                    ForEach(DuckRarity.allCases, id: \.self) { rarity in
                        RarityCollectionRow(rarity: rarity)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .padding(.bottom, 40)
        }
    }
}

private struct RarityCollectionRow: View {
    @Environment(GameManager.self) private var gameManager
    let rarity: DuckRarity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rarity.localizedName)
                    .font(.subheadline.bold())
                    .foregroundColor(rarity.color)

                Spacer()

                if gameManager.hasClaimedRarityCollection(rarity) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("+10 💎")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.green)
                } else if gameManager.isRarityCollectionComplete(rarity) {
                    Button(action: {
                        withAnimation { gameManager.claimRarityCollection(rarity: rarity) }
                    }) {
                        Text("\(tr("Réclamer")) 10 💎")
                    }
                    .buttonStyle(NeonButtonStyle(color: Neon.cyan, cornerRadius: 10, fullWidth: false, compact: true))
                }
            }

            HStack(spacing: 8) {
                ForEach(GameManager.collectibleSizes, id: \.self) { size in
                    DuckSilhouetteCell(
                        rarity: rarity,
                        size: size,
                        isUnlocked: gameManager.isDuckUnlocked(rarity: rarity, size: size)
                    )
                }
            }
        }
        .padding(10)
        .background(rarity.color.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rarity.color.opacity(gameManager.isRarityCollectionComplete(rarity) ? 0.6 : 0.2), lineWidth: 1)
        )
    }
}

private struct DuckSilhouetteCell: View {
    let rarity: DuckRarity
    let size: DuckSize
    let isUnlocked: Bool

    // L'image grandit avec la taille du canard
    private var imageSide: CGFloat {
        switch size {
        case .petit: return 22
        case .moyen: return 26
        case .grand: return 30
        case .geant: return 34
        case .colossal: return 38
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Image(rarity.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSide, height: imageSide)
                    .grayscale(isUnlocked ? 0 : 1)
                    .brightness(isUnlocked ? 0 : -0.55)
                    .opacity(isUnlocked ? 1 : 0.55)

                if !isUnlocked {
                    Text("?")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .frame(height: 40)

            Text(tr(size.rawValue))
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(isUnlocked ? .white.opacity(0.9) : .gray)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(isUnlocked ? 0.08 : 0.03))
        .cornerRadius(8)
    }
}

// MARK: - Onglet Perks

private struct PerkCollectionTab: View {
    @Environment(GameManager.self) private var gameManager
    @Binding var selectedPerkEntry: PerkCollectionEntry?

    private var factoryEntries: [PerkCollectionEntry] {
        PerkCollectionEntry.allEntries.filter { $0.type == .factory }
    }
    private var duckEntries: [PerkCollectionEntry] {
        PerkCollectionEntry.allEntries.filter { $0.type == .duck }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Jauge ultime
                CollectionProgressHeader(
                    current: gameManager.discoveredPerkCollectionCount,
                    total: PerkCollectionEntry.allEntries.count,
                    color: .purple
                )

                // Récompense finale
                if gameManager.isPerkCollectionComplete && !gameManager.claimedAllPerksCollection {
                    Button(action: {
                        withAnimation { gameManager.claimAllPerksCollection() }
                    }) {
                        VStack(spacing: 4) {
                            Text(tr("COLLECTION COMPLÈTE !"))
                                .font(.headline.bold())
                            Text("\(tr("Réclamer")) 100 💎")
                                .font(.caption)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: .purple.opacity(0.6), radius: 6)
                    }
                    .padding(.horizontal)
                } else if gameManager.claimedAllPerksCollection {
                    // Le perk secret n'est mentionné nulle part avant le déblocage.
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text(tr("Perk Secret débloqué"))
                                .font(.caption.bold())
                                .foregroundColor(.purple)
                        }
                        Text(tr("Bientôt disponible"))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                PerkSectionGrid(title: tr("Perks d'Usine"), icon: "building.2.fill", entries: factoryEntries, columns: columns, selectedPerkEntry: $selectedPerkEntry)
                PerkSectionGrid(title: tr("Perks de Canard"), icon: "bird.fill", entries: duckEntries, columns: columns, selectedPerkEntry: $selectedPerkEntry)
            }
            .padding(.vertical)
            .padding(.bottom, 40)
        }
    }
}

private struct PerkSectionGrid: View {
    @Environment(GameManager.self) private var gameManager
    let title: String
    let icon: String
    let entries: [PerkCollectionEntry]
    let columns: [GridItem]
    @Binding var selectedPerkEntry: PerkCollectionEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(entries) { entry in
                    PerkCollectionCell(entry: entry, count: gameManager.perkDiscoveryCount(for: entry))
                        .onTapGesture {
                            if gameManager.perkDiscoveryCount(for: entry) > 0 {
                                withAnimation { selectedPerkEntry = entry }
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct PerkCollectionCell: View {
    let entry: PerkCollectionEntry
    let count: Int

    private var isDiscovered: Bool { count > 0 }

    var body: some View {
        VStack(spacing: 4) {
            if isDiscovered {
                Image(systemName: entry.type == .factory ? "gearshape.fill" : "bird.fill")
                    .font(.system(size: 18))
                    .foregroundColor(entry.rarity.color)

                Text(entry.samplePerk.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(entry.rarity.localizedName)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(entry.rarity.color)

                Text("x\(count)")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.yellow)
            } else {
                Text("?")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.gray)

                Text(entry.rarity.localizedName)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding(6)
        .frame(height: 85)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(isDiscovered ? 0.07 : 0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDiscovered ? entry.rarity.color.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Popup de détail d'un perk

private struct PerkDetailPopup: View {
    let entry: PerkCollectionEntry
    let count: Int
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 12) {
                Image(systemName: entry.type == .factory ? "gearshape.fill" : "bird.fill")
                    .font(.system(size: 34))
                    .foregroundColor(entry.rarity.color)

                Text(entry.samplePerk.name)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(entry.rarity.localizedName)
                    .font(.caption.bold())
                    .foregroundColor(entry.rarity.color)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 10)
                    .background(entry.rarity.color.opacity(0.2))
                    .cornerRadius(8)

                Text(entry.samplePerk.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Text("\(tr("Obtenu")) x\(count)")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)

                Button(action: { onClose() }) {
                    Text(tr("Fermer"))
                }
                .neonButton(entry.rarity.color)
            }
            .padding(20)
            .frame(maxWidth: 300)
            .background(Color(red: 0.1, green: 0.1, blue: 0.18))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(entry.rarity.color.opacity(0.5), lineWidth: 1.5)
            )
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Jauge de progression commune

private struct CollectionProgressHeader: View {
    let current: Int
    let total: Int
    let color: Color

    private var progress: Double {
        total > 0 ? Double(current) / Double(total) : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(tr("Progression"))
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("\(current) / \(total)")
                    .font(.subheadline.bold())
                    .foregroundColor(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 10)
        }
        .padding(.horizontal)
    }
}
