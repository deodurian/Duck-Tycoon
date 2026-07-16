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
    "Sauts Temporels": "Sauts Temporels",
    "1H de revenus": "1H de revenus",
    "4H de revenus": "4H de revenus",
    "12H de revenus": "12H de revenus",
    "Packs d'Argent": "Packs d'Argent",
    "+10 K": "+10 K",
    "+100 K": "+100 K",
    "+1 M": "+1 M",
    "+10 M": "+10 M",
    "+100 M": "+100 M",
    "+1 B": "+1 B",
    "Packs d'ADN": "Packs d'ADN",
    "+100": "+100",
    "+500": "+500",
    "+2.5 K": "+2.5 K",
    "+10 K": "+10 K",
    "+50 K": "+50 K",
    "+250 K": "+250 K",
    "Acheter des Gemmes": "Acheter des Gemmes"
}

en_items = {
    "Sauts Temporels": "Time Skips",
    "1H de revenus": "1H of income",
    "4H de revenus": "4H of income",
    "12H de revenus": "12H of income",
    "Packs d'Argent": "Money Packs",
    "+10 K": "+10 K",
    "+100 K": "+100 K",
    "+1 M": "+1 M",
    "+10 M": "+10 M",
    "+100 M": "+100 M",
    "+1 B": "+1 B",
    "Packs d'ADN": "DNA Packs",
    "+100": "+100",
    "+500": "+500",
    "+2.5 K": "+2.5 K",
    "+10 K": "+10 K",
    "+50 K": "+50 K",
    "+250 K": "+250 K",
    "Acheter des Gemmes": "Buy Gems"
}

es_items = {
    "Sauts Temporels": "Saltos en el Tiempo",
    "1H de revenus": "1H de ingresos",
    "4H de revenus": "4H de ingresos",
    "12H de revenus": "12H de ingresos",
    "Packs d'Argent": "Packs de Dinero",
    "+10 K": "+10 K",
    "+100 K": "+100 K",
    "+1 M": "+1 M",
    "+10 M": "+10 M",
    "+100 M": "+100 M",
    "+1 B": "+1 B",
    "Packs d'ADN": "Packs de ADN",
    "+100": "+100",
    "+500": "+500",
    "+2.5 K": "+2.5 K",
    "+10 K": "+10 K",
    "+50 K": "+50 K",
    "+250 K": "+250 K",
    "Acheter des Gemmes": "Comprar Gemas"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

