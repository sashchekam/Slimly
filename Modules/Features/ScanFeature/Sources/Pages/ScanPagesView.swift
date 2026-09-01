import SwiftUI
import UIKit
import SlimlyCore
import SlimlyDesignSystem

/// Шаг «границы страниц»: страница крупно с рамкой, лента остальных внизу.
///
/// Один экран на все страницы, а не по экрану на каждую: границы правят
/// подряд, и уходить-возвращаться ради каждой страницы значило бы делать
/// из одного дела пять.
public struct ScanPagesView: View {
    /// Высота строки действий — по компактной кнопке.
    private static let actionsHeight: CGFloat = 34

    @State private var viewModel: ScanPagesViewModel

    public init(viewModel: ScanPagesViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            // Экран не скроллится намеренно: углы рамки тянут пальцем, и
            // вертикальный скролл перехватывал бы ровно то движение, которым
            // её и правят. Кадр забирает всё оставшееся место — на маленьком
            // экране он просто меньше.
            VStack(alignment: .leading, spacing: 14) {
                header
                editor
                hint
                actions

                if viewModel.hasMultiplePages {
                    strip
                }
            }
            .padding(.horizontal, SlimlySpacing.screenHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            SlimlyBottomAction {
                Button(viewModel.ctaTitle) { viewModel.proceed() }
                    .buttonStyle(.slimlyPrimary)
            }
        }
        .slimlyScreen()
        .task { await viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.title)
                .font(.slimlyTitle)
                .tracking(SlimlyTracking.title)

            Text(viewModel.subtitle)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral400)
        }
    }

    private var editor: some View {
        PageBoundsEditor(
            image: image(for: viewModel.page),
            fallbackAspectRatio: aspectRatio(for: viewModel.page.item),
            quad: viewModel.page.quad,
            onMove: { viewModel.move($0, to: $1) }
        )
        // Ручки углов наполовину выходят за кадр — без запаса они обрезались бы
        // о края экрана ровно там, где за них и тянут.
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Кадр меняется вместе со страницей, и без ключа SwiftUI переносит
        // на новую страницу состояние перетаскивания со старой.
        .id(viewModel.page.id)
    }

    private var hint: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.page.isReady ? SlimlyColor.accent : SlimlyColor.neutral600)
                .frame(width: 6, height: 6)

            Text(viewModel.hint)
                .font(.slimlyCaption)
                .foregroundStyle(SlimlyColor.neutral400)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Обе кнопки — на случай, когда что-то пошло не так: вернуть найденное
    /// после случайной правки и распрямить рамку по кадру, когда обрезать
    /// нечего. В обычном ходе дел они не нужны, поэтому и не показываются —
    /// но место под них держим всегда: кадр забирает остаток экрана, и
    /// появись строка внезапно, страница уехала бы прямо под пальцем.
    private var actions: some View {
        HStack(spacing: 10) {
            if viewModel.canResetToDetected {
                Button("Сбросить") { viewModel.resetToDetected() }
                    .buttonStyle(.slimlyCompact)
                    .transition(.opacity)
            }

            if viewModel.canUseWholeFrame {
                Button("Без обрезки") { viewModel.useWholeFrame() }
                    .buttonStyle(.slimlyCompact)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .frame(height: Self.actionsHeight, alignment: .leading)
        .animation(.easeOut(duration: 0.18), value: actionsKey)
    }

    /// По чему анимируется появление кнопок: важна пара признаков, а не
    /// каждый по отдельности.
    private var actionsKey: [Bool] {
        [viewModel.canResetToDetected, viewModel.canUseWholeFrame]
    }

    /// Лента страниц: миниатюра с той же рамкой, что стоит на большом кадре, —
    /// по ней видно, где границы уже поправлены, а где ещё нет.
    private var strip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { position, page in
                    Button {
                        viewModel.select(position)
                    } label: {
                        PageThumbnail(
                            image: image(for: page),
                            quad: page.quad,
                            number: position + 1,
                            isCurrent: viewModel.isCurrent(page),
                            isManual: page.isManual
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Страница \(position + 1)")
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Кадр

    private func image(for page: ScanPagesViewModel.Page) -> UIImage? {
        page.imageData.flatMap(UIImage.init(data:))
    }

    private func aspectRatio(for item: MediaItem) -> CGFloat {
        guard item.pixelWidth > 0, item.pixelHeight > 0 else { return 3.0 / 4.0 }
        return CGFloat(item.pixelWidth) / CGFloat(item.pixelHeight)
    }
}

// MARK: - Лента

/// Страница в ленте: кадр, номер и рамка поверх.
private struct PageThumbnail: View {
    let image: UIImage?
    let quad: DocumentQuad
    let number: Int
    let isCurrent: Bool
    let isManual: Bool

    private static let side: CGFloat = 58

    var body: some View {
        ZStack {
            SlimlyStripes.thumbnail

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }

            // Та же рамка, что и на большом кадре: миниатюра обрезана
            // до квадрата, поэтому линия здесь не обещание, а напоминание,
            // — но по ней сразу видно, какая страница уже размечена.
            GeometryReader { geometry in
                Path { path in
                    path.addLines(
                        quad.corners.map {
                            CGPoint(x: $0.x * geometry.size.width, y: $0.y * geometry.size.height)
                        }
                    )
                    path.closeSubpath()
                }
                .stroke(SlimlyColor.accent200.opacity(0.9), lineWidth: 1)
            }
        }
        .frame(width: Self.side, height: Self.side)
        .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous)
                .strokeBorder(
                    isCurrent ? SlimlyColor.accent : SlimlyColor.text.opacity(0.12),
                    lineWidth: isCurrent ? 2 : 1
                )
        }
        .overlay(alignment: .bottomLeading) {
            Text("\(number)")
                .font(.slimlyNano)
                .foregroundStyle(SlimlyColor.neutral200)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(SlimlyColor.tileCaption, in: RoundedRectangle(cornerRadius: SlimlyRadius.sm))
                .padding(4)
        }
        .overlay(alignment: .topTrailing) {
            // Точка вместо подписи: место есть только на неё, а знать нужно
            // одно — эту страницу человек уже размечал сам.
            if isManual {
                Circle()
                    .fill(SlimlyColor.accent)
                    .frame(width: 7, height: 7)
                    .padding(5)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous))
    }
}
