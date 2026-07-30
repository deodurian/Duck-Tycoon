import Foundation
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

/// Clés Remote Config centralisées.
/// Les valeurs peuvent être pilotées à distance depuis la console Firebase ;
/// à défaut de réseau, le jeu retombe sur les valeurs par défaut codées en dur.
enum RCKey {
    // Probabilités (génétique)
    // Perf : ces clés sont lues sur le chemin chaud des tirages (jusqu'à ~15 lectures par canard
    // généré, et l'Auto-Ouvrier peut en générer des dizaines par seconde). Les construire par
    // interpolation `"prob_rarity_\(k)"` allouait une String sur le tas À CHAQUE appel ; elles sont
    // désormais figées en constantes créées une seule fois. Les chaînes sont identiques au
    // caractère près, donc Firebase renvoie exactement les mêmes valeurs : équilibrage inchangé.
    static let probRarityCommun = "prob_rarity_commun"
    static let probRarityPeuCommun = "prob_rarity_peu_commun"
    static let probRarityRare = "prob_rarity_rare"
    static let probRarityEpique = "prob_rarity_epique"
    static let probRarityLegendaire = "prob_rarity_legendaire"
    static let probRarityMythique = "prob_rarity_mythique"
    static let probRarityExotique = "prob_rarity_exotique"
    static let probRarityCeleste = "prob_rarity_celeste"
    static let probRarityPrimordiale = "prob_rarity_primordiale"

    static let probSizePetit = "prob_size_petit"
    static let probSizeMoyen = "prob_size_moyen"
    static let probSizeGrand = "prob_size_grand"
    static let probSizeGeant = "prob_size_geant"
    static let probSizeColossal = "prob_size_colossal"

    static let probMutationAucune = "prob_mutation_aucune"
    static let probMutationDore = "prob_mutation_dore"
    static let probMutationRadioactif = "prob_mutation_radioactif"
    static let probMutationCristallise = "prob_mutation_cristallise"
    static let probMutationQuantique = "prob_mutation_quantique"

    static func probRitualColor(_ k: String) -> String { "prob_ritual_color_\(k)" }

    // Économie & usines
    static let economyFactoryCostMult = "economy_factory_cost_mult"
    static let economyFactoryProdMult = "economy_factory_prod_mult"
    static let offlineEarningsMaxHours = "offline_earnings_max_hours"

    // Boutique d'améliorations (ADN) — templates par id
    static func upgradeCost(_ id: String) -> String { "upgrade_cost_\(id)" }
    static func upgradePower(_ id: String) -> String { "upgrade_power_\(id)" }

    // Récompenses & temps d'attente
    static let rewardGemsDaily = "reward_gems_daily"
    static let rewardMysteryCrateGems = "reward_mystery_crate_gems"
    static let cooldownMysteryCrateSec = "cooldown_mystery_crate_sec"

    // Prestige & quêtes
    static let prestigeStarCostBase = "prestige_star_cost_base"
    static let prestigeStarCostFactor = "prestige_star_cost_factor"
    static let questDifficultyMult = "quest_difficulty_mult"

    // Perks — global + template par id
    static let perkPowerMult = "perk_power_mult"
    static func perkPower(_ id: String) -> String { "perk_power_\(id)" }
}

// MARK: - Instantanés de probabilités (chemin chaud des tirages)

/// Instantané immuable des probabilités de rareté.
/// Perf : un tirage lisait les 9 valeurs une par une, chacune coûtant une allocation de clé String,
/// une prise de `NSLock` et un hachage de dictionnaire. La table permet de tout récupérer en UNE
/// prise de verrou. Les valeurs proviennent du même instantané `activeCache` : probabilités et
/// résultats de tirage strictement inchangés.
struct RarityProbabilityTable {
    let commun: Double
    let peuCommun: Double
    let rare: Double
    let epique: Double
    let legendaire: Double
    let mythique: Double
    let exotique: Double
    let celeste: Double
    let primordiale: Double

    nonisolated func value(for rarity: DuckRarity) -> Double {
        switch rarity {
        case .commun: return commun
        case .peuCommun: return peuCommun
        case .rare: return rare
        case .epique: return epique
        case .legendaire: return legendaire
        case .mythique: return mythique
        case .exotique: return exotique
        case .celeste: return celeste
        case .primordiale: return primordiale
        }
    }
}

/// Instantané immuable des probabilités de taille (même motif que `RarityProbabilityTable`).
struct SizeProbabilityTable {
    let petit: Double
    let moyen: Double
    let grand: Double
    let geant: Double
    let colossal: Double

    nonisolated func value(for size: DuckSize) -> Double {
        switch size {
        case .petit: return petit
        case .moyen: return moyen
        case .grand: return grand
        case .geant: return geant
        case .colossal: return colossal
        }
    }
}

/// Instantané immuable des probabilités de mutation (même motif que `RarityProbabilityTable`).
struct MutationProbabilityTable {
    let aucune: Double
    let dore: Double
    let radioactif: Double
    let cristallise: Double
    let quantique: Double

    nonisolated func value(for mutation: DuckMutation) -> Double {
        switch mutation {
        case .aucune: return aucune
        case .dore: return dore
        case .radioactif: return radioactif
        case .cristallise: return cristallise
        case .quantique: return quantique
        }
    }
}

/// Singleton pilotant l'équilibrage à distance via Firebase Remote Config.
///
/// - Fournit des valeurs par défaut codées en dur (fonctionnement hors-ligne garanti).
/// - Récupère silencieusement les valeurs serveur en arrière-plan au démarrage.
/// - Le SDK persiste la dernière config activée : les sessions suivantes en bénéficient même hors-ligne.
/// - Compile et fonctionne même si le SDK FirebaseRemoteConfig n'est pas lié (fallback pur défauts).
final class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    /// Valeurs par défaut = équilibrage de référence embarqué dans le binaire.
    /// Elles servent aussi de defaults Firebase (visibles dans la console).
    private let defaults: [String: Double] = {
        var d: [String: Double] = [:]

        // Probabilités de rareté (somme ≈ 100)
        d[RCKey.probRarityCommun] = 67.0
        d[RCKey.probRarityPeuCommun] = 26.0
        d[RCKey.probRarityRare] = 5.5
        d[RCKey.probRarityEpique] = 1.2
        d[RCKey.probRarityLegendaire] = 0.25
        d[RCKey.probRarityMythique] = 0.04
        d[RCKey.probRarityExotique] = 0.008
        d[RCKey.probRarityCeleste] = 0.0015
        d[RCKey.probRarityPrimordiale] = 0.0005

        // Probabilités de taille
        d[RCKey.probSizePetit] = 68.0
        d[RCKey.probSizeMoyen] = 20.0
        d[RCKey.probSizeGrand] = 8.5
        d[RCKey.probSizeGeant] = 3.0
        d[RCKey.probSizeColossal] = 0.5

        // Probabilités de mutation
        d[RCKey.probMutationAucune] = 87.0
        d[RCKey.probMutationDore] = 9.0
        d[RCKey.probMutationRadioactif] = 3.0
        d[RCKey.probMutationCristallise] = 0.9
        d[RCKey.probMutationQuantique] = 0.1

        // Économie
        d[RCKey.economyFactoryCostMult] = 1.0
        d[RCKey.economyFactoryProdMult] = 1.0
        d[RCKey.offlineEarningsMaxHours] = 12.0

        // Récompenses & cooldowns
        d[RCKey.rewardGemsDaily] = 10.0
        d[RCKey.rewardMysteryCrateGems] = 0.0
        d[RCKey.cooldownMysteryCrateSec] = 1800.0

        // Prestige & quêtes
        d[RCKey.prestigeStarCostBase] = 1_000_000_000_000.0
        d[RCKey.prestigeStarCostFactor] = 0.25
        d[RCKey.questDifficultyMult] = 1.0

        // Perks
        d[RCKey.perkPowerMult] = 1.0

        return d
    }()

    /// Instantané des valeurs actives (rafraîchi après chaque activation Firebase).
    /// Lu sur les chemins chauds (tirages, économie) — accès rapide et thread-safe en lecture.
    private var activeCache: [String: Double]
    private let lock = NSLock()

    /// Tables de probabilités pré-extraites de `activeCache`.
    /// Elles ne changent qu'à l'activation d'une nouvelle config distante (une fois par session
    /// au plus) : les recalculer ici évite de refaire, à chaque canard généré, les allocations de
    /// clés et les lectures verrouillées du dictionnaire. Contenu identique à `getDouble`.
    private var rarityTable: RarityProbabilityTable
    private var sizeTable: SizeProbabilityTable
    private var mutationTable: MutationProbabilityTable

    private init() {
        activeCache = defaults
        rarityTable = RemoteConfigManager.makeRarityTable(from: defaults)
        sizeTable = RemoteConfigManager.makeSizeTable(from: defaults)
        mutationTable = RemoteConfigManager.makeMutationTable(from: defaults)
    }

    // MARK: - Cycle de vie

    /// À appeler une fois au démarrage, juste après `FirebaseApp.configure()`.
    func configure() {
        #if canImport(FirebaseRemoteConfig)
        let rc = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0          // Debug : voir les changements immédiatement
        #else
        settings.minimumFetchInterval = 3600       // Prod : au plus une fois par heure
        #endif
        rc.configSettings = settings

        rc.setDefaults(defaults.mapValues { NSNumber(value: $0) })

        // Récupération silencieuse en arrière-plan ; en cas d'échec, on garde les défauts/derniers connus.
        rc.fetchAndActivate { [weak self] _, _ in
            self?.refreshCache()
        }
        #endif
    }

    /// Recharge l'instantané depuis la config Firebase active.
    private func refreshCache() {
        #if canImport(FirebaseRemoteConfig)
        let rc = RemoteConfig.remoteConfig()
        var snapshot = defaults
        for key in defaults.keys {
            let value = rc.configValue(forKey: key).numberValue.doubleValue
            snapshot[key] = value
        }
        // Les tables sont reconstruites hors verrou puis publiées en même temps que l'instantané :
        // un tirage voit donc toujours un jeu de probabilités cohérent, comme avant.
        let newRarityTable = RemoteConfigManager.makeRarityTable(from: snapshot)
        let newSizeTable = RemoteConfigManager.makeSizeTable(from: snapshot)
        let newMutationTable = RemoteConfigManager.makeMutationTable(from: snapshot)
        lock.lock()
        activeCache = snapshot
        rarityTable = newRarityTable
        sizeTable = newSizeTable
        mutationTable = newMutationTable
        lock.unlock()
        #endif
    }

    // MARK: - Construction des tables

    /// `values` contient toujours au moins toutes les clés de `defaults` (l'instantané part des
    /// défauts), donc le repli `?? 0.0` reproduit exactement le comportement de `getDouble`.
    private static func makeRarityTable(from values: [String: Double]) -> RarityProbabilityTable {
        RarityProbabilityTable(
            commun: values[RCKey.probRarityCommun] ?? 0.0,
            peuCommun: values[RCKey.probRarityPeuCommun] ?? 0.0,
            rare: values[RCKey.probRarityRare] ?? 0.0,
            epique: values[RCKey.probRarityEpique] ?? 0.0,
            legendaire: values[RCKey.probRarityLegendaire] ?? 0.0,
            mythique: values[RCKey.probRarityMythique] ?? 0.0,
            exotique: values[RCKey.probRarityExotique] ?? 0.0,
            celeste: values[RCKey.probRarityCeleste] ?? 0.0,
            primordiale: values[RCKey.probRarityPrimordiale] ?? 0.0
        )
    }

    private static func makeSizeTable(from values: [String: Double]) -> SizeProbabilityTable {
        SizeProbabilityTable(
            petit: values[RCKey.probSizePetit] ?? 0.0,
            moyen: values[RCKey.probSizeMoyen] ?? 0.0,
            grand: values[RCKey.probSizeGrand] ?? 0.0,
            geant: values[RCKey.probSizeGeant] ?? 0.0,
            colossal: values[RCKey.probSizeColossal] ?? 0.0
        )
    }

    private static func makeMutationTable(from values: [String: Double]) -> MutationProbabilityTable {
        MutationProbabilityTable(
            aucune: values[RCKey.probMutationAucune] ?? 0.0,
            dore: values[RCKey.probMutationDore] ?? 0.0,
            radioactif: values[RCKey.probMutationRadioactif] ?? 0.0,
            cristallise: values[RCKey.probMutationCristallise] ?? 0.0,
            quantique: values[RCKey.probMutationQuantique] ?? 0.0
        )
    }

    // MARK: - Lecture

    /// Probabilités de rareté en une seule prise de verrou (aucune allocation).
    func rarityProbabilities() -> RarityProbabilityTable {
        lock.lock(); defer { lock.unlock() }
        return rarityTable
    }

    /// Probabilités de taille en une seule prise de verrou (aucune allocation).
    func sizeProbabilities() -> SizeProbabilityTable {
        lock.lock(); defer { lock.unlock() }
        return sizeTable
    }

    /// Probabilités de mutation en une seule prise de verrou (aucune allocation).
    func mutationProbabilities() -> MutationProbabilityTable {
        lock.lock(); defer { lock.unlock() }
        return mutationTable
    }

    /// Valeur Double pour une clé connue (défaut embarqué si absente/hors-ligne).
    func getDouble(_ key: String) -> Double {
        lock.lock(); defer { lock.unlock() }
        if let v = activeCache[key] { return v }
        return defaults[key] ?? 0.0
    }

    /// Valeur Double pour une clé dynamique (template par id) avec fallback explicite.
    func getDouble(_ key: String, default fallback: Double) -> Double {
        #if canImport(FirebaseRemoteConfig)
        lock.lock()
        if let v = activeCache[key] { lock.unlock(); return v }
        lock.unlock()
        // Clé hors instantané (id dynamique) : lecture directe, sinon fallback.
        let rc = RemoteConfig.remoteConfig()
        let cv = rc.configValue(forKey: key)
        if cv.source == .remote, let num = Double(exactly: cv.numberValue) {
            return num
        }
        return fallback
        #else
        lock.lock(); defer { lock.unlock() }
        return activeCache[key] ?? fallback
        #endif
    }

    func getInt(_ key: String) -> Int { Int(getDouble(key)) }

    func getInt(_ key: String, default fallback: Int) -> Int {
        Int(getDouble(key, default: Double(fallback)))
    }
}
