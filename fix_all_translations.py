# -*- coding: utf-8 -*-
import re

# Complete translation dictionary for ALL tr() keys used in the codebase
# Key = French key (as used in tr("...")), Value = (English, Spanish)
TRANSLATIONS = {
    # Emojis & symbols (pass-through)
    "⭐": ("⭐", "⭐"),
    "⭐️": ("⭐️", "⭐️"),
    "🎒": ("🎒", "🎒"),
    "🎯": ("🎯", "🎯"),
    "💀": ("💀", "💀"),
    "💎": ("💎", "💎"),
    "💰": ("💰", "💰"),
    "🦆": ("🦆", "🦆"),
    "🧬": ("🧬", "🧬"),
    "•": ("•", "•"),
    "/": ("/", "/"),
    "×1": ("×1", "×1"),
    "×10": ("×10", "×10"),
    "×2": ("×2", "×2"),
    "x2": ("x2", "x2"),
    "x10": ("x10", "x10"),
    "OK": ("OK", "OK"),
    "?": ("?", "?"),
    "/ sec": ("/ sec", "/ seg"),

    # Rarity short codes
    "COM": ("COM", "COM"),
    "PEU": ("UNC", "POC"),
    "RAR": ("RAR", "RAR"),
    "EPI": ("EPI", "EPI"),
    "LEG": ("LEG", "LEG"),
    "MYT": ("MYT", "MYT"),

    # Rarity names (crate opening)
    "COMMUN !": ("COMMON!", "¡COMÚN!"),
    "PEU COMMUN !": ("UNCOMMON!", "¡POCO COMÚN!"),
    "RARE !": ("RARE!", "¡RARO!"),
    "ÉPIQUE !": ("EPIC!", "¡ÉPICO!"),
    "LÉGENDAIRE !!!": ("LEGENDARY!!!", "¡¡¡LEGENDARIO!!!"),
    "MYTHIQUE !!!": ("MYTHIC!!!", "¡¡¡MÍTICO!!!"),

    # Game actions
    "Jouer": ("Play", "Jugar"),
    "Réinitialiser": ("Reset", "Reiniciar"),
    "Sélectionner": ("Select", "Seleccionar"),
    "Terminé": ("Done", "Terminado"),
    "Réclamer": ("Claim", "Reclamar"),
    "Améliorer": ("Upgrade", "Mejorar"),
    "Ouvrir": ("Open", "Abrir"),
    "Acheter": ("Buy", "Comprar"),
    "Vendre": ("Sell", "Vender"),
    "Recycler": ("Recycle", "Reciclar"),
    "Fermer": ("Close", "Cerrar"),
    "Annuler": ("Cancel", "Cancelar"),
    "Confirmer": ("Confirm", "Confirmar"),
    "Compris": ("Got it", "Entendido"),
    "Retirer": ("Remove", "Retirar"),
    "Muter": ("Mutate", "Mutar"),
    "Évoluer": ("Evolve", "Evolucionar"),
    "FUSIONNER": ("FUSE", "FUSIONAR"),
    "Max": ("Max", "Máx"),
    "MAX": ("MAX", "MÁX"),
    "MAXIMUM": ("MAXIMUM", "MÁXIMO"),
    "Auto": ("Auto", "Auto"),
    "Multiple": ("Multiple", "Múltiple"),
    "Total": ("Total", "Total"),

    # Tabs & navigation
    "Usines": ("Factories", "Fábricas"),
    "Canards": ("Ducks", "Patos"),
    "Amélio.": ("Upgrades", "Mejoras"),
    "Boutique": ("Shop", "Tienda"),
    "Rituel": ("Ritual", "Ritual"),
    "Prestige": ("Prestige", "Prestigio"),
    "Banque": ("Bank", "Banco"),
    "Informations": ("Details", "Detalles"),
    "Fusion": ("Fusion", "Fusión"),
    "Recyclage": ("Recycle", "Reciclaje"),
    "Inventaire": ("Inventory", "Inventario"),
    "Paramètres": ("Settings", "Ajustes"),
    "Labo": ("Lab", "Laboratorio"),
    "Missions": ("Missions", "Misiones"),
    "Principales": ("Main", "Principales"),
    "Quotidiennes": ("Daily", "Diarias"),
    "Perks": ("Perks", "Perks"),
    "Statistiques": ("Statistics", "Estadísticas"),

    # Main game UI
    "Niveau": ("Level", "Nivel"),
    "Niv. ": ("Lv. ", "Niv. "),
    "Niv ": ("Lv ", "Niv "),
    "Nv. ": ("Lv. ", "Niv. "),
    "Lvl ": ("Lvl ", "Lvl "),
    "Niveau ": ("Level ", "Nivel "),
    "⭐ Niveau ": ("⭐ Level ", "⭐ Nivel "),
    "Palier ": ("Tier ", "Nivel "),
    "Évo. ": ("Evo. ", "Evo. "),
    "Canard ": ("Duck ", "Pato "),
    "Canard": ("Duck", "Pato"),
    "Usine": ("Factory", "Fábrica"),
    "Mutation": ("Mutation", "Mutación"),
    "Rareté": ("Rarity", "Rareza"),
    "Taille": ("Size", "Tamaño"),
    "Actuelle": ("Current", "Actual"),
    "Perk": ("Perk", "Perk"),

    # Factory view
    "Nouvelle Usine": ("New Factory", "Nueva Fábrica"),
    "usine active": ("active factory", "fábrica activa"),
    "usines actives": ("active factories", "fábricas activas"),
    "Augmenter Niveau": ("Level Up", "Subir Nivel"),
    "Auto-Amélioration Usine": ("Auto-Upgrade Factory", "Auto-Mejora Fábrica"),
    "Niveau (Coûte des 💰)": ("Level (Costs 💰)", "Nivel (Cuesta 💰)"),
    "Réduction usines": ("Factory Discount", "Descuento fábricas"),
    "MAx (+": ("MAX (+", "MÁX (+"),
    "Génère : ": ("Generates: ", "Genera: "),
    "Revenus :": ("Income:", "Ingresos:"),
    "Mutation :": ("Mutation:", "Mutación:"),
    "Mutation: ": ("Mutation: ", "Mutación: "),
    "Taille: ": ("Size: ", "Tamaño: "),
    "Prix futur : ": ("Future price: ", "Precio futuro: "),
    "Coût : ": ("Cost: ", "Coste: "),
    "Choisir un canard": ("Choose a duck", "Elegir un pato"),
    "Sélectionner un canard": ("Select a duck", "Seleccionar un pato"),
    "Sélectionnez un canard pour voir les détails": ("Select a duck to see details", "Selecciona un pato para ver los detalles"),
    "Trier par": ("Sort by", "Ordenar por"),
    "Filtre: ": ("Filter: ", "Filtro: "),
    "Filtres": ("Filters", "Filtros"),
    "Tous affichés": ("All shown", "Todos mostrados"),
    "slots": ("slots", "ranuras"),
    "canards au total": ("ducks total", "patos en total"),

    # Inventory / Duck detail
    "Chargement des canards...": ("Loading ducks...", "Cargando patos..."),
    "Niveau MAX (100)": ("MAX Level (100)", "Nivel MÁX (100)"),
    "Niveau MAX": ("MAX Level", "Nivel MÁX"),
    "Niveau de Fusion ": ("Fusion Level ", "Nivel de Fusión "),
    "Niveaux, Mutations & Tailles": ("Levels, Mutations & Sizes", "Niveles, Mutaciones y Tamaños"),
    "Niveau :\\nChaque niveau augmente les revenus générés par le canard de 1%.\\n\\nMutations :\\n- Doré : Revenus x5 / Recyclage x2\\n- Radioactif : Revenus x15 / Recyclage x3\\n- Cristallisé : Revenus x50 / Recyclage x5\\n\\nTailles :\\n- Moyen : Revenus x1.5 / Recyclage x1.5\\n- Grand : Revenus x2.5 / Recyclage x2\\n- Géant : Revenus x5 / Recyclage x3": ("Level:\\nEach level increases the duck's income by 1%.\\n\\nMutations:\\n- Golden: Income x5 / Recycle x2\\n- Radioactive: Income x15 / Recycle x3\\n- Crystallized: Income x50 / Recycle x5\\n\\nSizes:\\n- Medium: Income x1.5 / Recycle x1.5\\n- Large: Income x2.5 / Recycle x2\\n- Giant: Income x5 / Recycle x3", "Nivel:\\nCada nivel aumenta los ingresos del pato en un 1%.\\n\\nMutaciones:\\n- Dorado: Ingresos x5 / Reciclaje x2\\n- Radiactivo: Ingresos x15 / Reciclaje x3\\n- Cristalizado: Ingresos x50 / Reciclaje x5\\n\\nTamaños:\\n- Mediano: Ingresos x1.5 / Reciclaje x1.5\\n- Grande: Ingresos x2.5 / Reciclaje x2\\n- Gigante: Ingresos x5 / Reciclaje x3"),
    "Mutation spontanée": ("Spontaneous Mutation", "Mutación espontánea"),
    "Recycler (+ ": ("Recycle (+ ", "Reciclar (+ "),
    "Ce canard sera retiré de l'usine si vous le recyclez.": ("This duck will be removed from the factory if you recycle it.", "Este pato será retirado de la fábrica si lo reciclas."),
    "Oui, Recycler": ("Yes, Recycle", "Sí, Reciclar"),
    "Confirmer le recyclage": ("Confirm Recycling", "Confirmar Reciclaje"),
    "Voulez-vous vraiment recycler ce canard de rareté ": ("Do you really want to recycle this duck of rarity ", "¿Realmente quieres reciclar este pato de rareza "),
    "? Cette action est définitive.": ("? This action is permanent.", "? Esta acción es definitiva."),
    "Récupérer": ("Collect", "Recoger"),
    "Récupérer X2": ("Collect X2", "Recoger X2"),
    "De Retour !": ("Welcome Back!", "¡Bienvenido de nuevo!"),
    "Pendant votre absence\\n(": ("During your absence\\n(", "Durante tu ausencia\\n("),
    "et": ("and", "y"),
    "minutes": ("minutes", "minutos"),
    "Gain d'argent": ("Money Earned", "Dinero ganado"),
    "Gain mutation": ("Mutation Earned", "Mutación ganada"),
    "Gain Total": ("Total Gain", "Ganancia Total"),
    "Gain du Rituel": ("Ritual Gain", "Ganancia del Ritual"),
    "💡 L'inventaire affiche les 100 meilleurs canards. L'Auto-Fusion et le Recyclage accèdent à toute la collection.": ("💡 Inventory shows the top 100 ducks. Auto-Fusion and Recycling access the full collection.", "💡 El inventario muestra los 100 mejores patos. La Auto-Fusión y el Reciclaje acceden a toda la colección."),

    # Crate shop
    "Quantité sélectionnée": ("Selected quantity", "Cantidad seleccionada"),
    "Ouverture Multiple": ("Multiple Opening", "Apertura Múltiple"),
    "Probabilités -": ("Probabilities -", "Probabilidades -"),
    "CONFIRMER L'ACHAT": ("CONFIRM PURCHASE", "CONFIRMAR COMPRA"),
    "Coût de l'opération": ("Operation Cost", "Coste de la operación"),
    "Achats Premium": ("Premium Purchases", "Compras Premium"),
    "Acheter pour ": ("Buy for ", "Comprar por "),
    "(Taxe 5%)": ("(5% Tax)", "(Impuesto 5%)"),
    "(Taxe 100%)": ("(100% Tax)", "(Impuesto 100%)"),

    # Fusion
    "Auto-Fusion": ("Auto-Fusion", "Auto-Fusión"),
    "Méga-Fusion": ("Mega-Fusion", "Mega-Fusión"),
    "LANCER LE RITUEL": ("START RITUAL", "INICIAR RITUAL"),
    "LANCER MÉGA-FUSION": ("START MEGA-FUSION", "INICIAR MEGA-FUSIÓN"),
    "TOUT FUSIONNER": ("FUSE ALL", "FUSIONAR TODO"),
    "Coût de fusion: ": ("Fusion cost: ", "Coste de fusión: "),
    "Bonus fusion": ("Fusion Bonus", "Bonus de fusión"),
    "Canards ciblés": ("Targeted Ducks", "Patos objetivo"),
    "Fusions possibles": ("Possible Fusions", "Fusiones posibles"),
    "Rareté cible": ("Target Rarity", "Rareza objetivo"),
    "Sélectionnez 3 canards de même rareté et niveau": ("Select 3 ducks of the same rarity and level", "Selecciona 3 patos de la misma rareza y nivel"),
    "Auto-Fusion : S'applique uniquement à la rareté sélectionnée. Assemble tous les groupes de 3 canards identiques.\\n\\nMéga-Fusion : Fusionne TOUS les canards de l'inventaire en cascade jusqu'à épuisement des canards ou de l'argent.": ("Auto-Fusion: Applies only to the selected rarity. Assembles all groups of 3 identical ducks.\\n\\nMega-Fusion: Fuses ALL ducks in the inventory in cascade until ducks or money run out.", "Auto-Fusión: Se aplica solo a la rareza seleccionada. Ensambla todos los grupos de 3 patos idénticos.\\n\\nMega-Fusión: Fusiona TODOS los patos del inventario en cascada hasta agotar patos o dinero."),
    "fusions estimées": ("estimated fusions", "fusiones estimadas"),
    "ciblés": ("targeted", "objetivo"),

    # Ritual
    "Le Rituel Canarifique": ("The Duck Ritual", "El Ritual Patuno"),
    "Sacrifiez un canard pour doubler sa valeur ! Mais attention : la chance de réussite diminue de 5% à chaque succès. En cas d'échec, le canard sera détruit à jamais !": ("Sacrifice a duck to double its value! But beware: the success chance decreases by 5% with each success. Upon failure, the duck will be destroyed forever!", "¡Sacrifica un pato para duplicar su valor! Pero cuidado: la probabilidad de éxito disminuye un 5% con cada éxito. ¡Si fallas, el pato será destruido para siempre!"),
    "Doré 🌟": ("Golden 🌟", "Dorado 🌟"),
    "RITUEL DORÉ !": ("GOLDEN RITUAL!", "¡RITUAL DORADO!"),
    "RITUEL RÉUSSI !": ("RITUAL SUCCEEDED!", "¡RITUAL EXITOSO!"),
    "DÉTRUIT...": ("DESTROYED...", "DESTRUIDO..."),
    "Chance de réussite": ("Success chance", "Probabilidad de éxito"),
    "Règles du Rituel": ("Ritual Rules", "Reglas del Ritual"),
    "Comment ça marche ?": ("How does it work?", "¿Cómo funciona?"),
    "Maintenir = boucle": ("Hold = loop", "Mantener = bucle"),

    # Prestige
    "Le Prestige": ("Prestige", "Prestigio"),
    "Bonus Passifs": ("Passive Bonuses", "Bonos Pasivos"),
    "Effectuez un Prestige pour gagner des étoiles et débloquer de puissants bonus passifs.": ("Perform a Prestige to earn stars and unlock powerful passive bonuses.", "Realiza un Prestigio para ganar estrellas y desbloquear poderosos bonos pasivos."),
    "Atteindre 10B d'argent": ("Reach 10B money", "Alcanzar 10B de dinero"),
    "Prestige Disponible !": ("Prestige Available!", "¡Prestigio Disponible!"),
    "Effectuer un Prestige": ("Perform Prestige", "Realizar Prestigio"),
    "Confirmation de Prestige": ("Prestige Confirmation", "Confirmación de Prestigio"),
    "Êtes-vous sûr ? Vous allez recommencer à zéro, mais vous conserverez vos étoiles pour de puissants bonus passifs permanents et l'Arbre Stellaire.": ("Are you sure? You will start from zero, but keep your stars for powerful permanent passive bonuses and the Stellar Tree.", "¿Estás seguro? Empezarás de cero, pero conservarás tus estrellas para poderosos bonos pasivos permanentes y el Árbol Estelar."),
    "Êtes-vous sûr ?": ("Are you sure?", "¿Estás seguro?"),
    "libres": ("available", "disponibles"),
    "Libres": ("Available", "Disponibles"),
    "Dépensées:": ("Spent:", "Gastadas:"),
    "Dépensées": ("Spent", "Gastadas"),
    "étoiles dépensées": ("stars spent", "estrellas gastadas"),
    "ACQUIS": ("ACQUIRED", "ADQUIRIDO"),
    "Étoiles libres insuffisantes.": ("Insufficient free stars.", "Estrellas libres insuficientes."),
    "Compétence Acquise": ("Skill Acquired", "Habilidad Adquirida"),
    "Progression": ("Progression", "Progresión"),
    "Nécessite ": ("Requires ", "Requiere "),
    "Certaines mécaniques nécessitent l'Arbre Stellaire (Prestige).": ("Some mechanics require the Stellar Tree (Prestige).", "Algunas mecánicas requieren el Árbol Estelar (Prestigio)."),
    "Débloqué via l'Arbre Stellaire": ("Unlocked via Stellar Tree", "Desbloqueado vía Árbol Estelar"),

    # Settings
    "Restaurer les achats": ("Restore Purchases", "Restaurar Compras"),
    "Réinitialiser ma progression": ("Reset My Progress", "Restablecer mi progreso"),
    "Cette action est irréversible. Vous perdrez tout votre argent, vos usines et vos canards.": ("This action is irreversible. You will lose all your money, factories, and ducks.", "Esta acción es irreversible. Perderás todo tu dinero, fábricas y patos."),
    "Oui, tout effacer": ("Yes, erase everything", "Sí, borrar todo"),
    "Langue": ("Language", "Idioma"),
    "Format des Nombres": ("Number Format", "Formato de Números"),
    "Affichage": ("Display", "Pantalla"),
    "CanardFactory v1.0": ("CanardFactory v1.0", "CanardFactory v1.0"),
    "v1.0.0": ("v1.0.0", "v1.0.0"),
    "Effets Sonores": ("Sound Effects", "Efectos de Sonido"),
    "Désactivé": ("Disabled", "Desactivado"),
    "scientifique": ("scientific", "científico"),
    "lettres": ("letters", "letras"),

    # Levels
    "Bonus Actuels": ("Current Bonuses", "Bonos Actuales"),
    "Prochain Palier (Niveau ": ("Next Milestone (Level ", "Próximo Hito (Nivel "),
    "+25% Revenus & +5% Mutation": ("+25% Income & +5% Mutation", "+25% Ingresos y +5% Mutación"),
    "10 Gemmes": ("10 Gems", "10 Gemas"),
    "1 Perk Usine & 1 Perk Canard": ("1 Factory Perk & 1 Duck Perk", "1 Perk Fábrica y 1 Perk Pato"),
    "Revenus doublés !": ("Income Doubled!", "¡Ingresos duplicados!"),
    "Niveau Joueur": ("Player Level", "Nivel de Jugador"),
    "Comment gagner de l'XP ?": ("How to earn XP?", "¿Cómo ganar XP?"),
    "Vous gagnez de l'XP passivement en fonction de l'argent généré par vos usines chaque seconde. L'XP continue d'augmenter même lorsque vous êtes hors ligne. Vous pouvez également gagner de l'XP en accomplissant des missions.": ("You earn XP passively based on the money generated by your factories every second. XP keeps increasing even when you are offline. You can also earn XP by completing missions.", "Ganas XP pasivamente según el dinero generado por tus fábricas cada segundo. La XP sigue aumentando incluso cuando estás desconectado. También puedes ganar XP completando misiones."),
    "XP": ("XP", "XP"),

    # Shop / IAP
    "Sauts Temporels": ("Time Skips", "Saltos en el Tiempo"),
    "1H de revenus": ("1H of income", "1H de ingresos"),
    "4H de revenus": ("4H of income", "4H de ingresos"),
    "12H de revenus": ("12H of income", "12H de ingresos"),
    "Packs d'Argent": ("Money Packs", "Packs de Dinero"),
    "+10 K": ("+10 K", "+10 K"),
    "+100 K": ("+100 K", "+100 K"),
    "+1 M": ("+1 M", "+1 M"),
    "+10 M": ("+10 M", "+10 M"),
    "+100 M": ("+100 M", "+100 M"),
    "+1 B": ("+1 B", "+1 B"),
    "Packs d'ADN": ("DNA Packs", "Packs de ADN"),
    "+100": ("+100", "+100"),
    "+500": ("+500", "+500"),
    "+2.5 K": ("+2.5 K", "+2.5 K"),
    "+50 K": ("+50 K", "+50 K"),
    "+250 K": ("+250 K", "+250 K"),
    "Acheter des Gemmes": ("Buy Gems", "Comprar Gemas"),

    # Perks
    "Inventaire de Perks": ("Perks Inventory", "Inventario de Perks"),
    "Type de Perks": ("Perk Type", "Tipo de Perks"),
    "Sélectionner un Perk": ("Select a Perk", "Seleccionar un Perk"),
    "Que sont les Perks ?": ("What are Perks?", "¿Qué son los Perks?"),
    "Les Perks sont des bonus d'équipement que vous gagnez via les missions et les passages de niveaux. Vous pouvez équiper un Perk d'Usine sur une usine (dans le menu Usines) ou un Perk de Canard sur un canard (dans son profil détaillé) pour augmenter sa rentabilité !": ("Perks are equipment bonuses that you earn through missions and leveling up. You can equip a Factory Perk on a factory (in the Factories menu) or a Duck Perk on a duck (in its detailed profile) to increase its profitability!", "¡Los Perks son bonos de equipo que ganas a través de misiones y subir de nivel. Puedes equipar un Perk de Fábrica en una fábrica (en el menú Fábricas) o un Perk de Pato en un pato (en su perfil detallado) para aumentar su rentabilidad!"),
    "Type : Usine": ("Type: Factory", "Tipo: Fábrica"),
    "Type : Canard": ("Type: Duck", "Tipo: Pato"),
    "Type de mission": ("Mission type", "Tipo de misión"),
    "Perk Équipé": ("Perk Equipped", "Perk Equipado"),
    "Disponibles": ("Available", "Disponibles"),
    "Équipés": ("Equipped", "Equipados"),
    "Aucun perk de ce type.": ("No perks of this type.", "Sin perks de este tipo."),
    "Aucun perk disponible de ce type.": ("No available perks of this type.", "Sin perks disponibles de este tipo."),
    "Aucun canard disponible.": ("No ducks available.", "No hay patos disponibles."),
    "Tous les emplacements sont pleins. Retirez un perk pour en équiper un autre.": ("All slots are full. Remove a perk to equip another.", "Todas las ranuras están llenas. Retira un perk para equipar otro."),
    "Ce perk est détruit au recyclage": ("This perk is destroyed on recycling", "Este perk se destruye al reciclar"),
    "Ce perk n'est pas enlevé lors d'une fusion": ("This perk is not removed during fusion", "Este perk no se retira durante una fusión"),

    # Perk effects - Factory
    "Donne 15% d'argent en plus a l'usine": ("Gives 15% more money to the factory", "Da un 15% más de dinero a la fábrica"),
    "Donne 50% d'argent en plus si un canard commun est équipé": ("Gives 50% more money if a common duck is equipped", "Da un 50% más de dinero si un pato común está equipado"),
    "Baisse le prix des améliorations de 5%": ("Reduces upgrade cost by 5%", "Reduce el precio de las mejoras un 5%"),
    "Réduit de 33% la production mais augmente de 10% les autres usines": ("Reduces production by 33% but increases other factories by 10%", "Reduce la producción un 33% pero aumenta las demás fábricas un 10%"),
    "Donnes 30% d'argent de plus a l'usine": ("Gives 30% more money to the factory", "Da un 30% más de dinero a la fábrica"),
    "Donne 30% d'argent de plus a l'usine": ("Gives 30% more money to the factory", "Da un 30% más de dinero a la fábrica"),
    "Donne 80% d'argent en plus si un canard commun est équipé": ("Gives 80% more money if a common duck is equipped", "Da un 80% más de dinero si un pato común está equipado"),
    "Donne 60% d'argent en plus si un canard Peu-commun est équipé": ("Gives 60% more money if an uncommon duck is equipped", "Da un 60% más de dinero si un pato poco común está equipado"),
    "Baisse le prix des améliorations de 15%": ("Reduces upgrade cost by 15%", "Reduce el precio de las mejoras un 15%"),
    "Réduit de 30% la production mais augmente de 20% les autres usines": ("Reduces production by 30% but increases other factories by 20%", "Reduce la producción un 30% pero aumenta las demás fábricas un 20%"),
    "Donne 50% d'argent de plus a l'usine": ("Gives 50% more money to the factory", "Da un 50% más de dinero a la fábrica"),
    "Donne 100% d'argent en plus si un canard commun est équipé": ("Gives 100% more money if a common duck is equipped", "Da un 100% más de dinero si un pato común está equipado"),
    "Donne 100% d'argent en plus si un canard Peu-commun est équipé": ("Gives 100% more money if an uncommon duck is equipped", "Da un 100% más de dinero si un pato poco común está equipado"),
    "Donne 80% d'argent en plus si un canard rare est équipé": ("Gives 80% more money if a rare duck is equipped", "Da un 80% más de dinero si un pato raro está equipado"),
    "Augmente de 100% la production si un canard de fusion 2 est équipé": ("Increases production by 100% if a fusion 2 duck is equipped", "Aumenta la producción un 100% si un pato de fusión 2 está equipado"),
    "Baisse le prix des améliorations de 30%": ("Reduces upgrade cost by 30%", "Reduce el precio de las mejoras un 30%"),
    "Réduit de 25% la production mais augmente de 50% les autres usines": ("Reduces production by 25% but increases other factories by 50%", "Reduce la producción un 25% pero aumenta las demás fábricas un 50%"),
    "Donne 80% d'argent en plus a l'usine": ("Gives 80% more money to the factory", "Da un 80% más de dinero a la fábrica"),
    "Donne 210% d'argent en plus si un canard C/PC/R est équipé": ("Gives 210% more money if a C/UC/R duck is equipped", "Da un 210% más de dinero si un pato C/PC/R está equipado"),
    "Donne 100% d'argent en plus si un canard épique/légendaire est équipé": ("Gives 100% more money if an epic/legendary duck is equipped", "Da un 100% más de dinero si un pato épico/legendario está equipado"),
    "Augmente de 150% la production si un canard de fusion 2/3 est équipé": ("Increases production by 150% if a fusion 2/3 duck is equipped", "Aumenta la producción un 150% si un pato de fusión 2/3 está equipado"),
    "Baisse le prix des améliorations de 40%": ("Reduces upgrade cost by 40%", "Reduce el precio de las mejoras un 40%"),
    "Réduit de 15% la production mais augmente de 80% les autres usines": ("Reduces production by 15% but increases other factories by 80%", "Reduce la producción un 15% pero aumenta las demás fábricas un 80%"),
    "Permet de rajouter un 2ème perk a l'usine et donne 50% d'argent en plus": ("Allows adding a 2nd perk to the factory and gives 50% more money", "Permite añadir un 2º perk a la fábrica y da un 50% más de dinero"),
    "Donne 150% d'argent en plus a l'usine": ("Gives 150% more money to the factory", "Da un 150% más de dinero a la fábrica"),
    "Donne 300% d'argent en plus si un canard C/PC/R est équipé": ("Gives 300% more money if a C/UC/R duck is equipped", "Da un 300% más de dinero si un pato C/PC/R está equipado"),
    "Donne 130% d'argent en plus si un canard E/L/M est équipé": ("Gives 130% more money if an E/L/M duck is equipped", "Da un 130% más de dinero si un pato E/L/M está equipado"),
    "Augmente de 150% la production si un canard de fusion 1/2/3/4 est équipé": ("Increases production by 150% if a fusion 1/2/3/4 duck is equipped", "Aumenta la producción un 150% si un pato de fusión 1/2/3/4 está equipado"),
    "Baisse le prix des améliorations de 55%": ("Reduces upgrade cost by 55%", "Reduce el precio de las mejoras un 55%"),
    "Réduit de 5% la production mais augmente de 120% les autres usines": ("Reduces production by 5% but increases other factories by 120%", "Reduce la producción un 5% pero aumenta las demás fábricas un 120%"),
    "Permet de rajouter un 2ème perk a l'usine et donne 90% d'argent en plus": ("Allows adding a 2nd perk to the factory and gives 90% more money", "Permite añadir un 2º perk a la fábrica y da un 90% más de dinero"),
    "Permet de mettre un 2ème canard dans l'usine et donne un bonus de 45%": ("Allows placing a 2nd duck in the factory with a 45% bonus", "Permite colocar un 2º pato en la fábrica con un bono del 45%"),
    "Donne 500% d'argent en plus a l'usine": ("Gives 500% more money to the factory", "Da un 500% más de dinero a la fábrica"),
    "Donne 10% d'argent en plus a l'usine par usine équipée d'un canard": ("Gives 10% more money per factory equipped with a duck", "Da un 10% más de dinero por fábrica equipada con un pato"),
    "Donne 50% d'argent en plus a l'usine": ("Gives 50% more money to the factory", "Da un 50% más de dinero a la fábrica"),
    "Donne 90% d'argent en plus a l'usine": ("Gives 90% more money to the factory", "Da un 90% más de dinero a la fábrica"),
    "Donne un bonus de 45% d'argent à l'usine": ("Gives a 45% money bonus to the factory", "Da un bono del 45% de dinero a la fábrica"),
    "Permet de rajouter un 2ème perk a l'usine": ("Allows adding a 2nd perk to the factory", "Permite añadir un 2º perk a la fábrica"),
    "Permet de mettre un 2ème canard dans l'usine": ("Allows placing a 2nd duck in the factory", "Permite colocar un 2º pato en la fábrica"),
    "Permet de mettre un 2ème perk": ("Allows equipping a 2nd perk", "Permite equipar un 2º perk"),
    "Permet de rajouter un 2ème perk au canard": ("Allows adding a 2nd perk to the duck", "Permite añadir un 2º perk al pato"),

    # Perk effects - Duck
    "Augmente de 15% la valeur du canard": ("Increases duck value by 15%", "Aumenta el valor del pato un 15%"),
    "Augmente de 40% la valeur du canard": ("Increases duck value by 40%", "Aumenta el valor del pato un 40%"),
    "Augmente de 80% la valeur du canard": ("Increases duck value by 80%", "Aumenta el valor del pato un 80%"),
    "Augmente de 100% la valeur du canard": ("Increases duck value by 100%", "Aumenta el valor del pato un 100%"),
    "Augmente de 200% la valeur du canard": ("Increases duck value by 200%", "Aumenta el valor del pato un 200%"),
    "Augmente de 300% la valeur du canard": ("Increases duck value by 300%", "Aumenta el valor del pato un 300%"),
    "Augmente de 500% la valeur du canard": ("Increases duck value by 500%", "Aumenta el valor del pato un 500%"),
    "Augmente de 1 la taille du canard": ("Increases duck size by 1", "Aumenta el tamaño del pato en 1"),
    "Augmente de 2 la taille du canard": ("Increases duck size by 2", "Aumenta el tamaño del pato en 2"),
    "Augmente de 3 la taille du canard": ("Increases duck size by 3", "Aumenta el tamaño del pato en 3"),
    "Augmente de 1 la mutation du canard": ("Increases duck mutation by 1", "Aumenta la mutación del pato en 1"),
    "Augmente de 2 la mutation du canard": ("Increases duck mutation by 2", "Aumenta la mutación del pato en 2"),
    "Augmente de 3 la mutation du canard": ("Increases duck mutation by 3", "Aumenta la mutación del pato en 3"),
    "Maximise les niveaux, la taille et la mutation": ("Maximizes levels, size, and mutation", "Maximiza niveles, tamaño y mutación"),
    "Maximise les niveaux, la taille, la mutation du canard": ("Maximizes duck levels, size, and mutation", "Maximiza niveles, tamaño y mutación del pato"),
    "Compte le canard 2 fois lors d'une fusion (perk conservé)": ("Counts the duck 2 times during fusion (perk kept)", "Cuenta el pato 2 veces en una fusión (perk conservado)"),
    "Compte le canard 4 fois lors d'une fusion (perk conservé)": ("Counts the duck 4 times during fusion (perk kept)", "Cuenta el pato 4 veces en una fusión (perk conservado)"),
    "Compte le canard 8 fois lors d'une fusion (perk conservé)": ("Counts the duck 8 times during fusion (perk kept)", "Cuenta el pato 8 veces en una fusión (perk conservado)"),
    "Compte le canard 16 fois lors d'une fusion (perk conservé)": ("Counts the duck 16 times during fusion (perk kept)", "Cuenta el pato 16 veces en una fusión (perk conservado)"),
    "Compte le canard 32 fois lors d'une fusion (perk conservé)": ("Counts the duck 32 times during fusion (perk kept)", "Cuenta el pato 32 veces en una fusión (perk conservado)"),
    "Compte 2 fois lors d'une fusion": ("Counts 2 times during fusion", "Cuenta 2 veces en una fusión"),
    "Compte 4 fois lors d'une fusion": ("Counts 4 times during fusion", "Cuenta 4 veces en una fusión"),
    "Compte 8 fois lors d'une fusion": ("Counts 8 times during fusion", "Cuenta 8 veces en una fusión"),
    "Compte 16 fois lors d'une fusion": ("Counts 16 times during fusion", "Cuenta 16 veces en una fusión"),
    "Multiplie par 100 les points de mutation du canard": ("Multiplies duck mutation points by 100", "Multiplica los puntos de mutación del pato por 100"),
    "Multiplie par 1000 les points de mutation du canard": ("Multiplies duck mutation points by 1,000", "Multiplica los puntos de mutación del pato por 1.000"),
    "Multiplie par 10000 les points de mutation du canard": ("Multiplies duck mutation points by 10,000", "Multiplica los puntos de mutación del pato por 10.000"),
    "Multiplie par 100 les points de mutation au recyclage (perk détruit)": ("Multiplies recycling mutation points by 100 (perk destroyed)", "Multiplica los puntos de mutación de reciclaje por 100 (perk destruido)"),
    "Multiplie par 1000 les points de mutation au recyclage (perk détruit)": ("Multiplies recycling mutation points by 1,000 (perk destroyed)", "Multiplica los puntos de mutación de reciclaje por 1.000 (perk destruido)"),
    "Multiplie par 10000 les points de mutation au recyclage (perk détruit)": ("Multiplies recycling mutation points by 10,000 (perk destroyed)", "Multiplica los puntos de mutación de reciclaje por 10.000 (perk destruido)"),
    "Permet de mettre un 2ème perk et augmente de 100% la valeur": ("Allows equipping a 2nd perk and increases value by 100%", "Permite equipar un 2º perk y aumenta el valor un 100%"),
    "Permet de mettre un 2ème perk et augmente de 300% la valeur": ("Allows equipping a 2nd perk and increases value by 300%", "Permite equipar un 2º perk y aumenta el valor un 300%"),
    "Si canard Commun : +20 niveaux (dépassement = +100% valeur)": ("If Common duck: +20 levels (overflow = +100% value)", "Si pato Común: +20 niveles (desbordamiento = +100% valor)"),
    "Si canard Peu-Commun : +10 niveaux (dépassement = +100% valeur)": ("If Uncommon duck: +10 levels (overflow = +100% value)", "Si pato Poco Común: +10 niveles (desbordamiento = +100% valor)"),
    "Si canard Rare : +5 niveaux (dépassement = +100% valeur)": ("If Rare duck: +5 levels (overflow = +100% value)", "Si pato Raro: +5 niveles (desbordamiento = +100% valor)"),
    "Si canard Commun : +30 niveaux (dépassement = +200% valeur)": ("If Common duck: +30 levels (overflow = +200% value)", "Si pato Común: +30 niveles (desbordamiento = +200% valor)"),
    "Si canard Peu-Commun : +20 niveaux (dépassement = +200% valeur)": ("If Uncommon duck: +20 levels (overflow = +200% value)", "Si pato Poco Común: +20 niveles (desbordamiento = +200% valor)"),
    "Si canard Rare : +10 niveaux (dépassement = +200% valeur)": ("If Rare duck: +10 levels (overflow = +200% value)", "Si pato Raro: +10 niveles (desbordamiento = +200% valor)"),
    "Si canard C/PC/R : +35 niveaux (dépassement = +300% valeur)": ("If C/UC/R duck: +35 levels (overflow = +300% value)", "Si pato C/PC/R: +35 niveles (desbordamiento = +300% valor)"),
    "Si canard Épique : +20 niveaux (dépassement = +300% valeur)": ("If Epic duck: +20 levels (overflow = +300% value)", "Si pato Épico: +20 niveles (desbordamiento = +300% valor)"),
    "Si canard C/PC/R : +70 niveaux (dépassement = +400% valeur)": ("If C/UC/R duck: +70 levels (overflow = +400% value)", "Si pato C/PC/R: +70 niveles (desbordamiento = +400% valor)"),
    "Si canard E/L/M : +40 niveaux (dépassement = +400% valeur)": ("If E/L/M duck: +40 levels (overflow = +400% value)", "Si pato E/L/M: +40 niveles (desbordamiento = +400% valor)"),
    "Si canard C/PC/R : +100 niveaux (dépassement = +400% valeur)": ("If C/UC/R duck: +100 levels (overflow = +400% value)", "Si pato C/PC/R: +100 niveles (desbordamiento = +400% valor)"),
    "Si canard E/L/M : +80 niveaux (dépassement = +400% valeur)": ("If E/L/M duck: +80 levels (overflow = +400% value)", "Si pato E/L/M: +80 niveles (desbordamiento = +400% valor)"),
    "Si équipé à un canard Commun : reçoit 20 niveaux": ("If equipped on a Common duck: receives 20 levels", "Si se equipa a un pato Común: recibe 20 niveles"),
    "Si équipé à un canard Commun : reçoit 30 niveaux": ("If equipped on a Common duck: receives 30 levels", "Si se equipa a un pato Común: recibe 30 niveles"),
    "Si équipé à un canard Peu-Commun : reçoit 10 niveaux": ("If equipped on an Uncommon duck: receives 10 levels", "Si se equipa a un pato Poco Común: recibe 10 niveles"),
    "Si équipé à un canard Peu-Commun : reçoit 20 niveaux": ("If equipped on an Uncommon duck: receives 20 levels", "Si se equipa a un pato Poco Común: recibe 20 niveles"),
    "Si équipé à un canard Rare : reçoit 5 niveaux": ("If equipped on a Rare duck: receives 5 levels", "Si se equipa a un pato Raro: recibe 5 niveles"),
    "Si équipé à un canard Rare : reçoit 10 niveaux": ("If equipped on a Rare duck: receives 10 levels", "Si se equipa a un pato Raro: recibe 10 niveles"),
    "Si équipé à un canard Épique : reçoit 20 niveaux": ("If equipped on an Epic duck: receives 20 levels", "Si se equipa a un pato Épico: recibe 20 niveles"),
    "Si équipé à un canard C/PC/R : reçoit 35 niveaux": ("If equipped on a C/UC/R duck: receives 35 levels", "Si se equipa a un pato C/PC/R: recibe 35 niveles"),
    "Si équipé à un canard C/PC/R : reçoit 70 niveaux": ("If equipped on a C/UC/R duck: receives 70 levels", "Si se equipa a un pato C/PC/R: recibe 70 niveles"),
    "Si équipé à un canard C/PC/R : reçoit 100 niveaux": ("If equipped on a C/UC/R duck: receives 100 levels", "Si se equipa a un pato C/PC/R: recibe 100 niveles"),
    "Si équipé à un canard E/L/M : reçoit 40 niveaux": ("If equipped on an E/L/M duck: receives 40 levels", "Si se equipa a un pato E/L/M: recibe 40 niveles"),
    "Si équipé à un canard E/L/M : reçoit 80 niveaux": ("If equipped on an E/L/M duck: receives 80 levels", "Si se equipa a un pato E/L/M: recibe 80 niveles"),
    "Dépassement de niveau : +100% de valeur": ("Level overflow: +100% value", "Desbordamiento de nivel: +100% de valor"),
    "Dépassement de niveau : +200% de valeur": ("Level overflow: +200% value", "Desbordamiento de nivel: +200% de valor"),
    "Dépassement de niveau : +300% de valeur": ("Level overflow: +300% value", "Desbordamiento de nivel: +300% de valor"),
    "Dépassement de niveau : +400% de valeur": ("Level overflow: +400% value", "Desbordamiento de nivel: +400% de valor"),
    "Dépassement de taille : +200% de valeur": ("Size overflow: +200% value", "Desbordamiento de tamaño: +200% de valor"),
    "Dépassement de taille : +300% de valeur": ("Size overflow: +300% value", "Desbordamiento de tamaño: +300% de valor"),
    "Dépassement de taille : +400% de valeur": ("Size overflow: +400% value", "Desbordamiento de tamaño: +400% de valor"),
    "Dépassement de taille : +500% de valeur": ("Size overflow: +500% value", "Desbordamiento de tamaño: +500% de valor"),
    "Dépassement de mutation : +200% de valeur": ("Mutation overflow: +200% value", "Desbordamiento de mutación: +200% de valor"),
    "Dépassement de mutation : +300% de valeur": ("Mutation overflow: +300% value", "Desbordamiento de mutación: +300% de valor"),
    "Dépassement de mutation : +400% de valeur": ("Mutation overflow: +400% value", "Desbordamiento de mutación: +400% de valor"),
    "Dépassement de mutation : +500% de valeur": ("Mutation overflow: +500% value", "Desbordamiento de mutación: +500% de valor"),

    # Recycling
    "Recyclage en Lot : S'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s'applique au niveau choisi et à ses niveaux inférieurs.\\n\\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau.": ("Batch Recycling: Applies to the selected rarity and all lower rarities. For the exact selected rarity, applies to the chosen level and lower levels.\\n\\nRecycle Rarity: Destroys ALL unassigned ducks of the selected rarity, regardless of their level.", "Reciclaje por Lotes: Se aplica a la rareza seleccionada y todas las rarezas inferiores. Para la rareza exacta seleccionada, se aplica al nivel elegido y niveles inferiores.\\n\\nReciclar Rareza: Destruye TODOS los patos no asignados de la rareza seleccionada, sin importar su nivel."),
    "RECYCLER EN LOT": ("BATCH RECYCLE", "RECICLAR POR LOTES"),
    "RECYCLER LA RARETÉ": ("RECYCLE RARITY", "RECICLAR RAREZA"),
    "Recycler la rareté": ("Recycle rarity", "Reciclar rareza"),
    "Recycler (+ ": ("Recycle (+ ", "Reciclar (+ "),

    # Materials
    "Bois": ("Wood", "Madera"),
    "Fer": ("Iron", "Hierro"),
    "Or": ("Gold", "Oro"),
    "Platine": ("Platinum", "Platino"),
    "Diamant": ("Diamond", "Diamante"),
    "Rubis": ("Ruby", "Rubí"),
    "Saphir": ("Sapphire", "Zafiro"),

    # Misc
    "Génération...": ("Generating...", "Generando..."),
    "Appuyer pour continuer": ("Tap to continue", "Toca para continuar"),
    "Toucher pour continuer": ("Tap to continue", "Toca para continuar"),
    "Améliorations": ("Upgrades", "Mejoras"),
    "DUCK TYCOON": ("DUCK TYCOON", "DUCK TYCOON"),
    "Mise à jour de la boutique...": ("Updating shop...", "Actualizando tienda..."),

    # Start screen
    "Chargement des canards...": ("Loading ducks...", "Cargando patos..."),
}

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

def extract_keys(content, lang):
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return set()
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return set()
    lang_content = content[start_idx:start_idx + end_match.start()]
    keys = re.findall(r'"([^"]+)":\s*"', lang_content)
    return set(keys)

def append_to_section(content, lang, items):
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return content
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return content
    
    lang_content = content[start_idx:start_idx + end_match.start()]
    insert_idx = start_idx + end_match.start()
    
    items_str = ""
    for k, v in items.items():
        k_esc = k.replace('\\', '\\\\').replace('"', '\\"')
        v_esc = v.replace('\\', '\\\\').replace('"', '\\"')
        # Check for key in this lang section only
        if f'"{k}":' not in lang_content and f'"{k_esc}":' not in lang_content:
            items_str += f',\n        "{k_esc}": "{v_esc}"'
    
    return content[:insert_idx] + items_str + content[insert_idx:]

# Build items to add per language
fr_add = {}
en_add = {}
es_add = {}

fr_keys = extract_keys(content, 'fr')
en_keys = extract_keys(content, 'en')
es_keys = extract_keys(content, 'es')

for fr_key, (en_val, es_val) in TRANSLATIONS.items():
    if fr_key not in fr_keys:
        fr_add[fr_key] = fr_key
    if fr_key not in en_keys:
        en_add[fr_key] = en_val
    if fr_key not in es_keys:
        es_add[fr_key] = es_val

print(f"Adding {len(fr_add)} to FR, {len(en_add)} to EN, {len(es_add)} to ES")

content = append_to_section(content, 'fr', fr_add)
content = append_to_section(content, 'en', en_add)
content = append_to_section(content, 'es', es_add)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
with open(loc_path, 'r', encoding='utf-8') as f:
    content2 = f.read()

fr2 = extract_keys(content2, 'fr')
en2 = extract_keys(content2, 'en')
es2 = extract_keys(content2, 'es')
print(f"After: FR={len(fr2)}, EN={len(en2)}, ES={len(es2)}")
print("Done!")
