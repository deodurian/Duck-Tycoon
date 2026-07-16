# -*- coding: utf-8 -*-
import re

# These are the exact keys that are still missing (with trailing spaces etc)
REMAINING = {
    # Keys with trailing spaces or special chars the first script missed
    "Acheter pour": ("Acheter pour", "Buy for", "Comprar por"),
    "Améliorations (Coûte des 🧬)": ("Améliorations (Coûte des 🧬)", "Upgrades (Costs 🧬)", "Mejoras (Cuesta 🧬)"),
    "Améliorer Taille": ("Améliorer Taille", "Upgrade Size", "Mejorar Tamaño"),
    "Appuie sur une barre pour voir les détails": ("Appuie sur une barre pour voir les détails", "Tap a bar to see details", "Toca una barra para ver los detalles"),
    "Aucun Perk équipé (Toucher pour choisir)": ("Aucun Perk équipé (Toucher pour choisir)", "No Perk equipped (Tap to choose)", "Sin Perk equipado (Toca para elegir)"),
    "Compte 32 fois lors d'une fusion (perk conservé)": ("Compte 32 fois lors d'une fusion (perk conservé)", "Counts 32 times during fusion (perk kept)", "Cuenta 32 veces en una fusión (perk conservado)"),
    "Coût :": ("Coût :", "Cost:", "Coste:"),
    "Coût de fusion:": ("Coût de fusion:", "Fusion cost:", "Coste de fusión:"),
    "Donne 10% d'argent en plus par usine équipée d'un canard": ("Donne 10% d'argent en plus par usine équipée d'un canard", "Gives 10% more money per factory with a duck", "Da un 10% más de dinero por fábrica con un pato"),
    "Donne 100% d'argent en plus si un canard Peu-commun est équipé": ("Donne 100% d'argent en plus si un canard Peu-commun est équipé", "Gives 100% more money if an uncommon duck is equipped", "Da un 100% más de dinero si un pato poco común está equipado"),
    "Donne 100% d'argent en plus si un canard commun est équipé": ("Donne 100% d'argent en plus si un canard commun est équipé", "Gives 100% more money if a common duck is equipped", "Da un 100% más de dinero si un pato común está equipado"),
    "Donne 100% d'argent en plus si un canard épique/légendaire est équipé": ("Donne 100% d'argent en plus si un canard épique/légendaire est équipé", "Gives 100% more money if an epic/legendary duck is equipped", "Da un 100% más de dinero si un pato épico/legendario está equipado"),
    "Donne 130% d'argent en plus si un canard E/L/M est équipé": ("Donne 130% d'argent en plus si un canard E/L/M est équipé", "Gives 130% more money if an E/L/M duck is equipped", "Da un 130% más de dinero si un pato E/L/M está equipado"),
    "Donne 15% d'argent en plus a l'usine": ("Donne 15% d'argent en plus a l'usine", "Gives 15% more money to the factory", "Da un 15% más de dinero a la fábrica"),
    "Donne 150% d'argent en plus a l'usine": ("Donne 150% d'argent en plus a l'usine", "Gives 150% more money to the factory", "Da un 150% más de dinero a la fábrica"),
    "Donne 210% d'argent en plus si un canard C/PC/R est équipé": ("Donne 210% d'argent en plus si un canard C/PC/R est équipé", "Gives 210% more money if a C/UC/R duck is equipped", "Da un 210% más de dinero si un pato C/PC/R está equipado"),
    "Donne 30% d'argent de plus a l'usine": ("Donne 30% d'argent de plus a l'usine", "Gives 30% more money to the factory", "Da un 30% más de dinero a la fábrica"),
    "Donne 300% d'argent en plus si un canard C/PC/R est équipé": ("Donne 300% d'argent en plus si un canard C/PC/R est équipé", "Gives 300% more money if a C/UC/R duck is equipped", "Da un 300% más de dinero si un pato C/PC/R está equipado"),
    "Donne 50% d'argent de plus a l'usine": ("Donne 50% d'argent de plus a l'usine", "Gives 50% more money to the factory", "Da un 50% más de dinero a la fábrica"),
    "Donne 50% d'argent en plus a l'usine": ("Donne 50% d'argent en plus a l'usine", "Gives 50% more money to the factory", "Da un 50% más de dinero a la fábrica"),
    "Donne 50% d'argent en plus si un canard commun est équipé": ("Donne 50% d'argent en plus si un canard commun est équipé", "Gives 50% more money if a common duck is equipped", "Da un 50% más de dinero si un pato común está equipado"),
    "Donne 500% d'argent en plus a l'usine": ("Donne 500% d'argent en plus a l'usine", "Gives 500% more money to the factory", "Da un 500% más de dinero a la fábrica"),
    "Donne 60% d'argent en plus si un canard Peu-commun est équipé": ("Donne 60% d'argent en plus si un canard Peu-commun est équipé", "Gives 60% more money if an uncommon duck is equipped", "Da un 60% más de dinero si un pato poco común está equipado"),
    "Donne 80% d'argent en plus a l'usine": ("Donne 80% d'argent en plus a l'usine", "Gives 80% more money to the factory", "Da un 80% más de dinero a la fábrica"),
    "Donne 80% d'argent en plus si un canard commun est équipé": ("Donne 80% d'argent en plus si un canard commun est équipé", "Gives 80% more money if a common duck is equipped", "Da un 80% más de dinero si un pato común está equipado"),
    "Donne 80% d'argent en plus si un canard rare est équipé": ("Donne 80% d'argent en plus si un canard rare est équipé", "Gives 80% more money if a rare duck is equipped", "Da un 80% más de dinero si un pato raro está equipado"),
    "Donne 90% d'argent en plus a l'usine": ("Donne 90% d'argent en plus a l'usine", "Gives 90% more money to the factory", "Da un 90% más de dinero a la fábrica"),
    "Filtre:": ("Filtre:", "Filter:", "Filtro:"),
    "Génère :": ("Génère :", "Generates:", "Genera:"),
    "Lvl": ("Lvl", "Lvl", "Lvl"),
    "Mutation:": ("Mutation:", "Mutation:", "Mutación:"),
    "Niv": ("Niv", "Lv", "Niv"),
    "Niv.": ("Niv.", "Lv.", "Niv."),
    "Niveau de Fusion": ("Niveau de Fusion", "Fusion Level", "Nivel de Fusión"),
    "Nv.": ("Nv.", "Lv.", "Niv."),
    "Nécessite": ("Nécessite", "Requires", "Requiere"),
    "Palier": ("Palier", "Tier", "Nivel"),
    "Permet de mettre un 2ème canard dans l'usine": ("Permet de mettre un 2ème canard dans l'usine", "Allows placing a 2nd duck in the factory", "Permite colocar un 2º pato en la fábrica"),
    "Permet de rajouter un 2ème perk a l'usine": ("Permet de rajouter un 2ème perk a l'usine", "Allows adding a 2nd perk to the factory", "Permite añadir un 2º perk a la fábrica"),
    "Prix futur :": ("Prix futur :", "Future price:", "Precio futuro:"),
    "Prochain Palier (Niveau": ("Prochain Palier (Niveau", "Next Milestone (Level", "Próximo Hito (Nivel"),
    "Recycler (+": ("Recycler (+", "Recycle (+", "Reciclar (+"),
    "Taille:": ("Taille:", "Size:", "Tamaño:"),
    "Voulez-vous vraiment recycler ce canard de rareté": ("Voulez-vous vraiment recycler ce canard de rareté", "Do you really want to recycle this duck of rarity", "¿Realmente quieres reciclar este pato de rareza"),
    "Évo.": ("Évo.", "Evo.", "Evo."),
    "⭐ Niveau": ("⭐ Niveau", "⭐ Level", "⭐ Nivel"),
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

def find_section_end(content, lang):
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return None
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return None
    return start_idx, start_idx + end_match.start()

def add_items(content, lang, items_dict):
    result = find_section_end(content, lang)
    if not result: return content
    start_idx, end_idx = result
    
    lang_section = content[start_idx:end_idx]
    
    additions = ""
    for key, val in items_dict.items():
        # Escape for Swift string literal
        k_swift = key.replace('"', '\\"')
        v_swift = val.replace('"', '\\"')
        # Check if already present
        if f'"{k_swift}":' in lang_section or f'"{key}":' in lang_section:
            continue
        additions += f',\n        "{k_swift}": "{v_swift}"'
    
    return content[:end_idx] + additions + content[end_idx:]

# Build per-lang dicts
fr_items = {k: v[0] for k, v in REMAINING.items()}
en_items = {k: v[1] for k, v in REMAINING.items()}
es_items = {k: v[2] for k, v in REMAINING.items()}

content = add_items(content, 'fr', fr_items)
content = add_items(content, 'en', en_items)
content = add_items(content, 'es', es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done adding remaining keys!")

# Quick re-check
def extract_keys(content, lang):
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return set()
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return set()
    lang_content = content[start_idx:start_idx + end_match.start()]
    keys = re.findall(r'"([^"]+)":\s*"', lang_content)
    return set(keys)

fr2 = extract_keys(content, 'fr')
en2 = extract_keys(content, 'en')
es2 = extract_keys(content, 'es')
print(f"After: FR={len(fr2)}, EN={len(en2)}, ES={len(es2)}")
