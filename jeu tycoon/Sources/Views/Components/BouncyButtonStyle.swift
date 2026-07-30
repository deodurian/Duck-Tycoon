import SwiftUI

/// Style de bouton "juicy" : léger rebond au clic (scale + ressort).
struct BouncyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    /// Applique le style rebondissant à un bouton.
    func bouncy(scale: CGFloat = 0.94) -> some View {
        buttonStyle(BouncyButtonStyle(scale: scale))
    }
}
