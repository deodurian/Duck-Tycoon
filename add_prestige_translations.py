# -*- coding: utf-8 -*-
import re

MISSING_TRANSLATIONS = {
    # Inventory Sort Options
    "Défaut": ("Défaut", "Default", "Defecto"),
    "Recyclage 🧬 (Max)": ("Recyclage 🧬 (Max)", "Recycle 🧬 (Max)", "Reciclaje 🧬 (Máx)"),
    "Recyclage 🧬 (Min)": ("Recyclage 🧬 (Min)", "Recycle 🧬 (Min)", "Reciclaje 🧬 (Mín)"),
    "Revenus 💰 (Max)": ("Revenus 💰 (Max)", "Income 💰 (Max)", "Ingresos 💰 (Máx)"),
    
    # PrestigeUpgrade Names
    "Automatisation Initiale": ("Automatisation Initiale", "Initial Automation", "Automatización Inicial"),
    "Valeur Commune": ("Valeur Commune", "Common Value", "Valor Común"),
    "Valeur Rare": ("Valeur Rare", "Rare Value", "Valor Raro"),
    "Valeur Légendaire": ("Valeur Légendaire", "Legendary Value", "Valor Legendario"),
    "Économie Globale": ("Économie Globale", "Global Economy", "Economía Global"),
    "Savoir de Fusion": ("Savoir de Fusion", "Fusion Knowledge", "Conocimiento de Fusión"),
    "Valeur de Base II": ("Valeur de Base II", "Base Value II", "Valor Base II"),
    "Évolution d'Usine": ("Évolution d'Usine", "Factory Evolution", "Evolución de Fábrica"),
    "Savoir de Recyclage": ("Savoir de Recyclage", "Recycling Knowledge", "Conocimiento de Reciclaje"),
    "Mutagénèse Globale": ("Mutagénèse Globale", "Global Mutagenesis", "Mutagénesis Global"),
    "Magie Rituelle": ("Magie Rituelle", "Ritual Magic", "Magia Ritual"),
    "Fusion Ingénieuse": ("Fusion Ingénieuse", "Ingenious Fusion", "Fusión Ingeniosa"),

    # PrestigeUpgrade Descriptions
    "Débloque l'accès aux automatisations dans l'onglet des améliorations.": ("Débloque l'accès aux automatisations dans l'onglet des améliorations.", "Unlocks access to automations in the upgrades tab.", "Desbloquea el acceso a las automatizaciones en la pestaña de mejoras."),
    "+100 % à la valeur des canards Communs et Peu Communs.": ("+100 % à la valeur des canards Communs et Peu Communs.", "+100% value to Common and Uncommon ducks.", "+100% de valor a los patos Comunes y Poco Comunes."),
    "+75 % à la valeur des canards Rares et Épiques.": ("+75 % à la valeur des canards Rares et Épiques.", "+75% value to Rare and Epic ducks.", "+75% de valor a los patos Raros y Épicos."),
    "+50 % à la valeur des canards Légendaires et Mythiques.": ("+50 % à la valeur des canards Légendaires et Mythiques.", "+50% value to Legendary and Mythic ducks.", "+50% de valor a los patos Legendarios y Míticos."),
    "+30 % à tous les revenus d'argent.": ("+30 % à tous les revenus d'argent.", "+30% to all money income.", "+30% a todos los ingresos de dinero."),
    "La mécanique de Fusion est débloquée d'office, même après un prestige.": ("La mécanique de Fusion est débloquée d'office, même après un prestige.", "Fusion mechanics are unlocked by default, even after a prestige.", "Las mecánicas de fusión están desbloqueadas por defecto, incluso después de un prestigio."),
    "+50 % à la valeur des canards Communs, Peu Communs et Rares.": ("+50 % à la valeur des canards Communs, Peu Communs et Rares.", "+50% value to Common, Uncommon, and Rare ducks.", "+50% de valor a los patos Comunes, Poco Comunes y Raros."),
    "Débloque la première Évolution de l'usine (permet de dépasser le niveau 100).": ("Débloque la première Évolution de l'usine (permet de dépasser le niveau 100).", "Unlocks the first Factory Evolution (allows exceeding level 100).", "Desbloquea la primera Evolución de Fábrica (permite superar el nivel 100)."),
    "La mécanique de Recyclage est débloquée d'office.": ("La mécanique de Recyclage est débloquée d'office.", "Recycling mechanics are unlocked by default.", "Las mecánicas de reciclaje están desbloqueadas por defecto."),
    "+200 % à tous les revenus d'ADN.": ("+200 % à tous les revenus d'ADN.", "+200% to all DNA income.", "+200% a todos los ingresos de ADN."),
    "Le gain de base du rituel passe de x2 à x3 (et le Rituel Doré passe de x10 à x15).": ("Le gain de base du rituel passe de x2 à x3 (et le Rituel Doré passe de x10 à x15).", "Base ritual gain increases from x2 to x3 (and Golden Ritual from x10 to x15).", "La ganancia base del ritual aumenta de x2 a x3 (y el Ritual Dorado de x10 a x15)."),
    "Lors d'une fusion, le canard avec la plus haute valeur est compté 2 fois !": ("Lors d'une fusion, le canard avec la plus haute valeur est compté 2 fois !", "During a fusion, the duck with the highest value is counted 2 times!", "¡Durante una fusión, el pato con el mayor valor se cuenta 2 veces!"),
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

print("Prestige translations added!")
