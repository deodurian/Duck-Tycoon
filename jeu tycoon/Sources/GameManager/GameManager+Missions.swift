import Foundation

extension GameManager {
    
    func initializeTutorialMissions() {
        guard missions.filter({ $0.type == .intro }).isEmpty else { return } // Déjà initialisé
        
        let introMissions = [
            Mission(id: "intro_1", title: "Le Commencement", description: "Ouvrir une caisse en bois", type: .intro, actionType: .openWoodenCrate, targetProgress: BigNumber(1), rewardXP: 50),
            Mission(id: "intro_2", title: "Au Travail", description: "Équiper un canard dans une usine", type: .intro, actionType: .assignDuckToFactory, targetProgress: BigNumber(1), rewardXP: 100),
            Mission(id: "intro_3", title: "Développement", description: "Améliorer 10 fois une usine", type: .intro, actionType: .upgradeFactory, targetProgress: BigNumber(10), rewardXP: 150),
            Mission(id: "intro_4", title: "Fournisseur", description: "Ouvrir 10 caisses", type: .intro, actionType: .openCrates, targetProgress: BigNumber(10), rewardXP: 200),
            Mission(id: "intro_5", title: "Tri Sélectif", description: "Recycler 1 canard", type: .intro, actionType: .recycleDuck, targetProgress: BigNumber(1), rewardXP: 150),
            Mission(id: "intro_6", title: "Science !", description: "Débloquer le labo de fusion", type: .intro, actionType: .unlockFusionLab, targetProgress: BigNumber(1), rewardXP: 300),
            Mission(id: "intro_7", title: "Mutation", description: "Faire une fusion de canard commun", type: .intro, actionType: .fuseCommonDuck, targetProgress: BigNumber(1), rewardXP: 300),
            Mission(id: "intro_8", title: "Capitaliste", description: "Atteindre une production de 300 d'argent par seconde", type: .intro, actionType: .reachIncome, targetProgress: BigNumber(300), rewardXP: 400),
            Mission(id: "intro_9", title: "Boucher", description: "Avoir recyclé au moins 30 canards jusqu'à présent", type: .intro, actionType: .totalRecycleCount, targetProgress: BigNumber(30), rewardXP: 500),
            Mission(id: "intro_10", title: "Gavage", description: "Augmenter la taille de 3 canards", type: .intro, actionType: .upgradeDuckSize, targetProgress: BigNumber(3), rewardXP: 600),
            Mission(id: "intro_11", title: "Anomalie", description: "Augmenter la mutation d'un canard", type: .intro, actionType: .upgradeDuckMutation, targetProgress: BigNumber(1), rewardXP: 600),
            Mission(id: "intro_12", title: "Vétéran", description: "Mettre un canard niveau 20", type: .intro, actionType: .reachDuckLevel, targetProgress: BigNumber(20), rewardXP: 700),
            Mission(id: "intro_13", title: "Grand Ménage", description: "Faire un recyclage de masse", type: .intro, actionType: .bulkRecycle, targetProgress: BigNumber(1), rewardXP: 800),
            Mission(id: "intro_14", title: "Arbre de Compétences", description: "Débloquer 5 améliorations « déblocages » de plus", type: .intro, actionType: .unlockUpgrades, targetProgress: BigNumber(5), rewardXP: 1000),
            Mission(id: "intro_15", title: "Automatisation", description: "Faire une auto fusion", type: .intro, actionType: .autoFusion, targetProgress: BigNumber(1), rewardXP: 1200),
            Mission(id: "intro_16", title: "La Totale", description: "Faire une mega fusion", type: .intro, actionType: .megaFusion, targetProgress: BigNumber(1), rewardXP: 1500),
            Mission(id: "intro_17", title: "Unboxing", description: "Faire une ouverture multiple d'au moins 150 canards", type: .intro, actionType: .bulkOpenCrates, targetProgress: BigNumber(150), rewardXP: 1800),
            Mission(id: "intro_18", title: "Millionnaire", description: "Atteindre 1M d'argent/sec", type: .intro, actionType: .reachIncome, targetProgress: BigNumber(1_000_000), rewardXP: 2000),
            Mission(id: "intro_19", title: "Culte", description: "Faire un rituel canarifique", type: .intro, actionType: .ritual, targetProgress: BigNumber(1), rewardXP: 2500),
            Mission(id: "intro_20", title: "Elite", description: "Attribuer 5 canards de niveau au moins 30 à 5 usines de niveau au moins 30", type: .intro, actionType: .assignHighLevelDucks, targetProgress: BigNumber(5), rewardXP: 3000),
            Mission(id: "intro_21", title: "Équipement", description: "Attribuer un perk à une usine ou un canard", type: .intro, actionType: .assignPerk, targetProgress: BigNumber(1), rewardXP: 3500),
            Mission(id: "intro_22", title: "Destructeur", description: "Avoir recyclé depuis le début au moins 50K canards", type: .intro, actionType: .totalRecycleCount, targetProgress: BigNumber(50_000), rewardXP: 5000),
            Mission(id: "intro_23", title: "Savoir Absolu", description: "Avoir débloqué au moins 15 améliorations jusque là", type: .intro, actionType: .unlockUpgrades, targetProgress: BigNumber(15), rewardXP: 6000),
            Mission(id: "intro_24", title: "Multimillionnaire", description: "Avoir au moins 50M d'argent/sec", type: .intro, actionType: .reachIncome, targetProgress: BigNumber(50_000_000), rewardXP: 10000)
        ]
        
        missions.append(contentsOf: introMissions)
    }
    
    func initializeDailyMissions() {
        // Enlève les anciennes quotidiennes
        missions.removeAll(where: { $0.type == .daily })
        
        let dailyMissions = [
            Mission(id: "daily_1", title: "Ouverture Quotidienne", description: "Ouvrir 10 caisses", type: .daily, actionType: .openCrates, targetProgress: BigNumber(10)),
            Mission(id: "daily_2", title: "Recyclage Quotidien", description: "Recycler 10 canards", type: .daily, actionType: .recycleDuck, targetProgress: BigNumber(10)),
            Mission(id: "daily_3", title: "Fusion Quotidienne", description: "Faire 10 fusions", type: .daily, actionType: .fuseCommonDuck, targetProgress: BigNumber(10)),
            Mission(id: "daily_4", title: "Rituel Quotidien", description: "Faire un rituel canarifique", type: .daily, actionType: .ritual, targetProgress: BigNumber(1)),
            Mission(id: "daily_5", title: "Achats Quotidiens", description: "Acheter 10 améliorations", type: .daily, actionType: .unlockUpgrades, targetProgress: BigNumber(10)),
            Mission(id: "daily_6", title: "Niveaux Quotidiens", description: "Monter de 20 niveaux soit un canard soit une usine", type: .daily, actionType: .reachDuckLevel, targetProgress: BigNumber(20)),
            Mission(id: "daily_7", title: "Le Grand Chelem", description: "Avoir fait toutes les missions quotidiennes précédentes", type: .daily, actionType: .none, targetProgress: BigNumber(1))
        ]
        
        missions.append(contentsOf: dailyMissions)
    }
    
    func checkDailyMissionsReset() {
        let lastReset = UserDefaults.standard.double(forKey: "lastDailyMissionReset")
        let now = Date().timeIntervalSince1970
        let secondsInDay: Double = 86400
        
        if now - lastReset > secondsInDay {
            initializeDailyMissions()
            UserDefaults.standard.set(now, forKey: "lastDailyMissionReset")
        }
    }
    
    func emitMissionEvent(_ type: MissionActionType, amount: BigNumber = BigNumber(1)) {
        let firstActiveIntroIndex = missions.firstIndex(where: { $0.type == .intro && $0.status != .claimed && $0.status != .completed })
        
        for index in missions.indices {
            let mission = missions[index]
            
            let isActiveDaily = mission.type == .daily && mission.status != .claimed && mission.status != .completed
            let isActiveIntro = (index == firstActiveIntroIndex)
            
            guard isActiveDaily || isActiveIntro else { continue }
            
            if missions[index].status == .notStarted {
                missions[index].status = .inProgress
            }
            
            if missions[index].actionType == type {
                missions[index].currentProgress += amount
                
                if missions[index].currentProgress >= missions[index].targetProgress {
                    missions[index].currentProgress = missions[index].targetProgress
                    missions[index].status = .completed
                    
                    // Si on vient de finir une mission quotidienne, on vérifie la mission 7
                    if missions[index].type == .daily {
                        checkDaily7Completion()
                    }
                }
            }
        }
    }
    
    private func checkDaily7Completion() {
        let dailyMissions = missions.filter { $0.type == .daily && $0.id != "daily_7" }
        let allCompleted = dailyMissions.allSatisfy { $0.status == .completed || $0.status == .claimed }
        
        if allCompleted {
            if let index = missions.firstIndex(where: { $0.id == "daily_7" }) {
                missions[index].currentProgress = BigNumber(1)
                missions[index].status = .completed
            }
        }
    }
    
    func claimMission(id: String) {
        if let index = missions.firstIndex(where: { $0.id == id }) {
            missions[index].status = .claimed
            playerXP += missions[index].rewardXP
            checkLevelUp()
            
            // Si on vient de réclamer une mission d'intro, la suivante devient active
            // On vérifie tout de suite l'état pour que la nouvelle puisse s'auto-valider si on a déjà les prérequis
            if missions[index].type == .intro {
                verifyStateMissions()
            }
        }
    }
    
    // MARK: - State Check Missions
    func verifyStateMissions() {
        let firstActiveIntroIndex = missions.firstIndex(where: { $0.type == .intro && $0.status != .claimed && $0.status != .completed })
        
        for index in missions.indices {
            let mission = missions[index]
            
            let isActiveDaily = mission.type == .daily && mission.status != .claimed && mission.status != .completed
            let isActiveIntro = (index == firstActiveIntroIndex)
            
            guard isActiveDaily || isActiveIntro else { continue }
            
            if missions[index].status == .notStarted {
                missions[index].status = .inProgress
            }
            
            var progressToSet: BigNumber? = nil
            
            switch mission.actionType {
            case .reachIncome:
                progressToSet = cachedEarningsPerSecond ?? .zero
            case .totalRecycleCount:
                progressToSet = BigNumber(totalRecycledDucks)
            case .totalFusionCount:
                progressToSet = BigNumber(totalFusionsDone)
            case .haveMaxMythicDuck:
                // Vérifier si on a un canard mythique de niveau >= mission.targetProgress
                // But typically it just checks if there is any mythic duck that is level 100 etc. Let's say level 100 mythic.
                let hasMythic = inventory.contains(where: { $0.rarity == .mythique && $0.level >= 100 })
                progressToSet = hasMythic ? BigNumber(1) : .zero
            case .assignHighLevelDucks:
                // Attribuer 5 canards lvl 30+ à 5 usines lvl 30+
                var validCount = 0
                for factory in factories where factory.level >= 30 {
                    let assignedDucks = factory.assignedDuckIds.compactMap { id in inventory.first { $0.id == id } }
                    if assignedDucks.contains(where: { $0.level >= 30 }) {
                        validCount += 1
                    }
                }
                progressToSet = BigNumber(validCount)
            case .maxRepeatableUpgrades:
                progressToSet = BigNumber(totalMaxedRepeatableUpgrades)
            case .unlockUpgrades:
                progressToSet = BigNumber(purchasedUpgrades.count)
            default:
                break
            }
            
            if let newProgress = progressToSet {
                if newProgress > missions[index].currentProgress {
                    missions[index].currentProgress = newProgress
                }
                if missions[index].currentProgress >= missions[index].targetProgress {
                    missions[index].currentProgress = missions[index].targetProgress
                    missions[index].status = .completed
                    
                    if missions[index].type == .daily {
                        checkDaily7Completion()
                    }
                }
            }
        }
    }
    
    // MARK: - Vérifications passives pour certaines missions (appelées dans la boucle de jeu ou au chargement)
    func passiveMissionChecks() {
        for index in missions.indices where missions[index].status == .inProgress {
            let m = missions[index]
            
            if m.actionType == .reachIncome {
                if let eps = cachedEarningsPerSecond, eps >= m.targetProgress {
                    completeMission(at: index)
                }
            } else if m.id == "intro_20" {
                // 5 canards lvl 30+ à 5 usines lvl 30+
                let eligibleFactories = factories.filter { factory in
                    if factory.level >= 30 {
                        let highLevelDucksCount = factory.assignedDuckIds.filter { duckId in
                            if let duck = inventory.first(where: { $0.id == duckId }) {
                                return duck.level >= 30
                            }
                            return false
                        }.count
                        return highLevelDucksCount > 0
                    }
                    return false
                }
                if eligibleFactories.count >= 5 {
                    completeMission(at: index)
                }
            }
        }
    }
    
    private func completeMission(at index: Int) {
        missions[index].currentProgress = missions[index].targetProgress
        missions[index].status = .completed
    }
}
