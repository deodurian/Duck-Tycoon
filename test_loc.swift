import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case fr = "Français"
    case en = "English"
    case es = "Español"
    var id: String { rawValue }
}

let translations: [AppLanguage: [String: String]] = [
    .fr: ["Paramètres": "Paramètres"],
    .en: ["Paramètres": "Settings"],
    .es: ["Paramètres": "Ajustes"]
]

class LocalizationManager {
    static let shared = LocalizationManager()
    var language: AppLanguage = .en
    
    func tr(_ key: String) -> String {
        return translations[language]?[key] ?? translations[.fr]?[key] ?? key
    }
}

func tr(_ key: String) -> String {
    return LocalizationManager.shared.tr(key)
}

print("In EN, Paramètres ->", tr("Paramètres"))
