import Foundation

@main
struct TestRunner {
    static func main() {
        LocalizationManager.shared.language = .en
        print("Test 1:", tr("Jouer"))
        print("Test 2:", tr("Paramètres"))
        print("Test 3:", tr("Toucher pour continuer"))
    }
}
