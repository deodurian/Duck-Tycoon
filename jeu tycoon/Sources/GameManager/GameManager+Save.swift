import SwiftUI

extension GameManager {
    // MARK: - Sauvegarde Professionnelle (JSON Local)
    
    func loadGame() {
        let url = saveFileURL()
        let backupUrl = url.appendingPathExtension("bak")
        
        // CE QUI COÛTAIT : le fichier principal était décodé DEUX fois — une première fois « pour
        // tester » qu'il n'était pas corrompu, puis une seconde fois pour de bon. Sur une partie
        // avancée c'est un décodage JSON complet (inventaire + usines + perks, plusieurs Mo) payé
        // intégralement pour rien au lancement, sur le thread principal.
        // POURQUOI LE RENDU RESTE IDENTIQUE : on conserve simplement le résultat de la première
        // tentative. Les règles de repli sont inchangées (fichier principal, puis .bak, puis
        // abandon silencieux), le décodage est déterministe, et aucune propriété n'est écrite tant
        // qu'un état n'a pas été décodé avec succès — exactement comme avant.
        let decoder = JSONDecoder()
        var decodedState: GameState? = nil

        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                decodedState = try decoder.decode(GameState.self, from: data)
            } catch {
                decodedState = nil
            }
        }

        if decodedState == nil && FileManager.default.fileExists(atPath: backupUrl.path) {
            do {
                let data = try Data(contentsOf: backupUrl)
                decodedState = try decoder.decode(GameState.self, from: data)
            } catch {
                // Silently ignore corrupted backup
            }
        }

        guard let loadedState = decodedState else { return }

        // (Plus de `do/catch` ici : le décodage — seule opération qui pouvait échouer — a déjà eu
        // lieu au-dessus. Les affectations ci-dessous sont exactement les mêmes, dans le même ordre.)
        money = loadedState.money
        mutationPoints = loadedState.mutationPoints
        inventory = loadedState.inventory
        factories = loadedState.factories
        lastSaveDate = loadedState.lastSaveDate
        purchasedUpgrades = loadedState.purchasedUpgrades
        upgradeLevels = loadedState.upgradeLevels
        autoCrateTargetId = loadedState.autoCrateTargetId
        autoFactoryLevels = loadedState.autoFactoryLevels

        // Migration pour les étoiles
        currentStars = loadedState.currentStars
        totalStars = loadedState.totalStars
        spentStars = loadedState.spentStars
        unspentStars = loadedState.unspentStars
        purchasedPrestigeUpgrades = loadedState.purchasedPrestigeUpgrades

        gems = loadedState.gems

        starsInEnergy = loadedState.starsInEnergy
        starsInMutagen = loadedState.starsInMutagen
        starsInOptimization = loadedState.starsInOptimization
        reactorCooldownEndTime = loadedState.reactorCooldownEndTime

        playerLevel = loadedState.playerLevel
        playerXP = loadedState.playerXP
        missions = loadedState.missions
        perksInventory = loadedState.perksInventory
        migrateRemovedPerks()
        invalidatePerkCache()

        currentStoryStep = loadedState.currentStoryStep
        isStoryQuestReadyToClaim = loadedState.isStoryQuestReadyToClaim
        storyFlags = loadedState.storyFlags

        // Statistiques cumulées (nécessaires aux quêtes secondaires)
        totalRecycledDucks = loadedState.totalRecycledDucks
        totalFusionsDone = loadedState.totalFusionsDone
        totalMaxedRepeatableUpgrades = loadedState.totalMaxedRepeatableUpgrades

        // Quêtes Secondaires
        totalDucksFromCrates = loadedState.totalDucksFromCrates
        claimedSideQuestIds = loadedState.claimedSideQuestIds

        // Migration V2 : insertion de l'étape « Auto-Fusion » avant l'Anomalie.
        // Les sauvegardes arrivées à l'Anomalie (>= 6) sont décalées d'un cran.
        if loadedState.storyVersion < 2 && currentStoryStep >= 6 {
            currentStoryStep += 1
        }
        storyVersion = 2

        // Ads
        adBoostMultiplier = loadedState.adBoostMultiplier
        adBoostEndTime = loadedState.adBoostEndTime
        nextMysteryCrateDate = loadedState.nextMysteryCrateDate
        dailyAdGemsCount = loadedState.dailyAdGemsCount
        lastAdGemsDate = loadedState.lastAdGemsDate

        // Collection (Compendium)
        unlockedDucks = loadedState.unlockedDucks
        discoveredPerks = loadedState.discoveredPerks
        claimedRarityCollections = loadedState.claimedRarityCollections
        claimedAllDucksCollection = loadedState.claimedAllDucksCollection
        claimedAllPerksCollection = loadedState.claimedAllPerksCollection

        invalidateEarningsCache()
        calculateOfflineEarnings()
        evaluateAffordableCrates(reset: true)
    }
    
    /// Taux passifs par seconde (argent et ADN) générés par les usines avec canards assignés.
    /// Utilisé pour les gains hors-ligne et le time travel du mode développeur.
    func computePassiveRates() -> (earningsPerSecond: BigNumber, mutationsPerSecond: BigNumber) {
        var earningsPerSecond: BigNumber = .zero
        var mutationsPerSecond: BigNumber = .zero

        // CE QUI COÛTAIT (temps de lancement pur, sur le thread principal) :
        // - `inventory.first { $0.id == id }` refaisait un scan linéaire de TOUT l'inventaire pour
        //   chaque canard assigné → O(usines × canards assignés × inventaire) alors qu'un index
        //   canard-assigné existe déjà (`getAssignedDuck(id:)`, reconstruit une seule fois) ;
        // - `perksInventory.first { ... }` refaisait un scan linéaire de l'inventaire de perks
        //   alors que l'index O(1) `perks(for:)` existe ;
        // - `perkPowerMultiplier` et `mutationMultiplier` étaient réévalués à chaque usine (chacun
        //   prend le NSLock de RemoteConfig), et `earningsMultiplier` à chaque canard via
        //   `displaySellValue`.
        // POURQUOI LE RENDU RESTE IDENTIQUE : ce sont les mêmes canards, résolus dans le même ordre
        // (compactMap sur `assignedDuckIds`, ids introuvables ignorés de la même façon), les mêmes
        // perks, et des multiplicateurs globaux invariants sur toute la passe. C'est exactement la
        // source de données qu'utilise déjà la boucle de jeu (`tick`).
        let ppm = perkPowerMultiplier
        let earningsMult = earningsMultiplier
        let collectionBonus = collectionDuckBonusMultiplier
        let mutMult = mutationMultiplier

        for factory in factories {
            if !factory.assignedDuckIds.isEmpty {
                let ducks = factory.assignedDuckIds.compactMap { getAssignedDuck(id: $0) }
                let displayValues = ducks.map {
                    displaySellValue(for: $0, earningsMult: earningsMult, perkPower: ppm, collectionBonus: collectionBonus)
                }
                let factoryPerks = perks(for: factory.equippedPerkIds)

                earningsPerSecond += factory.calculateEarningsPerSecond(assignedDucks: ducks, duckDisplayValues: displayValues, factoryPerks: factoryPerks, perkPowerFactor: ppm)
                mutationsPerSecond += factory.calculateMutationsPerSecond(assignedDucks: ducks, globalBonus: mutMult, factoryPerks: factoryPerks)
            }
        }
        return (earningsPerSecond, mutationsPerSecond)
    }

    private func calculateOfflineEarnings() {
        let rawSecondsOffline = Date().timeIntervalSince(lastSaveDate)
        guard rawSecondsOffline > 60 else { return } // On ignore si c'est moins d'une minute

        // Plafond de cumul des gains hors-ligne (pilotable à distance, 12 h par défaut).
        // max(0) : une valeur négative (mauvaise config) donnerait des gains négatifs.
        let maxHours = max(0.0, RemoteConfigManager.shared.getDouble(RCKey.offlineEarningsMaxHours))
        let secondsOffline = min(rawSecondsOffline, maxHours * 3600.0)

        let (earningsPerSecond, mutationsPerSecond) = computePassiveRates()

        let totalOfflineEarnings = earningsPerSecond * secondsOffline
        let totalOfflineMutations = mutationsPerSecond * secondsOffline
        
        let offlineXpRate = PlayerLevelSystem.calculatePassiveXP(earningsPerSecond: earningsPerSecond)
        let totalOfflineXP = offlineXpRate * Int(secondsOffline)

        // Pas de popup s'il n'y a rien à réclamer (ex: premier lancement, aucun canard assigné)
        guard totalOfflineEarnings > .zero || totalOfflineMutations > .zero || totalOfflineXP > 0 else { return }

        // On ne l'ajoute pas directement, on le stocke dans le popup
        pendingOfflineEarnings = OfflineEarnings(money: totalOfflineEarnings, dna: totalOfflineMutations, xp: totalOfflineXP, seconds: secondsOffline)
    }
    
    func claimOfflineEarnings(multiplier: Double) {
        guard let earnings = pendingOfflineEarnings else { return }
        
        // 1. Ajouter l'argent, l'ADN multiplié, et l'XP
        money += earnings.money * multiplier
        addMutationPoints(earnings.dna * multiplier)
        playerXP += Int(Double(earnings.xp) * multiplier)
        checkLevelUp()
        
        let secondsOffline = earnings.seconds
        
        // 2. Lancer l'automatisation avec le *nouveau* solde !
        // Pour estimer le earningsPerSecond original pour l'automatisation, on le recalcule (ou on le déduit)
        let earningsPerSecond = earnings.money / secondsOffline
        processOfflineAutomation(secondsPassed: secondsOffline, earningsPerSecond: earningsPerSecond.doubleValue)
        
        // 3. Fermer le popup
        pendingOfflineEarnings = nil
        saveGame()
    }
    
    /// Remplace les perks des familles retirées du jeu (Chance de Capsule, Ascension) par un perk
    /// aléatoire du même type et de la même rareté.
    /// L'UUID est CONSERVÉ : un perk déjà équipé sur un canard ou une usine le reste.
    func migrateRemovedPerks() {
        let removedFamilies: Set<PerkFamily> = [.crateLuck, .rarityUpgrade]
        var didMigrate = false

        for (index, perk) in perksInventory.enumerated() where removedFamilies.contains(perk.family) {
            let replacement = Perk.rollRandom(type: perk.type, forcedRarity: perk.rarity)
            perksInventory[index] = Perk(
                id: perk.id,
                type: perk.type,
                rarity: perk.rarity,
                family: replacement.family,
                target: replacement.target
            )
            registerPerkDiscovery(perksInventory[index])
            didMigrate = true
        }

        if didMigrate {
            invalidatePerkCache()
            invalidateEarningsCache()
        }
    }

    /// URL du fichier de sauvegarde, résolue UNE seule fois.
    ///
    /// CE QUI COÛTAIT : `FileManager.default.urls(for:in:)` interroge NSFileManager et alloue un
    /// tableau d'URL à chaque appel, suivi d'un `appendingPathComponent` (nouvelle URL). C'était
    /// payé sur le thread principal à chaque `saveGame()` — appelé depuis une soixantaine
    /// d'endroits, dont plusieurs sur le chemin du tick — alors que le dossier Documents ne change
    /// jamais pendant la vie du processus.
    ///
    /// POURQUOI LE RENDU RESTE IDENTIQUE : c'est rigoureusement la même URL, produite par le même
    /// code, simplement mémorisée. Le fichier écrit, son chemin, le moment des sauvegardes et leur
    /// contenu sont inchangés.
    private static let cachedSaveFileURL: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("CanardFactorySave.json")
    }()

    private func saveFileURL() -> URL {
        GameManager.cachedSaveFileURL
    }
    

    
    func saveGame(sync: Bool = false) {
        invalidateEarningsCache()

        // Annuler la sauvegarde précédente si elle n'a pas encore été exécutée
        saveWorkItem?.cancel()

        // Capturer un instantané COMPLET de l'état sur le main thread.
        // On réutilise la propriété `state` pour ne jamais oublier un champ (Histoire, stats, etc.).
        var snapshot = self.state
        let url = saveFileURL()

        let workItem = DispatchWorkItem { [weak self] in
            snapshot.lastSaveDate = Date() // heure réelle de sauvegarde (pour les gains hors-ligne)
            do {
                let data = try JSONEncoder().encode(snapshot)
                let backupUrl = url.appendingPathExtension("bak")
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: backupUrl)
                    try? FileManager.default.copyItem(at: url, to: backupUrl)
                }
                try data.write(to: url, options: [.atomic])
            } catch {
                // Silently handle save error
            }
            DispatchQueue.main.async { self?.lastDiskWriteDate = Date() }
        }
        saveWorkItem = workItem
        if sync {
            workItem.perform()
            lastDiskWriteDate = Date()
        } else {
            // Coalescence des écritures.
            //
            // `saveGame()` est appelé depuis ~60 endroits, dont plusieurs sur le chemin du tick
            // (montée de niveau, missions validées, automatisation…). Chaque appel ré-encodait
            // TOUT l'état en JSON (jusqu'à plusieurs Mo sur une grosse partie) et recopiait le
            // fichier de sauvegarde : sur une partie avancée, l'encodeur tournait quasiment sans
            // interruption. On garantit maintenant une fenêtre minimale entre deux écritures
            // réelles ; les appels intermédiaires ne font que remplacer l'instantané en attente.
            // Les sauvegardes critiques (passage en arrière-plan) passent par `sync: true`.
            let elapsed = Date().timeIntervalSince(lastDiskWriteDate)
            let delay = min(Self.minimumSaveInterval, max(0.5, Self.minimumSaveInterval - elapsed))
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    /// Fenêtre minimale entre deux écritures disque (hors sauvegarde synchrone).
    static var minimumSaveInterval: TimeInterval { 8.0 }
    
    func resetProgression() {
        let defaultState = GameState()
        
        money = defaultState.money
        mutationPoints = defaultState.mutationPoints
        inventory = defaultState.inventory
        factories = defaultState.factories
        
        autoCrateTargetId = defaultState.autoCrateTargetId
        autoFactoryLevels = defaultState.autoFactoryLevels
        
        purchasedUpgrades = defaultState.purchasedUpgrades
        upgradeLevels = defaultState.upgradeLevels
        
        totalRecycledDucks = defaultState.totalRecycledDucks
        totalFusionsDone = defaultState.totalFusionsDone
        totalMaxedRepeatableUpgrades = defaultState.totalMaxedRepeatableUpgrades

        currentStars = defaultState.currentStars
        totalStars = defaultState.totalStars
        spentStars = defaultState.spentStars
        unspentStars = defaultState.unspentStars
        purchasedPrestigeUpgrades = defaultState.purchasedPrestigeUpgrades

        gems = defaultState.gems

        starsInEnergy = defaultState.starsInEnergy
        starsInMutagen = defaultState.starsInMutagen
        starsInOptimization = defaultState.starsInOptimization
        reactorCooldownEndTime = defaultState.reactorCooldownEndTime
        
        playerLevel = defaultState.playerLevel
        playerXP = defaultState.playerXP
        missions = defaultState.missions
        perksInventory = defaultState.perksInventory
        invalidatePerkCache()

        currentStoryStep = defaultState.currentStoryStep
        isStoryQuestReadyToClaim = defaultState.isStoryQuestReadyToClaim
        storyFlags = defaultState.storyFlags

        totalDucksFromCrates = defaultState.totalDucksFromCrates
        claimedSideQuestIds = defaultState.claimedSideQuestIds
        storyVersion = defaultState.storyVersion
        
        adBoostMultiplier = defaultState.adBoostMultiplier
        adBoostEndTime = defaultState.adBoostEndTime
        nextMysteryCrateDate = defaultState.nextMysteryCrateDate
        dailyAdGemsCount = defaultState.dailyAdGemsCount
        lastAdGemsDate = defaultState.lastAdGemsDate

        unlockedDucks = defaultState.unlockedDucks
        discoveredPerks = defaultState.discoveredPerks
        claimedRarityCollections = defaultState.claimedRarityCollections
        claimedAllDucksCollection = defaultState.claimedAllDucksCollection
        claimedAllPerksCollection = defaultState.claimedAllPerksCollection
        syncCollectionWithCurrentState()

        lastSaveDate = Date()
        pendingOfflineEarnings = nil

        invalidateEarningsCache()
        evaluateAffordableCrates(reset: true)

        saveGame()
    }
    
}
