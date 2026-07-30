import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct jeu_tycoonApp: App {
    init() {
        // Mode développeur : actif uniquement dans les builds Xcode (Debug),
        // toujours écrasé à false dans les builds App Store (Release).
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "isDeveloperMode")
        #else
        UserDefaults.standard.set(false, forKey: "isDeveloperMode")
        #endif

        #if canImport(GoogleMobileAds)
        // Appareil de test AdMob : uniquement dans les builds Xcode. En Release, déclarer un
        // identifiant de test ferait servir des pubs de test à cet appareil en production.
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [ "04791426dd61ac2f0d7206d419c4d0bc" ]
        #endif
        MobileAds.shared.start { _ in }
        #endif
        
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif

        // Équilibrage pilotable à distance (fallback hors-ligne sur les valeurs par défaut).
        RemoteConfigManager.shared.configure()
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
