import SwiftUI

struct StoryView: View {
    @Environment(GameManager.self) private var gameManager
    
    var body: some View {
        ZStack {
            // Background
            Color(hue: 0.6, saturation: 0.1, brightness: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // Entête
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.blue)
                    Text(tr("Histoire & Objectifs"))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                if let storyInfo = gameManager.currentStoryInfo {
                    // Bulle de dialogue
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(alignment: .top, spacing: 15) {
                            // Avatar d'Anthony
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Text("👨‍🔬")
                                    .font(.system(size: 40))
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(tr("Anthony le scientifique"))
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text(tr(storyInfo.dialogue))
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Objectif Actuel
                    VStack(spacing: 15) {
                        Text(tr("Objectif Actuel"))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(tr(storyInfo.quest.title))
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                Text(tr(storyInfo.quest.description))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            
                            if gameManager.isStoryQuestReadyToClaim {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Récompense
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.purple)
                            Text(tr("Récompense :") + " " + tr(storyInfo.quest.rewardDescription))
                                .font(.subheadline.bold())
                                .foregroundColor(.purple)
                        }
                        .padding(.top, 5)
                        
                        // Bouton Réclamer
                        Button(action: {
                            withAnimation(.spring) {
                                gameManager.claimStoryReward()
                            }
                        }) {
                            Text(gameManager.isStoryQuestReadyToClaim ? tr("Récupérer la récompense") : tr("Quête en cours..."))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(gameManager.isStoryQuestReadyToClaim ? Color.green : Color.gray.opacity(0.5))
                                .cornerRadius(12)
                                .shadow(color: gameManager.isStoryQuestReadyToClaim ? Color.green.opacity(0.5) : Color.clear, radius: 10, y: 5)
                        }
                        .disabled(!gameManager.isStoryQuestReadyToClaim)
                        .padding(.top, 10)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                } else {
                    // Histoire terminée
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        Text(tr("Histoire Terminée !"))
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Text(tr("Tu as terminé toutes les quêtes d'histoire. Le mode libre est activé !"))
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
            }
        }
    }
}
