import SwiftUI

// MARK: - Palette "Cyber-Génétique"

enum Neon {
    static let cyan = Color(hex: 0x00FFFF)      // technologie standard
    static let green = Color(hex: 0x39FF14)     // mutations / ADN
    static let magenta = Color(hex: 0xFF00FF)   // prestige / critique
    static let purple = Color(hex: 0x8A2BE2)
    static let yellow = Color(hex: 0xFFD23F)
    static let red = Color(hex: 0xFF2D55)

    /// Couleur dominante par onglet (identité visuelle par page).
    static func accent(forTab index: Int) -> Color {
        switch index {
        case 0: return cyan        // Histoire
        case 1: return green       // Usines
        case 2: return cyan        // Canards / Labo
        case 3: return magenta     // Boutique
        case 4: return cyan        // Améliorations
        case 5: return red         // Rituel
        case 6: return purple      // Prestige
        case 7: return green       // Banque
        default: return cyan
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Fond global "Laboratoire Génétique"

/// Grille de laboratoire très subtile.
private struct LabGrid: Shape {
    var spacing: CGFloat = 34
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x = rect.minX
        while x <= rect.maxX { p.move(to: CGPoint(x: x, y: rect.minY)); p.addLine(to: CGPoint(x: x, y: rect.maxY)); x += spacing }
        var y = rect.minY
        while y <= rect.maxY { p.move(to: CGPoint(x: rect.minX, y: y)); p.addLine(to: CGPoint(x: rect.maxX, y: y)); y += spacing }
        return p
    }
}

/// Fond abyssal #090914, halo radial teinté (couleur dominante de l'onglet) + grille labo.
struct NeonBackground: View {
    var accent: Color = Neon.purple
    var body: some View {
        ZStack {
            Color(hex: 0x090914)
            RadialGradient(colors: [accent.opacity(0.20), .clear], center: .top, startRadius: 5, endRadius: 520)
            RadialGradient(colors: [Neon.cyan.opacity(0.06), .clear], center: .bottomTrailing, startRadius: 5, endRadius: 460)
            LabGrid().stroke(Color.white.opacity(0.03), lineWidth: 0.5)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Bouton Néon (le cœur du "juice")

/// Bouton "objet physique" : fond bombé dégradé, bordure néon, aura, reflet 3D,
/// enfoncement à ressort et retour haptique (léger à l'appui, moyen au relâchement).
struct NeonButtonStyle: ButtonStyle {
    var color: Color = Neon.cyan
    var cornerRadius: CGFloat = 16
    /// `false` pour un bouton qui s'ajuste à son contenu (chips inline type « Réclamer »).
    var fullWidth: Bool = true
    /// Rembourrage réduit pour les petits boutons.
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font((compact ? Font.subheadline : Font.headline).weight(.bold))
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, compact ? 7 : 14)
            .padding(.horizontal, compact ? 14 : 18)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x1A1A2E), Color(hex: 0x0D0D1A)], startPoint: .top, endPoint: .bottom))
            }
            // Reflet supérieur (arête métallique)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center),
                        lineWidth: 1
                    )
            }
            // Bordure néon
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: 1.5)
            }
            // Aura (renforcée à l'appui pour un "flash" lumineux)
            .shadow(color: color.opacity(configuration.isPressed ? 1.0 : 0.7), radius: configuration.isPressed ? 12 : 6)
            // Écrasement physique agressif + rebond très rapide
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.5), value: configuration.isPressed)
            // Haptique INSTANTANÉE : se déclenche au moment précis de l'enfoncement, pas au relâchement.
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { NeonHaptics.impact() }
            }
    }
}

/// Retours haptiques préparés et réutilisés pour une latence minimale.
enum NeonHaptics {
    private static let generator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        return g
    }()

    private static let lightGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()

    private static let notificationGenerator: UINotificationFeedbackGenerator = {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        return g
    }()

    static func impact() {
        generator.impactOccurred()
        // Re-préparer pour que le prochain appui soit lui aussi instantané.
        generator.prepare()
    }

    /// Petit « tic » léger, pensé pour être répété (compteurs qui défilent).
    static func tick() {
        lightGenerator.impactOccurred(intensity: 0.55)
        lightGenerator.prepare()
    }

    /// Vibration de réussite : récompense encaissée, palier franchi.
    static func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
}

// MARK: - Reflet de surface (verre / métal)

/// Dégradé du reflet qui balaye une surface. `phase` va de -0.35 à 1.35.
func neonSheenGradient(phase: CGFloat, opacity: Double = 0.45) -> LinearGradient {
    let lo = min(max(phase - 0.16, 0), 1)
    let mid = min(max(phase, 0), 1)
    let hi = min(max(phase + 0.16, 0), 1)
    return LinearGradient(
        stops: [
            .init(color: .clear, location: lo),
            .init(color: .white.opacity(opacity), location: mid),
            .init(color: .clear, location: hi)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

/// Reflet lumineux qui traverse la vue en boucle, avec une pause entre deux passages :
/// c'est ce qui fait « vitre » plutôt que « rectangle coloré ».
struct NeonSheen: ViewModifier {
    var cornerRadius: CGFloat = 12
    var active: Bool = true
    /// Temps d'attente avant chaque passage (évite le clignotement permanent).
    var pause: Double = 1.7
    /// Durée du balayage.
    var travel: Double = 0.8
    var opacity: Double = 0.45

    func body(content: Content) -> some View {
        content.overlay {
            if active {
                KeyframeAnimator(initialValue: CGFloat(-0.35), repeating: true) { phase in
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(neonSheenGradient(phase: phase, opacity: opacity))
                        .blendMode(.plusLighter)
                } keyframes: { _ in
                    LinearKeyframe(CGFloat(-0.35), duration: pause)
                    LinearKeyframe(CGFloat(1.35), duration: travel)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Jauge néon

/// Barre de progression « écran de labo » : rail creux, remplissage dégradé qui s'anime
/// à ressort, pointe lumineuse au bout et reflet qui balaye la partie remplie.
struct NeonProgressBar: View {
    var fraction: Double
    var color: Color = Neon.cyan
    var height: CGFloat = 8
    /// Reflet mobile : à couper dans les très longues listes.
    var animated: Bool = true

    private var clamped: CGFloat { CGFloat(min(max(fraction, 0), 1)) }

    var body: some View {
        GeometryReader { geo in
            let filled = geo.size.width * clamped
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.09))
                    .overlay(Capsule().stroke(Color.white.opacity(0.07), lineWidth: 1))

                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: filled)
                    .overlay(alignment: .trailing) {
                        // Pointe lumineuse : donne l'impression que la jauge « avance ».
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: height * 0.72, height: height * 0.72)
                            .blur(radius: 0.8)
                            .padding(.trailing, height * 0.14)
                            .opacity(filled > height ? 1 : 0)
                    }
                    .modifier(NeonSheen(cornerRadius: height / 2, active: animated && clamped > 0.04, opacity: 0.5))
                    .shadow(color: color.opacity(0.65), radius: 4)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: clamped)
    }
}

// MARK: - Bouton doré (offres « pub », actions héroïques)

/// Contrairement à `NeonButtonStyle` (fond sombre), ce bouton est **rempli** d'or et balayé
/// par un reflet : il doit écraser visuellement tout le reste de l'écran.
struct GoldenAdButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return configuration.label
            .foregroundStyle(Color(hex: 0x3F1D00))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .background {
                shape.fill(
                    LinearGradient(colors: [Color(hex: 0xFFE9A3), Color(hex: 0xFFC53F), Color(hex: 0xF0871A)],
                                   startPoint: .top, endPoint: .bottom)
                )
            }
            .modifier(NeonSheen(cornerRadius: cornerRadius, pause: 1.3, travel: 0.75, opacity: 0.55))
            // Arête métallique
            .overlay {
                shape.stroke(
                    LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
            }
            .clipShape(shape)
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.5), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { NeonHaptics.impact() }
            }
    }
}

// MARK: - Panneau Néon (cuves / écrans)

/// Accents lumineux dans les coins supérieurs (aspect "écran high-tech").
private struct CornerAccents: Shape {
    var length: CGFloat = 14
    var inset: CGFloat = 7
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset + length))
        p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.minX + inset + length, y: rect.minY + inset))
        p.move(to: CGPoint(x: rect.maxX - inset - length, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset + length))
        return p
    }
}

/// Verre blindé de labo : ultraThinMaterial assombri, bordure fine + accents de coins.
struct NeonPanel: ViewModifier {
    var color: Color = Neon.purple
    var cornerRadius: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.black.opacity(0.40))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            }
            .overlay {
                CornerAccents().stroke(color.opacity(0.9), lineWidth: 1.5)
                    .shadow(color: color.opacity(0.6), radius: 3)
            }
            .shadow(color: color.opacity(0.18), radius: 8)
    }
}

extension View {
    func neonPanel(color: Color = Neon.purple, cornerRadius: CGFloat = 18) -> some View {
        modifier(NeonPanel(color: color, cornerRadius: cornerRadius))
    }

    /// Bouton néon rapide.
    func neonButton(_ color: Color = Neon.cyan, cornerRadius: CGFloat = 16) -> some View {
        buttonStyle(NeonButtonStyle(color: color, cornerRadius: cornerRadius))
    }

    /// Titre "Laboratoire" : arrondi + halo.
    func neonTitle(_ color: Color = Neon.cyan) -> some View {
        self.fontDesign(.rounded).foregroundStyle(color).shadow(color: color.opacity(0.6), radius: 8)
    }

    /// Reflet qui balaye la surface en boucle (aspect vitré / métallique).
    func neonSheen(cornerRadius: CGFloat = 12, active: Bool = true, pause: Double = 1.7, travel: Double = 0.8, opacity: Double = 0.45) -> some View {
        modifier(NeonSheen(cornerRadius: cornerRadius, active: active, pause: pause, travel: travel, opacity: opacity))
    }
}

// MARK: - Tube d'incubation

/// Cuve d'incubation : le contenu "flotte" dans un tube semi-transparent avec des bulles qui montent.
struct IncubationTube<Content: View>: View {
    var color: Color = Neon.green
    var cornerRadius: CGFloat = 14
    @ViewBuilder var content: () -> Content

    @State private var animate = false
    private let bubbleX: [CGFloat] = [-13, 9, -5, 15]

    var body: some View {
        content()
            .padding(5)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(colors: [color.opacity(0.18), color.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                        )
                    ForEach(0..<bubbleX.count, id: \.self) { i in
                        Circle()
                            .fill(color.opacity(0.45))
                            .frame(width: CGFloat(3 + i), height: CGFloat(3 + i))
                            .offset(x: bubbleX[i], y: animate ? -24 : 22)
                            .opacity(animate ? 0.0 : 0.85)
                            .animation(
                                .easeInOut(duration: Double(2 + i))
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.45),
                                value: animate
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: color.opacity(0.4), radius: 5)
            .onAppear { animate = true }
    }
}

// MARK: - Popup d'information thématisé (remplace les .alert d'info « fades »)

/// Fenêtre d'aide « écran de labo » : fond assombri + carte sombre à bordure néon,
/// message défilant et bouton néon. Cohérent avec ProbabilityPopup.
struct InfoPopup: View {
    let title: String
    let message: String
    var accent: Color = Neon.cyan
    @Binding var isPresented: Bool

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(accent)
                        .shadow(color: accent.opacity(0.6), radius: 4)
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                ScrollView {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: 320)

                Button(action: { dismiss() }) {
                    Text(tr("Compris"))
                }
                .neonButton(accent)
            }
            .padding(20)
            .frame(maxWidth: 350)
            .background(Color(hex: 0x0E0E1A))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.45), lineWidth: 1)
            )
            .overlay(
                CornerAccents().stroke(accent.opacity(0.9), lineWidth: 1.5)
                    .shadow(color: accent.opacity(0.6), radius: 3)
            )
            .shadow(color: accent.opacity(0.35), radius: 24)
            .padding(28)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .zIndex(80)
    }
}

extension View {
    /// Superpose un `InfoPopup` thématisé au lieu d'un `.alert` système fade.
    func infoPopup(isPresented: Binding<Bool>, title: String, message: String, accent: Color = Neon.cyan) -> some View {
        overlay {
            if isPresented.wrappedValue {
                InfoPopup(title: title, message: message, accent: accent, isPresented: isPresented)
            }
        }
    }
}

// MARK: - Badge de monnaie (HUD)

/// Pilule allongée : icône dans un cercle lumineux à gauche, montant monospace à droite.
struct CurrencyBadge: View {
    let icon: String
    let amount: String
    var color: Color = Neon.cyan

    var body: some View {
        HStack(spacing: 5) {
            Text(icon)
                .font(.system(size: 12))
                .frame(width: 22, height: 22)
                .background(Circle().fill(color.opacity(0.18)))
                .overlay(Circle().stroke(color.opacity(0.7), lineWidth: 1))
                .shadow(color: color.opacity(0.6), radius: 3)

            Text(amount)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.35)
                .layoutPriority(1)
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().stroke(color.opacity(0.30), lineWidth: 1))
    }
}
