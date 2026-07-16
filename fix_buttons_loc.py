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
    "Compris": "Compris",
    "Annuler": "Annuler",
    "Oui, Recycler": "Oui, Recycler",
    "Fermer": "Fermer",
    "OK": "OK",
    "Confirmer": "Confirmer",
    "Confirmer le recyclage": "Confirmer le recyclage"
}

en_items = {
    "Compris": "Got it",
    "Annuler": "Cancel",
    "Oui, Recycler": "Yes, Recycle",
    "Fermer": "Close",
    "OK": "OK",
    "Confirmer": "Confirm",
    "Confirmer le recyclage": "Confirm Recycling"
}

es_items = {
    "Compris": "Entendido",
    "Annuler": "Cancelar",
    "Oui, Recycler": "Sí, Reciclar",
    "Fermer": "Cerrar",
    "OK": "OK",
    "Confirmer": "Confirmar",
    "Confirmer le recyclage": "Confirmar Reciclaje"
}

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift', 'w', encoding='utf-8') as f:
    f.write(content)

