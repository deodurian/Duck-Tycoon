import SwiftUI

struct PerkSheetView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    @State private var showInfo = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.0, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Type de Perks", selection: $selectedTab) {
                        Text("Usines").tag(0)
                        Text("Canards").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            let typeFilter: PerkType = selectedTab == 0 ? .factory : .duck
                            let filteredPerks = gameManager.perksInventory.filter { $0.type == typeFilter }
                            ForEach(filteredPerks) { perk in
                                PerkCardView(perk: perk)
                            }
                            if filteredPerks.isEmpty {
                                Text("Aucun perk de ce type.")
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Inventaire de Perks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.cyan)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
            .alert("Que sont les Perks ?", isPresented: $showInfo) {
                Button("Compris", role: .cancel) { }
            } message: {
                Text("Les Perks sont des bonus d'équipement que vous gagnez via les missions et les passages de niveaux. Vous pouvez équiper un Perk d'Usine sur une usine (dans le menu Usines) ou un Perk de Canard sur un canard (dans son profil détaillé) pour augmenter sa rentabilité !")
            }
        }
    }
}

struct PerkCardView: View {
    let perk: Perk
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 30))
                .foregroundColor(perk.type == .factory ? .cyan : .yellow)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            Text(perk.name)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
