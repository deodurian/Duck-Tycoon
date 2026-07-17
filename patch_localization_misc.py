import sys

file_path = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift"

with open(file_path, "r") as f:
    content = f.read()

missing_fr = """
        "Gemmes": "Gemmes",
        "canards au total": "canards au total",
        "canards": "canards",
        "canard": "canard",
        "Chargement des canards...": "Chargement des canards...",
        "Défaut (K, M, B)": "Défaut (K, M, B)",
        "Standard (a, b, c)": "Standard (a, b, c)",
        "Scientifique (e3, e6)": "Scientifique (e3, e6)",
"""

missing_en = """
        "Gemmes": "Gems",
        "canards au total": "ducks in total",
        "canards": "ducks",
        "canard": "duck",
        "Chargement des canards...": "Loading ducks...",
        "Défaut (K, M, B)": "Default (K, M, B)",
        "Standard (a, b, c)": "Standard (a, b, c)",
        "Scientifique (e3, e6)": "Scientific (e3, e6)",
"""

missing_es = """
        "Gemmes": "Gemas",
        "canards au total": "patos en total",
        "canards": "patos",
        "canard": "pato",
        "Chargement des canards...": "Cargando patos...",
        "Défaut (K, M, B)": "Predeterminado (K, M, B)",
        "Standard (a, b, c)": "Estándar (a, b, c)",
        "Scientifique (e3, e6)": "Científico (e3, e6)",
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
