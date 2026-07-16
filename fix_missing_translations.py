import re

def append_to_dict(content, lang, new_items):
    # Find the end of the language dictionary
    # e.g., .en: [ ... ]
    # We look for the closing bracket ']' corresponding to .lang: [
    
    # Simple heuristic: find `.lang: [`
    # Then find the next `],` or `]` at the same indentation level
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return content
    
    start_idx = match.end()
    
    # find the next `    ],` or `    ]`
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return content
    
    insert_idx = start_idx + end_match.start()
    
    # Prepare items
    items_str = ""
    for k, v in new_items.items():
        items_str += f',\n        "{k}": "{v}"'
        
    # insert
    new_content = content[:insert_idx] + items_str + content[insert_idx:]
    return new_content

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'r', encoding='utf-8') as f:
    content = f.read()

fr_missing = {
    "Commun": "Commun",
    "Peu Commun": "Peu Commun",
    "Rare": "Rare",
    "Épique": "Épique",
    "Légendaire": "Légendaire",
    "Mythique": "Mythique",
    "Moyen": "Moyen",
    "Grand": "Grand",
    "Géant": "Géant",
    "Canard ": "Canard ",
    "Niveau de Fusion ": "Niveau de Fusion ",
    "Lvl ": "Lvl ",
    "Génère : ": "Génère : ",
    " / sec": " / sec",
    "Taille: ": "Taille: ",
    "Auto-Fusion : S'applique uniquement à la rareté sélectionnée. Assemble tous les groupes de 3 canards identiques.\\n\\nMéga-Fusion : Fusionne TOUS les canards de l'inventaire en cascade jusqu'à épuisement des canards ou de l'argent.": "Auto-Fusion : S'applique uniquement à la rareté sélectionnée. Assemble tous les groupes de 3 canards identiques.\\n\\nMéga-Fusion : Fusionne TOUS les canards de l'inventaire en cascade jusqu'à épuisement des canards ou de l'argent.",
    " fusions estimées": " fusions estimées",
    "Palier ": "Palier ",
    "Nécessite ": "Nécessite ",
    " étoiles dépensées": " étoiles dépensées",
    "Acheter pour ": "Acheter pour "
}

en_missing = {
    "Commun": "Common",
    "Peu Commun": "Uncommon",
    "Rare": "Rare",
    "Épique": "Epic",
    "Légendaire": "Legendary",
    "Mythique": "Mythic",
    "Moyen": "Medium",
    "Grand": "Large",
    "Géant": "Giant",
    "Canard ": "Duck ",
    "Niveau de Fusion ": "Fusion Level ",
    "Lvl ": "Lvl ",
    "Génère : ": "Generates: ",
    " / sec": " / sec",
    "Taille: ": "Size: ",
    "Auto-Fusion : S'applique uniquement à la rareté sélectionnée. Assemble tous les groupes de 3 canards identiques.\\n\\nMéga-Fusion : Fusionne TOUS les canards de l'inventaire en cascade jusqu'à épuisement des canards ou de l'argent.": "Auto-Fusion: Applies only to the selected rarity. Assembles all groups of 3 identical ducks.\\n\\nMega-Fusion: Merges ALL ducks in inventory in a cascade until out of ducks or money.",
    " fusions estimées": " estimated fusions",
    "Palier ": "Tier ",
    "Nécessite ": "Requires ",
    " étoiles dépensées": " spent stars",
    "Acheter pour ": "Buy for "
}

es_missing = {
    "Commun": "Común",
    "Peu Commun": "Poco Común",
    "Rare": "Raro",
    "Épique": "Épico",
    "Légendaire": "Legendario",
    "Mythique": "Mítico",
    "Moyen": "Mediano",
    "Grand": "Grande",
    "Géant": "Gigante",
    "Canard ": "Pato ",
    "Niveau de Fusion ": "Nivel de Fusión ",
    "Lvl ": "Nivel ",
    "Génère : ": "Genera: ",
    " / sec": " / seg",
    "Taille: ": "Tamaño: ",
    "Auto-Fusion : S'applique uniquement à la rareté sélectionnée. Assemble tous les groupes de 3 canards identiques.\\n\\nMéga-Fusion : Fusionne TOUS les canards de l'inventaire en cascade jusqu'à épuisement des canards ou de l'argent.": "Auto-Fusión: Se aplica solo a la rareza seleccionada. Agrupa todos los grupos de 3 patos idénticos.\\n\\nMega-Fusión: Fusiona TODOS los patos del inventario en cascada hasta quedarse sin patos o dinero.",
    " fusions estimées": " fusiones estimadas",
    "Palier ": "Nivel ",
    "Nécessite ": "Requiere ",
    " étoiles dépensées": " estrellas gastadas",
    "Acheter pour ": "Comprar por "
}

content = append_to_dict(content, "fr", fr_missing)
content = append_to_dict(content, "en", en_missing)
content = append_to_dict(content, "es", es_missing)

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'w', encoding='utf-8') as f:
    f.write(content)

