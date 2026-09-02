import Foundation

/// Имя собранного документа.
protocol DocumentNaming: Sendable {
    func name(at date: Date) -> String
}

/// «Скан 2026-08-30 14-23.pdf».
///
/// Дата в имени, потому что своего имени у документа нет: страницы
/// приходят из медиатеки под номерами камеры, а сканов в папке
/// со временем накапливается много.
struct ScanDocumentNamer: DocumentNaming {
    func name(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        // Двоеточие «Файлы» показывают косой чертой — время разделяем дефисом.
        formatter.dateFormat = "yyyy-MM-dd HH-mm"
        return "Скан \(formatter.string(from: date)).pdf"
    }
}
