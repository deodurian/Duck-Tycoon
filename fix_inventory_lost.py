filepath = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ('Text("Canard \(currentDuck.rarity.localizedName)")', 'Text("\(tr("Canard "))\(currentDuck.rarity.localizedName)")'),
    ('Text("Niveau de Fusion \(currentDuck.fusionLevel)/4")', 'Text("\(tr("Niveau de Fusion "))\(currentDuck.fusionLevel)/4")'),
    ('Text("Lvl \(currentDuck.level)")', 'Text("\(tr("Lvl "))\(currentDuck.level)")'),
    ('Text("Génère : \(gameManager.displaySellValue(for: currentDuck).formattedString()) 💰 / sec")', 'Text("\(tr("Génère : "))\(gameManager.displaySellValue(for: currentDuck).formattedString()) 💰\(tr(" / sec"))")'),
    ('Text("Taille: \(currentDuck.size.localizedName)")', 'Text("\(tr("Taille: "))\(currentDuck.size.localizedName)")'),
    ('Text("Mutation: \(currentDuck.mutation.localizedName)")', 'Text("\(tr("Mutation: "))\(currentDuck.mutation.localizedName)")'),
    ('Text("Recycler (+ \(gameManager.displayRecycleValue(for: currentDuck).formattedString()) 🧬)")', 'Text("\(tr("Recycler (+ "))\(gameManager.displayRecycleValue(for: currentDuck).formattedString()) 🧬)")'),
    ('Text("Voulez-vous vraiment recycler ce canard de rareté \(currentDuck.rarity.localizedName) ? Cette action est définitive.")', 'Text("\(tr("Voulez-vous vraiment recycler ce canard de rareté "))\(currentDuck.rarity.localizedName)\(tr(" ? Cette action est définitive."))")'),
    ('Text("Voulez-vous vraiment recycler ce canard de rareté \(currentDuck.rarity.rawValue) ? Cette action est définitive.")', 'Text("\(tr("Voulez-vous vraiment recycler ce canard de rareté "))\(currentDuck.rarity.localizedName)\(tr(" ? Cette action est définitive."))")'),
    ('Text("Niveau \(level)").tag(level)', 'Text("\(tr("Niveau "))\(level)").tag(level)'),
    ('Text("\(totalMatching) ciblés")', 'Text("\(totalMatching)\(tr(" ciblés"))")'),
    ('Text("Recyclage en Lot : S\'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s\'applique au niveau choisi et à ses niveaux inférieurs.\\n\\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau.")', 'Text(tr("Recyclage en Lot : S\'applique à la rareté sélectionnée et toutes les raretés inférieures. Pour la rareté exacte sélectionnée, s\'applique au niveau choisi et à ses niveaux inférieurs.\\n\\nRecycler la rareté : Détruit TOUS les canards non-assignés de la rareté sélectionnée, quel que soit leur niveau."))'),
    ('Text("Coût : \(cost.formattedString()) \(icon)")', 'Text("\(tr("Coût : "))\(cost.formattedString()) \(icon)")'),
    ('.navigationTitle("Statistiques")', '.navigationTitle(tr("Statistiques"))'),
    ("""Picker("Onglet", selection: $selectedTab) {
                                    Text("Informations").tag(0)
                                    Text("Fusion").tag(1)
                                    Text("Recyclage").tag(2)
                                }""", """Picker("Onglet", selection: $selectedTab) {
                                    Text(tr("Informations")).tag(0)
                                    Text(tr("Fusion")).tag(1)
                                    Text(tr("Recyclage")).tag(2)
                                }""")
]

for old, new in replacements:
    content = content.replace(old, new)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

