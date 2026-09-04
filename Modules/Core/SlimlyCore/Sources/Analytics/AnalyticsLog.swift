import Foundation
import Observation

/// Строка журнала: что ушло в аналитику и когда.
public struct AnalyticsRecord: Identifiable, Sendable, Hashable {
    /// События и свойства лежат в одном списке: свойство уедет со всеми
    /// следующими событиями, и смотреть его отдельно — значит не заметить,
    /// что оно встало позже, чем нужно.
    public enum Content: Sendable, Hashable {
        case event(parameters: [String: AnalyticsValue])
        /// `nil` — свойство сняли.
        case property(value: String?)
    }

    public let id: UUID
    public let name: String
    public let content: Content
    public let date: Date

    /// Время ставится в момент создания записи, а не в момент попадания
    /// в журнал: до журнала запись добирается прыжком на главный поток,
    /// и показывать нужно момент отправки.
    public init(name: String, content: Content, date: Date = Date(), id: UUID = UUID()) {
        self.name = name
        self.content = content
        self.date = date
        self.id = id
    }
}

/// Журнал отправленной аналитики — зеркало для отладочного меню.
///
/// Живёт в памяти и только до перезапуска: журнал нужен, чтобы посмотреть
/// только что пройденный флоу, а не собрать историю установки. Отсюда и
/// предел на количество: длинный список всё равно никто не пролистает,
/// а память он держит.
@MainActor
@Observable
public final class AnalyticsLog {
    public private(set) var records: [AnalyticsRecord] = []

    /// Сколько последних записей остаётся. Число видно на экране журнала,
    /// поэтому оно и не спрятано в приватную константу.
    public let capacity: Int

    public init(capacity: Int = 300) {
        self.capacity = capacity
    }

    public func append(_ record: AnalyticsRecord) {
        // Записи приходят с разных потоков и до главного добираются не в том
        // порядке, в каком отправлялись: место ищем по времени отправки,
        // иначе соседние события меняются в списке местами.
        let index = records.lastIndex { $0.date <= record.date }.map { $0 + 1 } ?? 0
        records.insert(record, at: index)

        if records.count > capacity {
            records.removeFirst(records.count - capacity)
        }
    }

    public func clear() {
        records.removeAll()
    }
}
