import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation
import UIKit

/// Что приложение отправило в аналитику с этого запуска.
@MainActor
@Observable
public final class DebugAnalyticsViewModel {
    /// Строка списка — одна отправка.
    public struct Entry: Identifiable, Sendable {
        public let id: UUID
        public let name: String
        public let time: String
        /// Параметры в одну строку — то, что видно, пока строка не раскрыта.
        public let summary: String
        /// Пустой список значит «раскрывать нечего»: у события без параметров
        /// и у свойства всё уже написано в самой строке.
        public let parameters: [Parameter]

        public var isExpandable: Bool { !parameters.isEmpty }
    }

    public struct Parameter: Identifiable, Sendable {
        /// Имя — оно же идентификатор: двух одинаковых ключей в словаре нет.
        public var id: String { name }
        public let name: String
        public let value: String
    }

    public private(set) var toast: String?

    /// Выбранный префикс модуля; `nil` — показываем всё.
    public private(set) var scope: String?

    private let log: AnalyticsLog
    private let router: Router

    /// Раскрытые строки. Параметры всех событий сразу превращают список
    /// в стену текста, по которой уже не видно порядка отправки.
    private var expanded: Set<UUID> = []

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    /// Свойства собраны в свою группу: их имена не начинаются с префикса
    /// модуля, и делить их по первому слову бессмысленно —
    /// «has_saved_result» дал бы группу «has».
    private static var propertiesScope: String { L10n.Analytics.properties }

    /// Время с секундами и без даты: журнал не переживает перезапуск,
    /// так что всё в нём случилось только что.
    private static let clock = Date.FormatStyle(date: .omitted, time: .standard)

    public init(log: AnalyticsLog, router: Router) {
        self.log = log
        self.router = router
    }

    public var entries: [Entry] {
        visible.map(Self.entry(for:))
    }

    /// Префиксы, которые в журнале есть. Пока префикс один, фильтра нет:
    /// чипы предлагали бы выбор из единственного варианта.
    public var scopes: [String] {
        let names = Set(log.records.map(Self.scope(of:)))

        return names.count > 1 ? names.sorted() : []
    }

    public var isEmpty: Bool {
        log.records.isEmpty
    }

    public var capacity: Int {
        log.capacity
    }

    public func isSelected(_ scope: String?) -> Bool {
        self.scope == scope
    }

    public func select(_ scope: String?) {
        self.scope = scope
    }

    /// Раскрытой считается только строка, у которой есть что показать:
    /// иначе у свойства пропала бы единственная строка с его значением.
    public func isExpanded(_ entry: Entry) -> Bool {
        entry.isExpandable && expanded.contains(entry.id)
    }

    public func toggle(_ entry: Entry) {
        guard entry.isExpandable else { return }

        if expanded.contains(entry.id) {
            expanded.remove(entry.id)
        } else {
            expanded.insert(entry.id)
        }
    }

    /// В буфер уходит ровно то, что на экране: с тем же фильтром и в том же
    /// порядке. Журнал забирают, чтобы приложить к описанию бага, и объяснять
    /// потом расхождение с увиденным незачем.
    public func copyAll() {
        let lines = visible.map { record in
            "\(record.date.formatted(Self.clock))  \(record.name)  \(Self.summary(of: record))"
        }
        // Буфер обмена SwiftUI не отдаёт — за ним приходится идти в UIKit.
        UIPasteboard.general.string = lines.joined(separator: "\n")
        say(L10n.Analytics.copied)
    }

    /// Очистка — это не уборка, а способ смотреть: журнал чистят перед
    /// проверяемым флоу, чтобы в списке остался только он.
    public func clear() {
        log.clear()
        expanded.removeAll()
        scope = nil
        say(L10n.Analytics.logCleared)
    }

    public func goBack() {
        router.pop()
    }

    /// Свежие записи сверху: смотрят обычно то, что нажали минуту назад.
    private var visible: [AnalyticsRecord] {
        log.records
            .reversed()
            .filter { scope == nil || Self.scope(of: $0) == scope }
    }

    private static func entry(for record: AnalyticsRecord) -> Entry {
        Entry(
            id: record.id,
            name: record.name,
            time: record.date.formatted(clock),
            summary: summary(of: record),
            parameters: parameters(of: record)
        )
    }

    private static func parameters(of record: AnalyticsRecord) -> [Parameter] {
        guard case let .event(parameters) = record.content else { return [] }

        // По алфавиту: одинаковые события должны выглядеть одинаково, иначе
        // их не сравнить глазами.
        return parameters
            .sorted { $0.key < $1.key }
            .map { Parameter(name: $0.key, value: $0.value.text) }
    }

    private static func summary(of record: AnalyticsRecord) -> String {
        switch record.content {
        case .event:
            parameters(of: record)
                .map { "\($0.name)=\($0.value)" }
                .joined(separator: " · ")
        case let .property(value):
            L10n.Analytics.property(value ?? L10n.Analytics.valueCleared)
        }
    }

    /// Префикс модуля — первое слово имени: собирает имя `FeatureAnalytics`,
    /// и отдельным полем префикс в событие не приезжает.
    private static func scope(of record: AnalyticsRecord) -> String {
        guard case .event = record.content else { return propertiesScope }

        return String(record.name.prefix { $0 != "_" })
    }

    private func say(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }
}
