import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct jeu_tycoonApp: App {
    init() {
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
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
