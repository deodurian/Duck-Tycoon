import re
import os

filepath = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/GameManager/GameManager.swift"
with open(filepath, "r") as f:
    lines = f.readlines()

# Regions we want to extract:
# We will find the line numbers for each MARK and extract them into separate files.

marks = []
for i, line in enumerate(lines):
    if "MARK: -" in line:
        marks.append((i, line.strip()))

def get_block(start_mark, end_mark=None):
    start_idx = -1
    for m in marks:
        if start_mark in m[1]:
            start_idx = m[0]
            break
    if start_idx == -1:
        return []
    
    end_idx = len(lines) - 1 # up to the last closing brace
    if end_mark:
        for m in marks:
            if end_mark in m[1]:
                end_idx = m[0]
                break
    return lines[start_idx:end_idx]

# Define sections
save_content = ["import SwiftUI\n\nextension GameManager {\n"] + get_block("Sauvegarde Professionnelle", "Prestige System") + ["}\n"]
eco_content = ["import SwiftUI\n\nextension GameManager {\n"] + get_block("Shop UI Optimization", "Système d'Améliorations") + get_block("Système d'Améliorations", "Prestige Upgrades") + get_block("Prestige Upgrades", "Traitement de l'Ajout de Canards") + get_block("Sell Value & UI Helpers", "Actions Utilisateur") + get_block("Prestige System")
eco_content[-1] = eco_content[-1].replace("}", "") # remove the last brace of the class that was included in prestige system
eco_content.append("}\n")

inv_content = ["import SwiftUI\n\nextension GameManager {\n"] + get_block("Traitement de l'Ajout de Canards", "Inventory Limits") + get_block("Inventory Limits", "Sell Value & UI Helpers") + get_block("Actions Utilisateur", "Mutation & Recyclage") + get_block("Mutation & Recyclage", "Mass Recycle") + get_block("Mass Recycle", "Fusion") + get_block("Fusion", "Tri Asynchrone") + get_block("Tri Asynchrone", "Mega Auto-Fusion") + get_block("Mega Auto-Fusion", "Factory Upgrades") + get_block("Factory Upgrades", "Ritual") + get_block("Ritual", "Sauvegarde Professionnelle") + ["}\n"]

loop_content = ["import SwiftUI\n\nextension GameManager {\n"] + get_block("Core Loop", "Effets Visuels Globaux") + get_block("Effets Visuels Globaux", "Automatisation") + get_block("Automatisation", "Shop UI Optimization") + ["}\n"]

# Core GameManager:
# Contains everything from start to "Core Loop"
core_idx = -1
for m in marks:
    if "Core Loop" in m[1]:
        core_idx = m[0]
        break
core_content = lines[:core_idx] + ["}\n"]

base_path = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/GameManager/"

with open(base_path + "GameManager+Save.swift", "w") as f:
    f.writelines(save_content)
with open(base_path + "GameManager+Economy.swift", "w") as f:
    f.writelines(eco_content)
with open(base_path + "GameManager+Inventory.swift", "w") as f:
    f.writelines(inv_content)
with open(base_path + "GameManager+Loop.swift", "w") as f:
    f.writelines(loop_content)
with open(base_path + "GameManager.swift", "w") as f:
    f.writelines(core_content)

print("Split completed successfully!")
