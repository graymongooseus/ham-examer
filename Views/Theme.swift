import SwiftUI
import UIKit

enum RadioTheme {
    static let ink = adaptive(light: (242, 247, 250), dark: (7, 22, 34))
    static let ink2 = adaptive(light: (230, 239, 244), dark: (13, 35, 51))
    static let panel = adaptive(light: (255, 255, 255), dark: (16, 43, 62))
    static let panel2 = adaptive(light: (245, 250, 252), dark: (11, 32, 48))
    static let muted = adaptive(light: (74, 96, 110), dark: (155, 183, 198))
    static let text = adaptive(light: (19, 43, 58), dark: (236, 247, 251))
    static let amber = adaptive(light: (133, 82, 0), dark: (255, 191, 71))
    static let amber2 = adaptive(light: (117, 72, 0), dark: (255, 218, 143))
    static let cyan = adaptive(light: (0, 102, 128), dark: (90, 215, 246))
    static let green = adaptive(light: (22, 115, 68), dark: (118, 227, 165))
    static let red = adaptive(light: (178, 45, 43), dark: (255, 140, 135))
    static let line = adaptive(light: (62, 106, 128), dark: (155, 203, 224)).opacity(0.18)
    static let onAccent = adaptive(light: (255, 255, 255), dark: (7, 22, 34))

    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255, alpha: 1)
        })
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            RadioTheme.ink
            RadialGradient(colors: [RadioTheme.cyan.opacity(0.16), .clear], center: .topLeading, startRadius: 0, endRadius: 520)
            Canvas { context, size in
                let spacing: CGFloat = 44
                var path = Path()
                stride(from: CGFloat.zero, through: size.width, by: spacing).forEach {
                    path.move(to: CGPoint(x: $0, y: 0)); path.addLine(to: CGPoint(x: $0, y: size.height))
                }
                stride(from: CGFloat.zero, through: size.height, by: spacing).forEach {
                    path.move(to: CGPoint(x: 0, y: $0)); path.addLine(to: CGPoint(x: size.width, y: $0))
                }
                context.stroke(path, with: .color(RadioTheme.cyan.opacity(0.035)), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}

struct PanelModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [RadioTheme.panel.opacity(0.98), RadioTheme.panel2.opacity(0.98)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RadioTheme.line))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.06), radius: 28, y: 14)
    }
}

extension View {
    func radioPanel() -> some View { modifier(PanelModifier()) }
}

struct BrandMark: View {
    var body: some View {
        ZStack {
            Circle().fill(RadioTheme.amber.opacity(0.07))
            Circle().stroke(RadioTheme.amber.opacity(0.5))
            HStack(alignment: .center, spacing: 4) {
                Capsule().frame(width: 4, height: 16)
                Capsule().frame(width: 4, height: 32)
                Capsule().frame(width: 4, height: 22)
            }
            .foregroundStyle(RadioTheme.amber)
        }
        .frame(width: 54, height: 54)
        .accessibilityHidden(true)
    }
}

struct BrandHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var eyebrow: String = "TECHNICIAN · ELEMENT 2"
    var title: String = "Radio License Study"

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        BrandMark()
                        Spacer(minLength: 12)
                        statusDot
                    }
                    labels
                }
            } else {
                HStack(spacing: 14) {
                    BrandMark()
                    labels
                    Spacer(minLength: 0)
                    statusDot
                }
            }
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(eyebrow)
                .font(.caption.weight(.heavy))
                .tracking(1.4)
                .foregroundStyle(RadioTheme.amber)
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(RadioTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusDot: some View {
        Circle().fill(RadioTheme.green).frame(width: 8, height: 8).shadow(color: RadioTheme.green, radius: 7)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(RadioTheme.onAccent)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? RadioTheme.amber2 : RadioTheme.amber)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(configuration.isPressed ? RadioTheme.cyan : RadioTheme.text)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 14)
            .background(RadioTheme.ink2.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(RadioTheme.line))
    }
}
