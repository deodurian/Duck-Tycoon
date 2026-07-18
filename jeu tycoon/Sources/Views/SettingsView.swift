import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(GameManager.self) private var gameManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingResetConfirmation = false
    @State private var cheatAmount: String = ""
    @AppStorage("numberFormatStyle") private var numberFormatStyle: NumberFormatStyle = .scientific
    
    // Lecture directe depuis le LocalizationManager @Observable
    private var selectedLanguage: Binding<AppLanguage> {
        Binding(
            get: { LocalizationManager.shared.language },
            set: { newLang in
                // Sauvegarder avant de rebooter l'app (car .id(language) sur le App root va détruire la vue)
                gameManager.saveGame(sync: true)
                LocalizationManager.shared.language = newLang
            }
        )
    }
    
    @State private var isRestoring = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.0, blue: 0.12), Color(red: 0.02, green: 0.0, blue: 0.06), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Profil / Info
                        VStack(spacing: 10) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(LinearGradient(colors: [.gray, .white], startPoint: .top, endPoint: .bottom))
                            Text(tr("Paramètres"))
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Affichage
                        VStack(alignment: .leading, spacing: 15) {
                            Text(tr("Affichage"))
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            VStack(spacing: 10) {
                                HStack {
                                    Text(tr("Langue"))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("", selection: selectedLanguage) {
                                        ForEach(AppLanguage.allCases) { lang in
                                            Text(tr(lang.rawValue)).tag(lang)
                                        }
                                    }
                                    .accentColor(.white)
                                    .pickerStyle(MenuPickerStyle())
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                
                                HStack {
                                    Text(tr("Format des Nombres"))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("", selection: $numberFormatStyle) {
                                        ForEach(NumberFormatStyle.allCases) { style in
                                            Text(tr(style.rawValue)).tag(style)
                                        }
                                    }
                                    .accentColor(.white)
                                    .pickerStyle(MenuPickerStyle())
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Sauvegarde
                        VStack(alignment: .leading, spacing: 15) {
                            Text(tr("Progression"))
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            Button(action: {
                                showingResetConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text(tr("Réinitialiser ma progression"))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.horizontal)
                        }
                        // Achats
                        VStack(alignment: .leading, spacing: 15) {
                            Text(tr("Achats Premium"))
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            Button(action: {
                                Task {
                                    isRestoring = true
                                    try? await AppStore.sync()
                                    isRestoring = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text(isRestoring ? tr("Restauration en cours...") : tr("Restaurer les achats"))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.horizontal)
                            .disabled(isRestoring)
                        }
                        Spacer(minLength: 40)
                        
                        Text(tr("CanardFactory v1.0"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("Fermer")) { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert(tr("Êtes-vous sûr ?"), isPresented: $showingResetConfirmation) {
                Button(tr("Annuler"), role: .cancel) { }
                Button(tr("Oui, tout effacer"), role: .destructive) {
                    gameManager.resetProgression()
                    dismiss()
                }
            } message: {
                Text(tr("Cette action est irréversible. Vous perdrez tout votre argent, vos usines et vos canards."))
            }
            .onChange(of: LocalizationManager.shared.language) { _, _ in
                dismiss()
            }
        }
    }
}
