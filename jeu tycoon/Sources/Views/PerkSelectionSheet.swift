import SwiftUI

struct PerkSelectionSheet: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss
    
    let targetId: UUID
    let targetType: TargetType
    enum TargetType { case factory, duck }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.0, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    // Pour le moment on affiche juste la liste des perks disponibles dans l'inventaire
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(gameManager.perksInventory) { perk in
                            PerkCardView(perk: perk)
                                .onTapGesture {
                                    gameManager.equipPerk(perk, to: targetId)
                                    dismiss()
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Sélectionner un Perk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
