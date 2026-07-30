import SwiftUI

/// Message affiché temporairement en haut de l'écran (bannière "toast").
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// Bannière transitoire au design soigné (ultraThinMaterial + accent coloré).
struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.title3.bold())
                .foregroundColor(toast.color)
                .shadow(color: toast.color.opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(tr(toast.title))
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let subtitle = toast.subtitle {
                    Text(tr(subtitle))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(toast.color.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
}
