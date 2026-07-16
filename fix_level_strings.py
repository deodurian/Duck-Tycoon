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
    "Bonus Actuels": "Bonus Actuels",
    "Prochain Palier (Niveau ": "Prochain Palier (Niveau ",
    "+25% Revenus & +5% Mutation": "+25% Revenus & +5% Mutation",
    "10 Gemmes": "10 Gemmes",
    "1 Perk Usine & 1 Perk Canard": "1 Perk Usine & 1 Perk Canard",
    "Revenus doublés !": "Revenus doublés !",
    "Niveau Joueur": "Niveau Joueur",
    "Fermer": "Fermer",
    "Comment gagner de l'XP ?": "Comment gagner de l'XP ?",
    "Vous gagnez de l'XP en accomplissant des missions et en ouvrant des caisses !": "Vous gagnez de l'XP en accomplissant des missions et en ouvrant des caisses !",
    "Compris": "Compris"
}

en_items = {
    "Bonus Actuels": "Current Bonuses",
    "Prochain Palier (Niveau ": "Next Milestone (Level ",
    "+25% Revenus & +5% Mutation": "+25% Income & +5% Mutation",
    "10 Gemmes": "10 Gems",
    "1 Perk Usine & 1 Perk Canard": "1 Factory Perk & 1 Duck Perk",
    "Revenus doublés !": "Income Doubled!",
    "Niveau Joueur": "Player Level",
    "Fermer": "Close",
    "Comment gagner de l'XP ?": "How to earn XP?",
    "Vous gagnez de l'XP en accomplissant des missions et en ouvrant des caisses !": "You earn XP by completing missions and opening crates!",
    "Compris": "Got it"
}

es_items = {
    "Bonus Actuels": "Bonos Actuales",
    "Prochain Palier (Niveau ": "Próximo Hito (Nivel ",
    "+25% Revenus & +5% Mutation": "+25% Ingresos y +5% Mutación",
    "10 Gemmes": "10 Gemas",
    "1 Perk Usine & 1 Perk Canard": "1 Perk Fábrica y 1 Perk Pato",
    "Revenus doublés !": "¡Ingresos duplicados!",
    "Niveau Joueur": "Nivel de Jugador",
    "Fermer": "Cerrar",
    "Comment gagner de l'XP ?": "¿Cómo ganar XP?",
    "Vous gagnez de l'XP en accomplissant des missions et en ouvrant des caisses !": "¡Ganas XP completando misiones y abriendo cajas!",
    "Compris": "Entendido"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

