import SwiftUI
import Foundation

// MARK: - Picker pour Auto Recycle
struct AutoRecyclePicker: View {
    @Environment(GameManager.self) private var gameManager
    
    // Pour l'instant on utilise un @AppStorage pour la facilité
    @AppStorage("autoRecycleRarity") private var autoRecycleRarityRaw: String = "None"
    
    var body: some View {
        Menu {
            Button("Désactivé") { autoRecycleRarityRaw = "None" }
            ForEach(DuckRarity.allCases, id: \.self) { rarity in
                Button(rarity.rawValue) { autoRecycleRarityRaw = rarity.rawValue }
            }
        } label: {
            HStack {
                Text("Filtre: \(autoRecycleRarityRaw)")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
