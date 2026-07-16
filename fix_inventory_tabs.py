filepath = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_picker = """Picker("Onglet", selection: $selectedTab) {
                                    Text("Informations").tag(0)
                                    Text("Fusion").tag(1)
                                    Text("Recyclage").tag(2)
                                }"""

new_picker = """Picker("Onglet", selection: $selectedTab) {
                                    Text(tr("Informations")).tag(0)
                                    Text(tr("Fusion")).tag(1)
                                    Text(tr("Recyclage")).tag(2)
                                }"""

content = content.replace(old_picker, new_picker)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

