import sys

file_path = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift"

with open(file_path, "r") as f:
    content = f.read()

missing_fr = """
        "Donne 50% d'argent en plus si un canard Commun est équipé": "Donne 50% d'argent en plus si un canard Commun est équipé",
        "Donne 80% d'argent en plus si un canard Commun est équipé": "Donne 80% d'argent en plus si un canard Commun est équipé",
        "Donne 100% d'argent en plus si un canard Commun est équipé": "Donne 100% d'argent en plus si un canard Commun est équipé",
        "Donne 60% d'argent en plus si un canard Peu Commun est équipé": "Donne 60% d'argent en plus si un canard Peu Commun est équipé",
        "Donne 100% d'argent en plus si un canard Peu Commun est équipé": "Donne 100% d'argent en plus si un canard Peu Commun est équipé",
        "Donne 80% d'argent en plus si un canard Rare est équipé": "Donne 80% d'argent en plus si un canard Rare est équipé",
        "Donne 210% d'argent en plus si un canard C/PC/Rare est équipé": "Donne 210% d'argent en plus si un canard C/PC/Rare est équipé",
        "Donne 300% d'argent en plus si un canard C/PC/Rare est équipé": "Donne 300% d'argent en plus si un canard C/PC/Rare est équipé",
        "Donne 100% d'argent en plus si un canard Épique/Lég. est équipé": "Donne 100% d'argent en plus si un canard Épique/Lég. est équipé",
        "Donne 130% d'argent en plus si un canard Épique/Lég/Myth est équipé": "Donne 130% d'argent en plus si un canard Épique/Lég/Myth est équipé",
        "Augmente de 100% la production si un canard Fusion 2 est équipé": "Augmente de 100% la production si un canard Fusion 2 est équipé",
        "Augmente de 150% la production si un canard Fusion 2/3 est équipé": "Augmente de 150% la production si un canard Fusion 2/3 est équipé",
        "Augmente de 150% la production si un canard Fusion 1-4 est équipé": "Augmente de 150% la production si un canard Fusion 1-4 est équipé",
        "Si équipé à un canard Commun : reçoit 20 niveaux": "Si équipé à un canard Commun : reçoit 20 niveaux",
        "Si équipé à un canard Commun : reçoit 30 niveaux": "Si équipé à un canard Commun : reçoit 30 niveaux",
        "Si équipé à un canard Peu Commun : reçoit 10 niveaux": "Si équipé à un canard Peu Commun : reçoit 10 niveaux",
        "Si équipé à un canard Peu Commun : reçoit 20 niveaux": "Si équipé à un canard Peu Commun : reçoit 20 niveaux",
        "Si équipé à un canard Rare : reçoit 5 niveaux": "Si équipé à un canard Rare : reçoit 5 niveaux",
        "Si équipé à un canard Rare : reçoit 10 niveaux": "Si équipé à un canard Rare : reçoit 10 niveaux",
        "Si équipé à un canard Épique : reçoit 20 niveaux": "Si équipé à un canard Épique : reçoit 20 niveaux",
        "Si équipé à un canard C/PC/Rare : reçoit 35 niveaux": "Si équipé à un canard C/PC/Rare : reçoit 35 niveaux",
        "Si équipé à un canard C/PC/Rare : reçoit 70 niveaux": "Si équipé à un canard C/PC/Rare : reçoit 70 niveaux",
        "Si équipé à un canard C/PC/Rare : reçoit 100 niveaux": "Si équipé à un canard C/PC/Rare : reçoit 100 niveaux",
        "Si équipé à un canard Épique/Lég/Myth : reçoit 40 niveaux": "Si équipé à un canard Épique/Lég/Myth : reçoit 40 niveaux",
        "Si équipé à un canard Épique/Lég/Myth : reçoit 80 niveaux": "Si équipé à un canard Épique/Lég/Myth : reçoit 80 niveaux",
"""

missing_en = """
        "Donne 50% d'argent en plus si un canard Commun est équipé": "Gives 50% more money if a Common duck is equipped",
        "Donne 80% d'argent en plus si un canard Commun est équipé": "Gives 80% more money if a Common duck is equipped",
        "Donne 100% d'argent en plus si un canard Commun est équipé": "Gives 100% more money if a Common duck is equipped",
        "Donne 60% d'argent en plus si un canard Peu Commun est équipé": "Gives 60% more money if an Uncommon duck is equipped",
        "Donne 100% d'argent en plus si un canard Peu Commun est équipé": "Gives 100% more money if an Uncommon duck is equipped",
        "Donne 80% d'argent en plus si un canard Rare est équipé": "Gives 80% more money if a Rare duck is equipped",
        "Donne 210% d'argent en plus si un canard C/PC/Rare est équipé": "Gives 210% more money if a C/UC/Rare duck is equipped",
        "Donne 300% d'argent en plus si un canard C/PC/Rare est équipé": "Gives 300% more money if a C/UC/Rare duck is equipped",
        "Donne 100% d'argent en plus si un canard Épique/Lég. est équipé": "Gives 100% more money if an Epic/Leg. duck is equipped",
        "Donne 130% d'argent en plus si un canard Épique/Lég/Myth est équipé": "Gives 130% more money if an Epic/Leg/Myth duck is equipped",
        "Augmente de 100% la production si un canard Fusion 2 est équipé": "Increases production by 100% if a Fusion 2 duck is equipped",
        "Augmente de 150% la production si un canard Fusion 2/3 est équipé": "Increases production by 150% if a Fusion 2/3 duck is equipped",
        "Augmente de 150% la production si un canard Fusion 1-4 est équipé": "Increases production by 150% if a Fusion 1-4 duck is equipped",
        "Si équipé à un canard Commun : reçoit 20 niveaux": "If equipped on a Common duck: receives 20 levels",
        "Si équipé à un canard Commun : reçoit 30 niveaux": "If equipped on a Common duck: receives 30 levels",
        "Si équipé à un canard Peu Commun : reçoit 10 niveaux": "If equipped on an Uncommon duck: receives 10 levels",
        "Si équipé à un canard Peu Commun : reçoit 20 niveaux": "If equipped on an Uncommon duck: receives 20 levels",
        "Si équipé à un canard Rare : reçoit 5 niveaux": "If equipped on a Rare duck: receives 5 levels",
        "Si équipé à un canard Rare : reçoit 10 niveaux": "If equipped on a Rare duck: receives 10 levels",
        "Si équipé à un canard Épique : reçoit 20 niveaux": "If equipped on an Epic duck: receives 20 levels",
        "Si équipé à un canard C/PC/Rare : reçoit 35 niveaux": "If equipped on a C/UC/Rare duck: receives 35 levels",
        "Si équipé à un canard C/PC/Rare : reçoit 70 niveaux": "If equipped on a C/UC/Rare duck: receives 70 levels",
        "Si équipé à un canard C/PC/Rare : reçoit 100 niveaux": "If equipped on a C/UC/Rare duck: receives 100 levels",
        "Si équipé à un canard Épique/Lég/Myth : reçoit 40 niveaux": "If equipped on an Epic/Leg/Myth duck: receives 40 levels",
        "Si équipé à un canard Épique/Lég/Myth : reçoit 80 niveaux": "If equipped on an Epic/Leg/Myth duck: receives 80 levels",
"""

missing_es = """
        "Donne 50% d'argent en plus si un canard Commun est équipé": "Da un 50% más de dinero si se equipa un pato Común",
        "Donne 80% d'argent en plus si un canard Commun est équipé": "Da un 80% más de dinero si se equipa un pato Común",
        "Donne 100% d'argent en plus si un canard Commun est équipé": "Da un 100% más de dinero si se equipa un pato Común",
        "Donne 60% d'argent en plus si un canard Peu Commun est équipé": "Da un 60% más de dinero si se equipa un pato Poco Común",
        "Donne 100% d'argent en plus si un canard Peu Commun est équipé": "Da un 100% más de dinero si se equipa un pato Poco Común",
        "Donne 80% d'argent en plus si un canard Rare est équipé": "Da un 80% más de dinero si se equipa un pato Raro",
        "Donne 210% d'argent en plus si un canard C/PC/Rare est équipé": "Da un 210% más de dinero si se equipa un pato C/PC/Raro",
        "Donne 300% d'argent en plus si un canard C/PC/Rare est équipé": "Da un 300% más de dinero si se equipa un pato C/PC/Raro",
        "Donne 100% d'argent en plus si un canard Épique/Lég. est équipé": "Da un 100% más de dinero si se equipa un pato Épico/Leg.",
        "Donne 130% d'argent en plus si un canard Épique/Lég/Myth est équipé": "Da un 130% más de dinero si se equipa un pato Épico/Leg/Mít",
        "Augmente de 100% la production si un canard Fusion 2 est équipé": "Aumenta la producción un 100% si se equipa un pato Fusión 2",
        "Augmente de 150% la production si un canard Fusion 2/3 est équipé": "Aumenta la producción un 150% si se equipa un pato Fusión 2/3",
        "Augmente de 150% la production si un canard Fusion 1-4 est équipé": "Aumenta la producción un 150% si se equipa un pato Fusión 1-4",
        "Si équipé à un canard Commun : reçoit 20 niveaux": "Si se equipa a un pato Común: recibe 20 niveles",
        "Si équipé à un canard Commun : reçoit 30 niveaux": "Si se equipa a un pato Común: recibe 30 niveles",
        "Si équipé à un canard Peu Commun : reçoit 10 niveaux": "Si se equipa a un pato Poco Común: recibe 10 niveles",
        "Si équipé à un canard Peu Commun : reçoit 20 niveaux": "Si se equipa a un pato Poco Común: recibe 20 niveles",
        "Si équipé à un canard Rare : reçoit 5 niveaux": "Si se equipa a un pato Raro: recibe 5 niveles",
        "Si équipé à un canard Rare : reçoit 10 niveaux": "Si se equipa a un pato Raro: recibe 10 niveles",
        "Si équipé à un canard Épique : reçoit 20 niveaux": "Si se equipa a un pato Épico: recibe 20 niveles",
        "Si équipé à un canard C/PC/Rare : reçoit 35 niveaux": "Si se equipa a un pato C/PC/Raro: recibe 35 niveles",
        "Si équipé à un canard C/PC/Rare : reçoit 70 niveaux": "Si se equipa a un pato C/PC/Raro: recibe 70 niveles",
        "Si équipé à un canard C/PC/Rare : reçoit 100 niveaux": "Si se equipa a un pato C/PC/Raro: recibe 100 niveles",
        "Si équipé à un canard Épique/Lég/Myth : reçoit 40 niveaux": "Si se equipa a un pato Épico/Leg/Mít: recibe 40 niveles",
        "Si équipé à un canard Épique/Lég/Myth : reçoit 80 niveaux": "Si se equipa a un pato Épico/Leg/Mít: recibe 80 niveles",
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
