import SwiftUI

public struct SlimlyButtonStyle: ButtonStyle {
    public enum Kind: Sendable { case primary, secondary }

    private let kind: Kind

    public init(kind: Kind = .primary) { self.kind = kind }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.slimlyButton)
            .foregroundStyle(kind == .primary ? Color.white : SlimlyColor.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SlimlySpacing.m)
            .background(kind == .primary ? SlimlyColor.accent : SlimlyColor.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == SlimlyButtonStyle {
    static var slimlyPrimary: SlimlyButtonStyle { SlimlyButtonStyle(kind: .primary) }
    static var slimlySecondary: SlimlyButtonStyle { SlimlyButtonStyle(kind: .secondary) }
}
