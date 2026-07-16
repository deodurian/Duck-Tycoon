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
    "Réinitialiser": "Réinitialiser"
}

en_items = {
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
    "Réinitialiser": "Reset"
}

es_items = {
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
    "Réinitialiser": "Restablecer"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

