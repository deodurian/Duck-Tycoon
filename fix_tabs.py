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
        items_str += f',\n        "{k_escaped}": "{v_escaped}"'
        
    return content[:insert_idx] + items_str + content[insert_idx:]

fr_items = {
    "Usines": "Usines",
    "Canards": "Canards",
    "Amélio.": "Amélio.",
    "Boutique": "Boutique",
    "Rituel": "Rituel",
    "Prestige": "Prestige",
    "Banque": "Banque",
    "Informations": "Informations",
    "Fusion": "Fusion",
    "Recyclage": "Recyclage"
}

en_items = {
    "Usines": "Factories",
    "Canards": "Ducks",
    "Amélio.": "Upgrades",
    "Boutique": "Shop",
    "Rituel": "Ritual",
    "Prestige": "Prestige",
    "Banque": "Bank",
    "Informations": "Details",
    "Fusion": "Fusion",
    "Recyclage": "Recycle"
}

es_items = {
    "Usines": "Fábricas",
    "Canards": "Patos",
    "Amélio.": "Mejoras",
    "Boutique": "Tienda",
    "Rituel": "Ritual",
    "Prestige": "Prestigio",
    "Banque": "Banco",
    "Informations": "Detalles",
    "Fusion": "Fusión",
    "Recyclage": "Reciclaje"
}

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'w', encoding='utf-8') as f:
    f.write(content)

