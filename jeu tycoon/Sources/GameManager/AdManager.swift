import SwiftUI
import Combine

enum AdPlacement: CaseIterable {
    case factoryBoost
    case ritualSave
    case mysteryCrate
    case dailyGems
    case offlineBoost
    
    
    // TODO: Remplacer ces IDs par ceux créés sur AdMob pour chaque emplacement
    var adUnitID: String {
        switch self {
        case .factoryBoost: return "ca-app-pub-7096586150673683/1776948229" // 1. Boost Usines
        case .ritualSave: return "ca-app-pub-7096586150673683/1800998957"   // 2. Sauvetage Rituel
        case .mysteryCrate: return "ca-app-pub-7096586150673683/7361135752" // 3. Caisse Mystère
        case .dailyGems: return "ca-app-pub-7096586150673683/5524621544"    // 4. Gemmes Quotidiennes
        case .offlineBoost: return "ca-app-pub-7096586150673683/1776948229" // 5. Boost Hors-Ligne (J'utilise le même que Usine pour le moment)
        }
    }
}

#if canImport(GoogleMobileAds)
import GoogleMobileAds

@MainActor
class AdManager: NSObject, ObservableObject, FullScreenContentDelegate, @unchecked Sendable {
    static let shared = AdManager()
    
    @Published var isReady: Bool = false
    
    private var rewardedAds: [AdPlacement: RewardedAd] = [:]
    private var currentlyShowingPlacement: AdPlacement?
    private var onRewardEarned: ((Bool) -> Void)?
    private var isRewardEarned = false
    
    override init() {
        super.init()
        loadAllRewardedAds()
    }
    
    func loadAllRewardedAds() {
        self.isReady = false
        for placement in AdPlacement.allCases {
            loadRewardedAd(for: placement)
        }
    }
    
    func loadRewardedAd(for placement: AdPlacement) {
        let request = Request()
        RewardedAd.load(with: placement.adUnitID, request: request) { ad, error in
            Task { @MainActor in
                if error != nil {
                    return
                }
                ad?.fullScreenContentDelegate = AdManager.shared
                AdManager.shared.rewardedAds[placement] = ad
                AdManager.shared.isReady = !AdManager.shared.rewardedAds.isEmpty
            }
        }
    }
    
    func showRewardedAd(for placement: AdPlacement, completion: @escaping (Bool) -> Void) {
        self.onRewardEarned = completion
        self.isRewardEarned = false
        self.currentlyShowingPlacement = placement
        
        guard let rewardedAd = rewardedAds[placement] else {
            self.onRewardEarned?(false)
            self.loadRewardedAd(for: placement)
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
                self?.isRewardEarned = true
            }
        } else {
            self.onRewardEarned?(false)
            self.loadRewardedAd(for: placement)
        }
    }
    
    // MARK: - FullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Appeler le callback APRÈS la fermeture de la pub
        finishCurrentAd(earned: self.isRewardEarned)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finishCurrentAd(earned: false)
    }

    private func finishCurrentAd(earned: Bool) {
        DispatchQueue.main.async {
            self.onRewardEarned?(earned)
            self.onRewardEarned = nil
        }

        if let placement = currentlyShowingPlacement {
            self.rewardedAds[placement] = nil
            self.loadRewardedAd(for: placement)
        }

        self.currentlyShowingPlacement = nil
        self.isRewardEarned = false
        self.isReady = !self.rewardedAds.isEmpty
    }
}
#else
// Fallback if GoogleMobileAds SDK is not installed yet
class AdManager {
    static let shared = AdManager()
    
    func showRewardedAd(for placement: AdPlacement, completion: @escaping (Bool) -> Void) {
        // AdMob SDK not installed: simulate ad success
        completion(true)
    }
}
#endif
