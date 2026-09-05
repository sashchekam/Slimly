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
        // Формат фиксированный, поэтому и локаль фиксированная: с календарём
        // пользователя «2026» превратилось бы в год другой эры, а имена
        // файлов должны сортироваться одинаково у всех.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Двоеточие «Файлы» показывают косой чертой — время разделяем дефисом.
        formatter.dateFormat = "yyyy-MM-dd HH-mm"
        let stamp = formatter.string(from: date)
        return L10n.Scan.fileName(stamp)
    }
}
