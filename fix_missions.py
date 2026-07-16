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
    "Le Commencement": "Le Commencement",
    "Ouvrir une caisse en bois": "Ouvrir une caisse en bois",
    "Au Travail": "Au Travail",
    "Équiper un canard dans une usine": "Équiper un canard dans une usine",
    "Développement": "Développement",
    "Améliorer 10 fois une usine": "Améliorer 10 fois une usine",
    "Fournisseur": "Fournisseur",
    "Ouvrir 10 caisses": "Ouvrir 10 caisses",
    "Tri Sélectif": "Tri Sélectif",
    "Recycler 1 canard": "Recycler 1 canard",
    "Science !": "Science !",
    "Débloquer le labo de fusion": "Débloquer le labo de fusion",
    "Mutation": "Mutation",
    "Faire une fusion de canard commun": "Faire une fusion de canard commun",
    "Capitaliste": "Capitaliste",
    "Atteindre une production de 300 d'argent par seconde": "Atteindre une production de 300 d'argent par seconde",
    "Boucher": "Boucher",
    "Avoir recyclé au moins 30 canards jusqu'à présent": "Avoir recyclé au moins 30 canards jusqu'à présent",
    "Gavage": "Gavage",
    "Augmenter la taille de 3 canards": "Augmenter la taille de 3 canards",
    "Anomalie": "Anomalie",
    "Augmenter la mutation d'un canard": "Augmenter la mutation d'un canard",
    "Vétéran": "Vétéran",
    "Mettre un canard niveau 20": "Mettre un canard niveau 20",
    "Grand Ménage": "Grand Ménage",
    "Faire un recyclage de masse": "Faire un recyclage de masse",
    "Arbre de Compétences": "Arbre de Compétences",
    "Débloquer 5 améliorations « déblocages » de plus": "Débloquer 5 améliorations « déblocages » de plus",
    "Automatisation": "Automatisation",
    "Faire une auto fusion": "Faire une auto fusion",
    "La Totale": "La Totale",
    "Faire une mega fusion": "Faire une mega fusion",
    "Unboxing": "Unboxing",
    "Faire une ouverture multiple d'au moins 150 canards": "Faire une ouverture multiple d'au moins 150 canards",
    "Millionnaire": "Millionnaire",
    "Atteindre 1M d'argent/sec": "Atteindre 1M d'argent/sec",
    "Culte": "Culte",
    "Faire un rituel canarifique": "Faire un rituel canarifique",
    "Elite": "Elite",
    "Attribuer 5 canards de niveau au moins 30 à 5 usines de niveau au moins 30": "Attribuer 5 canards de niveau au moins 30 à 5 usines de niveau au moins 30",
    "Équipement": "Équipement",
    "Attribuer un perk à une usine ou un canard": "Attribuer un perk à une usine ou un canard",
    "Destructeur": "Destructeur",
    "Avoir recyclé depuis le début au moins 50K canards": "Avoir recyclé depuis le début au moins 50K canards",
    "Savoir Absolu": "Savoir Absolu",
    "Avoir débloqué au moins 15 améliorations jusque là": "Avoir débloqué au moins 15 améliorations jusque là",
    "Multimillionnaire": "Multimillionnaire",
    "Avoir au moins 50M d'argent/sec": "Avoir au moins 50M d'argent/sec",
    "Ouverture Quotidienne": "Ouverture Quotidienne",
    "Recyclage Quotidien": "Recyclage Quotidien",
    "Recycler 10 canards": "Recycler 10 canards",
    "Fusion Quotidienne": "Fusion Quotidienne",
    "Faire 10 fusions": "Faire 10 fusions",
    "Rituel Quotidien": "Rituel Quotidien",
    "Achats Quotidiens": "Achats Quotidiens",
    "Acheter 10 améliorations": "Acheter 10 améliorations",
    "Niveaux Quotidiens": "Niveaux Quotidiens",
    "Monter de 20 niveaux soit un canard soit une usine": "Monter de 20 niveaux soit un canard soit une usine",
    "Le Grand Chelem": "Le Grand Chelem",
    "Avoir fait toutes les missions quotidiennes précédentes": "Avoir fait toutes les missions quotidiennes précédentes"
}

en_items = {
    "Le Commencement": "The Beginning",
    "Ouvrir une caisse en bois": "Open a wooden crate",
    "Au Travail": "To Work",
    "Équiper un canard dans une usine": "Equip a duck in a factory",
    "Développement": "Development",
    "Améliorer 10 fois une usine": "Upgrade a factory 10 times",
    "Fournisseur": "Supplier",
    "Ouvrir 10 caisses": "Open 10 crates",
    "Tri Sélectif": "Sorting",
    "Recycler 1 canard": "Recycle 1 duck",
    "Science !": "Science!",
    "Débloquer le labo de fusion": "Unlock the fusion lab",
    "Mutation": "Mutation",
    "Faire une fusion de canard commun": "Fuse a common duck",
    "Capitaliste": "Capitalist",
    "Atteindre une production de 300 d'argent par seconde": "Reach a production of 300 money per second",
    "Boucher": "Butcher",
    "Avoir recyclé au moins 30 canards jusqu'à présent": "Recycle at least 30 ducks",
    "Gavage": "Force-Feeding",
    "Augmenter la taille de 3 canards": "Increase the size of 3 ducks",
    "Anomalie": "Anomaly",
    "Augmenter la mutation d'un canard": "Increase a duck's mutation",
    "Vétéran": "Veteran",
    "Mettre un canard niveau 20": "Reach level 20 with a duck",
    "Grand Ménage": "Spring Cleaning",
    "Faire un recyclage de masse": "Perform a bulk recycle",
    "Arbre de Compétences": "Skill Tree",
    "Débloquer 5 améliorations « déblocages » de plus": "Unlock 5 more upgrades",
    "Automatisation": "Automation",
    "Faire une auto fusion": "Perform an auto fusion",
    "La Totale": "The Full Package",
    "Faire une mega fusion": "Perform a mega fusion",
    "Unboxing": "Unboxing",
    "Faire une ouverture multiple d'au moins 150 canards": "Perform a bulk opening of at least 150 ducks",
    "Millionnaire": "Millionaire",
    "Atteindre 1M d'argent/sec": "Reach 1M money/sec",
    "Culte": "Cult",
    "Faire un rituel canarifique": "Perform a duck ritual",
    "Elite": "Elite",
    "Attribuer 5 canards de niveau au moins 30 à 5 usines de niveau au moins 30": "Assign 5 ducks of level 30+ to 5 factories of level 30+",
    "Équipement": "Equipment",
    "Attribuer un perk à une usine ou un canard": "Equip a perk to a factory or duck",
    "Destructeur": "Destroyer",
    "Avoir recyclé depuis le début au moins 50K canards": "Recycle 50K ducks total",
    "Savoir Absolu": "Absolute Knowledge",
    "Avoir débloqué au moins 15 améliorations jusque là": "Unlock at least 15 upgrades total",
    "Multimillionnaire": "Multimillionaire",
    "Avoir au moins 50M d'argent/sec": "Reach 50M money/sec",
    "Ouverture Quotidienne": "Daily Opening",
    "Recyclage Quotidien": "Daily Recycling",
    "Recycler 10 canards": "Recycle 10 ducks",
    "Fusion Quotidienne": "Daily Fusion",
    "Faire 10 fusions": "Perform 10 fusions",
    "Rituel Quotidien": "Daily Ritual",
    "Achats Quotidiens": "Daily Purchases",
    "Acheter 10 améliorations": "Buy 10 upgrades",
    "Niveaux Quotidiens": "Daily Levels",
    "Monter de 20 niveaux soit un canard soit une usine": "Level up a duck or factory by 20 levels",
    "Le Grand Chelem": "Grand Slam",
    "Avoir fait toutes les missions quotidiennes précédentes": "Complete all previous daily missions"
}

es_items = {
    "Le Commencement": "El Comienzo",
    "Ouvrir une caisse en bois": "Abre una caja de madera",
    "Au Travail": "Al Trabajo",
    "Équiper un canard dans une usine": "Equipa un pato en una fábrica",
    "Développement": "Desarrollo",
    "Améliorer 10 fois une usine": "Mejora una fábrica 10 veces",
    "Fournisseur": "Proveedor",
    "Ouvrir 10 caisses": "Abre 10 cajas",
    "Tri Sélectif": "Reciclaje Selectivo",
    "Recycler 1 canard": "Recicla 1 pato",
    "Science !": "¡Ciencia!",
    "Débloquer le labo de fusion": "Desbloquea el laboratorio de fusión",
    "Mutation": "Mutación",
    "Faire une fusion de canard commun": "Fusiona un pato común",
    "Capitaliste": "Capitalista",
    "Atteindre une production de 300 d'argent par seconde": "Alcanza una producción de 300 dinero por segundo",
    "Boucher": "Carnicero",
    "Avoir recyclé au moins 30 canards jusqu'à présent": "Recicla al menos 30 patos en total",
    "Gavage": "Ceba",
    "Augmenter la taille de 3 canards": "Aumenta el tamaño de 3 patos",
    "Anomalie": "Anomalía",
    "Augmenter la mutation d'un canard": "Aumenta la mutación de un pato",
    "Vétéran": "Veterano",
    "Mettre un canard niveau 20": "Sube un pato al nivel 20",
    "Grand Ménage": "Limpieza a Fondo",
    "Faire un recyclage de masse": "Haz un reciclaje masivo",
    "Arbre de Compétences": "Árbol de Habilidades",
    "Débloquer 5 améliorations « déblocages » de plus": "Desbloquea 5 mejoras más",
    "Automatisation": "Automatización",
    "Faire une auto fusion": "Haz una auto fusión",
    "La Totale": "El Paquete Completo",
    "Faire une mega fusion": "Haz una mega fusión",
    "Unboxing": "Unboxing",
    "Faire une ouverture multiple d'au moins 150 canards": "Abre 150 cajas a la vez",
    "Millionnaire": "Millonario",
    "Atteindre 1M d'argent/sec": "Alcanza 1M de dinero/seg",
    "Culte": "Culto",
    "Faire un rituel canarifique": "Haz un ritual de patos",
    "Elite": "Élite",
    "Attribuer 5 canards de niveau au moins 30 à 5 usines de niveau au moins 30": "Asigna 5 patos nivel 30+ a fábricas de nivel 30+",
    "Équipement": "Equipamiento",
    "Attribuer un perk à une usine ou un canard": "Equipa un perk en un pato o fábrica",
    "Destructeur": "Destructor",
    "Avoir recyclé depuis le début au moins 50K canards": "Recicla 50K patos en total",
    "Savoir Absolu": "Saber Absoluto",
    "Avoir débloqué au moins 15 améliorations jusque là": "Desbloquea 15 mejoras en total",
    "Multimillionnaire": "Multimillonario",
    "Avoir au moins 50M d'argent/sec": "Alcanza 50M de dinero/seg",
    "Ouverture Quotidienne": "Apertura Diaria",
    "Recyclage Quotidien": "Reciclaje Diario",
    "Recycler 10 canards": "Recicla 10 patos",
    "Fusion Quotidienne": "Fusión Diaria",
    "Faire 10 fusions": "Haz 10 fusiones",
    "Rituel Quotidien": "Ritual Diario",
    "Achats Quotidiens": "Compras Diarias",
    "Acheter 10 améliorations": "Compra 10 mejoras",
    "Niveaux Quotidiens": "Niveles Diarios",
    "Monter de 20 niveaux soit un canard soit une usine": "Sube de nivel un pato o fábrica 20 veces",
    "Le Grand Chelem": "Gran Slam",
    "Avoir fait toutes les missions quotidiennes précédentes": "Completa todas las misiones diarias previas"
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = append_to_dict(content, "fr", fr_items)
content = append_to_dict(content, "en", en_items)
content = append_to_dict(content, "es", es_items)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

