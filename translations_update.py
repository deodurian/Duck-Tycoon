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
        # Escape newlines
        v_escaped = v.replace('\n', '\\n')
        k_escaped = k.replace('\n', '\\n')
        items_str += f',\n        "{k_escaped}": "{v_escaped}"'
        
    return content[:insert_idx] + items_str + content[insert_idx:]

fr_items = {
    "Voulez-vous vraiment recycler ce canard de rareté ": "Voulez-vous vraiment recycler ce canard de rareté ",
    " ? Cette action est définitive.": " ? Cette action est définitive.",
    "Recyclage en Lot : S'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s'applique au niveau choisi et à ses niveaux inférieurs.\n\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau.": "Recyclage en Lot : S'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s'applique au niveau choisi et à ses niveaux inférieurs.\n\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau.",
    " ciblés": " ciblés",
    "Niveau ": "Niveau ",
    "⭐ Niveau ": "⭐ Niveau ",
    "Prochain Palier (Niveau ": "Prochain Palier (Niveau ",
    ")": ")",
    "Prix futur : ": "Prix futur : ",
    "Coût de fusion: ": "Coût de fusion: ",
    "Évo. ": "Évo. ",
    "Filtre: ": "Filtre: ",
    "Niv ": "Niv ",
    "MAX (+": "MAX (+",
    "Pendant votre absence\n(": "Pendant votre absence\n(",
    "Recycler (+ ": "Recycler (+ ",
    " Canards": " Canards",
    "Niv. ": "Niv. ",
    "Nv. ": "Nv. ",
    "Mutation: ": "Mutation: ",
    "Coût : ": "Coût : "
}

en_items = {
    "Voulez-vous vraiment recycler ce canard de rareté ": "Do you really want to recycle this duck of rarity ",
    " ? Cette action est définitive.": " ? This action is permanent.",
    "Recyclage en Lot : S'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s'applique au niveau choisi et à ses niveaux inférieurs.\n\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau.": "Batch Recycle: Applies to the selected rarity and all lower rarities. For the exact selected rarity, applies to the chosen level and lower levels.\n\nRecycle Rarity: Destroys ALL unassigned ducks of the selected rarity, regardless of level.",
    " ciblés": " targeted",
    "Niveau ": "Level ",
    "⭐ Niveau ": "⭐ Level ",
    "Prochain Palier (Niveau ": "Next Milestone (Level ",
    ")": ")",
    "Prix futur : ": "Future Price: ",
    "Coût de fusion: ": "Fusion Cost: ",
    "Évo. ": "Evo. ",
    "Filtre: ": "Filter: ",
    "Niv ": "Lvl ",
    "MAX (+": "MAX (+",
    "Pendant votre absence\n(": "While away\n(",
    "Recycler (+ ": "Recycle (+ ",
    " Canards": " Ducks",
    "Niv. ": "Lvl. ",
    "Nv. ": "Lvl. ",
    "Mutation: ": "Mutation: ",
    "Coût : ": "Cost: "
}

es_items = {
    "Voulez-vous vraiment recycler ce canard de rareté ": "¿De verdad quieres reciclar este pato de rareza ",
    " ? Cette action est définitive.": " ? Esta acción es permanente.",
    "Recyclage en Lot : S'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s'applique au niveau choisi et à ses niveaux inférieurs.\n\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau.": "Reciclaje en Lote: Se aplica a la rareza seleccionada y todas las inferiores. Para la rareza seleccionada, se aplica al nivel elegido y sus niveles inferiores.\n\nReciclar Rareza: Destruye TODOS los patos no asignados de la rareza seleccionada, sin importar su nivel.",
    " ciblés": " objetivo",
    "Niveau ": "Nivel ",
    "⭐ Niveau ": "⭐ Nivel ",
    "Prochain Palier (Niveau ": "Próximo Hito (Nivel ",
    ")": ")",
    "Prix futur : ": "Precio futuro: ",
    "Coût de fusion: ": "Costo de fusión: ",
    "Évo. ": "Evo. ",
    "Filtre: ": "Filtro: ",
    "Niv ": "Niv ",
    "MAX (+": "MAX (+",
    "Pendant votre absence\n(": "Mientras no estabas\n(",
    "Recycler (+ ": "Reciclar (+ ",
    " Canards": " Patos",
    "Niv. ": "Niv. ",
    "Nv. ": "Niv. ",
    "Mutation: ": "Mutación: ",
    "Coût : ": "Costo: "
}

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'w', encoding='utf-8') as f:
    f.write(content)

