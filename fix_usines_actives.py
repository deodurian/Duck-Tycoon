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
        if f'"{k_escaped}":' not in content:
            items_str += f',\n        "{k_escaped}": "{v_escaped}"'
        
    return content[:insert_idx] + items_str + content[insert_idx:]

fr_items = {
    "usine active": "usine active",
    "usines actives": "usines actives",
    "Usine": "Usine",
    "Canard": "Canard",
    "Missions": "Missions",
    "Principales": "Principales",
    "Quotidiennes": "Quotidiennes"
}

en_items = {
    "usine active": "active factory",
    "usines actives": "active factories",
    "Usine": "Factory",
    "Canard": "Duck",
    "Missions": "Missions",
    "Principales": "Main",
    "Quotidiennes": "Daily"
}

es_items = {
    "usine active": "fábrica activa",
    "usines actives": "fábricas activas",
    "Usine": "Fábrica",
    "Canard": "Pato",
    "Missions": "Misiones",
    "Principales": "Principales",
    "Quotidiennes": "Diarias"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

