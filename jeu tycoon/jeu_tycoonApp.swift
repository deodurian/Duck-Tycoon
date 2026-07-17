import SwiftUI

@main
struct jeu_tycoonApp: App {
    var body: some Scene {
        WindowGroup {
            StartScreenView()
                .id(LocalizationManager.shared.language.rawValue)
        }
    }
}
