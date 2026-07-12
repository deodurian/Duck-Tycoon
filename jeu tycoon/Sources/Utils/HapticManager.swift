import SwiftUI
import Foundation
import UIKit

// MARK: - Haptic Manager
struct HapticManager {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    
    func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }
    
    func lightTap() { lightImpact.impactOccurred() }
    func mediumTap() { mediumImpact.impactOccurred() }
    func heavyTap() { heavyImpact.impactOccurred() }
    func success() { notification.notificationOccurred(.success) }
    func warning() { notification.notificationOccurred(.warning) }
    
    func rarityReveal(_ rarity: DuckRarity) {
        switch rarity {
        case .commun, .peuCommun:
            lightTap()
        case .rare:
            mediumTap()
        case .epique:
            heavyTap()
        case .legendaire:
            heavyTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.heavyTap() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.success() }
        case .mythique:
            heavyTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.heavyTap() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.heavyTap() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self.success() }
        }
    }
}
