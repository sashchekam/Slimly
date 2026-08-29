import SwiftUI

/// Тумблер Nocturne. Строка целиком остаётся зоной нажатия — так же,
/// как в макете, — но остаётся настоящим `Toggle`, поэтому VoiceOver читает
/// его состоянием, а не картинкой.
public struct SlimlyToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                knobTrack(isOn: configuration.isOn)
            }
        }
        .buttonStyle(.plain)
    }

    private func knobTrack(isOn: Bool) -> some View {
        Capsule()
            .fill(isOn ? SlimlyColor.accent600 : SlimlyColor.neutral800)
            .frame(width: SlimlySize.toggleWidth, height: SlimlySize.toggleHeight)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(SlimlyColor.neutral100)
                    .padding(2)
                    .offset(x: isOn ? SlimlySize.toggleWidth - SlimlySize.toggleHeight : 0)
            }
            .animation(.easeOut(duration: 0.18), value: isOn)
    }
}

public extension ToggleStyle where Self == SlimlyToggleStyle {
    static var slimly: SlimlyToggleStyle { SlimlyToggleStyle() }
}
