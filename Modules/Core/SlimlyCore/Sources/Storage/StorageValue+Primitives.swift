import Foundation

extension Bool: StorageValue {
    public init?(stored: StoredValue) {
        guard case let .bool(value) = stored else { return nil }

        self = value
    }

    public var stored: StoredValue { .bool(self) }
}

extension Int: StorageValue {
    public init?(stored: StoredValue) {
        guard case let .int(value) = stored else { return nil }

        self = value
    }

    public var stored: StoredValue { .int(self) }
}

extension Double: StorageValue {
    public init?(stored: StoredValue) {
        guard case let .double(value) = stored else { return nil }

        self = value
    }

    public var stored: StoredValue { .double(self) }
}

extension String: StorageValue {
    public init?(stored: StoredValue) {
        guard case let .string(value) = stored else { return nil }

        self = value
    }

    public var stored: StoredValue { .string(self) }
}

extension Data: StorageValue {
    public init?(stored: StoredValue) {
        guard case let .data(value) = stored else { return nil }

        self = value
    }

    public var stored: StoredValue { .data(self) }
}
