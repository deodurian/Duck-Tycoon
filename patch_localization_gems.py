import sys

file_path = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift"

with open(file_path, "r") as f:
    content = f.read()

missing_fr = """
        "Pas assez de gemmes !": "Pas assez de gemmes !",
        "Packs d'Argent": "Packs d'Argent",
        "Packs d'ADN": "Packs d'ADN",
        "Achats Premium": "Achats Premium",
"""

missing_en = """
        "Pas assez de gemmes !": "Not enough gems!",
        "Packs d'Argent": "Money Packs",
        "Packs d'ADN": "DNA Packs",
        "Achats Premium": "Premium Purchases",
"""

missing_es = """
        "Pas assez de gemmes !": "¡No hay suficientes gemas!",
        "Packs d'Argent": "Packs de Dinero",
        "Packs d'ADN": "Packs de ADN",
        "Achats Premium": "Compras Premium",
"""

def insert_before_bracket(content, lang_start, insert_str):
    idx = content.find(lang_start)
    if idx == -1: return content
    if ".fr: [" in lang_start:
        return content.replace("    ],\n    .en: [", insert_str + "    ],\n    .en: [")
    elif ".en: [" in lang_start:
        return content.replace("    ],\n    .es: [", insert_str + "    ],\n    .es: [")
    elif ".es: [" in lang_start:
        return content.replace("    ]\n]", insert_str + "    ]\n]")
    return content

c2 = insert_before_bracket(content, ".fr: [", missing_fr)
c3 = insert_before_bracket(c2, ".en: [", missing_en)
c4 = insert_before_bracket(c3, ".es: [", missing_es)

with open(file_path, "w") as f:
    f.write(c4)
print("Done")
