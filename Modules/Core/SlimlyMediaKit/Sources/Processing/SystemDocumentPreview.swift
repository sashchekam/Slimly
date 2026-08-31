import QuickLook
import SwiftUI
import UIKit

/// Системный просмотр документа во весь экран.
///
/// Своего экрана для PDF нет намеренно: QuickLook уже умеет страницы, зум,
/// поиск и отправку — повторять это значило бы делать хуже то, что у системы
/// работает и выглядит привычно.
public struct SystemDocumentPreview: UIViewControllerRepresentable {
    private let url: URL
    private let onClose: () -> Void

    public init(url: URL, onClose: @escaping () -> Void) {
        self.url = url
        self.onClose = onClose
    }

    public func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator
        // «Готово» QuickLook рисует сам, только когда его показали модально
        // из UIKit; здесь модалку держит роутер, поэтому кнопка своя.
        preview.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [onClose] _ in onClose() }
        )
        return UINavigationController(rootViewController: preview)
    }

    public func updateUIViewController(_ controller: UINavigationController, context: Context) {
        guard context.coordinator.item as URL != url else { return }
        context.coordinator.item = url as NSURL
        (controller.viewControllers.first as? QLPreviewController)?.reloadData()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(item: url as NSURL)
    }

    @MainActor
    public final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var item: NSURL

        init(item: NSURL) {
            self.item = item
        }

        public func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        public func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            item
        }
    }
}
