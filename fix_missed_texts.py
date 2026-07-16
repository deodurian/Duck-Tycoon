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
        v_escaped = v.replace('\n', '\\n').replace('"', '\\"')
        k_escaped = k.replace('\n', '\\n').replace('"', '\\"')
        # Prevent adding duplicates
        if f'"{k_escaped}":' not in content:
            items_str += f',\n        "{k_escaped}": "{v_escaped}"'
        
    return content[:insert_idx] + items_str + content[insert_idx:]

fr_items = {
    "Trier par": "Trier par",
    "Type de Perks": "Type de Perks",
    "Type de mission": "Type de mission",
    "Canard ": "Canard ",
    "Taille: ": "Taille: ",
    "Mutation: ": "Mutation: ",
    "Perk Équipé": "Perk Équipé",
    "Aucun Perk équipé (Toucher pour choisir)": "Aucun Perk équipé (Toucher pour choisir)",
    "Améliorations (Coûte des 🧬)": "Améliorations (Coûte des 🧬)",
    "Niveau (Coûte des 💰)": "Niveau (Coûte des 💰)",
    "Ce canard sera retiré de l'usine si vous le recyclez.": "Ce canard sera retiré de l'usine si vous le recyclez.",
    "Filtres": "Filtres",
    "Niveau": "Niveau",
    "Canards ciblés": "Canards ciblés",
    "Gain Total": "Gain Total",
    "RECYCLER EN LOT": "RECYCLER EN LOT",
    "Recycler la rareté": "Recycler la rareté",
    "RECYCLER LA RARETÉ": "RECYCLER LA RARETÉ",
    " canards au total": " canards au total",
    "Appuie sur une barre pour voir les détails": "Appuie sur une barre pour voir les détails",
    "💡 L'inventaire affiche les 100 meilleurs canards. L'Auto-Fusion et le Recyclage accèdent à toute la collection.": "💡 L'inventaire affiche les 100 meilleurs canards. L'Auto-Fusion et le Recyclage accèdent à toute la collection."
}

en_items = {
    "Trier par": "Sort by",
    "Type de Perks": "Perk Type",
    "Type de mission": "Mission Type",
    "Canard ": "Duck ",
    "Taille: ": "Size: ",
    "Mutation: ": "Mutation: ",
    "Perk Équipé": "Equipped Perk",
    "Aucun Perk équipé (Toucher pour choisir)": "No Perk equipped (Tap to select)",
    "Améliorations (Coûte des 🧬)": "Upgrades (Costs 🧬)",
    "Niveau (Coûte des 💰)": "Level (Costs 💰)",
    "Ce canard sera retiré de l'usine si vous le recyclez.": "This duck will be removed from the factory if you recycle it.",
    "Filtres": "Filters",
    "Niveau": "Level",
    "Canards ciblés": "Targeted Ducks",
    "Gain Total": "Total Yield",
    "RECYCLER EN LOT": "BULK RECYCLE",
    "Recycler la rareté": "Recycle Rarity",
    "RECYCLER LA RARETÉ": "RECYCLE RARITY",
    " canards au total": " ducks in total",
    "Appuie sur une barre pour voir les détails": "Tap a bar to see details",
    "💡 L'inventaire affiche les 100 meilleurs canards. L'Auto-Fusion et le Recyclage accèdent à toute la collection.": "💡 The inventory shows the top 100 ducks. Auto-Fusion and Recycle access the entire collection."
}

es_items = {
    "Trier par": "Ordenar por",
    "Type de Perks": "Tipo de Perks",
    "Type de mission": "Tipo de misión",
    "Canard ": "Pato ",
    "Taille: ": "Tamaño: ",
    "Mutation: ": "Mutación: ",
    "Perk Équipé": "Perk Equipado",
    "Aucun Perk équipé (Toucher pour choisir)": "Ningún Perk equipado (Toca para elegir)",
    "Améliorations (Coûte des 🧬)": "Mejoras (Cuesta 🧬)",
    "Niveau (Coûte des 💰)": "Nivel (Cuesta 💰)",
    "Ce canard sera retiré de l'usine si vous le recyclez.": "Este pato será eliminado de la fábrica si lo reciclas.",
    "Filtres": "Filtros",
    "Niveau": "Nivel",
    "Canards ciblés": "Patos seleccionados",
    "Gain Total": "Ganancia Total",
    "RECYCLER EN LOT": "RECICLAR EN LOTE",
    "Recycler la rareté": "Reciclar Rareza",
    "RECYCLER LA RARETÉ": "RECICLAR RAREZA",
    " canards au total": " patos en total",
    "Appuie sur une barre pour voir les détails": "Toca una barra para ver detalles",
    "💡 L'inventaire affiche les 100 meilleurs canards. L'Auto-Fusion et le Recyclage accèdent à toute la collection.": "💡 El inventario muestra los mejores 100 patos. La Autofusión y el Reciclaje acceden a toda la colección."
}

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'w', encoding='utf-8') as f:
    f.write(content)

# Now apply replacements in Swift files
replacements = [
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryView.swift', 'Picker("Trier par"', 'Picker(tr("Trier par")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/FusionView.swift', 'Picker("Trier par"', 'Picker(tr("Trier par")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/FactoryComponents.swift', 'Picker("Trier par"', 'Picker(tr("Trier par")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PerkSheetView.swift', 'Picker("Type de Perks"', 'Picker(tr("Type de Perks")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/MissionSheetView.swift', 'Picker("Type de mission"', 'Picker(tr("Type de mission")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Canard \(currentDuck.rarity.rawValue)")', 'Text("\(tr("Canard "))\(currentDuck.rarity.localizedName)")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Taille: \(currentDuck.size.rawValue)")', 'Text("\(tr("Taille: "))\(currentDuck.size.localizedName)")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Mutation: \(currentDuck.mutation.rawValue)")', 'Text("\(tr("Mutation: "))\(currentDuck.mutation.localizedName)")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Perk Équipé")', 'Text(tr("Perk Équipé"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Aucun Perk équipé (Toucher pour choisir)")', 'Text(tr("Aucun Perk équipé (Toucher pour choisir)"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Améliorations (Coûte des 🧬)")', 'Text(tr("Améliorations (Coûte des 🧬)"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Niveau (Coûte des 💰)")', 'Text(tr("Niveau (Coûte des 💰)"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Ce canard sera retiré de l\'usine si vous le recyclez.")', 'Text(tr("Ce canard sera retiré de l\'usine si vous le recyclez."))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Recyclage")', 'Text(tr("Recyclage"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Filtres")', 'Text(tr("Filtres"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Picker("Niveau"', 'Picker(tr("Niveau")'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Canards ciblés")', 'Text(tr("Canards ciblés"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Gain Total")', 'Text(tr("Gain Total"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("RECYCLER EN LOT")', 'Text(tr("RECYCLER EN LOT"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Recycler la rareté")', 'Text(tr("Recycler la rareté"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("RECYCLER LA RARETÉ")', 'Text(tr("RECYCLER LA RARETÉ"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text(" canards au total")', 'Text(tr(" canards au total"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("Appuie sur une barre pour voir les détails")', 'Text(tr("Appuie sur une barre pour voir les détails"))'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Text("💡 L\'inventaire affiche les 100 meilleurs canards. L\'Auto-Fusion et le Recyclage accèdent à toute la collection.")', 'Text(tr("💡 L\'inventaire affiche les 100 meilleurs canards. L\'Auto-Fusion et le Recyclage accèdent à toute la collection."))')
]

for filepath, old_str, new_str in replacements:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            file_content = f.read()
        file_content = file_content.replace(old_str, new_str)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(file_content)
    except Exception as e:
        pass

