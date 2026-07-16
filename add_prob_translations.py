# -*- coding: utf-8 -*-
import re

MISSING_TRANSLATIONS = {
    # DuckSize
    "Petit": ("Petit", "Small", "Pequeño"),
    "Moyen": ("Moyen", "Medium", "Mediano"),
    "Grand": ("Grand", "Large", "Grande"),
    "Géant": ("Géant", "Giant", "Gigante"),

    # DuckMutation
    "Aucune": ("Aucune", "None", "Ninguna"),
    "Doré": ("Doré", "Golden", "Dorado"),
    "Radioactif": ("Radioactif", "Radioactive", "Radiactivo"),
    "Cristallisé": ("Cristallisé", "Crystallized", "Cristalizado"),

    # DuckRarity missing exact match
    "Peu-commun": ("Peu-commun", "Uncommon", "Poco Común"),
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
        k_swift = key.replace('"', '\\"')
        v_swift = val.replace('"', '\\"')
        if f'"{k_swift}":' in lang_section or f'"{key}":' in lang_section:
            continue
        additions += f',\n        "{k_swift}": "{v_swift}"'
    
    return content[:end_idx] + additions + content[end_idx:]

fr_items = {k: v[0] for k, v in MISSING_TRANSLATIONS.items()}
en_items = {k: v[1] for k, v in MISSING_TRANSLATIONS.items()}
es_items = {k: v[2] for k, v in MISSING_TRANSLATIONS.items()}

content = add_items(content, 'fr', fr_items)
content = add_items(content, 'en', en_items)
content = add_items(content, 'es', es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Probability translations added!")
