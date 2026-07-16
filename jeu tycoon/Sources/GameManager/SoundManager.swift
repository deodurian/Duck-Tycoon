import Foundation
import AudioToolbox
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    // Possibilité de l'activer/désactiver plus tard dans les paramètres
    var isMuted = false
    
    private init() {}
    
    func playClick() {
        guard !isMuted else { return }
        // Son système de "Tock"
        AudioServicesPlaySystemSound(1104)
    }
    
    func playPurchase() {
        guard !isMuted else { return }
        // Son de succès
        AudioServicesPlaySystemSound(1016)
    }
    
    func playFusion() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1025)
    }
    
    func playOpenCrate() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1000)
    }
    
    func playLevelUp() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1026)
    }
    
    func playError() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1053)
    }
}
