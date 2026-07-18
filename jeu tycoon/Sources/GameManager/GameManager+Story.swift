import Foundation

struct StoryQuest {
    let title: String
    let description: String
    let rewardDescription: String
}

struct StoryStepInfo {
    let dialogue: String
    let quest: StoryQuest
    let unlocks: String
}

extension GameManager {
    
    var currentStoryInfo: StoryStepInfo? {
        return getStoryInfo(for: currentStoryStep)
    }
    
    func getStoryInfo(for step: Int) -> StoryStepInfo? {
        switch step {
        case 0:
            return StoryStepInfo(
                dialogue: "Ho salut tu es le nouveau gérant de la ferme je suis Anthony le scientifique. Avec l’ancien gérant ça a mal tourné quand on faisait des expériences et toutes les infrastructures sont détruites. Il faut que l’on reconstruise ça ensemble. Pour commencer la production, mets le dernier canard dans l'usine.",
                quest: StoryQuest(title: "La Production", description: "Assigner 1 canard dans l'usine", rewardDescription: "Débloque l'onglet Boutique"),
                unlocks: "Boutique"
            )
        case 1:
            return StoryStepInfo(
                dialogue: "Bravo, c’est la première étape d’un avenir radieux entre toi et les canards. Il nous faut maintenant plus de canards pour plus d’argent. J’ai fait livrer des caisses, va en ouvrir une en bois dans la boutique.",
                quest: StoryQuest(title: "Les Caisses", description: "Ouvrir 1 caisse en bois", rewardDescription: "Débloque l'onglet Inventaire"),
                unlocks: "Inventaire"
            )
        case 2:
            return StoryStepInfo(
                dialogue: "Bon, pendant que tu ouvrais des caisses j’ai eu le temps de réparer le bâtiment des améliorations, tu vas pouvoir booster tes gains. J’ai remarqué qu’il y a des canards trop normaux dans l’inventaire. Tu peux les améliorer mais cela coûte des points de mutation, que l’on obtient en détruisant (recyclant) nos précieux canards.",
                quest: StoryQuest(title: "Le Laboratoire", description: "Recycler 1 canard ET l'améliorer", rewardDescription: "50 ADN + Mécanique de Fusion"),
                unlocks: "Améliorations"
            )
        case 3:
            return StoryStepInfo(
                dialogue: "L'usine commence à être surpeuplée ! Plutôt que de jeter nos canards, j'ai bricolé un compresseur moléculaire. Si tu as trois canards identiques, écrase-les ensemble pour créer une version améliorée !",
                quest: StoryQuest(title: "La Fusion", description: "Effectuer 1 Fusion de canards", rewardDescription: "Débloque l'onglet Banque + 1 Puce gratuite"),
                unlocks: "Fusion"
            )
        case 4:
            return StoryStepInfo(
                dialogue: "La technologie, c'est fantastique. J'ai conçu des \"Perks\" (Puces technologiques). On peut les greffer directement sur le cerveau de nos canards ou dans le système de ventilation des usines. Va équiper celle que je viens de te donner !",
                quest: StoryQuest(title: "Les Perks", description: "Équiper 1 Perk", rewardDescription: "Débloque l'onglet Rituel"),
                unlocks: "Perks & Banque"
            )
        case 5:
            return StoryStepInfo(
                dialogue: "Euh... gérant ? En creusant pour agrandir le labo, on est tombés sur un vieil autel occulte. Il émet une énergie fascinante. J'ai une théorie : si on y sacrifie nos canards les plus rares, l'autel pourrait décupler leur valeur pour toujours. Prêt à tenter le diable ?",
                quest: StoryQuest(title: "L'Art Sombre", description: "Effectuer 1 Rituel avec succès", rewardDescription: "Débloque le Prestige"),
                unlocks: "Rituel"
            )
        case 6:
            return StoryStepInfo(
                dialogue: "[Anthony est paniqué] L'énergie occulte des rituels a fusionné avec la génétique des canards ! Un trou noir est en train de se former au centre de l'usine ! La seule solution pour sauver cette dimension est d'y précipiter toute notre entreprise. En échange, l'anomalie nous donnera des Étoiles d'Énergie Pure pour tout recommencer en mieux. On n'a pas le choix... clique sur Prestige !",
                quest: StoryQuest(title: "L'Anomalie", description: "Atteindre 10 Milliards $ et faire un Prestige", rewardDescription: "10 Gemmes + Quêtes Secondaires"),
                unlocks: "Prestige"
            )
        default:
            return nil
        }
    }
    
    // MARK: - Validation Checkers
    
    func checkStoryAction(_ action: String) {
        // Skip if story is over
        if currentStoryStep > 6 { return }
        
        switch currentStoryStep {
        case 0:
            if action == "assign_duck" { isStoryQuestReadyToClaim = true }
        case 1:
            if action == "open_wooden_crate" { isStoryQuestReadyToClaim = true }
        case 2:
            if action == "recycle_duck" { storyFlags["hasRecycled"] = true }
            if action == "upgrade_duck" { storyFlags["hasUpgraded"] = true }
            if storyFlags["hasRecycled"] == true && storyFlags["hasUpgraded"] == true {
                isStoryQuestReadyToClaim = true
            }
        case 3:
            if action == "fusion_duck" { isStoryQuestReadyToClaim = true }
        case 4:
            if action == "equip_perk" { isStoryQuestReadyToClaim = true }
        case 5:
            if action == "ritual_success" { isStoryQuestReadyToClaim = true }
        case 6:
            if action == "prestige" { isStoryQuestReadyToClaim = true }
        default:
            break
        }
        
        if isStoryQuestReadyToClaim {
            saveGame()
        }
    }
    
    func claimStoryReward() {
        guard isStoryQuestReadyToClaim else { return }
        
        // Give rewards
        switch currentStoryStep {
        case 0:
            break
        case 1:
            break
        case 2:
            mutationPoints += BigNumber(50) // 50 DNA
        case 3:
            let freePerk = Perk.rollRandom(type: .duck)
            perksInventory.append(freePerk)
        case 4:
            break
        case 5:
            break
        case 6:
            gems += BigNumber(10) // 10 gems
            // Activer missions secondaires plus tard
        default:
            break
        }
        
        // Move to next step
        currentStoryStep += 1
        isStoryQuestReadyToClaim = false
        storyFlags.removeAll() // reset flags for next step
        
        saveGame()
    }
    
    // MARK: - Unlocks
    
    var isHistoireUnlocked: Bool { true }
    var isUsinesUnlocked: Bool { true }
    var isBoutiqueUnlocked: Bool { currentStoryStep >= 1 }
    var isInventoryUnlocked: Bool { currentStoryStep >= 2 }
    var isAmelioUnlocked: Bool { currentStoryStep >= 2 } // unlocked at the beginning of step 2
    var isBanqueUnlocked: Bool { currentStoryStep >= 4 } // also unlocks perks
    var isRituelUnlocked: Bool { currentStoryStep >= 5 }
    var isPrestigeUnlocked: Bool { currentStoryStep >= 6 && (hasPrestiged || money >= BigNumber(10_000_000_000)) }
}
