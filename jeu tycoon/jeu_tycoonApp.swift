import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct jeu_tycoonApp: App {
    init() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [ "04791426dd61ac2f0d7206d419c4d0bc" ]
        MobileAds.shared.start { _ in }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    // En observant la langue ici, on force la vue à se redessiner
    var languageId: String {
        LocalizationManager.shared.language.rawValue
    }
    
    var body: some View {
        StartScreenView()
            .id(languageId)
    }
}
