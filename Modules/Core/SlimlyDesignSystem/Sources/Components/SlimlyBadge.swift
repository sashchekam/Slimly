import SwiftUI

/// Пилюля с дельтой сжатия: «−64%».
public struct SlimlyDeltaBadge: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.slimlyPill)
            .foregroundStyle(SlimlyColor.accent300)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(SlimlyColor.accent900, in: Capsule())
    }
}
