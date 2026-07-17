import sys

file_path = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift"

with open(file_path, "r") as f:
    content = f.read()

missing_fr = """
        "Boost Revenu": "Boost Revenu",
        "Synergie": "Synergie",
        "Réduction Coût": "Réduction Coût",
        "Sacrifice": "Sacrifice",
        "Boost Fusion": "Boost Fusion",
        "Emplacement+": "Emplacement+",
        "Canard+": "Canard+",
        "Omnipotence Usine": "Omnipotence Usine",
        "Perk Usine": "Perk Usine",
        "Boost Valeur": "Boost Valeur",
        "Gènes": "Gènes",
        "Croissance": "Croissance",
        "Mutagène": "Mutagène",
        "Poids Fusion": "Poids Fusion",
        "Recyclage+": "Recyclage+",
        "Dieu Canard": "Dieu Canard",
        "Perk Canard": "Perk Canard",
"""

missing_en = """
        "Boost Revenu": "Income Boost",
        "Synergie": "Synergy",
        "Réduction Coût": "Cost Reduction",
        "Sacrifice": "Sacrifice",
        "Boost Fusion": "Fusion Boost",
        "Emplacement+": "Extra Slot",
        "Canard+": "Extra Duck",
        "Omnipotence Usine": "Factory Omnipotence",
        "Perk Usine": "Factory Perk",
        "Boost Valeur": "Value Boost",
        "Gènes": "Genes",
        "Croissance": "Growth",
        "Mutagène": "Mutagen",
        "Poids Fusion": "Fusion Weight",
        "Recyclage+": "Recycling+",
        "Dieu Canard": "Duck God",
        "Perk Canard": "Duck Perk",
"""

missing_es = """
        "Boost Revenu": "Mejora de Ingresos",
        "Synergie": "Sinergia",
        "Réduction Coût": "Reducción de Costo",
        "Sacrifice": "Sacrificio",
        "Boost Fusion": "Mejora de Fusión",
        "Emplacement+": "Ranura Extra",
        "Canard+": "Pato Extra",
        "Omnipotence Usine": "Omnipotencia de Fábrica",
        "Perk Usine": "Perk de Fábrica",
        "Boost Valeur": "Mejora de Valor",
        "Gènes": "Genes",
        "Croissance": "Crecimiento",
        "Mutagène": "Mutágeno",
        "Poids Fusion": "Peso de Fusión",
        "Recyclage+": "Reciclaje+",
        "Dieu Canard": "Dios Pato",
        "Perk Canard": "Perk de Pato",
"""

def insert_before_bracket(content, lang_start, insert_str):
    idx = content.find(lang_start)
    if idx == -1: return content
    if "french" in lang_start:
        return content.replace("    ],\n    .en: [", insert_str + "    ],\n    .en: [")
    elif "en" in lang_start:
        return content.replace("    ],\n    .es: [", insert_str + "    ],\n    .es: [")
    elif "es" in lang_start:
        return content.replace("    ]\n]", insert_str + "    ]\n]")
    return content

c2 = insert_before_bracket(content, ".fr: [", missing_fr)
c3 = insert_before_bracket(c2, ".en: [", missing_en)
c4 = insert_before_bracket(c3, ".es: [", missing_es)

with open(file_path, "w") as f:
    f.write(c4)
print("Done")
