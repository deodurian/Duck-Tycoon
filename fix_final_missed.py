import re
import os

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
        v_escaped = v.replace('\n', '\\n').replace('"', '\\"')
        k_escaped = k.replace('\n', '\\n').replace('"', '\\"')
        if f'"{k_escaped}":' not in content:
            items_str += f',\n        "{k_escaped}": "{v_escaped}"'
        
    return content[:insert_idx] + items_str + content[insert_idx:]

fr_items = {
    "Gain d'argent": "Gain d'argent",
    "Bonus fusion": "Bonus fusion",
    "Réduction usines": "Réduction usines",
    "Gain mutation": "Gain mutation",
    "Mutation spontanée": "Mutation spontanée",
    "Gain du Rituel": "Gain du Rituel",
    "Améliorer Taille": "Améliorer Taille",
    "Muter": "Muter",
    "Augmenter Niveau": "Augmenter Niveau",
    "Niveau MAX": "Niveau MAX",
    "Niveau MAX (100)": "Niveau MAX (100)",
    "MAX": "MAX",
    "ACQUIS": "ACQUIS",
    "Max": "Max",
    "Total": "Total",
    "Libres": "Libres",
    "Dépensées": "Dépensées"
}

en_items = {
    "Gain d'argent": "Money Gain",
    "Bonus fusion": "Fusion Bonus",
    "Réduction usines": "Factory Discount",
    "Gain mutation": "Mutation Gain",
    "Mutation spontanée": "Spontaneous Mut.",
    "Gain du Rituel": "Ritual Gain",
    "Améliorer Taille": "Upgrade Size",
    "Muter": "Mutate",
    "Augmenter Niveau": "Upgrade Level",
    "Niveau MAX": "MAX Level",
    "Niveau MAX (100)": "MAX Level (100)",
    "MAX": "MAX",
    "ACQUIS": "OWNED",
    "Max": "Max",
    "Total": "Total",
    "Libres": "Unspent",
    "Dépensées": "Spent"
}

es_items = {
    "Gain d'argent": "Ganancia Dinero",
    "Bonus fusion": "Bono Fusión",
    "Réduction usines": "Dcto. Fábricas",
    "Gain mutation": "Ganancia Mutación",
    "Mutation spontanée": "Mutación Espontánea",
    "Gain du Rituel": "Ganancia Ritual",
    "Améliorer Taille": "Mejorar Tamaño",
    "Muter": "Mutar",
    "Augmenter Niveau": "Subir Nivel",
    "Niveau MAX": "Nivel MAX",
    "Niveau MAX (100)": "Nivel MAX (100)",
    "MAX": "MAX",
    "ACQUIS": "ADQUIRIDO",
    "Max": "Max",
    "Total": "Total",
    "Libres": "Libres",
    "Dépensées": "Gastadas"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

# File Replacements
replacements = [
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'title: "Améliorer Taille"', 'title: tr("Améliorer Taille")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'title: "Muter"', 'title: tr("Muter")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'title: "Augmenter Niveau"', 'title: tr("Augmenter Niveau")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'maxLabel: "Niveau MAX"', 'maxLabel: tr("Niveau MAX")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'maxLabel: "Niveau MAX (100)"', 'maxLabel: tr("Niveau MAX (100)")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'label: "Gain d\'argent"', 'label: tr("Gain d\'argent")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'label: "Bonus fusion"', 'label: tr("Bonus fusion")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'label: "Réduction usines"', 'label: tr("Réduction usines")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'label: "Gain mutation"', 'label: tr("Gain mutation")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'label: "Mutation spontanée"', 'label: tr("Mutation spontanée")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'label: "Gain du Rituel"', 'label: tr("Gain du Rituel")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'title: "Total"', 'title: tr("Total")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'title: "Libres"', 'title: tr("Libres")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'title: "Dépensées"', 'title: tr("Dépensées")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/FactoryComponents.swift', 'label: "Max"', 'label: tr("Max")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/Upgrades/AutoFactoryCard.swift', 'text: "MAX"', 'text: tr("MAX")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/Upgrades/UnlockCard.swift', 'text: "ACQUIS"', 'text: tr("ACQUIS")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/Upgrades/BonusCard.swift', 'text: "MAX"', 'text: tr("MAX")')
]

for filepath, old_str, new_str in replacements:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            file_content = f.read()
        file_content = file_content.replace(old_str, new_str)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(file_content)

