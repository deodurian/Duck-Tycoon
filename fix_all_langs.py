import re

def append_to_dict(content, lang, new_items):
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return content
    
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return content
    
    insert_idx = start_idx + end_match.start()
    
    # Check if key is in THIS lang section
    lang_content = content[start_idx:insert_idx]
    
    items_str = ""
    for k, v in new_items.items():
        v_escaped = v.replace('\n', '\\n').replace('"', '\\"')
        k_escaped = k.replace('\n', '\\n').replace('"', '\\"')
        if f'"{k_escaped}":' not in lang_content:
            items_str += f',\n        "{k_escaped}": "{v_escaped}"'
            
    return content[:insert_idx] + items_str + content[insert_idx:]

fr_items = {
    # Usines
    "usine active": "usine active",
    "usines actives": "usines actives",
    "Usine": "Usine",
    "Canard": "Canard",
    "Missions": "Missions",
    "Principales": "Principales",
    "Quotidiennes": "Quotidiennes",
    
    # Shop
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
    "Acheter des Gemmes": "Acheter des Gemmes",
    
    # Settings
    "Restaurer les achats": "Restaurer les achats",
    "Réinitialiser ma progression": "Réinitialiser ma progression",
    "Cette action est irréversible. Vous perdrez tout votre argent, vos usines et vos canards.": "Cette action est irréversible. Vous perdrez tout votre argent, vos usines et vos canards.",
    "Langue": "Langue",
    "Format des Nombres": "Format des Nombres",
    "Affichage": "Affichage",
    "Paramètres": "Paramètres",
    "Boutique": "Boutique",
    "CanardFactory v1.0": "CanardFactory v1.0",
    "Annuler": "Annuler",
    "Réinitialiser": "Réinitialiser",
    "scientifique": "scientifique",
    "lettres": "lettres",
    
    # Levels
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
    "Compris": "Compris",
    
    # Prestige
    "Le Prestige": "Le Prestige",
    "Bonus Passifs": "Bonus Passifs",
    "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.": "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.",
    "Atteindre 10B d'argent": "Atteindre 10B d'argent",
    "Prestige Disponible !": "Prestige Disponible !",
    "Effectuer un Prestige": "Effectuer un Prestige",
    "libres": "libres",
    "Dépensées:": "Dépensées:",
    "ACQUIS": "ACQUIS",
    
    # Others
    "Chargement des canards...": "Chargement des canards...",
    "Revenus :": "Revenus :",
    "Mutation :": "Mutation :",
    "et": "et",
    "minutes": "minutes",
    "Perk": "Perk"
}

en_items = {
    # Usines
    "usine active": "active factory",
    "usines actives": "active factories",
    "Usine": "Factory",
    "Canard": "Duck",
    "Missions": "Missions",
    "Principales": "Main",
    "Quotidiennes": "Daily",
    
    # Shop
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
    "Acheter des Gemmes": "Buy Gems",
    
    # Settings
    "Restaurer les achats": "Restore Purchases",
    "Réinitialiser ma progression": "Reset My Progress",
    "Cette action est irréversible. Vous perdrez tout votre argent, vos usines et vos canards.": "This action is irreversible. You will lose all your money, factories, and ducks.",
    "Langue": "Language",
    "Format des Nombres": "Number Format",
    "Affichage": "Display",
    "Paramètres": "Settings",
    "Boutique": "Shop",
    "CanardFactory v1.0": "CanardFactory v1.0",
    "Annuler": "Cancel",
    "Réinitialiser": "Reset",
    "scientifique": "scientific",
    "lettres": "letters",
    
    # Levels
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
    "Compris": "Got it",
    
    # Prestige
    "Le Prestige": "Prestige",
    "Bonus Passifs": "Passive Bonuses",
    "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.": "Perform a Prestige to earn stars and unlock powerful passive bonuses.",
    "Atteindre 10B d'argent": "Reach 10B money",
    "Prestige Disponible !": "Prestige Available!",
    "Effectuer un Prestige": "Perform Prestige",
    "libres": "available",
    "Dépensées:": "Spent:",
    "ACQUIS": "ACQUIRED",
    
    # Others
    "Chargement des canards...": "Loading ducks...",
    "Revenus :": "Income:",
    "Mutation :": "Mutation:",
    "et": "and",
    "minutes": "minutes",
    "Perk": "Perk"
}

es_items = {
    # Usines
    "usine active": "fábrica activa",
    "usines actives": "fábricas activas",
    "Usine": "Fábrica",
    "Canard": "Pato",
    "Missions": "Misiones",
    "Principales": "Principales",
    "Quotidiennes": "Diarias",
    
    # Shop
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
    "Acheter des Gemmes": "Comprar Gemas",
    
    # Settings
    "Restaurer les achats": "Restaurar Compras",
    "Réinitialiser ma progression": "Restablecer mi progreso",
    "Cette action est irréversible. Vous perdrez tout votre argent, vos usines et vos canards.": "Esta acción es irreversible. Perderás todo tu dinero, fábricas y patos.",
    "Langue": "Idioma",
    "Format des Nombres": "Formato de Números",
    "Affichage": "Pantalla",
    "Paramètres": "Ajustes",
    "Boutique": "Tienda",
    "CanardFactory v1.0": "CanardFactory v1.0",
    "Annuler": "Cancelar",
    "Réinitialiser": "Restablecer",
    "scientifique": "científico",
    "lettres": "letras",
    
    # Levels
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
    "Compris": "Entendido",
    
    # Prestige
    "Le Prestige": "Prestigio",
    "Bonus Passifs": "Bonos Pasivos",
    "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.": "Realiza un Prestigio para ganar estrellas y desbloquear poderosos bonos pasivos.",
    "Atteindre 10B d'argent": "Alcanzar 10B de dinero",
    "Prestige Disponible !": "¡Prestigio Disponible!",
    "Effectuer un Prestige": "Realizar Prestigio",
    "libres": "disponibles",
    "Dépensées:": "Gastadas:",
    "ACQUIS": "ADQUIRIDO",
    
    # Others
    "Chargement des canards...": "Cargando patos...",
    "Revenus :": "Ingresos:",
    "Mutation :": "Mutación:",
    "et": "y",
    "minutes": "minutos",
    "Perk": "Perk"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

