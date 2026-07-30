import Foundation

// MARK: - Compendium (Collection)

/// Une entrée collectionnable du Pokédex des Perks : une combinaison Type + Famille + Rareté
/// existant réellement dans les tables de génération (Perk.rollRandom).
struct PerkCollectionEntry: Identifiable, Hashable {
    let type: PerkType
    let family: PerkFamily
    let rarity: DuckRarity

    /// Clé de collection, calculée UNE fois à la construction.
    ///
    /// Coût évité : `id` était une propriété calculée qui reconstruisait une String (interpolation +
    /// allocation) à chaque lecture — or elle est lue pour les ~90 entrées à chaque test de complétude
    /// du Compendium et pour chaque cellule de la grille de la Collection. La chaîne produite est
    /// rigoureusement la même (même formule `perkCollectionKey`), donc l'identité des entrées, l'ordre
    /// d'affichage et les compteurs sont inchangés.
    let id: String

    init(type: PerkType, family: PerkFamily, rarity: DuckRarity) {
        self.type = type
        self.family = family
        self.rarity = rarity
        self.id = GameManager.perkCollectionKey(type: type, family: family, rarity: rarity)
    }

    /// Perk représentatif (pour récupérer nom et description existants)
    var samplePerk: Perk {
        // Cible représentative pour les familles qui en exigent une (affichage description)
        let target: PerkTarget?
        switch family {
        case .synergy: target = .commun
        case .fusion: target = .fusion2
        case .levelBoost: target = .commun
        default: target = nil
        }
        return Perk(type: type, rarity: rarity, family: family, target: target)
    }

    /// Toutes les combinaisons collectionnables, miroir exact des options de Perk.rollRandom.
    static let allEntries: [PerkCollectionEntry] = {
        var entries: [PerkCollectionEntry] = []

        let factoryFamilies: [(DuckRarity, [PerkFamily])] = [
            (.commun,     [.income, .synergy, .discount, .sacrifice, .stackBonus]),
            (.peuCommun,  [.income, .synergy, .discount, .sacrifice, .stackBonus]),
            (.rare,       [.income, .synergy, .discount, .sacrifice, .fusion, .stackBonus, .evolutionBoost, .mutationYield]),
            (.epique,     [.income, .synergy, .discount, .sacrifice, .fusion, .extraSlot, .stackBonus, .evolutionBoost, .mutationYield]),
            (.legendaire, [.income, .synergy, .discount, .sacrifice, .fusion, .extraSlot, .extraDuck, .stackBonus, .evolutionBoost, .mutationYield]),
            (.mythique,   [.mythicFactory])
        ]
        let duckFamilies: [(DuckRarity, [PerkFamily])] = [
            (.commun,     [.value, .levelBoost, .size]),
            (.peuCommun,  [.value, .levelBoost, .size, .mutation, .fusionWeight]),
            (.rare,       [.value, .levelBoost, .size, .mutation, .fusionWeight, .recycleMut]),
            (.epique,     [.value, .levelBoost, .size, .mutation, .fusionWeight, .recycleMut, .extraSlot]),
            (.legendaire, [.value, .levelBoost, .size, .mutation, .fusionWeight, .recycleMut, .extraSlot]),
            (.mythique,   [.mythicDuck])
        ]

        for (rarity, families) in factoryFamilies {
            for family in families {
                entries.append(PerkCollectionEntry(type: .factory, family: family, rarity: rarity))
            }
        }
        for (rarity, families) in duckFamilies {
            for family in families {
                entries.append(PerkCollectionEntry(type: .duck, family: family, rarity: rarity))
            }
        }
        return entries
    }()
}

extension GameManager {

    // MARK: - Clés de collection

    static func duckCollectionKey(rarity: DuckRarity, size: DuckSize) -> String {
        return "\(rarity.rawValue)_\(size.rawValue)"
    }

    static func perkCollectionKey(type: PerkType, family: PerkFamily, rarity: DuckRarity) -> String {
        return "\(type.rawValue)_\(family.rawValue)_\(rarity.rawValue)"
    }

    /// Les 45 clés de collection canard (9 raretés × 5 tailles), construites une seule fois.
    /// Coût évité : chaque test de complétude reconstruisait ces String par interpolation.
    /// Les chaînes sont identiques à celles de `duckCollectionKey`, donc les mêmes clés sont testées.
    static let duckCollectionKeysByRarity: [DuckRarity: [String]] = {
        var map: [DuckRarity: [String]] = [:]
        for rarity in DuckRarity.allCases {
            map[rarity] = GameManager.collectibleSizes.map {
                GameManager.duckCollectionKey(rarity: rarity, size: $0)
            }
        }
        return map
    }()

    /// Accès aux clés pré-calculées, avec repli sur le calcul d'origine (jamais atteint : la table
    /// est construite à partir de `DuckRarity.allCases`) pour garantir un résultat identique.
    static func duckCollectionKeys(for rarity: DuckRarity) -> [String] {
        duckCollectionKeysByRarity[rarity]
            ?? collectibleSizes.map { duckCollectionKey(rarity: rarity, size: $0) }
    }

    /// Les mêmes 45 clés, mises à plat (toutes raretés confondues), construites une seule fois.
    ///
    /// Coût évité : les tests globaux de collection parcouraient `DuckRarity.allCases` — un tableau
    /// ré-alloué à chaque lecture — puis faisaient un lookup de dictionnaire par rareté pour retrouver
    /// ses 5 clés. Le contenu est rigoureusement le même ensemble de clés (union des clés de chaque
    /// rareté, sans doublon possible puisque les `rawValue` de rareté sont distinctes), et l'ordre
    /// n'intervient ni dans un comptage ni dans un `allSatisfy`.
    static let allDuckCollectionKeys: [String] = DuckRarity.allCases.flatMap {
        GameManager.duckCollectionKeys(for: $0)
    }

    // MARK: - Enregistrement des découvertes

    func registerDuckDiscovery(rarity: DuckRarity, size: DuckSize) {
        let key = GameManager.duckCollectionKey(rarity: rarity, size: size)
        // CE QUI COÛTAIT : `unlockedDucks.insert(...)` passe par l'accesseur généré par @Observable et
        // signale donc une mutation MÊME quand la clé était déjà présente — c'est-à-dire quasiment
        // toujours (il n'existe que 45 silhouettes, et cette fonction est appelée pour chaque canard
        // produit, y compris par l'auto-fusion à chaque tick). Chaque fausse mutation prend le verrou
        // du registrar d'observation et réveille les vues qui lisent la Collection.
        // POURQUOI LE RENDU RESTE IDENTIQUE : `contains` est une simple LECTURE ; quand la clé est déjà
        // là, l'ancien code n'écrivait rien non plus (`inserted == false`). Ensemble final, badge
        // « nouveau canard » et pastille de récompense sont donc rigoureusement les mêmes.
        guard !unlockedDucks.contains(key) else { return }
        unlockedDucks.insert(key)
        hasUnseenCollectionDuck = true
        // Seule une silhouette réellement nouvelle peut rendre une récompense réclamable :
        // on ne recalcule le badge que dans ce cas (au plus 45 fois sur toute une partie).
        refreshClaimableCollectionReward()
    }

    func registerDuckDiscovery(_ duck: Duck) {
        registerDuckDiscovery(rarity: duck.rarity, size: duck.size)
    }

    func registerDuckDiscoveries(_ ducks: [Duck]) {
        // CE QUI COÛTAIT : les lots sont potentiellement énormes (ouverture de capsules en masse,
        // Méga Auto-Fusion sur tout l'inventaire, auto-fusion déclenchée à chaque tick). La boucle
        // touchait la propriété @Observable `unlockedDucks` — et donc le registrar d'observation —
        // une fois par canard, alors que l'ensemble des silhouettes ne peut changer qu'au plus
        // 45 fois sur toute la partie.
        // POURQUOI LE RENDU RESTE IDENTIQUE : on insère exactement les mêmes clés, dans une copie
        // locale, avant de publier l'ensemble final en une seule écriture ; `hasUnseenCollectionDuck`
        // passe à true dans exactement les mêmes cas (au moins une clé réellement nouvelle) ; et
        // `refreshClaimableCollectionReward()` est une fonction pure de l'état de collection, donc
        // l'appeler une fois sur l'état final donne la même valeur que le dernier appel de la boucle.
        var unlocked = unlockedDucks
        var didUnlockNewDuck = false
        for duck in ducks {
            let (inserted, _) = unlocked.insert(GameManager.duckCollectionKey(rarity: duck.rarity, size: duck.size))
            if inserted { didUnlockNewDuck = true }
        }
        guard didUnlockNewDuck else { return }
        unlockedDucks = unlocked
        hasUnseenCollectionDuck = true
        refreshClaimableCollectionReward()
    }

    func registerPerkDiscovery(_ perk: Perk) {
        let key = GameManager.perkCollectionKey(type: perk.type, family: perk.family, rarity: perk.rarity)
        let wasUndiscovered = (discoveredPerks[key] ?? 0) == 0
        discoveredPerks[key, default: 0] += 1
        // Incrémenter le compteur d'une entrée DÉJÀ découverte ne peut pas changer la complétude du
        // Compendium : on ne recalcule le badge que lors d'une vraie première découverte.
        if wasUndiscovered {
            refreshClaimableCollectionReward()
        }
    }

    /// Rattrapage / migration : enregistre tout ce que le joueur possède déjà.
    /// Appelé une fois au lancement (couvre les vieilles sauvegardes et le canard de départ).
    func syncCollectionWithCurrentState() {
        // Rattrapage en masse : l'inventaire peut contenir des milliers de canards. On accumule dans des
        // copies locales et on n'écrit les propriétés @Observable qu'UNE fois — chaque écriture dans la
        // boucle invalidait tous les observateurs pour rien. L'état final est rigoureusement identique.
        var unlocked = unlockedDucks
        var didUnlockNewDuck = false
        for duck in inventory {
            let (inserted, _) = unlocked.insert(GameManager.duckCollectionKey(rarity: duck.rarity, size: duck.size))
            if inserted { didUnlockNewDuck = true }
        }
        if didUnlockNewDuck {
            unlockedDucks = unlocked
            hasUnseenCollectionDuck = true
        }

        var discovered = discoveredPerks
        var didDiscoverNewPerk = false
        for perk in perksInventory {
            let key = GameManager.perkCollectionKey(type: perk.type, family: perk.family, rarity: perk.rarity)
            if discovered[key] == nil {
                discovered[key] = 1
                didDiscoverNewPerk = true
            }
        }
        if didDiscoverNewPerk {
            discoveredPerks = discovered
        }

        // Un SEUL recalcul du badge à la fin du rattrapage (et non un par canard parcouru).
        refreshClaimableCollectionReward()
    }

    // MARK: - Progression

    /// Tailles collectionnables (les 5 tailles du jeu).
    /// `static let` au lieu de `static var` calculée : `DuckSize.allCases` allouait un tableau à chaque
    /// lecture (et il y en a une par cellule de la grille de Collection). Contenu et ordre identiques.
    static let collectibleSizes: [DuckSize] = DuckSize.allCases

    var totalDuckCollectionSlots: Int {
        // Même valeur qu'avant (9 raretés × 5 tailles = 45 clés) mais sans ré-allouer les deux
        // tableaux `allCases` à chaque lecture : la table à plat contient exactement ces 45 clés.
        GameManager.allDuckCollectionKeys.count
    }

    var unlockedDuckCollectionCount: Int {
        // On compte uniquement les clés valides (au cas où une taille/rareté disparaîtrait).
        // Les clés sont pré-calculées : mêmes chaînes, mêmes tests, zéro String construite ici.
        // Table à plat : plus de tableau `DuckRarity.allCases` alloué ni de lookup par rareté ;
        // ce sont les mêmes 45 clés, et l'ordre n'a aucune incidence sur un comptage.
        var count = 0
        for key in GameManager.allDuckCollectionKeys where unlockedDucks.contains(key) {
            count += 1
        }
        return count
    }

    func isDuckUnlocked(rarity: DuckRarity, size: DuckSize) -> Bool {
        unlockedDucks.contains(GameManager.duckCollectionKey(rarity: rarity, size: size))
    }

    func isRarityCollectionComplete(_ rarity: DuckRarity) -> Bool {
        // Même test qu'avant (les 5 clés de la rareté sont-elles dans `unlockedDucks` ?),
        // mais sur les clés pré-calculées au lieu de 5 interpolations de String par appel.
        GameManager.duckCollectionKeys(for: rarity).allSatisfy { unlockedDucks.contains($0) }
    }

    func hasClaimedRarityCollection(_ rarity: DuckRarity) -> Bool {
        claimedRarityCollections.contains(rarity.rawValue)
    }

    var isDuckCollectionComplete: Bool {
        // Strictement le même test : « toutes les raretés sont complètes » équivaut à « les 45 clés
        // sont débloquées », la table à plat étant l'union exacte des clés de chaque rareté.
        // On économise l'allocation de `DuckRarity.allCases` et les 9 lookups de dictionnaire.
        GameManager.allDuckCollectionKeys.allSatisfy { unlockedDucks.contains($0) }
    }

    func perkDiscoveryCount(for entry: PerkCollectionEntry) -> Int {
        discoveredPerks[entry.id] ?? 0
    }

    var discoveredPerkCollectionCount: Int {
        // `filter { }.count` allouait un tableau intermédiaire de ~90 entrées à chaque lecture.
        // `reduce` compte la même chose sans allocation.
        PerkCollectionEntry.allEntries.reduce(into: 0) { total, entry in
            if perkDiscoveryCount(for: entry) > 0 { total += 1 }
        }
    }

    var isPerkCollectionComplete: Bool {
        PerkCollectionEntry.allEntries.allSatisfy { perkDiscoveryCount(for: $0) > 0 }
    }

    // MARK: - Récompenses

    /// +10 gemmes quand les silhouettes d'une rareté sont toutes débloquées
    func claimRarityCollection(rarity: DuckRarity) {
        guard isRarityCollectionComplete(rarity), !hasClaimedRarityCollection(rarity) else { return }
        claimedRarityCollections.insert(rarity.rawValue)
        gems += BigNumber(10)
        refreshClaimableCollectionReward()
        saveGame()
    }

    /// Récompense finale canards : +50% de revenus des canards et déblocage de la Capsule Secrète
    func claimAllDucksCollection() {
        guard isDuckCollectionComplete, !claimedAllDucksCollection else { return }
        claimedAllDucksCollection = true
        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)
        refreshClaimableCollectionReward()
        saveGame()
    }

    /// Récompense finale perks : +100 gemmes (et déblocage du perk secret, masqué jusqu'ici)
    func claimAllPerksCollection() {
        guard isPerkCollectionComplete, !claimedAllPerksCollection else { return }
        claimedAllPerksCollection = true
        gems += BigNumber(100)
        refreshClaimableCollectionReward()
        saveGame()
    }

    // MARK: - Badge de récompense réclamable (valeur dérivée mise en cache)

    /// Recalcule `hasClaimableCollectionReward` (voir GameManager.swift).
    ///
    /// Reprend à l'identique l'ancienne expression : « une récompense de rareté, la récompense finale
    /// canards ou la récompense finale perks est complète et non réclamée ». Les trois conditions sont
    /// pures et combinées par un OU logique : les tester dans un autre ordre (drapeaux booléens d'abord,
    /// puis complétude) donne exactement le même résultat pour un coût moindre.
    /// N'écrit la propriété que si la valeur change, pour ne pas invalider les observateurs pour rien.
    func refreshClaimableCollectionReward() {
        var newValue = false
        if !claimedAllDucksCollection, isDuckCollectionComplete {
            newValue = true
        } else if !claimedAllPerksCollection, isPerkCollectionComplete {
            newValue = true
        } else {
            for rarity in DuckRarity.allCases where !hasClaimedRarityCollection(rarity) {
                if isRarityCollectionComplete(rarity) {
                    newValue = true
                    break
                }
            }
        }

        if newValue != hasClaimableCollectionReward {
            hasClaimableCollectionReward = newValue
        }
    }

    /// Multiplicateur appliqué à la valeur des canards une fois la collection complète réclamée
    var collectionDuckBonusMultiplier: Double {
        claimedAllDucksCollection ? 1.5 : 1.0
    }
}
