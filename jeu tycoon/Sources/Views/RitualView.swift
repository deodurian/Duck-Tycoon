import SwiftUI

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct RitualView: View {
    @Environment(GameManager.self) var gameManager: GameManager
    
    @State private var selectedDuck: Duck? = nil
    @State private var showDuckPicker = false
    
    @State private var wheelRotation: Double = 0
    @State private var isSpinning = false
    @State private var showResult = false
    @State private var resultSuccess = false
    @State private var resultGolden = false
    @State private var showInfoAlert = false
    
    // Animations
    @State private var flameFlicker = false
    @State private var glowPulse = false
    
    var successChance: Double {
        guard let duck = selectedDuck else { return 0.5 }
        return duck.ritualSuccessChance(occulteLevel: gameManager.occulteLevel)
    }
    
    var body: some View {
        ZStack {
            // Particules flottantes
            RitualParticlesView()
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Titre
                HStack(spacing: 8) {
                    Text("Le Rituel Canarifique")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hue: 0.78, saturation: 0.6, brightness: 1.0), Color(hue: 0.83, saturation: 0.5, brightness: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 8)
                    
                    Button(action: {
                        showInfoAlert = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(colors: [.purple.opacity(0.7), .blue.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                    }
                }
                .padding(.top, 8)
                
                // Roue de la fortune stylisée
                ZStack {
                    // Glow derrière la roue
                    Circle()
                        .fill(
                            RadialGradient(colors: [
                                .purple.opacity(glowPulse ? 0.25 : 0.1),
                                .clear
                            ], center: .center, startRadius: 60, endRadius: 160)
                        )
                        .frame(width: 300, height: 300)
                    
                    // Roue
                    ZStack {
                        // Fond rouge
                        Circle()
                            .fill(
                                RadialGradient(colors: [Color(red: 0.7, green: 0.1, blue: 0.1), Color(red: 0.4, green: 0.05, blue: 0.05)], center: .center, startRadius: 20, endRadius: 100)
                            )
                        
                        let chance = successChance
                        let greenEnd = 360.0 * chance
                        
                        let goldenLevel = gameManager.goldenRitualLevel
                        if goldenLevel > 0 {
                            let goldenRatio = Double(goldenLevel) * 0.04
                            let goldenEnd = 360.0 * goldenRatio
                            
                            PieSlice(startAngle: .degrees(0), endAngle: .degrees(greenEnd))
                                .fill(
                                    LinearGradient(colors: [Color(hue: 0.35, saturation: 0.8, brightness: 0.7), Color(hue: 0.35, saturation: 0.9, brightness: 0.5)], startPoint: .top, endPoint: .bottom)
                                )
                            
                            let actualGoldenEnd = min(goldenEnd, greenEnd)
                            PieSlice(startAngle: .degrees(0), endAngle: .degrees(actualGoldenEnd))
                                .fill(
                                    LinearGradient(colors: [Color(hue: 0.13, saturation: 0.9, brightness: 1.0), Color(hue: 0.10, saturation: 0.8, brightness: 0.85)], startPoint: .top, endPoint: .bottom)
                                )
                        } else {
                            PieSlice(startAngle: .degrees(0), endAngle: .degrees(greenEnd))
                                .fill(
                                    LinearGradient(colors: [Color(hue: 0.35, saturation: 0.8, brightness: 0.7), Color(hue: 0.35, saturation: 0.9, brightness: 0.5)], startPoint: .top, endPoint: .bottom)
                                )
                        }
                        
                        // Centre de la roue
                        Circle()
                            .fill(
                                RadialGradient(colors: [Color(white: 0.2), Color(white: 0.08)], center: .center, startRadius: 0, endRadius: 20)
                            )
                            .frame(width: 30, height: 30)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 30, height: 30)
                    }
                    .rotationEffect(.degrees(wheelRotation))
                    .frame(width: 210, height: 210)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .purple.opacity(0.3), .white.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: .purple.opacity(0.5), radius: 15)
                    
                    // Flèche stylisée
                    HStack {
                        Spacer()
                        ZStack {
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                                .shadow(color: .purple, radius: 6)
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(colors: [.white, Color(hue: 0.80, saturation: 0.3, brightness: 1.0)], startPoint: .top, endPoint: .bottom)
                                )
                        }
                        .offset(x: 18)
                    }
                    .frame(width: 260)
                }
                .padding(.vertical, 10)
                
                // Sélection de canard
                Button(action: {
                    if !isSpinning {
                        showDuckPicker = true
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.4), .blue.opacity(0.2), .purple.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .frame(width: 105, height: 105)
                        
                        if let duck = selectedDuck {
                            DuckGridCard(
                                duck: duck,
                                displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                isAssigned: gameManager.isDuckAssigned(duckId: duck.id)
                            )
                            .scaleEffect(100.0 / 55.0)
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple.opacity(0.7), .blue.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                    )
                                Text("Sélectionner")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showDuckPicker) {
                    RitualDuckPickerSheet(selectedDuck: $selectedDuck)
                        .environment(gameManager)
                }
                
                // Infos de prix
                if let duck = selectedDuck {
                    VStack(spacing: 10) {
                        // Barre de chance
                        VStack(spacing: 5) {
                            HStack {
                                Text("Chance de réussite")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(successChance * 100))%")
                                    .font(.headline.weight(.bold).monospacedDigit())
                                    .foregroundColor(chanceColor)
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(colors: [chanceColor, chanceColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .frame(width: geo.size.width * min(CGFloat(successChance), 1.0))
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.horizontal, 20)
                        
                        // Valeurs
                        HStack(spacing: 12) {
                            VStack(spacing: 2) {
                                Text("Actuelle")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("\(gameManager.displaySellValue(for: duck).formattedString()) 💰")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            
                            VStack(spacing: 2) {
                                Text("x2")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundColor(.green)
                                Text("\((gameManager.displaySellValue(for: duck) * 2.0).formattedString()) 💰")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.green)
                            }
                            
                            if gameManager.isUnlocked(.goldenRitual) {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.yellow.opacity(0.6))
                                
                                VStack(spacing: 2) {
                                    Text("x10")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundColor(.yellow)
                                    Text("Doré 🌟")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal)
                } else {
                    Text("Sélectionnez un canard pour voir les détails")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding(.vertical, 14)
                }
                
                Spacer()
                
                // Bouton Lancer
                Button(action: {
                    lancerRituel()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .scaleEffect(flameFlicker ? 1.15 : 1.0)
                        Text("LANCER LE RITUEL")
                            .font(.title3.weight(.bold))
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .scaleEffect(flameFlicker ? 1.0 : 1.15)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Group {
                            if selectedDuck == nil || isSpinning {
                                Color.gray.opacity(0.3)
                            } else {
                                LinearGradient(
                                    colors: [Color(hue: 0.78, saturation: 0.7, brightness: 0.7), Color(hue: 0.83, saturation: 0.8, brightness: 0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: selectedDuck != nil && !isSpinning ? .purple.opacity(0.5) : .clear, radius: 10, y: 5)
                }
                .disabled(selectedDuck == nil || isSpinning)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .overlay {
            if showResult {
                RitualResultOverlay(success: resultSuccess, isGolden: resultGolden)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showResult = false
                            }
                        }
                    }
            }
        }
        .alert("Règles du Rituel", isPresented: $showInfoAlert) {
            Button("Compris", role: .cancel) {}
        } message: {
            Text("Sacrifiez un canard pour doubler sa valeur ! Mais attention : la chance de réussite diminue de 5% à chaque succès. En cas d'échec, le canard sera détruit à jamais !")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                flameFlicker = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    private var chanceColor: Color {
        if successChance > 0.7 { return .green }
        if successChance > 0.4 { return .yellow }
        return .red
    }
    
    private func lancerRituel() {
        guard let duck = selectedDuck else { return }
        
        isSpinning = true
        let chance = successChance
        let goldenLevel = gameManager.goldenRitualLevel
        let goldenRatio = Double(goldenLevel) * 0.04
        let goldenDegrees = min(360.0 * goldenRatio, 360.0 * chance)
        let goldenChance = goldenDegrees / 360.0
        
        let roll = Double.random(in: 0.0..<1.0)
        let isGoldenResult = roll < goldenChance
        let isSuccess = roll < chance
        
        let targetAngle: Double
        if isGoldenResult {
            targetAngle = goldenDegrees > 0 ? Double.random(in: 0..<goldenDegrees) : 0
        } else if isSuccess {
            let maxAngle = 360 * chance
            targetAngle = goldenDegrees < maxAngle ? Double.random(in: goldenDegrees..<maxAngle) : goldenDegrees
        } else {
            let minAngle = min(360 * chance, 360.0)
            targetAngle = minAngle < 360.0 ? Double.random(in: minAngle...360.0) : 360.0
        }
        
        // On veut que l'angle `targetAngle` tombe sur la flèche (à 0 degrés).
        // Donc on tourne de `-targetAngle` + 5 tours complets
        let totalRotation = -(targetAngle) - (360 * 5)
        
        withAnimation(.easeOut(duration: 3.0)) {
            wheelRotation = totalRotation
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            resultSuccess = isSuccess
            resultGolden = isGoldenResult
            withAnimation {
                showResult = true
            }
            
            // Appliquer la logique métier
            gameManager.performRitual(on: duck.id, success: isSuccess, isGolden: isGoldenResult)
            
            // Mettre à jour l'UI
            if isSuccess {
                // Le canard a gagné, on met à jour son instance locale pour voir la flamme
                if let updatedDuck = gameManager.inventory.first(where: { $0.id == duck.id }) {
                    selectedDuck = updatedDuck
                }
            } else {
                // Le canard est détruit
                selectedDuck = nil
            }
            
            // Réinitialiser la roue silencieusement
            wheelRotation = -(targetAngle) // Garder la même position visuelle mais enlever les tours
            isSpinning = false
        }
    }
}



// MARK: - Particules rituelles
private struct RitualParticlesView: View {
    @State private var particles: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double, hue: Double)] = []
    @State private var animate = false
    
    var body: some View {
        Canvas { context, size in
            for p in particles {
                let yOffset = animate ? -30.0 : 30.0
                let rect = CGRect(
                    x: p.x * size.width,
                    y: p.y * size.height + yOffset,
                    width: p.size,
                    height: p.size
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color(hue: p.hue, saturation: 0.6, brightness: 0.8).opacity(p.opacity * (animate ? 0.7 : 0.3)))
                )
            }
        }
        .onAppear {
            particles = (0..<30).map { _ in
                (
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    size: CGFloat.random(in: 1.5...4),
                    opacity: Double.random(in: 0.15...0.5),
                    hue: Double.random(in: 0.7...0.9) // Purple range
                )
            }
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct RitualDuckPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(GameManager.self) var gameManager: GameManager
    @Binding var selectedDuck: Duck?
    
    @State private var displayDucks: [Duck] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var currentPage = 0
    @State private var sortedAll: [Duck] = []
    @State private var hasMore = false
    private let pageSize = 100
    
    private func updateDisplayInventory() {
        isLoading = true
        currentPage = 0
        displayDucks = []
        let gm = gameManager
        Task {
            let all = await gm.getSortedInventoryAsync(by: .sellValueDesc, limit: Int.max)
            let firstSlice = Array(all.prefix(pageSize))
            await MainActor.run {
                self.sortedAll = all
                self.displayDucks = firstSlice
                self.hasMore = all.count > pageSize
                self.currentPage = 1
                self.isLoading = false
            }
        }
    }
    
    private func loadMoreIfNeeded() {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        Task {
            let nextSlice = Array(sortedAll.dropFirst(currentPage * pageSize).prefix(pageSize))
            await MainActor.run {
                self.displayDucks.append(contentsOf: nextSlice)
                self.currentPage += 1
                self.hasMore = (self.currentPage * self.pageSize) < self.sortedAll.count
                self.isLoadingMore = false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView("Chargement des canards...")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 55), spacing: 8)], spacing: 8) {
                        ForEach(displayDucks) { duck in
                            DuckGridCard(
                                duck: duck,
                                displayValue: gameManager.displaySellValue(for: duck).formattedString(),
                                isAssigned: gameManager.isDuckAssigned(duckId: duck.id)
                            )
                            .onTapGesture {
                                selectedDuck = duck
                                dismiss()
                            }
                            .onAppear {
                                if duck.id == displayDucks.last?.id {
                                    loadMoreIfNeeded()
                                }
                            }
                        }
                        
                        if isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding()
                }
                .navigationTitle(tr("Sélectionner un canard"))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
        }
        .onAppear {
            updateDisplayInventory()
        }
    }
}
