import SwiftUI
import SlimlyDesignSystem
import SlimlyNavigation

/// Выбор источника страниц: камера или галерея.
///
/// Шторка, а не экран: выбрать источник — это одно касание, и ради него
/// уводить с хаба незачем. По тапу шторка уходит, а на её месте
/// открывается уже сам источник.
public struct ScanIntroView: View {
    @State private var viewModel: ScanIntroViewModel

    public init(viewModel: ScanIntroViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        SlimlySheetScaffold(
            title: "Скан документа",
            onCancel: { viewModel.cancel() }
        ) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Найдём границы листа, выпрямим страницу и соберём в PDF — рамку можно поправить вручную")
                    .font(.slimlyBodySmall)
                    .foregroundStyle(SlimlyColor.neutral400)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    viewModel.openCamera()
                } label: {
                    SourceRow(
                        icon: .camera,
                        title: "Снять на камеру",
                        subtitle: "Границы ловим на лету, поправить можно после",
                        isAccented: true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.openGallery()
                } label: {
                    SourceRow(
                        icon: .gallery,
                        title: "Выбрать фото",
                        subtitle: "До \(ScanFeature.pageLimit) страниц из галереи",
                        isAccented: false
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheetHeight(310)
    }
}

private struct SourceRow: View {
    let icon: SlimlyIcon.Kind
    let title: String
    let subtitle: String
    let isAccented: Bool

    var body: some View {
        HStack(spacing: 13) {
            SlimlyIcon(icon, width: 24)
                .foregroundStyle(isAccented ? SlimlyColor.accent300 : SlimlyColor.neutral300)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isAccented ? SlimlyColor.accent100 : SlimlyColor.text)
                Text(subtitle)
                    .font(.slimlyCaption)
                    .foregroundStyle(isAccented ? SlimlyColor.neutral400 : SlimlyColor.neutral500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SlimlyIcon(.chevronRight, width: 7)
                .foregroundStyle(isAccented ? SlimlyColor.accent400 : SlimlyColor.neutral600)
        }
        .multilineTextAlignment(.leading)
        .padding(16)
        .background(
            isAccented ? SlimlyColor.accentTint(10) : SlimlyColor.surface,
            in: RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
        )
        .overlay {
            if isAccented {
                RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
                    .strokeBorder(SlimlyColor.accent600, lineWidth: 1)
            }
        }
        .slimlyElevation(isAccented ? .flat : .sm)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
