#if DEBUG
import SwiftUI

// MARK: - Menu Développeur
// Compilé uniquement en Debug : ce fichier n'existe pas dans le build App Store.

struct DeveloperMenu: View {
    @Environment(GameManager.self) private var gameManager

    // Ressources
    @State private var resourceAmount: String = "1000"

    // Générateur de canards
    @State private var duckRarity: DuckRarity = .commun
    @State private var duckSize: DuckSize = .petit
    @State private var duckMutation: DuckMutation = .aucune

    // Time travel
    @State private var timeJump: TimeJump = .oneHour

    // Pubs
    @State private var simulateAds = AdManager.simulateAdSuccess

    // Feedback & confirmations
    @State private var feedback: String = ""
    @State private var showingResetQuestsConfirmation = false
    @State private var showingResetAllConfirmation = false

    enum TimeJump: String, CaseIterable, Identifiable {
        case oneMinute = "1 Min"
        case oneHour = "1 Heure"
        case oneDay = "1 Jour"
        case oneWeek = "1 Semaine"
        case oneMonth = "1 Mois"
        case oneYear = "1 An"

        var id: String { rawValue }

        var seconds: TimeInterval {
            switch self {
            case .oneMinute: return 60
            case .oneHour: return 3600
            case .oneDay: return 86_400
            case .oneWeek: return 604_800
            case .oneMonth: return 2_592_000
            case .oneYear: return 31_536_000
            }
        }
    }

    private var parsedAmount: Double? {
        Double(resourceAmount.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        Form {
            if !feedback.isEmpty {
                Section {
                    Text(feedback)
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }

            // MARK: Ressources
            Section("💰 Gestion des Ressources") {
                TextField("Montant", text: $resourceAmount)
                    .keyboardType(.decimalPad)

                HStack {
                    Button("+ Argent") {
                        if let amount = parsedAmount {
                            gameManager.devAddMoney(amount)
                            note("+\(resourceAmount) 💰")
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("+ ADN") {
                        if let amount = parsedAmount {
                            gameManager.devAddDNA(amount)
                            note("+\(resourceAmount) 🧬")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    Button("+ Gemmes") {
                        if let amount = parsedAmount {
                            gameManager.devAddGems(amount)
                            note("+\(resourceAmount) 💎")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
                .buttonStyle(.plain)
            }

            // MARK: Générateur de canards
            Section("🦆 Générateur de Canards Sur-Mesure") {
                Picker("Rareté", selection: $duckRarity) {
                    ForEach(DuckRarity.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Taille", selection: $duckSize) {
                    ForEach(DuckSize.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Mutation", selection: $duckMutation) {
                    ForEach(DuckMutation.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Button("Générer ce Canard") {
                    gameManager.devSpawnDuck(rarity: duckRarity, size: duckSize, mutation: duckMutation)
                    note("Canard \(duckRarity.rawValue) \(duckSize.rawValue) ajouté")
                }
                .bold()
            }

            // MARK: Collection
            Section("📖 Collection") {
                Button("Débloquer tous les Perks (Collection)") {
                    let total = gameManager.devUnlockAllPerks()
                    note("\(total) perks débloqués dans la Collection")
                }
                .bold()
                Text("Marque toutes les combinaisons de perks comme découvertes pour les voir dans l'onglet Collection › Perks.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // MARK: Time travel
            Section("⏰ Contrôle du Temps") {
                Picker("Durée du saut", selection: $timeJump) {
                    ForEach(TimeJump.allCases) { Text($0.rawValue).tag($0) }
                }
                Button("Avancer le Temps") {
                    gameManager.devSimulateTimeJump(seconds: timeJump.seconds)
                    note("Saut de \(timeJump.rawValue) effectué (gains + automatisation crédités)")
                }
                .bold()
                Text("Crédite argent, ADN, XP et rejoue l'automatisation comme après une absence de la durée choisie.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // MARK: Pubs & capsules
            Section("📺 Capsules & Publicités") {
                Toggle("Simuler les pubs (succès immédiat)", isOn: $simulateAds)
                    .onChange(of: simulateAds) { _, newValue in
                        AdManager.simulateAdSuccess = newValue
                        if newValue {
                            #if canImport(GoogleMobileAds)
                            AdManager.shared.isReady = true
                            #endif
                        }
                        note(newValue ? "Toutes les pubs réussiront sans AdMob" : "Pubs réelles rétablies")
                    }

                Button("Reset des Cooldowns (pubs, gemmes, capsule mystère)") {
                    gameManager.devResetAdCooldowns()
                    note("Cooldowns réinitialisés")
                }

                Button("Spawn Forcé : Capsule Mystère") {
                    gameManager.devForceMysteryCrateSpawn()
                    note("Capsule Mystère disponible en boutique")
                }

                Button("Récompense directe : Boost Usines (+1h x2)") {
                    gameManager.devGrantAdReward(for: .factoryBoost)
                    note("Boost usine appliqué")
                }
                Button("Récompense directe : +10 Gemmes Quotidiennes") {
                    gameManager.devGrantAdReward(for: .dailyGems)
                    note("+10 💎")
                }
                Button("Récompense directe : Canard Mythique (Capsule Mystère)") {
                    gameManager.devGrantAdReward(for: .mysteryCrate)
                    note("Canard Mythique ajouté à l'inventaire")
                }
            }

            // MARK: Quêtes secondaires
            Section("🗺️ Quêtes Secondaires") {
                if let quest = gameManager.devActiveSideQuest {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quête active : \(quest.title)")
                            .font(.subheadline.bold())
                        Text(quest.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Button("Remplir les jauges (tester « Réclamer »)") {
                        let skipped = gameManager.devFillActiveSideQuestRequirements()
                        if skipped.isEmpty {
                            note("Objectifs remplis — le bouton Réclamer doit s'allumer")
                        } else {
                            note("Objectifs remplis (sauf revenus/s : dépend des usines réelles)")
                        }
                    }

                    Button("Sauter la Quête (récompense forcée)") {
                        gameManager.devSkipActiveSideQuest()
                        note("Quête « \(quest.title) » validée de force")
                    }
                } else {
                    Text("Toutes les quêtes sont réclamées ✅")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Button("Réinitialiser les Quêtes", role: .destructive) {
                    showingResetQuestsConfirmation = true
                }
            }

            // MARK: Système
            Section("⚙️ Outils Système") {
                Button("RESET TOTAL de la sauvegarde", role: .destructive) {
                    showingResetAllConfirmation = true
                }
                .bold()
            }
        }
        .navigationTitle("🔧 Mode Développeur")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.0, blue: 0.12))
        .alert("Réinitialiser les quêtes ?", isPresented: $showingResetQuestsConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Réinitialiser", role: .destructive) {
                gameManager.devResetSideQuests()
                note("Quêtes et compteurs remis à zéro")
            }
        } message: {
            Text("Retire les récompenses de quêtes déjà obtenues et remet les compteurs (capsules, recyclage, fusions) à zéro.")
        }
        .alert("Tout effacer ?", isPresented: $showingResetAllConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Oui, tout effacer", role: .destructive) {
                gameManager.resetProgression()
                note("Sauvegarde réinitialisée")
            }
        } message: {
            Text("Cette action est irréversible : la sauvegarde repart de zéro.")
        }
    }

    private func note(_ text: String) {
        withAnimation { feedback = text }
    }
}
#endif
