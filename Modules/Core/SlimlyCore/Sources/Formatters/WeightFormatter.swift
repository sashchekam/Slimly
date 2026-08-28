import Foundation

public enum WeightFormatter {
    public static func string(_ weight: Measurement<UnitMass>) -> String {
        weight.formatted(
            .measurement(width: .abbreviated, usage: .personWeight, numberFormatStyle: .number.precision(.fractionLength(0...1)))
        )
    }

    /// «Осталось 8 кг» / «Цель достигнута».
    public static func progress(
        from current: Measurement<UnitMass>,
        to goal: Measurement<UnitMass>
    ) -> String {
        let remaining = current.converted(to: .kilograms).value - goal.converted(to: .kilograms).value
        guard remaining > 0 else { return "Цель достигнута" }
        return "Осталось \(string(.init(value: remaining, unit: UnitMass.kilograms)))"
    }
}
