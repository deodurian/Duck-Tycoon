import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds

@MainActor
class AdManager: NSObject, FullScreenContentDelegate, @unchecked Sendable {
    static let shared = AdManager()
    
    // Identifiant de test Google officiel pour les vidéos avec récompense
    private let rewardedAdUnitID = "ca-app-pub-7096586150673683/6259968771"
    
    private var rewardedAd: RewardedAd?
    private var onRewardEarned: ((Bool) -> Void)?
    
    override init() {
        super.init()
        loadRewardedAd()
    }
    
    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: rewardedAdUnitID, request: request) { ad, error in
            Task { @MainActor in
                if let error = error {
                    print("Erreur de chargement de la pub: \(error.localizedDescription)")
                    return
                }
                AdManager.shared.rewardedAd = ad
                AdManager.shared.rewardedAd?.fullScreenContentDelegate = AdManager.shared
                print("Pub récompensée chargée avec succès.")
            }
        }
    }
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        self.onRewardEarned = completion
        
        guard let rewardedAd = rewardedAd else {
            print("La pub n'est pas encore prête.")
            // ERREUR ICI : on donnait la récompense (true) alors que la pub n'était pas prête !
            self.onRewardEarned?(false) 
            self.loadRewardedAd()
            return
        }
        
        // Obtenir la vue racine de l'application de façon plus robuste pour SwiftUI
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? scenes.first as? UIWindowScene
        var topController = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene?.windows.first?.rootViewController
        
        // Trouver le contrôleur le plus au premier plan (s'il y a déjà des popups ou sheets d'ouverts)
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        
        if let topController = topController {
            rewardedAd.present(from: topController) { [weak self] in
                print("Le joueur a gagné la récompense !")
                self?.onRewardEarned?(true)
            }
        } else {
            print("Erreur: Impossible de trouver la fenêtre principale pour afficher la pub.")
            self.onRewardEarned?(false)
            self.loadRewardedAd()
        }
    }
    
    // MARK: - FullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("La pub a été fermée.")
        self.rewardedAd = nil
        self.loadRewardedAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Erreur d'affichage de la pub : \(error.localizedDescription)")
        self.onRewardEarned?(false)
        self.rewardedAd = nil
        self.loadRewardedAd()
    }
}
#else
// Fallback if GoogleMobileAds SDK is not installed yet
class AdManager {
    static let shared = AdManager()
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        print("AdMob SDK not installed. Simulating ad success.")
        completion(true)
    }
}
#endif
