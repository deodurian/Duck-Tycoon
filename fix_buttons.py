replacements = [
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryView.swift', 'Button("Compris", role: .cancel) {}', 'Button(tr("Compris"), role: .cancel) {}'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Button("Annuler", role: .cancel) { }', 'Button(tr("Annuler"), role: .cancel) { }'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Button("Oui, Recycler", role: .destructive) {', 'Button(tr("Oui, Recycler"), role: .destructive) {'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Button("Fermer") { dismiss() }', 'Button(tr("Fermer")) { dismiss() }'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Button("OK", role: .cancel) { }', 'Button(tr("OK"), role: .cancel) { }'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/InventoryComponents.swift', 'Button("Fermer") {', 'Button(tr("Fermer")) {'),
    ('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views/PrestigeView.swift', 'Button("Confirmer", role: .destructive) {', 'Button(tr("Confirmer"), role: .destructive) {'),
]

for filepath, old_str, new_str in replacements:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            file_content = f.read()
        file_content = file_content.replace(old_str, new_str)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(file_content)
    except Exception as e:
        print(f"Error replacing in {filepath}: {e}")

