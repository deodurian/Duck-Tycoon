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
    "Le Prestige": "Le Prestige",
    "Êtes-vous sûr ? Vous allez recommencer à zéro, mais vous conserverez vos étoiles pour de puissants bonus passifs permanents et l'Arbre Stellaire.": "Êtes-vous sûr ? Vous allez recommencer à zéro, mais vous conserverez vos étoiles pour de puissants bonus passifs permanents et l'Arbre Stellaire.",
    "Bonus Passifs": "Bonus Passifs",
    "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.": "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.",
    "Atteindre 10B d'argent": "Atteindre 10B d'argent",
    "Prestige Disponible !": "Prestige Disponible !",
    "Effectuer un Prestige": "Effectuer un Prestige",
    "libres": "libres",
    "Dépensées:": "Dépensées:",
    "ACQUIS": "ACQUIS"
}

en_items = {
    "Le Prestige": "Prestige",
    "Êtes-vous sûr ? Vous allez recommencer à zéro, mais vous conserverez vos étoiles pour de puissants bonus passifs permanents et l'Arbre Stellaire.": "Are you sure? You will start from zero, but keep your stars for powerful permanent passive bonuses and the Stellar Tree.",
    "Bonus Passifs": "Passive Bonuses",
    "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.": "Perform a Prestige to earn stars and unlock powerful passive bonuses.",
    "Atteindre 10B d'argent": "Reach 10B money",
    "Prestige Disponible !": "Prestige Available!",
    "Effectuer un Prestige": "Perform Prestige",
    "libres": "available",
    "Dépensées:": "Spent:",
    "ACQUIS": "ACQUIRED"
}

es_items = {
    "Le Prestige": "Prestigio",
    "Êtes-vous sûr ? Vous allez recommencer à zéro, mais vous conserverez vos étoiles pour de puissants bonus passifs permanents et l'Arbre Stellaire.": "¿Estás seguro? Empezarás de cero, pero conservarás tus estrellas para poderosos bonos pasivos permanentes y el Árbol Estelar.",
    "Bonus Passifs": "Bonos Pasivos",
    "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.": "Realiza un Prestigio para ganar estrellas y desbloquear poderosos bonos pasivos.",
    "Atteindre 10B d'argent": "Alcanzar 10B de dinero",
    "Prestige Disponible !": "¡Prestigio Disponible!",
    "Effectuer un Prestige": "Realizar Prestigio",
    "libres": "disponibles",
    "Dépensées:": "Gastadas:",
    "ACQUIS": "ADQUIRIDO"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

