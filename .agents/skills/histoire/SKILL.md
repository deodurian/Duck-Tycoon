---
name: histoire
description: Se déclenche quand l'utilisateur prononce le mot "histoire". Rappelle le plan de conception pour le mode histoire hybride.
---

# Mode Histoire Hybride (Progression Verrouillée)

Lorsque l'utilisateur souhaite travailler sur l'"histoire", rappelle-lui exactement ce concept sur lequel vous vous êtes mis d'accord :

## 1. Interface et Onglet Missions
- Le menu "Missions" ne doit plus être un simple bouton ouvrant une "sheet".
- Il doit devenir **un onglet complet à part entière dans la barre de navigation principale (TabBar)**.
- Cela offrira beaucoup plus de place pour afficher des textes narratifs plus longs, l'organisation des missions, et potentiellement l'avatar/le visage d'un personnage (Savant fou, Dieu Canard, Investisseur) qui parle au joueur.

## 2. Contrôle de la Progression (Verrouillage de l'UI)
- Le jeu démarre avec une interface **entièrement vide ou grisée**, à l'exception de l'usine de base et de l'onglet "Missions" (qui sert d'histoire).
- Le joueur ne peut accéder à rien d'autre au début.
- La validation des quêtes principales de l'histoire déclenchera le déblocage des différentes fonctionnalités du jeu (variables `isUnlocked`).

## 3. Exemples de Déblocage Progressif
- **Chapitre 1 (Bases)** : Assigner un canard. Débloque le gain d'XP.
- **Chapitre 2 (Caisses)** : L'histoire explique le besoin de nouveaux spécimens. Débloque l'onglet **Boutique**.
- **Chapitre 3 (Mutation)** : Le joueur doit améliorer un canard. Débloque l'onglet **Améliorations (Labo)**.
- **Chapitre 4 (Fusion)** : L'espace manque, il faut écraser les canards ensemble. Débloque la **Fusion**.
- **Plus tard** : Déblocage graduel des Perks, du Recyclage, du Rituel, et du Prestige en suivant la narration.

> **Instruction pour l'agent** : Présente un résumé de ces idées à l'utilisateur dès que cette compétence est déclenchée, et demande-lui par quelle étape technique (ex: transformer le bouton mission en onglet complet) il souhaite commencer !
