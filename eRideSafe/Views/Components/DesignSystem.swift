import SwiftUI
import UIKit

extension Color {
    static let erideNavy = Color(red: 0.025, green: 0.075, blue: 0.145)
    static let erideGreen = Color(red: 0.08, green: 0.72, blue: 0.46)
    static let erideTeal = Color(red: 0.08, green: 0.64, blue: 0.68)
    static let erideBlue = Color(red: 0.12, green: 0.43, blue: 0.92)
    static let erideGold = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let erideCoral = Color(red: 0.94, green: 0.31, blue: 0.31)
    static let erideMint = Color(red: 0.86, green: 0.97, blue: 0.91)
    static let erideBackground = Color(uiColor: .systemGroupedBackground)
    static let erideSurface = Color(uiColor: .secondarySystemGroupedBackground)
}

extension LinearGradient {
    static let erideHero = LinearGradient(
        colors: [Color.erideNavy, Color(red: 0.03, green: 0.30, blue: 0.39), Color.erideGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let erideOnboarding = LinearGradient(
        colors: [Color.erideNavy, Color(red: 0.025, green: 0.19, blue: 0.27)],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct ERideCard<Content: View>: View {
    private let tint: Color
    private let content: Content

    init(tint: Color = .erideGreen, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.erideSurface, tint.opacity(0.055)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .shadow(color: Color.black.opacity(0.055), radius: 10, y: 5)
    }
}

struct TintedIcon: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 46, height: 46)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct StatusPill: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Color.erideGreen, Color.erideTeal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.76 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: Color.erideGreen.opacity(0.22), radius: 8, y: 4)
    }
}
