import re

def append_to_dict(content, lang, new_items):
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return content
    
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return content
    
    insert_idx = start_idx + end_match.start()
    
    items_str = ""
    for k, v in new_items.items():
        v_escaped = v.replace('\n', '\\n')
        k_escaped = k.replace('\n', '\\n')
        items_str += f',\n        "{k_escaped}": "{v_escaped}"'
        
    return content[:insert_idx] + items_str + content[insert_idx:]

fr_items = {
    "Statistiques": "Statistiques",
    "Sélectionner un Perk": "Sélectionner un Perk",
    "Inventaire de Perks": "Inventaire de Perks",
    "Choisir un canard": "Choisir un canard",
    "Niveau Joueur": "Niveau Joueur",
    "Sélectionner un canard": "Sélectionner un canard",
    "Missions": "Missions",
    "Répétables": "Répétables",
    "Déblocages": "Déblocages",
    "Automatisation": "Automatisation",
    "Principales": "Principales",
    "Quotidiennes": "Quotidiennes",
    "Caisse en Bois": "Caisse en Bois",
    "Caisse en Fer": "Caisse en Fer",
    "Caisse en Or": "Caisse en Or",
    "Caisse en Platine": "Caisse en Platine",
    "Caisse en Saphir": "Caisse en Saphir",
    "Caisse en Rubis": "Caisse en Rubis",
    "Caisse en Diamant": "Caisse en Diamant",
    "Bois": "Bois",
    "Fer": "Fer",
    "Or": "Or",
    "Platine": "Platine",
    "Saphir": "Saphir",
    "Rubis": "Rubis",
    "Diamant": "Diamant",
    " XP": " XP"
}

en_items = {
    "Statistiques": "Stats",
    "Sélectionner un Perk": "Select a Perk",
    "Inventaire de Perks": "Perk Inventory",
    "Choisir un canard": "Choose a duck",
    "Niveau Joueur": "Player Level",
    "Sélectionner un canard": "Select a duck",
    "Missions": "Missions",
    "Répétables": "Repeatable",
    "Déblocages": "Unlocks",
    "Automatisation": "Automation",
    "Principales": "Main",
    "Quotidiennes": "Daily",
    "Caisse en Bois": "Wood Crate",
    "Caisse en Fer": "Iron Crate",
    "Caisse en Or": "Gold Crate",
    "Caisse en Platine": "Platinum Crate",
    "Caisse en Saphir": "Sapphire Crate",
    "Caisse en Rubis": "Ruby Crate",
    "Caisse en Diamant": "Diamond Crate",
    "Bois": "Wood",
    "Fer": "Iron",
    "Or": "Gold",
    "Platine": "Platinum",
    "Saphir": "Sapphire",
    "Rubis": "Ruby",
    "Diamant": "Diamond",
    " XP": " XP"
}

es_items = {
    "Statistiques": "Estadísticas",
    "Sélectionner un Perk": "Seleccionar un Perk",
    "Inventaire de Perks": "Inventario de Perks",
    "Choisir un canard": "Elige un pato",
    "Niveau Joueur": "Nivel de Jugador",
    "Sélectionner un canard": "Selecciona un pato",
    "Missions": "Misiones",
    "Répétables": "Repetible",
    "Déblocages": "Desbloqueos",
    "Automatisation": "Automatización",
    "Principales": "Principales",
    "Quotidiennes": "Diarias",
    "Caisse en Bois": "Caja de Madera",
    "Caisse en Fer": "Caja de Hierro",
    "Caisse en Or": "Caja de Oro",
    "Caisse en Platine": "Caja de Platino",
    "Caisse en Saphir": "Caja de Zafiro",
    "Caisse en Rubis": "Caja de Rubí",
    "Caisse en Diamant": "Caja de Diamante",
    "Bois": "Madera",
    "Fer": "Hierro",
    "Or": "Oro",
    "Platine": "Platino",
    "Saphir": "Zafiro",
    "Rubis": "Rubí",
    "Diamant": "Diamante",
    " XP": " XP"
}

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'w', encoding='utf-8') as f:
    f.write(content)

# File Replacements
replacements = [
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', '.navigationTitle("Statistiques")', '.navigationTitle(tr("Statistiques"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PerkSelectionSheet.swift', '.navigationTitle("Sélectionner un Perk")', '.navigationTitle(tr("Sélectionner un Perk"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PerkSheetView.swift', '.navigationTitle("Inventaire de Perks")', '.navigationTitle(tr("Inventaire de Perks"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/FactoryComponents.swift', '.navigationTitle("Choisir un canard")', '.navigationTitle(tr("Choisir un canard"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/LevelSheetView.swift', '.navigationTitle("Niveau Joueur")', '.navigationTitle(tr("Niveau Joueur"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/RitualView.swift', '.navigationTitle("Sélectionner un canard")', '.navigationTitle(tr("Sélectionner un canard"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/MissionSheetView.swift', '.navigationTitle("Missions")', '.navigationTitle(tr("Missions"))'),
    
    # Also fix LevelSheetView "XP"
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/LevelSheetView.swift', 'Text("\(currentXP) / \(requiredXP) XP")', 'Text("\(currentXP) / \(requiredXP)\(tr(" XP"))")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/OfflineEarningsPopupView.swift', 'Text("\(earnings.xp) XP")', 'Text("\(earnings.xp)\(tr(" XP"))")'),
]

for filepath, old_str, new_str in replacements:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            file_content = f.read()
        file_content = file_content.replace(old_str, new_str)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(file_content)
    except Exception as e:
        print(f"Error replacing in {filepath}: {e}")

