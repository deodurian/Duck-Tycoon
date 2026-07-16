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
    "Savoir de Fusion": "Savoir de Fusion",
    "Magie Rituelle": "Magie Rituelle",
    "Économie Globale": "Économie Globale",
    "Valeur Rare": "Valeur Rare",
    "Automatisation Initiale": "Automatisation Initiale",
    "Évolution d'Usine": "Évolution d'Usine",
    "Valeur de Base II": "Valeur de Base II",
    "Valeur Commune": "Valeur Commune",
    "Valeur Légendaire": "Valeur Légendaire",
    "Mutagénèse Globale": "Mutagénèse Globale",
    "Fusion Ingénieuse": "Fusion Ingénieuse",
    "Savoir de Recyclage": "Savoir de Recyclage"
}

en_items = {
    "Savoir de Fusion": "Fusion Knowledge",
    "Magie Rituelle": "Ritual Magic",
    "Économie Globale": "Global Economy",
    "Valeur Rare": "Rare Value",
    "Automatisation Initiale": "Initial Automation",
    "Évolution d'Usine": "Factory Evolution",
    "Valeur de Base II": "Base Value II",
    "Valeur Commune": "Common Value",
    "Valeur Légendaire": "Legendary Value",
    "Mutagénèse Globale": "Global Mutagenesis",
    "Fusion Ingénieuse": "Ingenious Fusion",
    "Savoir de Recyclage": "Recycling Knowledge"
}

es_items = {
    "Savoir de Fusion": "Sabiduría de Fusión",
    "Magie Rituelle": "Magia Ritual",
    "Économie Globale": "Economía Global",
    "Valeur Rare": "Valor Raro",
    "Automatisation Initiale": "Automatización Inicial",
    "Évolution d'Usine": "Evolución de Fábrica",
    "Valeur de Base II": "Valor Base II",
    "Valeur Commune": "Valor Común",
    "Valeur Légendaire": "Valor Legendario",
    "Mutagénèse Globale": "Mutagénesis Global",
    "Fusion Ingénieuse": "Fusión Ingeniosa",
    "Savoir de Recyclage": "Sabiduría de Reciclaje"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

