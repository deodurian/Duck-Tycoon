import SwiftUI
import Foundation

// MARK: - Picker pour Auto Crate
struct AutoCratePicker: View {
    @Environment(GameManager.self) private var gameManager
    
    var body: some View {
        Menu {
            Button(tr("Désactivé")) { gameManager.autoCrateTargetId = nil }
            ForEach(Crate.allCrates, id: \.type.rawValue) { crate in
                Button(crate.type.rawValue) { gameManager.autoCrateTargetId = crate.type.rawValue }
            }
        } label: {
            HStack {
                Text("Cible: \(gameManager.autoCrateTargetId ?? "Aucune")")
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .foregroundColor(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
